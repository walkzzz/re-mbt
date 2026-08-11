// desc_test.mbt — tests for Desc pub APIs (initial/status/remove_duplicates)

///|
fn desc_status_is_failed(s : Status) -> Bool {
  match s {
    Failed => true
    _ => false
  }
}

///|
fn desc_status_is_running(s : Status) -> Bool {
  match s {
    Running => true
    _ => false
  }
}

///|
fn desc_status_is_match(s : Status) -> Bool {
  match s {
    Match(_, _) => true
    _ => false
  }
}

///|
test "desc initial returns single TExp with empty marks" {
  let ids = Ids::create()
  let expr = Expr::cst(ids, Cset::single(97))
  let result = Desc::initial(expr)
  assert_eq(result.length(), 1)
  assert_true(desc_status_is_running(Desc::status(result)))
}

///|
test "desc status empty array returns Failed" {
  let t = Desc::empty()
  assert_true(desc_status_is_failed(Desc::status(t)))
}

///|
test "desc status TMatch head returns Match" {
  let t = Desc::add_match(Desc::empty(), Marks::empty())
  assert_true(desc_status_is_match(Desc::status(t)))
}

///|
test "desc status TExp head returns Running" {
  let ids = Ids::create()
  let expr = Expr::cst(ids, Cset::single(97))
  let t = Desc::texp(Marks::empty(), expr, Desc::empty())
  assert_true(desc_status_is_running(Desc::status(t)))
}

///|
test "desc remove_duplicates dedup same expr TExp" {
  let ids = Ids::create()
  let e = Expr::cst(ids, Cset::single(97))
  let t = Desc::texp(
    Marks::empty(),
    e,
    Desc::texp(Marks::empty(), e, Desc::empty()),
  )
  let result = Desc::remove_duplicates(HashSet::create(), t, e)
  assert_eq(result.length(), 1)
}

///|
test "desc remove_duplicates keeps distinct expr TExp" {
  let ids = Ids::create()
  let e1 = Expr::cst(ids, Cset::single(97))
  let e2 = Expr::cst(ids, Cset::single(98))
  let t = Desc::texp(
    Marks::empty(),
    e1,
    Desc::texp(Marks::empty(), e2, Desc::empty()),
  )
  let result = Desc::remove_duplicates(HashSet::create(), t, e1)
  assert_eq(result.length(), 2)
}
