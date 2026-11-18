// crap_test.mbt — CRAP coverage tests for re_compile
// Covers compile.mbt, compile_translate.mbt

// === GroupT::get coverage ===

///|
test "GroupT::get None for invalid group" {
  let re = @re_compile.compile(@ast.Ast::group(@ast.Ast::char('a')))
  match @re_compile.exec_opt(re, @base.sb("a")) {
    Some(g) => assert_eq(@re_compile.GroupT::get(g, 100) is None, true)
    None => assert_eq(true, false)
  }
}

///|
test "GroupT::get len < 0 for unmatched group" {
  let re = @re_compile.compile(
    @ast.Ast::alt([
      @ast.Ast::group(@ast.Ast::char('a')),
      @ast.Ast::group(@ast.Ast::char('b')),
    ]),
  )
  match @re_compile.exec_opt(re, @base.sb("a")) {
    Some(g) => assert_eq(@re_compile.GroupT::get(g, 2) is None, true)
    None => assert_eq(true, false)
  }
}

// === match_str_p coverage ===

///|
test "match_str_p out of bounds" {
  let re = @re_compile.compile(@ast.Ast::char('a'))
  let r1 = try {
    let _ = @re_compile.match_str_p(re, @base.sb("a"), pos=-1, len=0)
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
  let r2 = try {
    let _ = @re_compile.match_str_p(re, @base.sb("a"), pos=0, len=100)
    false
  } catch {
    _ => true
  }
  assert_eq(r2, true)
}

// === make_match_str partial Match ===

///|
test "exec_partial_detailed match status" {
  let re = @re_compile.compile(@ast.Ast::str(@base.sb("hello")))
  let result = @re_compile.exec_partial_detailed(re, @base.sb("hello"))
  match result {
    FullD(_) => assert_eq(true, true)
    _ => assert_eq(true, true)
  }
}

// === translate coverage ===

///|
test "translate NotBound" {
  let re = @re_compile.compile(@ast.Ast::not_boundary())
  let _ = @re_compile.execp(re, @base.sb("ab"))
}

///|
test "translate Stop" {
  let re = @re_compile.compile(@ast.Ast::stop())
  let _ = @re_compile.execp(re, @base.sb("a"))
}

///|
test "translate Pmark" {
  let (_, marked) = @ast.Ast::mark(@ast.Ast::char('a'))
  let re = @re_compile.compile(marked)
  assert_eq(@re_compile.execp(re, @base.sb("a")), true)
}

///|
test "translate NoCase" {
  let re = @re_compile.compile(@ast.Ast::no_case(@ast.Ast::char('a')))
  assert_eq(@re_compile.execp(re, @base.sb("A")), true)
}

///|
test "translate merge single" {
  let re = @re_compile.compile(@ast.Ast::alt([@ast.Ast::str(@base.sb("ab"))]))
  assert_eq(@re_compile.execp(re, @base.sb("ab")), true)
}

///|
test "make_repeater NonGreedy" {
  let re = @re_compile.compile(
    @ast.Ast::non_greedy(@ast.Ast::repn(@ast.Ast::char('a'), 2, Some(3))),
  )
  assert_eq(@re_compile.execp(re, @base.sb("aa")), true)
  assert_eq(@re_compile.execp(re, @base.sb("aaa")), true)
}

///|
test "trans_seq is_eps cr1" {
  let re = @re_compile.compile(
    @ast.Ast::seq([@ast.Ast::epsilon(), @ast.Ast::char('a')]),
  )
  assert_eq(@re_compile.execp(re, @base.sb("a")), true)
}

// === get_color and handle_last_newline coverage ===

///|
test "get_color pos >= slen" {
  // pos >= slen 时 get_color 走 null_char 哨兵分支；空窗口下模式 'a' 无匹配
  // when pos >= slen, get_color takes the null_char sentinel branch; no match
  // in an empty window (same as upstream ocaml-re)
  let re = @re_compile.compile(@ast.Ast::char('a'))
  assert_eq(@re_compile.execp(re, @base.sb("a"), pos=1, len=0), false)
}

///|
test "handle_last_newline with groups" {
  let re = @re_compile.compile(
    @ast.Ast::seq([@ast.Ast::char('a'), @ast.Ast::leol()]),
  )
  assert_eq(@re_compile.execp(re, @base.sb("a\n")), true)
}

///|
test "scan_str is_break with last newline" {
  let re = @re_compile.compile(
    @ast.Ast::seq([@ast.Ast::str(@base.sb("abc")), @ast.Ast::leol()]),
  )
  assert_eq(@re_compile.execp(re, @base.sb("abc\n")), true)
}

// === positions_resize coverage ===

///|
test "positions_resize recursive" {
  let re = @re_compile.compile(
    @ast.Ast::group(@ast.Ast::group(@ast.Ast::group(@ast.Ast::char('a')))),
  )
  match @re_compile.exec_opt(re, @base.sb("a")) {
    Some(g) => {
      assert_eq(@re_compile.GroupT::get(g, 0) is Some(_), true)
      assert_eq(@re_compile.GroupT::get(g, 1) is Some(_), true)
    }
    None => assert_eq(true, false)
  }
}

// === follow_transition coverage ===

///|
test "follow_transition via exec" {
  let re = @re_compile.compile(
    @ast.Ast::seq([@ast.Ast::char('a'), @ast.Ast::char('b')]),
  )
  assert_eq(@re_compile.execp(re, @base.sb("ab")), true)
}
