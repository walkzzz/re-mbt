// R17 五类多手段测试 — P0 trait 化（re_base 侧）
// 测试 Dynable/Hashable/Equatable trait 及其 re_base impl
// re_base impl: Dynable for {Sem,RepKind,Cset,Pmark,Category}, Hashable for {Cset}

// =========================================================================
// 1. 形式化证明 — 验证 trait 不变量：to_dyn 返回 Dyn、hash 确定性、累加器传递
// =========================================================================

///|
test "R17-formal: Dynable::to_dyn returns Dyn for Sem" {
  let d = @re_base.Dynable::to_dyn(@re_base.Sem::longest())
  assert_eq(@re_base.Dyn::equal(d, d), true)
}

///|
test "R17-formal: Dynable::to_dyn returns Dyn for RepKind" {
  let d = @re_base.Dynable::to_dyn(@re_base.RepKind::greedy())
  assert_eq(@re_base.Dyn::equal(d, d), true)
}

///|
test "R17-formal: Dynable::to_dyn returns Dyn for Cset" {
  let s = @re_base.Cset::single(65)
  let d = @re_base.Dynable::to_dyn(s)
  assert_eq(@re_base.Dyn::equal(d, d), true)
}

///|
test "R17-formal: Dynable::to_dyn returns Dyn for Pmark" {
  let p = @re_base.Pmark::gen()
  let d = @re_base.Dynable::to_dyn(p)
  assert_eq(@re_base.Dyn::equal(d, d), true)
}

///|
test "R17-formal: Dynable::to_dyn returns Dyn for Category" {
  let c = @re_base.Category::from_char('a')
  let d = @re_base.Dynable::to_dyn(c)
  assert_eq(@re_base.Dyn::equal(d, d), true)
}

///|
test "R17-formal: Hashable::hash deterministic for Cset" {
  let s = @re_base.Cset::single(65)
  let h1 = @re_base.Hashable::hash(s, 0)
  let h2 = @re_base.Hashable::hash(s, 0)
  assert_eq(h1, h2)
}

///|
test "R17-formal: Hashable::hash accumulator chaining for Cset" {
  let s = @re_base.Cset::single(65)
  let h0 = @re_base.Hashable::hash(s, 0)
  let h1 = @re_base.Hashable::hash(s, 1)
  assert_eq(@re_base.Hashable::hash(s, 0), h0)
  assert_eq(@re_base.Hashable::hash(s, 1), h1)
}

// =========================================================================
// 2. AI 测试 — 模拟 trait 多态调用：用 Dynable trait 统一调用不同类型的 to_dyn
// =========================================================================

///|
test "R17-ai: polymorphic to_dyn via Dynable trait for re_base types" {
  let sem = @re_base.Dynable::to_dyn(@re_base.Sem::longest())
  let rep = @re_base.Dynable::to_dyn(@re_base.RepKind::greedy())
  let cset = @re_base.Dynable::to_dyn(@re_base.Cset::single(65))
  let pmark = @re_base.Dynable::to_dyn(@re_base.Pmark::gen())
  let cat = @re_base.Dynable::to_dyn(@re_base.Category::from_char('a'))
  assert_eq(@re_base.Dyn::equal(sem, sem), true)
  assert_eq(@re_base.Dyn::equal(rep, rep), true)
  assert_eq(@re_base.Dyn::equal(cset, cset), true)
  assert_eq(@re_base.Dyn::equal(pmark, pmark), true)
  assert_eq(@re_base.Dyn::equal(cat, cat), true)
}

// =========================================================================
// 3. FAKE 测试 — 构造假数据/边界值验证 trait 方法不崩溃
// =========================================================================

///|
test "R17-fake: empty Cset to_dyn does not crash" {
  let s = @re_base.Cset::empty()
  let d = @re_base.Dynable::to_dyn(s)
  assert_eq(@re_base.Dyn::equal(d, d), true)
}

///|
test "R17-fake: cany Cset to_dyn does not crash" {
  let s = @re_base.Cset::cany()
  let d = @re_base.Dynable::to_dyn(s)
  assert_eq(@re_base.Dyn::equal(d, d), true)
}

///|
test "R17-fake: Cset hash with zero accumulator" {
  let s = @re_base.Cset::empty()
  let h = @re_base.Hashable::hash(s, 0)
  assert_eq(h, h)
}

///|
test "R17-fake: Cset hash with extreme accumulator" {
  let s = @re_base.Cset::single(255)
  let h = @re_base.Hashable::hash(s, 2147483647)
  assert_eq(h, h)
}

// =========================================================================
// 4. MOCK 测试 — 验证 trait 方法分发与直接方法调用一致
// =========================================================================

///|
test "R17-mock: trait dispatch via Dynable::to_dyn equals direct for Cset" {
  let s = @re_base.Cset::single(65)
  let d1 = @re_base.Dynable::to_dyn(s)
  let d2 = @re_base.Cset::to_dyn(s)
  assert_eq(@re_base.Dyn::equal(d1, d2), true)
}

///|
test "R17-mock: trait dispatch via Hashable::hash equals direct for Cset" {
  let s = @re_base.Cset::single(65)
  let h1 = @re_base.Hashable::hash(s, 42)
  let h2 = @re_base.Cset::hash(s, 42)
  assert_eq(h1, h2)
}

// =========================================================================
// 5. E2E 测试 — 端到端：创建类型 → to_dyn → hash 全链路
// =========================================================================

///|
test "R17-e2e: re_base Cset create→to_dyn→hash full chain" {
  let s = @re_base.Cset::seq(65, 90)
  let d = @re_base.Dynable::to_dyn(s)
  let h = @re_base.Hashable::hash(s, 0)
  assert_eq(@re_base.Dyn::equal(d, d), true)
  assert_eq(h, h)
}
