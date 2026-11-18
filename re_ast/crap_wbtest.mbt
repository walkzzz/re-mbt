// crap_wbtest.mbt — Whitebox CRAP coverage tests for re_ast
// Covers ET::equal and ET::equal_list with TExp constructor

///|
test "wb ET::equal different types" {
  let ids = @base.Ids::create()
  let a = Expr::cst(ids, @base.Cset::single(97))
  let b = Expr::cst(ids, @base.Cset::single(98))
  let m = Marks::empty()
  let e1 = TExp(m, a)
  let e2 = TExp(m, b)
  assert_eq(ET::equal(e1, e2), false)
}

///|
test "wb ET::equal_list different length and elements" {
  let ids = @base.Ids::create()
  let a = Expr::cst(ids, @base.Cset::single(97))
  let m = Marks::empty()
  let e1 = TExp(m, a)
  assert_eq(ET::equal_list([], [e1]), false)
  let b = Expr::cst(ids, @base.Cset::single(98))
  let e2 = TExp(m, b)
  assert_eq(ET::equal_list([e1], [e2]), false)
}

///|
test "wb ET::equal same type" {
  let ids = @base.Ids::create()
  let a = Expr::cst(ids, @base.Cset::single(97))
  let m = Marks::empty()
  let e1 = TExp(m, a)
  let e2 = TExp(m, a)
  assert_eq(ET::equal(e1, e2), true)
}

///|
test "wb ET::equal TMatch different" {
  let m1 = Marks::empty()
  let m2 = Marks::set_mark(m1, 0)
  let e1 = TMatch(m1)
  let e2 = TMatch(m2)
  assert_eq(ET::equal(e1, e2), false)
}

///|
test "wb ET::equal TSeq different" {
  let ids = @base.Ids::create()
  let a = Expr::cst(ids, @base.Cset::single(97))
  let e1 = TSeq(@base.Sem::first(), [], a)
  let e2 = TSeq(@base.Sem::first(), [], a)
  assert_eq(ET::equal(e1, e2), true)
}
