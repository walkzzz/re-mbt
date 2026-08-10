///|
test "Ast::char constructs single char" {
  let a = Ast::char('a')
  match a {
    Set(CsetOf(c)) => assert_eq(c.intervals, [(97, 97)])
    _ => assert_eq(true, false)
  }
}

///|
test "Ast::str constructs sequence" {
  let s = Ast::str(b"ab")
  match s {
    Sequence(xs) => assert_eq(xs.length(), 2)
    _ => assert_eq(true, false)
  }
}

///|
test "Ast::any matches all" {
  let a = Ast::any()
  match a {
    Set(CsetOf(c)) => assert_eq(c.intervals, [(0, 255)])
    _ => assert_eq(true, false)
  }
}

///|
test "Ast::empty is empty alt" {
  let e = Ast::empty()
  match e {
    AstNode(Alternative(xs)) => assert_eq(xs.length(), 0)
    _ => assert_eq(true, false)
  }
}

///|
test "Ast::alt single element returns element" {
  let a = Ast::char('a')
  let r = Ast::alt([a])
  assert_eq(a == r, true)
}

///|
test "Ast::alt empty returns empty" {
  let r = Ast::alt([])
  match r {
    AstNode(Alternative(xs)) => assert_eq(xs.length(), 0)
    _ => assert_eq(true, false)
  }
}

///|
test "Ast::alt multiple elements" {
  let r = Ast::alt([Ast::char('a'), Ast::char('b')])
  match r {
    AstNode(Alternative(xs)) => assert_eq(xs.length(), 2)
    _ => assert_eq(true, false)
  }
}

///|
test "Ast::epsilon is empty seq" {
  let e = Ast::epsilon()
  match e {
    Sequence(xs) => assert_eq(xs.length(), 0)
    _ => assert_eq(true, false)
  }
}

///|
test "Ast::repn basic" {
  let r = Ast::repn(Ast::char('a'), 0, None)
  match r {
    Repeat(_, 0, None) => assert_eq(true, true)
    _ => assert_eq(true, false)
  }
}

///|
test "Ast::repn 1,1 returns original" {
  let a = Ast::char('a')
  let r = Ast::repn(a, 1, Some(1))
  assert_eq(a == r, true)
}

///|
test "Ast::anchored BegOfStr" {
  assert_eq(Ast::anchored(Ast::bos()), true)
}

///|
test "Ast::anchored Start" {
  assert_eq(Ast::anchored(Ast::start()), true)
}

///|
test "Ast::anchored char is false" {
  assert_eq(Ast::anchored(Ast::char('a')), false)
}

///|
test "Ast::anchored seq with bos" {
  let r = Ast::seq([Ast::bos(), Ast::char('a')])
  assert_eq(Ast::anchored(r), true)
}

///|
test "Ast::anchored repeat with min>0" {
  let r = Ast::rep1(Ast::bos())
  assert_eq(Ast::anchored(r), true)
}

///|
test "Ast::anchored repeat with min=0" {
  let r = Ast::rep(Ast::bos())
  assert_eq(Ast::anchored(r), false)
}

///|
test "Ast::anchored group" {
  let r = Ast::group(Ast::bos())
  assert_eq(Ast::anchored(r), true)
}

///|
test "Ast::handle_case basic" {
  let r = Ast::char('a')
  let r2 = Ast::handle_case(r, false)
  match r2 {
    Set(c) => assert_eq(c.intervals, [(97, 97)])
    _ => assert_eq(true, false)
  }
}

///|
test "Ast::case wraps with Case" {
  let r = Ast::char('a')
  let rc = Ast::case(r)
  match rc {
    Set(Cast(Case(_))) => assert_eq(true, true)
    _ => assert_eq(true, false)
  }
}

///|
test "Ast::no_case wraps with NoCase" {
  let r = Ast::char('a')
  let rc = Ast::no_case(r)
  match rc {
    Set(Cast(NoCase(_))) => assert_eq(true, true)
    _ => assert_eq(true, false)
  }
}

///|
test "Ast::mark returns pmark and marked ast" {
  let (pm, r) = Ast::mark(Ast::char('a'))
  match r {
    Pmark(p, _) => assert_eq(Pmark::equal(pm, p), true)
    _ => assert_eq(true, false)
  }
}

///|
test "Ast::seq single returns element" {
  let a = Ast::char('a')
  let r = Ast::seq([a])
  assert_eq(a == r, true)
}

///|
test "Ast::seq multiple returns Sequence" {
  let r = Ast::seq([Ast::char('a'), Ast::char('b')])
  match r {
    Sequence(xs) => assert_eq(xs.length(), 2)
    _ => assert_eq(true, false)
  }
}
