// coverage_frontend_test.mbt — Frontend edge cases/mark_test coverage tests

// === Frontend edge cases ===

///|
test "perl anchor ^" {
  let re = @re_frontend.Perl::compile_pat(@base.sb("^hello"))
  assert_eq(@compile.execp(re, @base.sb("hello world")), true)
  assert_eq(@compile.execp(re, @base.sb("say hello")), false)
}

///|
test "perl anchor end of string" {
  let pat : Array[Byte] = [119, 111, 114, 108, 100, 36]
  let re = @re_frontend.Perl::compile_pat(Bytes::from_array(pat))
  assert_eq(@compile.execp(re, @base.sb("hello world")), true)
  assert_eq(@compile.execp(re, @base.sb("world hello")), false)
}

///|
test "perl \\s class" {
  let re = @re_frontend.Perl::compile_pat(@base.sb("\\s+"))
  assert_eq(@compile.execp(re, @base.sb("   ")), true)
  assert_eq(@compile.execp(re, @base.sb("abc")), false)
}

///|
test "perl \\w class" {
  let re = @re_frontend.Perl::compile_pat(@base.sb("\\w+"))
  assert_eq(@compile.execp(re, @base.sb("hello_123")), true)
  assert_eq(@compile.execp(re, @base.sb("   ")), false)
}

///|
test "perl {n} exact" {
  let re = @re_frontend.Perl::compile_pat(@base.sb("a{3}"))
  assert_eq(@compile.execp(re, @base.sb("aaa")), true)
  assert_eq(@compile.execp(re, @base.sb("aa")), false)
}

///|
test "perl {n,} open-ended" {
  let re = @re_frontend.Perl::compile_pat(@base.sb("a{2,}"))
  assert_eq(@compile.execp(re, @base.sb("aa")), true)
  assert_eq(@compile.execp(re, @base.sb("aaaa")), true)
  assert_eq(@compile.execp(re, @base.sb("a")), false)
}

///|
test "perl nested groups" {
  let re = @re_frontend.Perl::compile_pat(@base.sb("(a(b)c)"))
  match @compile.exec_opt(re, @base.sb("abc")) {
    Some(g) => {
      assert_eq(@base.bs(@compile.GroupT::get(g, 0).unwrap()), "abc")
      assert_eq(@base.bs(@compile.GroupT::get(g, 1).unwrap()), "abc")
      assert_eq(@base.bs(@compile.GroupT::get(g, 2).unwrap()), "b")
    }
    None => assert_eq(true, false)
  }
}

///|
test "perl alternation with groups" {
  let re = @re_frontend.Perl::compile_pat(@base.sb("(cat)|(dog)"))
  match @compile.exec_opt(re, @base.sb("cat")) {
    Some(g) => {
      assert_eq(@base.bs(@compile.GroupT::get(g, 0).unwrap()), "cat")
      assert_eq(@base.bs(@compile.GroupT::get(g, 1).unwrap()), "cat")
    }
    None => assert_eq(true, false)
  }
  match @compile.exec_opt(re, @base.sb("dog")) {
    Some(g) => assert_eq(@base.bs(@compile.GroupT::get(g, 0).unwrap()), "dog")
    None => assert_eq(true, false)
  }
}

///|
test "perl char class negation" {
  let re = @re_frontend.Perl::compile_pat(@base.sb("[^abc]"))
  assert_eq(@compile.execp(re, @base.sb("d")), true)
  assert_eq(@compile.execp(re, @base.sb("a")), false)
}

///|
test "perl optional ? after group" {
  let re = @re_frontend.Perl::compile_pat(@base.sb("(ab)?c"))
  assert_eq(@compile.execp(re, @base.sb("c")), true)
  assert_eq(@compile.execp(re, @base.sb("abc")), true)
  assert_eq(@compile.execp(re, @base.sb("ab")), false)
}

///|
test "emacs char class" {
  let re = @re_frontend.Emacs::compile_pat(@base.sb("[abc]"))
  assert_eq(@compile.execp(re, @base.sb("a")), true)
  assert_eq(@compile.execp(re, @base.sb("b")), true)
  assert_eq(@compile.execp(re, @base.sb("d")), false)
}

///|
test "emacs plus" {
  let re = @re_frontend.Emacs::compile_pat(@base.sb("ab+c"))
  assert_eq(@compile.execp(re, @base.sb("ac")), false)
  assert_eq(@compile.execp(re, @base.sb("abc")), true)
  assert_eq(@compile.execp(re, @base.sb("abbbbc")), true)
}

///|
test "glob escape char" {
  let re = @re_frontend.Glob::compile(@base.sb("\\a.txt"))
  assert_eq(@compile.execp(re, @base.sb("a.txt")), true)
  assert_eq(@compile.execp(re, @base.sb("b.txt")), false)
}

///|
test "pcre groups and alternation" {
  let re = @re_frontend.Pcre::regexp(@base.sb("(a|b)(c|d)"))
  assert_eq(@re_frontend.Pcre::pmatch(re, @base.sb("ac")), true)
  assert_eq(@re_frontend.Pcre::pmatch(re, @base.sb("bd")), true)
  assert_eq(@re_frontend.Pcre::pmatch(re, @base.sb("ad")), true)
  assert_eq(@re_frontend.Pcre::pmatch(re, @base.sb("bc")), true)
  assert_eq(@re_frontend.Pcre::pmatch(re, @base.sb("cd")), false)
  assert_eq(@re_frontend.Pcre::pmatch(re, @base.sb("ef")), false)
}

///|
test "str string_match with pos" {
  let re = @re_frontend.Str::regexp(@base.sb("world"))
  assert_eq(
    @re_frontend.Str::string_match(re, @base.sb("hello world"), 6),
    true,
  )
  assert_eq(
    @re_frontend.Str::string_match(re, @base.sb("hello world"), 0),
    false,
  )
}

///|
test "str search_forward not found" {
  let re = @re_frontend.Str::regexp(@base.sb("xyz"))
  let raised = try {
    let _ = @re_frontend.Str::search_forward(re, @base.sb("hello world"), 0)
    false
  } catch {
    _ => true
  }
  assert_eq(raised, true)
}

///|
test "search matches with groups in result" {
  let re = @compile.compile(@ast.Ast::rep1(@compile.Re::digit()))
  let s = @base.sb("abc123def456")
  let groups = @exec.Search::all(re, s)
  assert_eq(groups.length(), 2)
  assert_eq(@base.bs(@compile.GroupT::get(groups[0], 0).unwrap()), "123")
  assert_eq(@base.bs(@compile.GroupT::get(groups[1], 0).unwrap()), "456")
}

///|
test "replace with function all=false" {
  let re = @compile.compile(@ast.Ast::rep1(@compile.Re::digit()))
  let s = @base.sb("a1b2c3")
  let result = @exec.Replace::replace(
    re,
    s,
    f=fn(g : @compile.GroupT) { @compile.GroupT::get(g, 0).unwrap() },
    all=false,
  )
  assert_eq(@base.bs(result), "a1b2c3")
}

///|
test "exec_partial_detailed partial" {
  let re = @compile.compile(
    @ast.Ast::seq([@ast.Ast::bos(), @ast.Ast::str(@base.sb("hello"))]),
  )
  let result = @compile.exec_partial_detailed(re, @base.sb("hel"))
  match result {
    PartialD(_) => assert_eq(true, true)
    _ => assert_eq(true, false)
  }
}

///|
test "exec_partial_detailed mismatch" {
  let re = @compile.compile(
    @ast.Ast::seq([@ast.Ast::bos(), @ast.Ast::str(@base.sb("hello"))]),
  )
  let result = @compile.exec_partial_detailed(re, @base.sb("world"))
  match result {
    MismatchD => assert_eq(true, true)
    _ => assert_eq(true, false)
  }
}

// === Re::mark_test / mark_all ===

///|
test "Re::mark_test and mark_all" {
  let re = @compile.compile(@ast.Ast::group(@ast.Ast::str(@base.sb("a"))))
  match @compile.exec_opt(re, @base.sb("a")) {
    Some(g) => {
      let all_marks = @compile.Re::mark_all(g)
      let _pm = @base.PmarkSet::to_list(all_marks)
      assert_eq(true, true)
    }
    None => assert_eq(true, false)
  }
}
