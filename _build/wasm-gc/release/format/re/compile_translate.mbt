// CompileTranslate — AST to Expr translation (port of lib/compile.ml lines 691-883)

// --- context ---

///|
priv struct CompileContext {
  ids : Ids
  kind : Sem
  ign_group : Bool
  greedy : RepKind
  pos : Ref[Int]
  names : Ref[Array[(String, Int)]]
  cache : Ref[CSetMap]
  colors : ColorTable
  boundary_table : BoundaryTable
}

// --- enforce_kind ---

///|
fn enforce_kind(ids : Ids, kind : Sem, kind2 : Sem, cr : Expr) -> Expr {
  match (kind, kind2) {
    (First, First) => cr
    (First, k) => Expr::seq(ids, k, cr, Expr::eps(ids))
    (_, _) => cr
  }
}

// --- trans_set ---

///|
fn trans_set(
  cache : Ref[CSetMap],
  cm : ColorTable,
  boundary_table : BoundaryTable,
  s : Cset,
) -> Cset {
  match Cset::one_char(s) {
    Some(i) => Cset::csingle(cm.get_char(i).to_int().unsafe_to_char())
    None => {
      let v = (Cset::hash(s), s)
      match CSetMap::find(cache.val, v) {
        Some(l) => l
        None => {
          let l = ColorTable::translate_colors(cm, boundary_table, s)
          cache.val = CSetMap::add(cache.val, v, l)
          l
        }
      }
    }
  }
}

// --- make_repeater ---

///|
fn make_repeater(
  ids : Ids,
  cr : Expr,
  kind : Sem,
  greedy : RepKind,
) -> (Expr) -> Expr {
  match greedy {
    Greedy =>
      fn(rem) {
        Expr::alt(ids, [
          Expr::seq(ids, kind, Expr::rename(ids, cr), rem),
          Expr::eps(ids),
        ])
      }
    NonGreedy =>
      fn(rem) {
        Expr::alt(ids, [
          Expr::eps(ids),
          Expr::seq(ids, kind, Expr::rename(ids, cr), rem),
        ])
      }
  }
}

// --- iter (apply f n times) ---

///|
fn iter_n(n : Int, f : (Expr) -> Expr, v : Expr) -> Expr {
  if n == 0 {
    v
  } else {
    iter_n(n - 1, f, f(v))
  }
}

// --- translate ---

///|
fn translate(ctx : CompileContext, ast : AstNoCase) -> (Expr, Sem) {
  match ast {
    Set(s) => {
      let cset = trans_set(ctx.cache, ctx.colors, ctx.boundary_table, s)
      (Expr::cst(ctx.ids, cset), ctx.kind)
    }
    Sequence(l) => {
      let ctx2 = { ..ctx, kind: Sem::first() }
      (trans_seq(ctx2, l, 0), ctx.kind)
    }
    AstNode(Alternative(l)) => {
      let merged = Ast::merge_sequences_no_case(l)
      if merged.length() == 1 {
        translate(ctx, merged[0])
      } else {
        let results : Array[Expr] = []
        for r in merged {
          let (cr, kind2) = translate(ctx, r)
          results.push(enforce_kind(ctx.ids, ctx.kind, kind2, cr))
        }
        (Expr::alt(ctx.ids, results), ctx.kind)
      }
    }
    AstNode(NoCase(r)) => translate(ctx, r)
    AstNode(Case(r)) => translate(ctx, r)
    Repeat(r, i, j) => {
      let ctx2 = { ..ctx, kind: Sem::first() }
      let (cr, kind2) = translate(ctx2, r)
      let rem = match j {
        None => Expr::rep(ctx.ids, ctx.greedy, kind2, cr)
        Some(jv) => {
          let f = make_repeater(ctx.ids, cr, kind2, ctx.greedy)
          iter_n(jv - i, f, Expr::eps(ctx.ids))
        }
      }
      let result = iter_n(
        i,
        fn(rem2) { Expr::seq(ctx.ids, kind2, Expr::rename(ctx.ids, cr), rem2) },
        rem,
      )
      (result, ctx.kind)
    }
    BegOfLine => {
      let cat = Category::add(Category::inexistant(), Category::newline())
      (Expr::after(ctx.ids, cat), ctx.kind)
    }
    EndOfLine => {
      let cat = Category::add(Category::inexistant(), Category::newline())
      (Expr::before(ctx.ids, cat), ctx.kind)
    }
    BegOfWord => {
      let cat1 = Category::add(Category::inexistant(), Category::not_letter())
      let e1 = Expr::after(ctx.ids, cat1)
      let e2 = Expr::before(ctx.ids, Category::letter())
      (Expr::seq(ctx.ids, Sem::first(), e1, e2), ctx.kind)
    }
    EndOfWord => {
      let e1 = Expr::after(ctx.ids, Category::letter())
      let cat = Category::add(Category::inexistant(), Category::not_letter())
      let e2 = Expr::before(ctx.ids, cat)
      (Expr::seq(ctx.ids, Sem::first(), e1, e2), ctx.kind)
    }
    NotBound => {
      let cat1 = Category::add(Category::inexistant(), Category::not_letter())
      let e1 = Expr::seq(
        ctx.ids,
        Sem::first(),
        Expr::after(ctx.ids, Category::letter()),
        Expr::before(ctx.ids, Category::letter()),
      )
      let e2 = Expr::seq(
        ctx.ids,
        Sem::first(),
        Expr::after(ctx.ids, cat1),
        Expr::before(ctx.ids, cat1),
      )
      (Expr::alt(ctx.ids, [e1, e2]), ctx.kind)
    }
    BegOfStr => (Expr::after(ctx.ids, Category::inexistant()), ctx.kind)
    EndOfStr => (Expr::before(ctx.ids, Category::inexistant()), ctx.kind)
    LastEndOfLine => {
      let cat = Category::add(Category::inexistant(), Category::lastnewline())
      (Expr::before(ctx.ids, cat), ctx.kind)
    }
    Start => (Expr::after(ctx.ids, Category::search_boundary()), ctx.kind)
    Stop => (Expr::before(ctx.ids, Category::search_boundary()), ctx.kind)
    Sem(kind2, r) => {
      let ctx2 = { ..ctx, kind: kind2 }
      let (cr, kind3) = translate(ctx2, r)
      (enforce_kind(ctx.ids, kind2, kind3, cr), kind2)
    }
    SemGreedy(greedy2, r) => {
      let ctx2 = { ..ctx, greedy: greedy2 }
      translate(ctx2, r)
    }
    Group(n, r) =>
      if ctx.ign_group {
        translate(ctx, r)
      } else {
        let p = ctx.pos.val
        match n {
          Some(name) => ctx.names.val.push((name, Mark::group_count(p)))
          None => ()
        }
        ctx.pos.val = Mark::next2(ctx.pos.val)
        let (cr, kind2) = translate(ctx, r)
        let e1 = Expr::mark(ctx.ids, p)
        let e2 = Expr::mark(ctx.ids, Mark::next(p))
        let result = Expr::seq(
          ctx.ids,
          Sem::first(),
          e1,
          Expr::seq(ctx.ids, Sem::first(), cr, e2),
        )
        (result, kind2)
      }
    NoGroup(r) => {
      let ctx2 = { ..ctx, ign_group: true }
      translate(ctx2, r)
    }
    Nest(r) => {
      let b = ctx.pos.val
      let (cr, kind2) = translate(ctx, r)
      let e = Mark::prev(ctx.pos.val)
      if Mark::compare(e, b) == -1 {
        (cr, kind2)
      } else {
        (
          Expr::seq(ctx.ids, Sem::first(), Expr::erase(ctx.ids, b, e), cr),
          kind2,
        )
      }
    }
    Pmark(i, r) => {
      let (cr, kind2) = translate(ctx, r)
      (Expr::seq(ctx.ids, Sem::first(), Expr::pmark(ctx.ids, i), cr), kind2)
    }
  }
}

// --- trans_seq ---

///|
fn trans_seq(ctx : CompileContext, l : Array[AstNoCase], start : Int) -> Expr {
  if start >= l.length() {
    Expr::eps(ctx.ids)
  } else {
    let (cr1, kind1) = translate(ctx, l[start])
    let cr2 = trans_seq(ctx, l, start + 1)
    if Expr::is_eps(cr2) {
      enforce_kind(ctx.ids, ctx.kind, kind1, cr1)
    } else if Expr::is_eps(cr1) {
      cr2
    } else {
      Expr::seq(ctx.ids, kind1, cr1, cr2)
    }
  }
}

// --- compile_1 ---

///|
fn compile_1(regexp : Ast) -> Re {
  let regexp_nc = Ast::handle_case(regexp, false)
  let color_map = ColorMap::make()
  let need_lnl = Ast::colorize(color_map, regexp_nc)
  let (colors, boundary_table, color_repr) = ColorMap::flatten(color_map)
  let ncolor = ColorRepr::length(color_repr)
  let lnl = if need_lnl { CsetC::of_int(ncolor) } else { CsetC::null_char() }
  let ncolor2 = if need_lnl { ncolor + 1 } else { ncolor }
  let ctx = {
    ids: Ids::create(),
    kind: Sem::first(),
    ign_group: false,
    greedy: RepKind::greedy(),
    pos: Ref::{ val: Mark::start() },
    names: Ref::{ val: [] },
    cache: Ref::{ val: CSetMap::empty() },
    colors,
    boundary_table,
  }
  let (r, kind) = translate(ctx, regexp_nc)
  let r2 = enforce_kind(ctx.ids, Sem::first(), kind, r)
  let group_names = ctx.names.val
  let group_count = Mark::group_count(ctx.pos.val)
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
pub fn compile(r : Ast) -> Re {
  let r_nc = if Ast::anchored(r) {
    Ast::group(r)
  } else {
    Ast::seq([Ast::shortest(Ast::rep(Ast::any())), Ast::group(r)])
  }
  compile_1(r_nc)
}
