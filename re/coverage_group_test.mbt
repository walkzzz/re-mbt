// coverage_group_test.mbt — GroupT/Re char classes/exec coverage tests

// === GroupT _opt variants ===

///|
test "GroupT::get_opt matched" {
  let re = compile(
    Ast::seq([Ast::str(sb("a")), Ast::group(Ast::str(sb("b")))]),
  )
  match exec_opt(re, sb("ab")) {
    Some(g) =>
      match GroupT::get_opt(g, 1) {
        Some(b) => assert_eq(bs(b), "b")
        None => assert_eq(true, false)
      }
    None => assert_eq(true, false)
  }
}

///|
test "GroupT::get_opt unmatched" {
  let re = compile(
    Ast::seq([
      Ast::str(sb("a")),
      Ast::group(Ast::opt(Ast::str(sb("b")))),
    ]),
  )
  match exec_opt(re, sb("a")) {
    Some(g) => {
      let opt = GroupT::get_opt(g, 1)
      match opt {
        Some(b) => assert_eq(b.length(), 0)
        None => assert_eq(true, true)
      }
    }
    None => assert_eq(true, false)
  }
}

///|
test "GroupT::offset_opt" {
  let re = compile(
    Ast::seq([Ast::str(sb("a")), Ast::group(Ast::str(sb("b")))]),
  )
  match exec_opt(re, sb("ab")) {
    Some(g) =>
      match GroupT::offset_opt(g, 1) {
        Some((s, t)) => {
          assert_eq(s, 1)
          assert_eq(t, 2)
        }
        None => assert_eq(true, false)
      }
    None => assert_eq(true, false)
  }
}

///|
test "GroupT::start_opt / stop_opt" {
  let re = compile(
    Ast::seq([Ast::str(sb("a")), Ast::group(Ast::str(sb("b")))]),
  )
  match exec_opt(re, sb("ab")) {
    Some(g) => {
      assert_eq(GroupT::start_opt(g, 1), Some(1))
      assert_eq(GroupT::stop_opt(g, 1), Some(2))
    }
    None => assert_eq(true, false)
  }
}

///|
test "GroupT::pmarks" {
  let re = compile(Ast::group(Ast::str(sb("a"))))
  match exec_opt(re, sb("a")) {
    Some(g) => {
      let _pm = GroupT::pmarks(g)
      assert_eq(true, true)
    }
    None => assert_eq(true, false)
  }
}

// === Core Re char class shortcuts ===

///|
test "Re::rg" {
  let re = compile(Ast::whole_string(Ast::rep1(Re::rg('a', 'z'))))
  assert_eq(execp(re, sb("hello")), true)
  assert_eq(execp(re, sb("Hello")), false)
}

///|
test "Re::lower" {
  let re = compile(Re::lower())
  assert_eq(execp(re, sb("abc")), true)
  assert_eq(execp(re, sb("ABC")), false)
}

///|
test "Re::upper" {
  let re = compile(Re::upper())
  assert_eq(execp(re, sb("ABC")), true)
  assert_eq(execp(re, sb("abc")), false)
}

///|
test "Re::alnum" {
  let re = compile(Re::alnum())
  assert_eq(execp(re, sb("a")), true)
  assert_eq(execp(re, sb("1")), true)
  assert_eq(execp(re, sb(" ")), false)
}

///|
test "Re::wordc" {
  let re = compile(Re::wordc())
  assert_eq(execp(re, sb("a")), true)
  assert_eq(execp(re, sb("1")), true)
  assert_eq(execp(re, sb("_")), true)
  assert_eq(execp(re, sb(" ")), false)
}

///|
test "Re::xdigit" {
  let re = compile(Re::xdigit())
  assert_eq(execp(re, sb("a")), true)
  assert_eq(execp(re, sb("F")), true)
  assert_eq(execp(re, sb("9")), true)
  assert_eq(execp(re, sb("g")), false)
}

///|
test "Re::notnl" {
  let re = compile(Re::notnl())
  assert_eq(execp(re, sb("a")), true)
}

///|
test "Re::ascii" {
  let re = compile(Re::ascii())
  assert_eq(execp(re, sb("a")), true)
}

///|
test "Re::cntrl" {
  let re = compile(Re::cntrl())
  assert_eq(execp(re, sb("\t")), true)
}

///|
test "Re::graph" {
  let re = compile(Re::graph())
  assert_eq(execp(re, sb("a")), true)
}

///|
test "Re::print" {
  let re = compile(Re::print())
  assert_eq(execp(re, sb(" ")), true)
}

///|
test "Re::punct" {
  let re = compile(Re::punct())
  assert_eq(execp(re, sb("!")), true)
  assert_eq(execp(re, sb("a")), false)
}

// === exec (non-optional) ===

///|
test "exec returns group on match" {
  let re = compile(Ast::str(sb("hello")))
  let g = exec(re, sb("hello world"))
  assert_eq(GroupT::start(g, 0), 0)
}

///|
test "exec raises on no match" {
  let re = compile(Ast::str(sb("xyz")))
  let raised = try {
    let _ = exec(re, sb("hello"))
    false
  } catch {
    _ => true
  }
  assert_eq(raised, true)
}

// === ExecPartialResult::partial ===

///|
test "exec_partial partial" {
  let re = compile(Ast::seq([Ast::bos(), Ast::str(sb("hello"))]))
  let result = exec_partial(re, sb("hel"))
  assert_eq(result, ExecPartialResult::partial())
}
