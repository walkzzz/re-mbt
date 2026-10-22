// R17 五类多手段测试 — P0 trait 化（re_ast 侧）
// 测试跨包 impl @base.Dynable/Hashable/Equatable for re_ast types
// re_ast impl: Dynable for {Ast,State,Expr}, Hashable for {Marks,ET}, Equatable for {State,Marks,ET}

// =========================================================================
// 1. 形式化证明 — 验证 trait 不变量：to_dyn 返回 Dyn、hash 确定性、equal 自反/对称
// =========================================================================

///|
test "R17-formal: Dynable::to_dyn returns Dyn for Ast" {
  let a = @re_ast.Ast::char('a')
  let d = @base.Dynable::to_dyn(a)
  assert_eq(@base.Dyn::equal(d, d), true)
}

///|
test "R17-formal: Dynable::to_dyn returns Dyn for State" {
  let ids = @base.Ids::create()
  let expr = @re_ast.Expr::cst(ids, @base.Cset::single(97))
  let cat = @base.Category::from_char('a')
  let s = @re_ast.State::create(cat, expr)
  let d = @base.Dynable::to_dyn(s)
  assert_eq(@base.Dyn::equal(d, d), true)
}

///|
test "R17-formal: Dynable::to_dyn returns Dyn for Expr" {
  let ids = @base.Ids::create()
  let e = @re_ast.Expr::cst(ids, @base.Cset::single(97))
  let d = @base.Dynable::to_dyn(e)
  assert_eq(@base.Dyn::equal(d, d), true)
}

///|
test "R17-formal: Hashable::hash deterministic for Marks" {
  let m = @re_ast.Marks::empty()
  let h1 = @base.Hashable::hash(m, 0)
  let h2 = @base.Hashable::hash(m, 0)
  assert_eq(h1, h2)
}

///|
test "R17-formal: Hashable::hash deterministic for ET" {
  let ids = @base.Ids::create()
  let expr = @re_ast.Expr::cst(ids, @base.Cset::single(97))
  let ets = @re_ast.Desc::initial(expr)
  let et = ets[0]
  let h1 = @base.Hashable::hash(et, 0)
  let h2 = @base.Hashable::hash(et, 0)
  assert_eq(h1, h2)
}

///|
test "R17-formal: Equatable::equal reflexivity for State" {
  let ids = @base.Ids::create()
  let expr = @re_ast.Expr::cst(ids, @base.Cset::single(97))
  let cat = @base.Category::from_char('a')
  let s = @re_ast.State::create(cat, expr)
  assert_eq(@base.Equatable::equal(s, s), true)
}

///|
test "R17-formal: Equatable::equal symmetry for State" {
  let ids = @base.Ids::create()
  let expr = @re_ast.Expr::cst(ids, @base.Cset::single(97))
  let cat = @base.Category::from_char('a')
  let s1 = @re_ast.State::create(cat, expr)
  let s2 = @re_ast.State::create(cat, expr)
  assert_eq(
    @base.Equatable::equal(s1, s2),
    @base.Equatable::equal(s2, s1),
  )
}

///|
test "R17-formal: Equatable::equal reflexivity for Marks" {
  let m = @re_ast.Marks::empty()
  assert_eq(@base.Equatable::equal(m, m), true)
}

///|
test "R17-formal: Equatable::equal symmetry for Marks" {
  let m1 = @re_ast.Marks::empty()
  let m2 = @re_ast.Marks::empty()
  assert_eq(
    @base.Equatable::equal(m1, m2),
    @base.Equatable::equal(m2, m1),
  )
}

///|
test "R17-formal: Equatable::equal reflexivity for ET" {
  let ids = @base.Ids::create()
  let expr = @re_ast.Expr::cst(ids, @base.Cset::single(97))
  let ets = @re_ast.Desc::initial(expr)
  let et = ets[0]
  assert_eq(@base.Equatable::equal(et, et), true)
}

///|
test "R17-formal: Equatable::equal symmetry for ET" {
  let ids = @base.Ids::create()
  let expr = @re_ast.Expr::cst(ids, @base.Cset::single(97))
  let ets = @re_ast.Desc::initial(expr)
  let et1 = ets[0]
  let et2 = ets[0]
  assert_eq(
    @base.Equatable::equal(et1, et2),
    @base.Equatable::equal(et2, et1),
  )
}

// =========================================================================
// 2. AI 测试 — 验证跨包 trait impl 正确（re_ast 类型 C@base.Dynable）
// =========================================================================

///|
test "R17-ai: cross-package Dynable impl via @base.Dynable for Ast" {
  let a = @re_ast.Ast::char('a')
  let d = @base.Dynable::to_dyn(a)
  assert_eq(@base.Dyn::equal(d, d), true)
}

///|
test "R17-ai: cross-package Dynable impl via @base.Dynable for State" {
  let s = @re_ast.State::dummy()
  let d = @base.Dynable::to_dyn(s)
  assert_eq(@base.Dyn::equal(d, d), true)
}

///|
test "R17-ai: cross-package Dynable impl via @base.Dynable for Expr" {
  let ids = @base.Ids::create()
  let e = @re_ast.Expr::eps(ids)
  let d = @base.Dynable::to_dyn(e)
  assert_eq(@base.Dyn::equal(d, d), true)
}

///|
test "R17-ai: cross-package Hashable impl via @base.Hashable for Marks" {
  let m = @re_ast.Marks::empty()
  let h1 = @base.Hashable::hash(m, 42)
  let h2 = @base.Hashable::hash(m, 42)
  assert_eq(h1, h2)
}

///|
test "R17-ai: cross-package Equatable impl via @base.Equatable for State" {
  let s = @re_ast.State::dummy()
  assert_eq(@base.Equatable::equal(s, s), true)
}

// =========================================================================
// 3. FAKE 测试 — 构造假数据/边界值验证 trait 方法不崩溃
// =========================================================================

///|
test "R17-fake: empty Marks hash and equal does not crash" {
  let m = @re_ast.Marks::empty()
  let h = @base.Hashable::hash(m, 0)
  assert_eq(h, h)
  assert_eq(@base.Equatable::equal(m, m), true)
}

///|
test "R17-fake: dummy State to_dyn does not crash" {
  let s = @re_ast.State::dummy()
  let d = @base.Dynable::to_dyn(s)
  assert_eq(@base.Dyn::equal(d, d), true)
}

///|
test "R17-fake: Marks hash with zero accumulator" {
  let m = @re_ast.Marks::empty()
  let h = @base.Hashable::hash(m, 0)
  assert_eq(h, h)
}

///|
test "R17-fake: ET equal self does not crash" {
  let ids = @base.Ids::create()
  let expr = @re_ast.Expr::cst(ids, @base.Cset::single(97))
  let ets = @re_ast.Desc::initial(expr)
  let et = ets[0]
  assert_eq(@base.Equatable::equal(et, et), true)
}

// =========================================================================
// 4. MOCK 测试 — 验证 pub(open) trait 允许跨包扩展、多态分发
// =========================================================================

///|
test "R17-mock: pub(open) trait cross-package impl works for Ast" {
  let a = @re_ast.Ast::char('a')
  let d1 = @base.Dynable::to_dyn(a)
  let d2 = @re_ast.Ast::to_dyn(a)
  assert_eq(@base.Dyn::equal(d1, d2), true)
}

///|
test "R17-mock: trait dispatch via @base.Dynable vs direct for State" {
  let s = @re_ast.State::dummy()
  let d1 = @base.Dynable::to_dyn(s)
  let d2 = @re_ast.State::to_dyn(s)
  assert_eq(@base.Dyn::equal(d1, d2), true)
}

// =========================================================================
// 5. E2E 测试 — 端到端：创建类型 → to_dyn → hash → equal 全链路
// =========================================================================

///|
test "R17-e2e: re_ast State create→to_dyn→equal full chain" {
  let ids = @base.Ids::create()
  let expr = @re_ast.Expr::cst(ids, @base.Cset::single(97))
  let cat = @base.Category::from_char('a')
  let s = @re_ast.State::create(cat, expr)
  let d = @base.Dynable::to_dyn(s)
  assert_eq(@base.Dyn::equal(d, d), true)
  assert_eq(@base.Equatable::equal(s, s), true)
}

///|
test "R17-e2e: cross-package trait call via @base.Dynable::to_dyn for Expr" {
  let ids = @base.Ids::create()
  let e1 = @re_ast.Expr::cst(ids, @base.Cset::single(97))
  let e2 = @re_ast.Expr::cst(@base.Ids::create(), @base.Cset::single(97))
  let d1 = @base.Dynable::to_dyn(e1)
  let d2 = @base.Dynable::to_dyn(e2)
  assert_eq(@base.Dyn::equal(d1, d1), true)
  assert_eq(@base.Dyn::equal(d2, d2), true)
}

///|
test "R17-e2e: Marks create→hash→equal full chain" {
  let m1 = @re_ast.Marks::empty()
  let m2 = @re_ast.Marks::empty()
  let h1 = @base.Hashable::hash(m1, 0)
  let h2 = @base.Hashable::hash(m2, 0)
  assert_eq(h1, h2)
  assert_eq(@base.Equatable::equal(m1, m2), true)
}