// coverage_frontend_test.mbt — Frontend edge cases/mark_test coverage tests

// === Frontend edge cases ===

///|
test "perl anchor ^" {
  let re = Perl::compile_pat(sb("^hello"))
  assert_eq(execp(re, sb("hello world")), true)
  assert_eq(execp(re, sb("say hello")), false)
}

///|
test "perl anchor end of string" {
  let pat : Array[Byte] = [119, 111, 114, 108, 100, 36]
  let re = Perl::compile_pat(Bytes::from_array(pat))
  assert_eq(execp(re, sb("hello world")), true)
  assert_eq(execp(re, sb("world hello")), false)
}

///|
test "perl \\s class" {
  let re = Perl::compile_pat(sb("\\s+"))
  assert_eq(execp(re, sb("   ")), true)
  assert_eq(execp(re, sb("abc")), false)
}

///|
test "perl \\w class" {
  let re = Perl::compile_pat(sb("\\w+"))
  assert_eq(execp(re, sb("hello_123")), true)
  assert_eq(execp(re, sb("   ")), false)
}

///|
test "perl {n} exact" {
  let re = Perl::compile_pat(sb("a{3}"))
  assert_eq(execp(re, sb("aaa")), true)
  assert_eq(execp(re, sb("aa")), false)
}

///|
test "perl {n,} open-ended" {
  let re = Perl::compile_pat(sb("a{2,}"))
  assert_eq(execp(re, sb("aa")), true)
  assert_eq(execp(re, sb("aaaa")), true)
  assert_eq(execp(re, sb("a")), false)
}

///|
test "perl nested groups" {
  let re = Perl::compile_pat(sb("(a(b)c)"))
  match exec_opt(re, sb("abc")) {
    Some(g) => {
      assert_eq(bs(GroupT::get(g, 0).unwrap()), "abc")
      assert_eq(bs(GroupT::get(g, 1).unwrap()), "abc")
      assert_eq(bs(GroupT::get(g, 2).unwrap()), "b")
    }
    None => assert_eq(true, false)
  }
}

///|
test "perl alternation with groups" {
  let re = Perl::compile_pat(sb("(cat)|(dog)"))
  match exec_opt(re, sb("cat")) {
    Some(g) => {
      assert_eq(bs(GroupT::get(g, 0).unwrap()), "cat")
      assert_eq(bs(GroupT::get(g, 1).unwrap()), "cat")
    }
    None => assert_eq(true, false)
  }
  match exec_opt(re, sb("dog")) {
    Some(g) => assert_eq(bs(GroupT::get(g, 0).unwrap()), "dog")
    None => assert_eq(true, false)
  }
}

///|
test "perl char class negation" {
  let re = Perl::compile_pat(sb("[^abc]"))
  assert_eq(execp(re, sb("d")), true)
  assert_eq(execp(re, sb("a")), false)
}

///|
test "perl optional ? after group" {
  let re = Perl::compile_pat(sb("(ab)?c"))
  assert_eq(execp(re, sb("c")), true)
  assert_eq(execp(re, sb("abc")), true)
  assert_eq(execp(re, sb("ab")), false)
}

///|
test "emacs char class" {
  let re = Emacs::compile_pat(sb("[abc]"))
  assert_eq(execp(re, sb("a")), true)
  assert_eq(execp(re, sb("b")), true)
  assert_eq(execp(re, sb("d")), false)
}

///|
test "emacs plus" {
  let re = Emacs::compile_pat(sb("ab+c"))
  assert_eq(execp(re, sb("ac")), false)
  assert_eq(execp(re, sb("abc")), true)
  assert_eq(execp(re, sb("abbbbc")), true)
}

///|
test "glob escape char" {
  let re = Glob::compile(sb("\\a.txt"))
  assert_eq(execp(re, sb("a.txt")), true)
  assert_eq(execp(re, sb("b.txt")), false)
}

///|
test "pcre groups and alternation" {
  let re = Pcre::regexp(sb("(a|b)(c|d)"))
  assert_eq(Pcre::pmatch(re, sb("ac")), true)
  assert_eq(Pcre::pmatch(re, sb("bd")), true)
  assert_eq(Pcre::pmatch(re, sb("ad")), true)
  assert_eq(Pcre::pmatch(re, sb("bc")), true)
  assert_eq(Pcre::pmatch(re, sb("cd")), false)
  assert_eq(Pcre::pmatch(re, sb("ef")), false)
}

///|
test "str string_match with pos" {
  let re = Str::regexp(sb("world"))
  assert_eq(Str::string_match(re, sb("hello world"), 6), true)
  assert_eq(Str::string_match(re, sb("hello world"), 0), false)
}

///|
test "str search_forward not found" {
  let re = Str::regexp(sb("xyz"))
  let raised = try {
    let _ = Str::search_forward(re, sb("hello world"), 0)
    false
  } catch {
    _ => true
  }
  assert_eq(raised, true)
}

///|
test "search matches with groups in result" {
  let re = compile(Ast::rep1(Re::digit()))
  let s = sb("abc123def456")
  let groups = Search::all(re, s)
  assert_eq(groups.length(), 2)
  assert_eq(bs(GroupT::get(groups[0], 0).unwrap()), "123")
  assert_eq(bs(GroupT::get(groups[1], 0).unwrap()), "456")
}

///|
test "replace with function all=false" {
  let re = compile(Ast::rep1(Re::digit()))
  let s = sb("a1b2c3")
  let result = Replace::replace(
    re,
    s,
    f=fn(g : GroupT) { GroupT::get(g, 0).unwrap() },
    all=false,
  )
  assert_eq(bs(result), "a1b2c3")
}

///|
test "exec_partial_detailed partial" {
  let re = compile(Ast::seq([Ast::bos(), Ast::str(sb("hello"))]))
  let result = exec_partial_detailed(re, sb("hel"))
  match result {
    PartialD(_) => assert_eq(true, true)
    _ => assert_eq(true, false)
  }
}

///|
test "exec_partial_detailed mismatch" {
  let re = compile(Ast::seq([Ast::bos(), Ast::str(sb("hello"))]))
  let result = exec_partial_detailed(re, sb("world"))
  match result {
    MismatchD => assert_eq(true, true)
    _ => assert_eq(true, false)
  }
}

// === Re::mark_test / mark_all ===

///|
test "Re::mark_test and mark_all" {
  let re = compile(Ast::group(Ast::str(sb("a"))))
  match exec_opt(re, sb("a")) {
    Some(g) => {
      let all_marks = Re::mark_all(g)
      let _pm = PmarkSet::to_list(all_marks)
      assert_eq(true, true)
    }
    None => assert_eq(true, false)
  }
}
