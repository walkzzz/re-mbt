// crap_test.mbt — CRAP coverage tests for re_ast
// Covers ast.mbt, automata_desc.mbt, automata_expr.mbt, automata_state.mbt

// === ast_to_dyn coverage (ast_to_dyn CRAP ~69) ===

///|
test "ast_to_dyn NoGroup Pmark Sem SemGreedy" {
  let _d1 = @re_ast.Ast::to_dyn(@re_ast.Ast::no_group(@re_ast.Ast::char('a')))
  let (pm, marked) = @re_ast.Ast::mark(@re_ast.Ast::char('a'))
  let _d2 = @re_ast.Ast::to_dyn(marked)
  ignore(pm)
  let _d3 = @re_ast.Ast::to_dyn(@re_ast.Ast::longest(@re_ast.Ast::char('a')))
  let _d4 = @re_ast.Ast::to_dyn(@re_ast.Ast::greedy(@re_ast.Ast::char('a')))
  let _d5 = @re_ast.Ast::to_dyn(@re_ast.Ast::shortest(@re_ast.Ast::char('a')))
  let _d6 = @re_ast.Ast::to_dyn(@re_ast.Ast::first(@re_ast.Ast::char('a')))
  let _d7 = @re_ast.Ast::to_dyn(@re_ast.Ast::non_greedy(@re_ast.Ast::char('a')))
}

///|
test "ast_to_dyn NoCase via no_case" {
  let _d = @re_ast.Ast::to_dyn(@re_ast.Ast::no_case(@re_ast.Ast::char('a')))
}

///|
test "ast_to_dyn Nest Group" {
  let _d1 = @re_ast.Ast::to_dyn(@re_ast.Ast::nest(@re_ast.Ast::char('a')))
  let _d2 = @re_ast.Ast::to_dyn(@re_ast.Ast::group(@re_ast.Ast::char('a')))
  let _d3 = @re_ast.Ast::to_dyn(
    @re_ast.Ast::group(name=Some("foo"), @re_ast.Ast::char('a')),
  )
}

///|
test "ast_to_dyn anchors" {
  let _d1 = @re_ast.Ast::to_dyn(@re_ast.Ast::bow())
  let _d2 = @re_ast.Ast::to_dyn(@re_ast.Ast::eow())
  let _d3 = @re_ast.Ast::to_dyn(@re_ast.Ast::not_boundary())
  let _d4 = @re_ast.Ast::to_dyn(@re_ast.Ast::leol())
  let _d5 = @re_ast.Ast::to_dyn(@re_ast.Ast::stop())
}

///|
test "ast_alt_to_dyn_cset Alternative" {
  let cset : @re_ast.AstCset = @re_ast.Cast(
    @re_ast.Alternative([
      @re_ast.CsetOf(@base.Cset::single(97)),
      @re_ast.CsetOf(@base.Cset::single(98)),
    ]),
  )
  let _d = @re_ast.Ast::to_dyn(@re_ast.Set(cset))
}

///|
test "Ast::t_of_cset" {
  let cset : @re_ast.AstCset = @re_ast.CsetOf(@base.Cset::single(97))
  let r = @re_ast.Ast::t_of_cset(cset)
  match r {
    Set(_) => assert_eq(true, true)
    _ => assert_eq(true, false)
  }
}

// === handle_case_cset coverage ===

///|
test "handle_case_cset Cast Alternative" {
  let cset : @re_ast.AstCset = @re_ast.Cast(
    @re_ast.Alternative([
      @re_ast.CsetOf(@base.Cset::single(97)),
      @re_ast.CsetOf(@base.Cset::single(98)),
    ]),
  )
  let r = @re_ast.Set(cset)
  let _ = @re_ast.Ast::handle_case(r, false)
}

///|
test "handle_case Pmark" {
  let (pm, marked) = @re_ast.Ast::mark(@re_ast.Ast::char('a'))
  let _ = @re_ast.Ast::handle_case(marked, false)
  ignore(pm)
}

// === Ast::anchored coverage (CRAP ~53) ===

///|
test "Ast::anchored Pmark NotBound Stop" {
  let (pm, marked) = @re_ast.Ast::mark(@re_ast.Ast::bos())
  assert_eq(@re_ast.Ast::anchored(marked), true)
  ignore(pm)
  assert_eq(@re_ast.Ast::anchored(@re_ast.Ast::not_boundary()), false)
  assert_eq(@re_ast.Ast::anchored(@re_ast.Ast::stop()), false)
}

// === merge_sequences coverage (CRAP ~52) ===

///|
test "merge_sequences same prefix" {
  let a = @re_ast.Ast::char('a')
  let b = @re_ast.Ast::char('b')
  let c = @re_ast.Ast::char('c')
  let d = @re_ast.Ast::char('d')
  let l = [@re_ast.Ast::seq([a, b]), @re_ast.Ast::seq([a, c]), d]
  let merged = @re_ast.Ast::merge_sequences(l)
  assert_eq(merged.length() >= 1, true)
}

///|
test "merge_sequences different prefix" {
  let a = @re_ast.Ast::char('a')
  let b = @re_ast.Ast::char('b')
  let c = @re_ast.Ast::char('c')
  let d = @re_ast.Ast::char('d')
  let l = [@re_ast.Ast::seq([a, b]), @re_ast.Ast::seq([c, d])]
  let merged = @re_ast.Ast::merge_sequences(l)
  assert_eq(merged.length() >= 1, true)
}

///|
test "merge_sequences non-seq rest" {
  let a = @re_ast.Ast::char('a')
  let b = @re_ast.Ast::char('b')
  let c = @re_ast.Ast::char('c')
  let l = [@re_ast.Ast::seq([a, b]), c]
  let merged = @re_ast.Ast::merge_sequences(l)
  assert_eq(merged.length() >= 1, true)
}

///|
test "merge_sequences empty seq" {
  let a = @re_ast.Ast::char('a')
  let l = [@re_ast.Ast::seq([]), a]
  let merged = @re_ast.Ast::merge_sequences(l)
  assert_eq(merged.length() >= 1, true)
}

///|
test "merge_sequences with alternative" {
  let a = @re_ast.Ast::char('a')
  let b = @re_ast.Ast::char('b')
  let c = @re_ast.Ast::char('c')
  let l = [@re_ast.Ast::alt([a, b]), c]
  let merged = @re_ast.Ast::merge_sequences(l)
  assert_eq(merged.length() >= 1, true)
}

// === merge_sequences_no_case coverage (CRAP ~81) ===

///|
test "merge_sequences_no_case same prefix" {
  let a = @re_ast.Ast::char('a')
  let b = @re_ast.Ast::char('b')
  let c = @re_ast.Ast::char('c')
  let d = @re_ast.Ast::char('d')
  let l = [
    @re_ast.Ast::handle_case(@re_ast.Ast::seq([a, b]), false),
    @re_ast.Ast::handle_case(@re_ast.Ast::seq([a, c]), false),
    @re_ast.Ast::handle_case(d, false),
  ]
  let merged = @re_ast.Ast::merge_sequences_no_case(l)
  assert_eq(merged.length() >= 1, true)
}

///|
test "merge_sequences_no_case different prefix" {
  let a = @re_ast.Ast::char('a')
  let b = @re_ast.Ast::char('b')
  let c = @re_ast.Ast::char('c')
  let d = @re_ast.Ast::char('d')
  let l = [
    @re_ast.Ast::handle_case(@re_ast.Ast::seq([a, b]), false),
    @re_ast.Ast::handle_case(@re_ast.Ast::seq([c, d]), false),
  ]
  let merged = @re_ast.Ast::merge_sequences_no_case(l)
  assert_eq(merged.length() >= 1, true)
}

///|
test "merge_sequences_no_case non-seq rest" {
  let a = @re_ast.Ast::char('a')
  let b = @re_ast.Ast::char('b')
  let c = @re_ast.Ast::char('c')
  let l = [
    @re_ast.Ast::handle_case(@re_ast.Ast::seq([a, b]), false),
    @re_ast.Ast::handle_case(c, false),
  ]
  let merged = @re_ast.Ast::merge_sequences_no_case(l)
  assert_eq(merged.length() >= 1, true)
}

///|
test "merge_sequences_no_case empty seq" {
  let a = @re_ast.Ast::char('a')
  let l = [
    @re_ast.Ast::handle_case(@re_ast.Ast::seq([]), false),
    @re_ast.Ast::handle_case(a, false),
  ]
  let merged = @re_ast.Ast::merge_sequences_no_case(l)
  assert_eq(merged.length() >= 1, true)
}

///|
test "merge_sequences_no_case with alternative" {
  let a = @re_ast.Ast::char('a')
  let b = @re_ast.Ast::char('b')
  let c = @re_ast.Ast::char('c')
  let l = [
    @re_ast.Ast::handle_case(@re_ast.Ast::alt([a, b]), false),
    @re_ast.Ast::handle_case(c, false),
  ]
  let merged = @re_ast.Ast::merge_sequences_no_case(l)
  assert_eq(merged.length() >= 1, true)
}

// === ast_colorize_rec coverage (CRAP ~41) ===

///|
test "ast_colorize_rec NoCase NotBound Stop Pmark" {
  let cm = @re_ast.ColorMap::make()
  let c : @base.Cset = @base.Cset::single(97)
  let r_nocase : @re_ast.AstNoCase = @re_ast.AstNode(
    @re_ast.NoCase(@re_ast.Set(c)),
  )
  let _ = @re_ast.Ast::colorize(cm, r_nocase)
  let r_notbound : @re_ast.AstNoCase = @re_ast.NotBound
  let _ = @re_ast.Ast::colorize(@re_ast.ColorMap::make(), r_notbound)
  let r_stop : @re_ast.AstNoCase = @re_ast.Stop
  let _ = @re_ast.Ast::colorize(@re_ast.ColorMap::make(), r_stop)
  let pm = @base.Pmark::gen()
  let r_pmark : @re_ast.AstNoCase = @re_ast.Pmark(pm, @re_ast.Set(c))
  let _ = @re_ast.Ast::colorize(@re_ast.ColorMap::make(), r_pmark)
}

// === Ast::repn coverage (CRAP ~14) ===

///|
test "Ast::repn 0 0 returns epsilon" {
  let r = @re_ast.Ast::repn(@re_ast.Ast::char('a'), 0, Some(0))
  match r {
    Sequence(xs) => assert_eq(xs.length(), 0)
    _ => assert_eq(true, false)
  }
}

// === Ast::diff and inter error coverage ===

///|
test "Ast::diff non-Set fail" {
  let r1 = try {
    let _ = @re_ast.Ast::diff(@re_ast.Ast::bos(), @re_ast.Ast::char('a'))
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
}

///|
test "Ast::inter non-Set fail" {
  let r1 = try {
    let _ = @re_ast.Ast::inter([@re_ast.Ast::bos()])
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
}

///|
test "Ast::compl non-Set fail" {
  let r1 = try {
    let _ = @re_ast.Ast::compl([@re_ast.Ast::bos()])
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
}

// === automata_expr coverage ===

///|
test "Expr::id Erase and After" {
  let ids = @base.Ids::create()
  let erase = @re_ast.Expr::erase(ids, 0, 1)
  let _ = @re_ast.Expr::id(erase)
  let cat = @base.Category::from_char('a')
  let after = @re_ast.Expr::after(ids, cat)
  let _ = @re_ast.Expr::id(after)
}

///|
test "Expr::cst empty cset" {
  let ids = @base.Ids::create()
  let r = @re_ast.Expr::cst(ids, @base.Cset::empty())
  assert_eq(@re_ast.Expr::is_eps(r), true)
}

///|
test "Expr::alt single element" {
  let ids = @base.Ids::create()
  let e = @re_ast.Expr::cst(ids, @base.Cset::single(97))
  let r = @re_ast.Expr::alt(ids, [e])
  assert_eq(@re_ast.Expr::id(r) == @re_ast.Expr::id(e), true)
}

///|
test "Expr::to_dyn Seq" {
  let ids = @base.Ids::create()
  let a = @re_ast.Expr::cst(ids, @base.Cset::single(97))
  let b = @re_ast.Expr::cst(ids, @base.Cset::single(98))
  let seq = @re_ast.Expr::seq(ids, @base.Sem::first(), a, b)
  let _d = @re_ast.Expr::to_dyn(seq)
  let rep = @re_ast.Expr::rep(
    ids,
    @base.RepKind::greedy(),
    @base.Sem::first(),
    a,
  )
  let _d2 = @re_ast.Expr::to_dyn(rep)
}

// === automata_desc coverage ===

///|
test "Marks::set_pmark" {
  let pm = @base.Pmark::gen()
  let m = @re_ast.Marks::set_pmark(@re_ast.Marks::empty(), pm)
  let _ = @re_ast.Marks::hash(m, 0)
}

///|
test "Marks::equal different" {
  let m1 = @re_ast.Marks::empty()
  let m2 = @re_ast.Marks::set_mark(m1, 0)
  assert_eq(@re_ast.Marks::equal(m1, m2), false)
}

///|
test "Desc::status_is_ambiguous empty" {
  let pm = @base.Pmark::gen()
  assert_eq(@re_ast.Desc::status_is_ambiguous([], pm), false)
}

///|
test "ET::equal via Desc" {
  let ids = @base.Ids::create()
  let a = @re_ast.Expr::cst(ids, @base.Cset::single(97))
  let m = @re_ast.Marks::empty()
  let d1 = @re_ast.Desc::texp(m, a, @re_ast.Desc::empty())
  let d2 = @re_ast.Desc::texp(m, a, @re_ast.Desc::empty())
  assert_eq(@re_ast.Desc::equal(d1, d2), true)
}

// === automata_state coverage ===

///|
test "delta_expr PmarkOf" {
  let ids = @base.Ids::create()
  let pm = @base.Pmark::gen()
  let pmark_expr = @re_ast.Expr::pmark(ids, pm)
  let cat = @base.Category::from_char('a')
  let wa = @re_ast.WorkingArea::create()
  let s0 = @re_ast.State::create(cat, pmark_expr)
  let _ = @re_ast.delta(wa, cat, 97, s0)
}

///|
test "delta_expr Before and After" {
  let ids = @base.Ids::create()
  let cat = @base.Category::from_char('a')
  let before = @re_ast.Expr::before(ids, cat)
  let after = @re_ast.Expr::after(ids, cat)
  let wa = @re_ast.WorkingArea::create()
  let s0 = @re_ast.State::create(cat, before)
  let _ = @re_ast.delta(wa, cat, 97, s0)
  let s1 = @re_ast.State::create(cat, after)
  let _ = @re_ast.delta(wa, cat, 97, s1)
  let _ = @re_ast.advance(wa, s1)
}

///|
test "delta_rep with match" {
  let ids = @base.Ids::create()
  let a_cset = @base.Cset::single(97)
  let a_expr = @re_ast.Expr::cst(ids, a_cset)
  let rep_expr = @re_ast.Expr::rep(
    ids,
    @base.RepKind::non_greedy(),
    @base.Sem::first(),
    a_expr,
  )
  let cat = @base.Category::from_char('a')
  let wa = @re_ast.WorkingArea::create()
  let s0 = @re_ast.State::create(cat, rep_expr)
  let _ = @re_ast.delta(wa, cat, 97, s0)
}
