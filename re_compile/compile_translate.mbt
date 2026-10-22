// CompileTranslate — AST to Expr translation (port of lib/compile.ml lines 691-883)

// --- context ---

///|
priv struct CompileContext {
  ids : @base.Ids
  kind : @base.Sem
  ign_group : Bool
  greedy : @base.RepKind
  pos : Ref[Int32]
  names : Ref[Array[(String, Int32)]]
  cache : Ref[@base.CSetMap]
  colors : @ast.ColorTable
  boundary_table : @ast.BoundaryTable
}

// --- enforce_kind ---

///|
fn enforce_kind(ids : @base.Ids, kind : @base.Sem, kind2 : @base.Sem, cr : @ast.Expr) -> @ast.Expr {
  match (kind, kind2) {
    (First, First) => cr
    (First, k) => @ast.Expr::seq(ids, k, cr, @ast.Expr::eps(ids))
    (_, _) => cr
  }
}

// --- trans_set ---

///|
fn trans_set(
  cache : Ref[@base.CSetMap],
  cm : @ast.ColorTable,
  boundary_table : @ast.BoundaryTable,
  s : @base.Cset,
) -> @base.Cset {
  match @base.Cset::one_char(s) {
    Some(i) => @base.Cset::csingle(cm.get_char(i).to_int().unsafe_to_char())
    None => {
      let v = (@base.Cset::hash(s), s)
      match @base.CSetMap::find(cache.val, v) {
        Some(l) => l
        None => {
          let l = @ast.ColorTable::translate_colors(cm, boundary_table, s)
          cache.val = @base.CSetMap::add(cache.val, v, l)
          l
        }
      }
    }
  }
}

// --- make_repeater ---

///|
fn make_repeater(
  ids : @base.Ids,
  cr : @ast.Expr,
  kind : @base.Sem,
  greedy : @base.RepKind,
) -> (@ast.Expr) -> @ast.Expr {
  match greedy {
    @base.Greedy =>
      fn(rem) {
        @ast.Expr::alt(ids, [
          @ast.Expr::seq(ids, kind, @ast.Expr::rename(ids, cr), rem),
          @ast.Expr::eps(ids),
        ])
      }
    @base.NonGreedy =>
      fn(rem) {
        @ast.Expr::alt(ids, [
          @ast.Expr::eps(ids),
          @ast.Expr::seq(ids, kind, @ast.Expr::rename(ids, cr), rem),
        ])
      }
  }
}

// --- iter (apply f n times) ---

///|
fn iter_n(n : Int32, f : (@ast.Expr) -> @ast.Expr, v : @ast.Expr) -> @ast.Expr {
  if n == 0 {
    v
  } else {
    iter_n(n - 1, f, f(v))
  }
}

// --- translate ---

///|
fn translate(ctx : CompileContext, ast : @ast.AstNoCase) -> (@ast.Expr, @base.Sem) {
  match ast {
    Set(s) => {
      let cset = trans_set(ctx.cache, ctx.colors, ctx.boundary_table, s)
      (@ast.Expr::cst(ctx.ids, cset), ctx.kind)
    }
    Sequence(l) => {
      let ctx2 = { ..ctx, kind: @base.Sem::first(), }
      (trans_seq(ctx2, l, 0), ctx.kind)
    }
    AstNode(Alternative(l)) => {
      let merged = @ast.Ast::merge_sequences_no_case(l)
      if merged.length() == 1 {
        translate(ctx, merged[0])
      } else {
        let results : Array[@ast.Expr] = []
        for r in merged {
          let (cr, kind2) = translate(ctx, r)
          results.push(enforce_kind(ctx.ids, ctx.kind, kind2, cr))
        }
        (@ast.Expr::alt(ctx.ids, results), ctx.kind)
      }
    }
    AstNode(NoCase(r)) => translate(ctx, r)
    AstNode(Case(r)) => translate(ctx, r)
    Repeat(r, i, j) => {
      let ctx2 = { ..ctx, kind: @base.Sem::first(), }
      let (cr, kind2) = translate(ctx2, r)
      let rem = match j {
        None => @ast.Expr::rep(ctx.ids, ctx.greedy, kind2, cr)
        Some(jv) => {
          let f = make_repeater(ctx.ids, cr, kind2, ctx.greedy)
          iter_n(jv - i, f, @ast.Expr::eps(ctx.ids))
        }
      }
      let result = iter_n(
        i,
        fn(rem2) { @ast.Expr::seq(ctx.ids, kind2, @ast.Expr::rename(ctx.ids, cr), rem2) },
        rem,
      )
      (result, ctx.kind)
    }
    BegOfLine => {
      let cat = @base.Category::add(@base.Category::inexistant(), @base.Category::newline())
      (@ast.Expr::after(ctx.ids, cat), ctx.kind)
    }
    EndOfLine => {
      let cat = @base.Category::add(@base.Category::inexistant(), @base.Category::newline())
      (@ast.Expr::before(ctx.ids, cat), ctx.kind)
    }
    BegOfWord => {
      let cat1 = @base.Category::add(@base.Category::inexistant(), @base.Category::not_letter())
      let e1 = @ast.Expr::after(ctx.ids, cat1)
      let e2 = @ast.Expr::before(ctx.ids, @base.Category::letter())
      (@ast.Expr::seq(ctx.ids, @base.Sem::first(), e1, e2), ctx.kind)
    }
    EndOfWord => {
      let e1 = @ast.Expr::after(ctx.ids, @base.Category::letter())
      let cat = @base.Category::add(@base.Category::inexistant(), @base.Category::not_letter())
      let e2 = @ast.Expr::before(ctx.ids, cat)
      (@ast.Expr::seq(ctx.ids, @base.Sem::first(), e1, e2), ctx.kind)
    }
    NotBound => {
      let cat1 = @base.Category::add(@base.Category::inexistant(), @base.Category::not_letter())
      let e1 = @ast.Expr::seq(
        ctx.ids,
        @base.Sem::first(),
        @ast.Expr::after(ctx.ids, @base.Category::letter()),
        @ast.Expr::before(ctx.ids, @base.Category::letter()),
      )
      let e2 = @ast.Expr::seq(
        ctx.ids,
        @base.Sem::first(),
        @ast.Expr::after(ctx.ids, cat1),
        @ast.Expr::before(ctx.ids, cat1),
      )
      (@ast.Expr::alt(ctx.ids, [e1, e2]), ctx.kind)
    }
    BegOfStr => (@ast.Expr::after(ctx.ids, @base.Category::inexistant()), ctx.kind)
    EndOfStr => (@ast.Expr::before(ctx.ids, @base.Category::inexistant()), ctx.kind)
    LastEndOfLine => {
      let cat = @base.Category::add(@base.Category::inexistant(), @base.Category::lastnewline())
      (@ast.Expr::before(ctx.ids, cat), ctx.kind)
    }
    Start => (@ast.Expr::after(ctx.ids, @base.Category::search_boundary()), ctx.kind)
    Stop => (@ast.Expr::before(ctx.ids, @base.Category::search_boundary()), ctx.kind)
    @ast.Sem(kind2, r) => {
      let ctx2 = { ..ctx, kind: kind2, }
      let (cr, kind3) = translate(ctx2, r)
      (enforce_kind(ctx.ids, kind2, kind3, cr), kind2)
    }
    SemGreedy(greedy2, r) => {
      let ctx2 = { ..ctx, greedy: greedy2, }
      translate(ctx2, r)
    }
    Group(n, r) =>
      if ctx.ign_group {
        translate(ctx, r)
      } else {
        let p = ctx.pos.val
        match n {
          Some(name) => ctx.names.val.push((name, @base.Mark::group_count(p)))
          None => ()
        }
        ctx.pos.val = @base.Mark::next2(ctx.pos.val)
        let (cr, kind2) = translate(ctx, r)
        let e1 = @ast.Expr::mark(ctx.ids, p)
        let e2 = @ast.Expr::mark(ctx.ids, @base.Mark::next(p))
        let result = @ast.Expr::seq(
          ctx.ids,
          @base.Sem::first(),
          e1,
          @ast.Expr::seq(ctx.ids, @base.Sem::first(), cr, e2),
        )
        (result, kind2)
      }
    NoGroup(r) => {
      let ctx2 = { ..ctx, ign_group: true, }
      translate(ctx2, r)
    }
    Nest(r) => {
      let b = ctx.pos.val
      let (cr, kind2) = translate(ctx, r)
      let e = @base.Mark::prev(ctx.pos.val)
      if @base.Mark::compare(e, b) == -1 {
        (cr, kind2)
      } else {
        (
          @ast.Expr::seq(ctx.ids, @base.Sem::first(), @ast.Expr::erase(ctx.ids, b, e), cr),
          kind2,
        )
      }
    }
    @ast.Pmark(i, r) => {
      let (cr, kind2) = translate(ctx, r)
      (@ast.Expr::seq(ctx.ids, @base.Sem::first(), @ast.Expr::pmark(ctx.ids, i), cr), kind2)
    }
  }
}

// --- trans_seq ---

///|
fn trans_seq(ctx : CompileContext, l : Array[@ast.AstNoCase], start : Int32) -> @ast.Expr {
  if start >= l.length() {
    @ast.Expr::eps(ctx.ids)
  } else {
    let (cr1, kind1) = translate(ctx, l[start])
    let cr2 = trans_seq(ctx, l, start + 1)
    if @ast.Expr::is_eps(cr2) {
      enforce_kind(ctx.ids, ctx.kind, kind1, cr1)
    } else if @ast.Expr::is_eps(cr1) {
      cr2
    } else {
      @ast.Expr::seq(ctx.ids, kind1, cr1, cr2)
    }
  }
}

// --- compile_1 ---

///|
fn compile_1(regexp : @ast.Ast) -> Re {
  let regexp_nc = @ast.Ast::handle_case(regexp, false)
  let color_map = @ast.ColorMap::make()
  let need_lnl = @ast.Ast::colorize(color_map, regexp_nc)
  let (colors, boundary_table, color_repr) = @ast.ColorMap::flatten(color_map)
  let ncolor = @ast.ColorRepr::length(color_repr)
  let lnl = if need_lnl { @base.CsetC::of_int(ncolor) } else { @base.CsetC::null_char() }
  let ncolor2 = if need_lnl { ncolor + 1 } else { ncolor }
  let ctx = {
    ids: @base.Ids::create(),
    kind: @base.Sem::first(),
    ign_group: false,
    greedy: @base.RepKind::greedy(),
    pos: Ref::{ val: @base.Mark::start(), },
    names: Ref::{ val: [], },
    cache: Ref::{ val: @base.CSetMap::empty(), },
    colors,
    boundary_table,
  }
  let (r, kind) = translate(ctx, regexp_nc)
  let r2 = enforce_kind(ctx.ids, @base.Sem::first(), kind, r)
  let group_names = ctx.names.val
  let group_count = @base.Mark::group_count(ctx.pos.val)
  mk_re(
    initial=r2,
    colors~,
    color_repr~,
    ncolor=ncolor2,
    lnl~,
    group_names~,
    group_count~,
  )
}

// --- compile ---

///|
pub fn compile(r : @ast.Ast) -> Re {
  let r_nc = if @ast.Ast::anchored(r) {
    @ast.Ast::group(r)
  } else {
    @ast.Ast::seq([@ast.Ast::shortest(@ast.Ast::rep(@ast.Ast::any())), @ast.Ast::group(r)])
  }
  compile_1(r_nc)
}
