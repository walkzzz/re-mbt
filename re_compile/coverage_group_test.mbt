// coverage_group_test.mbt — GroupT/Re char classes/exec coverage tests

// === GroupT _opt variants ===

///|
test "GroupT::get_opt matched" {
  let re = @re_compile.compile(
    @ast.Ast::seq([
      @ast.Ast::str(@base.sb("a")),
      @ast.Ast::group(@ast.Ast::str(@base.sb("b"))),
    ]),
  )
  match @re_compile.exec_opt(re, @base.sb("ab")) {
    Some(g) =>
      match @re_compile.GroupT::get_opt(g, 1) {
        Some(b) => assert_eq(@base.bs(b), "b")
        None => assert_eq(true, false)
      }
    None => assert_eq(true, false)
  }
}

///|
test "GroupT::get_opt unmatched" {
  let re = @re_compile.compile(
    @ast.Ast::seq([
      @ast.Ast::str(@base.sb("a")),
      @ast.Ast::group(@ast.Ast::opt(@ast.Ast::str(@base.sb("b")))),
    ]),
  )
  match @re_compile.exec_opt(re, @base.sb("a")) {
    Some(g) => {
      let opt = @re_compile.GroupT::get_opt(g, 1)
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
  let re = @re_compile.compile(
    @ast.Ast::seq([
      @ast.Ast::str(@base.sb("a")),
      @ast.Ast::group(@ast.Ast::str(@base.sb("b"))),
    ]),
  )
  match @re_compile.exec_opt(re, @base.sb("ab")) {
    Some(g) =>
      match @re_compile.GroupT::offset_opt(g, 1) {
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
  let re = @re_compile.compile(
    @ast.Ast::seq([
      @ast.Ast::str(@base.sb("a")),
      @ast.Ast::group(@ast.Ast::str(@base.sb("b"))),
    ]),
  )
  match @re_compile.exec_opt(re, @base.sb("ab")) {
    Some(g) => {
      assert_eq(@re_compile.GroupT::start_opt(g, 1), Some(1))
      assert_eq(@re_compile.GroupT::stop_opt(g, 1), Some(2))
    }
    None => assert_eq(true, false)
  }
}

///|
test "GroupT::pmarks" {
  let re = @re_compile.compile(@ast.Ast::group(@ast.Ast::str(@base.sb("a"))))
  match @re_compile.exec_opt(re, @base.sb("a")) {
    Some(g) => {
      let _pm = @re_compile.GroupT::pmarks(g)
      assert_eq(true, true)
    }
    None => assert_eq(true, false)
  }
}

// === Core Re char class shortcuts ===

///|
test "Re::rg" {
  let re = @re_compile.compile(
    @ast.Ast::whole_string(@ast.Ast::rep1(@re_compile.Re::rg('a', 'z'))),
  )
  assert_eq(@re_compile.execp(re, @base.sb("hello")), true)
  assert_eq(@re_compile.execp(re, @base.sb("Hello")), false)
}

///|
test "Re::lower" {
  let re = @re_compile.compile(@re_compile.Re::lower())
  assert_eq(@re_compile.execp(re, @base.sb("abc")), true)
  assert_eq(@re_compile.execp(re, @base.sb("ABC")), false)
}

///|
test "Re::upper" {
  let re = @re_compile.compile(@re_compile.Re::upper())
  assert_eq(@re_compile.execp(re, @base.sb("ABC")), true)
  assert_eq(@re_compile.execp(re, @base.sb("abc")), false)
}

///|
test "Re::alnum" {
  let re = @re_compile.compile(@re_compile.Re::alnum())
  assert_eq(@re_compile.execp(re, @base.sb("a")), true)
  assert_eq(@re_compile.execp(re, @base.sb("1")), true)
  assert_eq(@re_compile.execp(re, @base.sb(" ")), false)
}

///|
test "Re::wordc" {
  let re = @re_compile.compile(@re_compile.Re::wordc())
  assert_eq(@re_compile.execp(re, @base.sb("a")), true)
  assert_eq(@re_compile.execp(re, @base.sb("1")), true)
  assert_eq(@re_compile.execp(re, @base.sb("_")), true)
  assert_eq(@re_compile.execp(re, @base.sb(" ")), false)
}

///|
test "Re::xdigit" {
  let re = @re_compile.compile(@re_compile.Re::xdigit())
  assert_eq(@re_compile.execp(re, @base.sb("a")), true)
  assert_eq(@re_compile.execp(re, @base.sb("F")), true)
  assert_eq(@re_compile.execp(re, @base.sb("9")), true)
  assert_eq(@re_compile.execp(re, @base.sb("g")), false)
}

///|
test "Re::notnl" {
  let re = @re_compile.compile(@re_compile.Re::notnl())
  assert_eq(@re_compile.execp(re, @base.sb("a")), true)
}

///|
test "Re::ascii" {
  let re = @re_compile.compile(@re_compile.Re::ascii())
  assert_eq(@re_compile.execp(re, @base.sb("a")), true)
}

///|
test "Re::cntrl" {
  let re = @re_compile.compile(@re_compile.Re::cntrl())
  assert_eq(@re_compile.execp(re, @base.sb("\t")), true)
}

///|
test "Re::graph" {
  let re = @re_compile.compile(@re_compile.Re::graph())
  assert_eq(@re_compile.execp(re, @base.sb("a")), true)
}

///|
test "Re::print" {
  let re = @re_compile.compile(@re_compile.Re::print())
  assert_eq(@re_compile.execp(re, @base.sb(" ")), true)
}

///|
test "Re::punct" {
  let re = @re_compile.compile(@re_compile.Re::punct())
  assert_eq(@re_compile.execp(re, @base.sb("!")), true)
  assert_eq(@re_compile.execp(re, @base.sb("a")), false)
}

// === exec (non-optional) ===

///|
test "exec returns group on match" {
  let re = @re_compile.compile(@ast.Ast::str(@base.sb("hello")))
  let g = @re_compile.exec(re, @base.sb("hello world"))
  assert_eq(@re_compile.GroupT::start(g, 0), 0)
}

///|
test "exec raises on no match" {
  let re = @re_compile.compile(@ast.Ast::str(@base.sb("xyz")))
  let raised = try {
    let _ = @re_compile.exec(re, @base.sb("hello"))
    false
  } catch {
    _ => true
  }
  assert_eq(raised, true)
}

// === ExecPartialResult::partial ===

///|
test "exec_partial partial" {
  let re = @re_compile.compile(
    @ast.Ast::seq([@ast.Ast::bos(), @ast.Ast::str(@base.sb("hello"))]),
  )
  let result = @re_compile.exec_partial(re, @base.sb("hel"))
  assert_eq(result, @re_compile.ExecPartialResult::partial())
}
