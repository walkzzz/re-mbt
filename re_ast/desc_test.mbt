// desc_test.mbt — tests for Desc pub APIs (initial/status/remove_duplicates)

///|
fn desc_status_is_failed(s : @re_ast.Status) -> Bool {
  match s {
    Failed => true
    _ => false
  }
}

///|
fn desc_status_is_running(s : @re_ast.Status) -> Bool {
  match s {
    Running => true
    _ => false
  }
}

///|
fn desc_status_is_match(s : @re_ast.Status) -> Bool {
  match s {
    Match(_, _) => true
    _ => false
  }
}

///|
test "desc initial returns single TExp with empty marks" {
  let ids = @base.Ids::create()
  let expr = @re_ast.Expr::cst(ids, @base.Cset::single(97))
  let result = @re_ast.Desc::initial(expr)
  assert_eq(result.length(), 1)
  assert_true(desc_status_is_running(@re_ast.Desc::status(result)))
}

///|
test "desc status empty array returns Failed" {
  let t = @re_ast.Desc::empty()
  assert_true(desc_status_is_failed(@re_ast.Desc::status(t)))
}

///|
test "desc status TMatch head returns Match" {
  let t = @re_ast.Desc::add_match(@re_ast.Desc::empty(), @re_ast.Marks::empty())
  assert_true(desc_status_is_match(@re_ast.Desc::status(t)))
}

///|
test "desc status TExp head returns Running" {
  let ids = @base.Ids::create()
  let expr = @re_ast.Expr::cst(ids, @base.Cset::single(97))
  let t = @re_ast.Desc::texp(
    @re_ast.Marks::empty(),
    expr,
    @re_ast.Desc::empty(),
  )
  assert_true(desc_status_is_running(@re_ast.Desc::status(t)))
}

///|
test "desc remove_duplicates dedup same expr TExp" {
  let ids = @base.Ids::create()
  let e = @re_ast.Expr::cst(ids, @base.Cset::single(97))
  let t = @re_ast.Desc::texp(
    @re_ast.Marks::empty(),
    e,
    @re_ast.Desc::texp(@re_ast.Marks::empty(), e, @re_ast.Desc::empty()),
  )
  let result = @re_ast.Desc::remove_duplicates(@base.HashSet::create(), t, e)
  assert_eq(result.length(), 1)
}

///|
test "desc remove_duplicates keeps distinct expr TExp" {
  let ids = @base.Ids::create()
  let e1 = @re_ast.Expr::cst(ids, @base.Cset::single(97))
  let e2 = @re_ast.Expr::cst(ids, @base.Cset::single(98))
  let t = @re_ast.Desc::texp(
    @re_ast.Marks::empty(),
    e1,
    @re_ast.Desc::texp(@re_ast.Marks::empty(), e2, @re_ast.Desc::empty()),
  )
  let result = @re_ast.Desc::remove_duplicates(@base.HashSet::create(), t, e1)
  assert_eq(result.length(), 2)
}
