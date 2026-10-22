///|
test "Ast::char constructs single char" {
  let a = @re_ast.Ast::char('a')
  match a {
    Set(CsetOf(c)) => assert_eq(c.intervals, [(97, 97)])
    _ => assert_eq(true, false)
  }
}

///|
test "Ast::str constructs sequence" {
  let s = @re_ast.Ast::str(b"ab")
  match s {
    Sequence(xs) => assert_eq(xs.length(), 2)
    _ => assert_eq(true, false)
  }
}

///|
test "Ast::any matches all" {
  let a = @re_ast.Ast::any()
  match a {
    Set(CsetOf(c)) => assert_eq(c.intervals, [(0, 255)])
    _ => assert_eq(true, false)
  }
}

///|
test "Ast::empty is empty alt" {
  let e = @re_ast.Ast::empty()
  match e {
    AstNode(Alternative(xs)) => assert_eq(xs.length(), 0)
    _ => assert_eq(true, false)
  }
}

///|
test "Ast::alt single element returns element" {
  let a = @re_ast.Ast::char('a')
  let r = @re_ast.Ast::alt([a])
  assert_eq(a == r, true)
}

///|
test "Ast::alt empty returns empty" {
  let r = @re_ast.Ast::alt([])
  match r {
    AstNode(Alternative(xs)) => assert_eq(xs.length(), 0)
    _ => assert_eq(true, false)
  }
}

///|
test "Ast::alt multiple elements" {
  let r = @re_ast.Ast::alt([@re_ast.Ast::char('a'), @re_ast.Ast::char('b')])
  match r {
    AstNode(Alternative(xs)) => assert_eq(xs.length(), 2)
    _ => assert_eq(true, false)
  }
}

///|
test "Ast::epsilon is empty seq" {
  let e = @re_ast.Ast::epsilon()
  match e {
    Sequence(xs) => assert_eq(xs.length(), 0)
    _ => assert_eq(true, false)
  }
}

///|
test "Ast::repn basic" {
  let r = @re_ast.Ast::repn(@re_ast.Ast::char('a'), 0, None)
  match r {
    Repeat(_, 0, None) => assert_eq(true, true)
    _ => assert_eq(true, false)
  }
}

///|
test "Ast::repn 1,1 returns original" {
  let a = @re_ast.Ast::char('a')
  let r = @re_ast.Ast::repn(a, 1, Some(1))
  assert_eq(a == r, true)
}

///|
test "Ast::anchored BegOfStr" {
  assert_eq(@re_ast.Ast::anchored(@re_ast.Ast::bos()), true)
}

///|
test "Ast::anchored Start" {
  assert_eq(@re_ast.Ast::anchored(@re_ast.Ast::start()), true)
}

///|
test "Ast::anchored char is false" {
  assert_eq(@re_ast.Ast::anchored(@re_ast.Ast::char('a')), false)
}

///|
test "Ast::anchored seq with bos" {
  let r = @re_ast.Ast::seq([@re_ast.Ast::bos(), @re_ast.Ast::char('a')])
  assert_eq(@re_ast.Ast::anchored(r), true)
}

///|
test "Ast::anchored repeat with min>0" {
  let r = @re_ast.Ast::rep1(@re_ast.Ast::bos())
  assert_eq(@re_ast.Ast::anchored(r), true)
}

///|
test "Ast::anchored repeat with min=0" {
  let r = @re_ast.Ast::rep(@re_ast.Ast::bos())
  assert_eq(@re_ast.Ast::anchored(r), false)
}

///|
test "Ast::anchored group" {
  let r = @re_ast.Ast::group(@re_ast.Ast::bos())
  assert_eq(@re_ast.Ast::anchored(r), true)
}

///|
test "Ast::handle_case basic" {
  let r = @re_ast.Ast::char('a')
  let r2 = @re_ast.Ast::handle_case(r, false)
  match r2 {
    Set(c) => assert_eq(c.intervals, [(97, 97)])
    _ => assert_eq(true, false)
  }
}

///|
test "Ast::case wraps with Case" {
  let r = @re_ast.Ast::char('a')
  let rc = @re_ast.Ast::case(r)
  match rc {
    Set(Cast(Case(_))) => assert_eq(true, true)
    _ => assert_eq(true, false)
  }
}

///|
test "Ast::no_case wraps with NoCase" {
  let r = @re_ast.Ast::char('a')
  let rc = @re_ast.Ast::no_case(r)
  match rc {
    Set(Cast(NoCase(_))) => assert_eq(true, true)
    _ => assert_eq(true, false)
  }
}

///|
test "Ast::mark returns pmark and marked ast" {
  let (pm, r) = @re_ast.Ast::mark(@re_ast.Ast::char('a'))
  match r {
    Pmark(p, _) => assert_eq(@base.Pmark::equal(pm, p), true)
    _ => assert_eq(true, false)
  }
}

///|
test "Ast::seq single returns element" {
  let a = @re_ast.Ast::char('a')
  let r = @re_ast.Ast::seq([a])
  assert_eq(a == r, true)
}

///|
test "Ast::seq multiple returns Sequence" {
  let r = @re_ast.Ast::seq([@re_ast.Ast::char('a'), @re_ast.Ast::char('b')])
  match r {
    Sequence(xs) => assert_eq(xs.length(), 2)
    _ => assert_eq(true, false)
  }
}
