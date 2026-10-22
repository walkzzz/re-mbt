///|
test "Ast::char constructs single char" {
  let a = @re.Ast::char('a')
  match a {
    Set(CsetOf(c)) => assert_eq(c.intervals, [(97, 97)])
    _ => assert_eq(true, false)
  }
}

///|
test "Ast::str constructs sequence" {
  let s = @re.Ast::str(b"ab")
  match s {
    Sequence(xs) => assert_eq(xs.length(), 2)
    _ => assert_eq(true, false)
  }
}

///|
test "Ast::any matches all" {
  let a = @re.Ast::any()
  match a {
    Set(CsetOf(c)) => assert_eq(c.intervals, [(0, 255)])
    _ => assert_eq(true, false)
  }
}

///|
test "Ast::empty is empty alt" {
  let e = @re.Ast::empty()
  match e {
    AstNode(Alternative(xs)) => assert_eq(xs.length(), 0)
    _ => assert_eq(true, false)
  }
}

///|
test "Ast::alt single element returns element" {
  let a = @re.Ast::char('a')
  let r = @re.Ast::alt([a])
  assert_eq(a == r, true)
}

///|
test "Ast::alt empty returns empty" {
  let r = @re.Ast::alt([])
  match r {
    AstNode(Alternative(xs)) => assert_eq(xs.length(), 0)
    _ => assert_eq(true, false)
  }
}

///|
test "Ast::alt multiple elements" {
  let r = @re.Ast::alt([@re.Ast::char('a'), @re.Ast::char('b')])
  match r {
    AstNode(Alternative(xs)) => assert_eq(xs.length(), 2)
    _ => assert_eq(true, false)
  }
}

///|
test "Ast::epsilon is empty seq" {
  let e = @re.Ast::epsilon()
  match e {
    Sequence(xs) => assert_eq(xs.length(), 0)
    _ => assert_eq(true, false)
  }
}

///|
test "Ast::repn basic" {
  let r = @re.Ast::repn(@re.Ast::char('a'), 0, None)
  match r {
    Repeat(_, 0, None) => assert_eq(true, true)
    _ => assert_eq(true, false)
  }
}

///|
test "Ast::repn 1,1 returns original" {
  let a = @re.Ast::char('a')
  let r = @re.Ast::repn(a, 1, Some(1))
  assert_eq(a == r, true)
}

///|
test "Ast::anchored BegOfStr" {
  assert_eq(@re.Ast::anchored(@re.Ast::bos()), true)
}

///|
test "Ast::anchored Start" {
  assert_eq(@re.Ast::anchored(@re.Ast::start()), true)
}

///|
test "Ast::anchored char is false" {
  assert_eq(@re.Ast::anchored(@re.Ast::char('a')), false)
}

///|
test "Ast::anchored seq with bos" {
  let r = @re.Ast::seq([@re.Ast::bos(), @re.Ast::char('a')])
  assert_eq(@re.Ast::anchored(r), true)
}

///|
test "Ast::anchored repeat with min>0" {
  let r = @re.Ast::rep1(@re.Ast::bos())
  assert_eq(@re.Ast::anchored(r), true)
}

///|
test "Ast::anchored repeat with min=0" {
  let r = @re.Ast::rep(@re.Ast::bos())
  assert_eq(@re.Ast::anchored(r), false)
}

///|
test "Ast::anchored group" {
  let r = @re.Ast::group(@re.Ast::bos())
  assert_eq(@re.Ast::anchored(r), true)
}

///|
test "Ast::handle_case basic" {
  let r = @re.Ast::char('a')
  let r2 = @re.Ast::handle_case(r, false)
  match r2 {
    Set(c) => assert_eq(c.intervals, [(97, 97)])
    _ => assert_eq(true, false)
  }
}

///|
test "Ast::case wraps with Case" {
  let r = @re.Ast::char('a')
  let rc = @re.Ast::case(r)
  match rc {
    Set(Cast(Case(_))) => assert_eq(true, true)
    _ => assert_eq(true, false)
  }
}

///|
test "Ast::no_case wraps with NoCase" {
  let r = @re.Ast::char('a')
  let rc = @re.Ast::no_case(r)
  match rc {
    Set(Cast(NoCase(_))) => assert_eq(true, true)
    _ => assert_eq(true, false)
  }
}

///|
test "Ast::mark returns pmark and marked ast" {
  let (pm, r) = @re.Ast::mark(@re.Ast::char('a'))
  match r {
    @re.Pmark(p, _) => assert_eq(@re.Pmark::equal(pm, p), true)
    _ => assert_eq(true, false)
  }
}

///|
test "Ast::seq single returns element" {
  let a = @re.Ast::char('a')
  let r = @re.Ast::seq([a])
  assert_eq(a == r, true)
}

///|
test "Ast::seq multiple returns Sequence" {
  let r = @re.Ast::seq([@re.Ast::char('a'), @re.Ast::char('b')])
  match r {
    Sequence(xs) => assert_eq(xs.length(), 2)
    _ => assert_eq(true, false)
  }
}
