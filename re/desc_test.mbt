// desc_test.mbt — tests for Desc pub APIs (initial/status/remove_duplicates)

///|
fn desc_status_is_failed(s : @re.Status) -> Bool {
  match s {
    Failed => true
    _ => false
  }
}

///|
fn desc_status_is_running(s : @re.Status) -> Bool {
  match s {
    Running => true
    _ => false
  }
}

///|
fn desc_status_is_match(s : @re.Status) -> Bool {
  match s {
    Match(_, _) => true
    _ => false
  }
}

///|
test "desc initial returns single TExp with empty marks" {
  let ids = @re.Ids::create()
  let expr = @re.Expr::cst(ids, @re.Cset::single(97))
  let result = @re.Desc::initial(expr)
  assert_eq(result.length(), 1)
  assert_true(desc_status_is_running(@re.Desc::status(result)))
}

///|
test "desc status empty array returns Failed" {
  let t = @re.Desc::empty()
  assert_true(desc_status_is_failed(@re.Desc::status(t)))
}

///|
test "desc status TMatch head returns Match" {
  let t = @re.Desc::add_match(@re.Desc::empty(), @re.Marks::empty())
  assert_true(desc_status_is_match(@re.Desc::status(t)))
}

///|
test "desc status TExp head returns Running" {
  let ids = @re.Ids::create()
  let expr = @re.Expr::cst(ids, @re.Cset::single(97))
  let t = @re.Desc::texp(@re.Marks::empty(), expr, @re.Desc::empty())
  assert_true(desc_status_is_running(@re.Desc::status(t)))
}

///|
test "desc remove_duplicates dedup same expr TExp" {
  let ids = @re.Ids::create()
  let e = @re.Expr::cst(ids, @re.Cset::single(97))
  let t = @re.Desc::texp(
    @re.Marks::empty(),
    e,
    @re.Desc::texp(@re.Marks::empty(), e, @re.Desc::empty()),
  )
  let result = @re.Desc::remove_duplicates(@re.HashSet::create(), t, e)
  assert_eq(result.length(), 1)
}

///|
test "desc remove_duplicates keeps distinct expr TExp" {
  let ids = @re.Ids::create()
  let e1 = @re.Expr::cst(ids, @re.Cset::single(97))
  let e2 = @re.Expr::cst(ids, @re.Cset::single(98))
  let t = @re.Desc::texp(
    @re.Marks::empty(),
    e1,
    @re.Desc::texp(@re.Marks::empty(), e2, @re.Desc::empty()),
  )
  let result = @re.Desc::remove_duplicates(@re.HashSet::create(), t, e1)
  assert_eq(result.length(), 2)
}
