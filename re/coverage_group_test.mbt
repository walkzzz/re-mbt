// coverage_group_test.mbt — GroupT/Re char classes/exec coverage tests

// === GroupT _opt variants ===

///|
test "GroupT::get_opt matched" {
  let re = @re.compile(
    @re.Ast::seq([@re.Ast::str(sb("a")), @re.Ast::group(@re.Ast::str(sb("b")))]),
  )
  match @re.exec_opt(re, sb("ab")) {
    Some(g) =>
      match @re.GroupT::get_opt(g, 1) {
        Some(b) => assert_eq(bs(b), "b")
        None => assert_eq(true, false)
      }
    None => assert_eq(true, false)
  }
}

///|
test "GroupT::get_opt unmatched" {
  let re = @re.compile(
    @re.Ast::seq([
      @re.Ast::str(sb("a")),
      @re.Ast::group(@re.Ast::opt(@re.Ast::str(sb("b")))),
    ]),
  )
  match @re.exec_opt(re, sb("a")) {
    Some(g) => {
      let opt = @re.GroupT::get_opt(g, 1)
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
  let re = @re.compile(
    @re.Ast::seq([@re.Ast::str(sb("a")), @re.Ast::group(@re.Ast::str(sb("b")))]),
  )
  match @re.exec_opt(re, sb("ab")) {
    Some(g) =>
      match @re.GroupT::offset_opt(g, 1) {
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
  let re = @re.compile(
    @re.Ast::seq([@re.Ast::str(sb("a")), @re.Ast::group(@re.Ast::str(sb("b")))]),
  )
  match @re.exec_opt(re, sb("ab")) {
    Some(g) => {
      assert_eq(@re.GroupT::start_opt(g, 1), Some(1))
      assert_eq(@re.GroupT::stop_opt(g, 1), Some(2))
    }
    None => assert_eq(true, false)
  }
}

///|
test "GroupT::pmarks" {
  let re = @re.compile(@re.Ast::group(@re.Ast::str(sb("a"))))
  match @re.exec_opt(re, sb("a")) {
    Some(g) => {
      let _pm = @re.GroupT::pmarks(g)
      assert_eq(true, true)
    }
    None => assert_eq(true, false)
  }
}

// === Core Re char class shortcuts ===

///|
test "Re::rg" {
  let re = @re.compile(
    @re.Ast::whole_string(@re.Ast::rep1(@re.Re::rg('a', 'z'))),
  )
  assert_eq(@re.execp(re, sb("hello")), true)
  assert_eq(@re.execp(re, sb("Hello")), false)
}

///|
test "Re::lower" {
  let re = @re.compile(@re.Re::lower())
  assert_eq(@re.execp(re, sb("abc")), true)
  assert_eq(@re.execp(re, sb("ABC")), false)
}

///|
test "Re::upper" {
  let re = @re.compile(@re.Re::upper())
  assert_eq(@re.execp(re, sb("ABC")), true)
  assert_eq(@re.execp(re, sb("abc")), false)
}

///|
test "Re::alnum" {
  let re = @re.compile(@re.Re::alnum())
  assert_eq(@re.execp(re, sb("a")), true)
  assert_eq(@re.execp(re, sb("1")), true)
  assert_eq(@re.execp(re, sb(" ")), false)
}

///|
test "Re::wordc" {
  let re = @re.compile(@re.Re::wordc())
  assert_eq(@re.execp(re, sb("a")), true)
  assert_eq(@re.execp(re, sb("1")), true)
  assert_eq(@re.execp(re, sb("_")), true)
  assert_eq(@re.execp(re, sb(" ")), false)
}

///|
test "Re::xdigit" {
  let re = @re.compile(@re.Re::xdigit())
  assert_eq(@re.execp(re, sb("a")), true)
  assert_eq(@re.execp(re, sb("F")), true)
  assert_eq(@re.execp(re, sb("9")), true)
  assert_eq(@re.execp(re, sb("g")), false)
}

///|
test "Re::notnl" {
  let re = @re.compile(@re.Re::notnl())
  assert_eq(@re.execp(re, sb("a")), true)
}

///|
test "Re::ascii" {
  let re = @re.compile(@re.Re::ascii())
  assert_eq(@re.execp(re, sb("a")), true)
}

///|
test "Re::cntrl" {
  let re = @re.compile(@re.Re::cntrl())
  assert_eq(@re.execp(re, sb("\t")), true)
}

///|
test "Re::graph" {
  let re = @re.compile(@re.Re::graph())
  assert_eq(@re.execp(re, sb("a")), true)
}

///|
test "Re::print" {
  let re = @re.compile(@re.Re::print())
  assert_eq(@re.execp(re, sb(" ")), true)
}

///|
test "Re::punct" {
  let re = @re.compile(@re.Re::punct())
  assert_eq(@re.execp(re, sb("!")), true)
  assert_eq(@re.execp(re, sb("a")), false)
}

// === exec (non-optional) ===

///|
test "exec returns group on match" {
  let re = @re.compile(@re.Ast::str(sb("hello")))
  let g = @re.exec(re, sb("hello world"))
  assert_eq(@re.GroupT::start(g, 0), 0)
}

///|
test "exec raises on no match" {
  let re = @re.compile(@re.Ast::str(sb("xyz")))
  let raised = try {
    let _ = @re.exec(re, sb("hello"))
    false
  } catch {
    _ => true
  }
  assert_eq(raised, true)
}

// === ExecPartialResult::partial ===

///|
test "exec_partial partial" {
  let re = @re.compile(
    @re.Ast::seq([@re.Ast::bos(), @re.Ast::str(sb("hello"))]),
  )
  let result = @re.exec_partial(re, sb("hel"))
  assert_eq(result, @re.ExecPartialResult::partial())
}
