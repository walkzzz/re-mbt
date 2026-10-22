// Tests for frontends: Perl, Emacs, Posix, Glob, Pcre, Str

///|
test "perl basic match" {
  let re = @re_frontend.Perl::compile_pat(@base.sb("hello"))
  assert_eq(@compile.execp(re, @base.sb("hello world")), true)
  assert_eq(@compile.execp(re, @base.sb("goodbye")), false)
}

///|
test "perl alternation" {
  let re = @re_frontend.Perl::compile_pat(@base.sb("cat|dog|bird"))
  assert_eq(@compile.execp(re, @base.sb("I have a cat")), true)
  assert_eq(@compile.execp(re, @base.sb("I have a dog")), true)
  assert_eq(@compile.execp(re, @base.sb("I have a bird")), true)
  assert_eq(@compile.execp(re, @base.sb("I have a fish")), false)
}

///|
test "perl groups" {
  let re = @re_frontend.Perl::compile_pat(@base.sb("(a)(b)(c)"))
  match @compile.exec_opt(re, @base.sb("abc")) {
    Some(g) => {
      assert_eq(@base.bs(@compile.GroupT::get(g, 0).unwrap()), "abc")
      assert_eq(@base.bs(@compile.GroupT::get(g, 1).unwrap()), "a")
      assert_eq(@base.bs(@compile.GroupT::get(g, 2).unwrap()), "b")
      assert_eq(@base.bs(@compile.GroupT::get(g, 3).unwrap()), "c")
    }
    None => assert_eq(true, false)
  }
}

///|
test "perl star" {
  let re = @re_frontend.Perl::compile_pat(@base.sb("ab*c"))
  assert_eq(@compile.execp(re, @base.sb("ac")), true)
  assert_eq(@compile.execp(re, @base.sb("abc")), true)
  assert_eq(@compile.execp(re, @base.sb("abbbbc")), true)
  assert_eq(@compile.execp(re, @base.sb("adc")), false)
}

///|
test "perl plus" {
  let re = @re_frontend.Perl::compile_pat(@base.sb("ab+c"))
  assert_eq(@compile.execp(re, @base.sb("ac")), false)
  assert_eq(@compile.execp(re, @base.sb("abc")), true)
  assert_eq(@compile.execp(re, @base.sb("abbbbc")), true)
}

///|
test "perl char class" {
  let re = @re_frontend.Perl::compile_pat(@base.sb("[abc]"))
  assert_eq(@compile.execp(re, @base.sb("a")), true)
  assert_eq(@compile.execp(re, @base.sb("b")), true)
  assert_eq(@compile.execp(re, @base.sb("c")), true)
  assert_eq(@compile.execp(re, @base.sb("d")), false)
}

///|
test "perl char class range" {
  let re = @re_frontend.Perl::compile_pat(@base.sb("[0-9]+"))
  assert_eq(@compile.execp(re, @base.sb("abc123")), true)
  assert_eq(@compile.execp(re, @base.sb("abc")), false)
}

///|
test "perl escaped chars" {
  let re = @re_frontend.Perl::compile_pat(@base.sb("a\\.b"))
  assert_eq(@compile.execp(re, @base.sb("a.b")), true)
  assert_eq(@compile.execp(re, @base.sb("axb")), false)
}

///|
test "perl digit class" {
  let re = @re_frontend.Perl::compile_pat(@base.sb("\\d+"))
  assert_eq(@compile.execp(re, @base.sb("abc123")), true)
  assert_eq(@compile.execp(re, @base.sb("abc")), false)
}

///|
test "perl word boundary" {
  let re = @re_frontend.Perl::compile_pat(@base.sb("\\bword\\b"))
  assert_eq(@compile.execp(re, @base.sb("a word here")), true)
  assert_eq(@compile.execp(re, @base.sb("a wordy here")), false)
}

///|
test "emacs basic" {
  let re = @re_frontend.Emacs::compile_pat(@base.sb("hello"))
  assert_eq(@compile.execp(re, @base.sb("hello world")), true)
  assert_eq(@compile.execp(re, @base.sb("goodbye")), false)
}

///|
test "emacs groups" {
  let re = @re_frontend.Emacs::compile_pat(@base.sb("\\(ab\\)*c"))
  assert_eq(@compile.execp(re, @base.sb("c")), true)
  assert_eq(@compile.execp(re, @base.sb("abc")), true)
  assert_eq(@compile.execp(re, @base.sb("ababc")), true)
}

///|
test "posix basic" {
  let re = @re_frontend.Posix::compile(@base.sb("ab*c"))
  assert_eq(@compile.execp(re, @base.sb("ac")), true)
  assert_eq(@compile.execp(re, @base.sb("abbbbc")), true)
  assert_eq(@compile.execp(re, @base.sb("adc")), false)
}

///|
test "posix groups" {
  let re = @re_frontend.Posix::compile(@base.sb("(ab)*c"))
  assert_eq(@compile.execp(re, @base.sb("c")), true)
  assert_eq(@compile.execp(re, @base.sb("abc")), true)
  assert_eq(@compile.execp(re, @base.sb("ababc")), true)
}

///|
test "glob basic" {
  let re = @re_frontend.Glob::compile(@base.sb("*.txt"))
  assert_eq(@compile.execp(re, @base.sb("hello.txt")), true)
  assert_eq(@compile.execp(re, @base.sb("hello.py")), false)
}

///|
test "glob star match" {
  let re = @re_frontend.Glob::compile(@base.sb("a*b"))
  assert_eq(@compile.execp(re, @base.sb("ab")), true)
  assert_eq(@compile.execp(re, @base.sb("axxxb")), true)
  assert_eq(@compile.execp(re, @base.sb("axxc")), false)
}

///|
test "glob question mark" {
  let re = @re_frontend.Glob::compile(@base.sb("a?b"))
  assert_eq(@compile.execp(re, @base.sb("axb")), true)
  assert_eq(@compile.execp(re, @base.sb("ab")), false)
}

///|
test "pcre basic" {
  let re = @re_frontend.Pcre::regexp(@base.sb("hello"))
  assert_eq(@re_frontend.Pcre::pmatch(re, @base.sb("hello world")), true)
  assert_eq(@re_frontend.Pcre::pmatch(re, @base.sb("goodbye")), false)
}

///|
test "pcre extract" {
  let re = @re_frontend.Pcre::regexp(@base.sb("(a)(b)"))
  let groups = @re_frontend.Pcre::extract(re, @base.sb("ab"))
  assert_eq(groups.length(), 3)
  assert_eq(@base.bs(groups[0]), "ab")
  assert_eq(@base.bs(groups[1]), "a")
  assert_eq(@base.bs(groups[2]), "b")
}

///|
test "str basic match" {
  let re = @re_frontend.Str::regexp(@base.sb("hello"))
  assert_eq(
    @re_frontend.Str::string_match(re, @base.sb("hello world"), 0),
    true,
  )
  assert_eq(@re_frontend.Str::string_match(re, @base.sb("goodbye"), 0), false)
}

///|
test "str search" {
  let re = @re_frontend.Str::regexp(@base.sb("world"))
  let pos = @re_frontend.Str::search_forward(re, @base.sb("hello world"), 0)
  assert_eq(pos, 6)
}

///|
test "str split" {
  let re = @re_frontend.Str::regexp(@base.sb(","))
  let parts = @re_frontend.Str::split(re, @base.sb("a,b,c"))
  assert_eq(parts.length(), 3)
  assert_eq(@base.bs(parts[0]), "a")
  assert_eq(@base.bs(parts[1]), "b")
  assert_eq(@base.bs(parts[2]), "c")
}

///|
test "perl non-greedy" {
  let re = @re_frontend.Perl::compile_pat(@base.sb("a.*?b"))
  match @compile.exec_opt(re, @base.sb("axxbxxb")) {
    Some(g) => assert_eq(@base.bs(@compile.GroupT::get(g, 0).unwrap()), "axxb")
    None => assert_eq(true, false)
  }
}

///|
test "perl {n,m}" {
  let re = @re_frontend.Perl::compile_pat(@base.sb("a{2,3}"))
  assert_eq(@compile.execp(re, @base.sb("a")), false)
  assert_eq(@compile.execp(re, @base.sb("aa")), true)
  assert_eq(@compile.execp(re, @base.sb("aaa")), true)
  assert_eq(@compile.execp(re, @base.sb("aaaa")), true)
}

///|
test "perl caseless" {
  let re = @re_frontend.Perl::compile_pat(@base.sb("hello"), opts=[
    @re_frontend.PerlOpt::caseless(),
  ])
  assert_eq(@compile.execp(re, @base.sb("HELLO")), true)
  assert_eq(@compile.execp(re, @base.sb("Hello")), true)
}

///|
test "perl unclosed paren raise" {
  let r1 = try {
    let _ = @re_frontend.Perl::compile_pat(@base.sb("("))
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
  let r2 = try {
    let _ = @re_frontend.Perl::compile_pat(@base.sb("(abc"))
    false
  } catch {
    _ => true
  }
  assert_eq(r2, true)
}

///|
test "perl invalid escape raise" {
  let r1 = try {
    let _ = @re_frontend.Perl::compile_pat(@base.sb("\\"))
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
  let r2 = try {
    let _ = @re_frontend.Perl::compile_pat(@base.sb("\\8"))
    false
  } catch {
    _ => true
  }
  assert_eq(r2, true)
}

///|
test "perl unclosed bracket raise" {
  let r1 = try {
    let _ = @re_frontend.Perl::compile_pat(@base.sb("["))
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
  let r2 = try {
    let _ = @re_frontend.Perl::compile_pat(@base.sb("[abc"))
    false
  } catch {
    _ => true
  }
  assert_eq(r2, true)
}

///|
test "emacs unclosed paren raise" {
  let r1 = try {
    let _ = @re_frontend.Emacs::compile_pat(@base.sb("\\("))
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
  let r2 = try {
    let _ = @re_frontend.Emacs::compile_pat(@base.sb("\\(abc"))
    false
  } catch {
    _ => true
  }
  assert_eq(r2, true)
}

///|
test "emacs invalid escape raise" {
  let r1 = try {
    let _ = @re_frontend.Emacs::compile_pat(@base.sb("\\"))
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
}

///|
test "pcre unclosed paren raise" {
  let r1 = try {
    let _ = @re_frontend.Pcre::regexp(@base.sb("("))
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
  let r2 = try {
    let _ = @re_frontend.Pcre::regexp(@base.sb("(abc"))
    false
  } catch {
    _ => true
  }
  assert_eq(r2, true)
}

///|
test "pcre invalid escape raise" {
  let r1 = try {
    let _ = @re_frontend.Pcre::regexp(@base.sb("\\8"))
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
}

///|
test "perl anchored opt" {
  let re_a = @re_frontend.Perl::compile_pat(@base.sb("hello"), opts=[
    @re_frontend.PerlOpt::anchored(),
  ])
  assert_eq(@compile.execp(re_a, @base.sb("hello world")), true)
  assert_eq(@compile.execp(re_a, @base.sb("say hello")), false)
  let re_no = @re_frontend.Perl::compile_pat(@base.sb("hello"))
  assert_eq(@compile.execp(re_no, @base.sb("say hello")), true)
}

///|
test "perl dotall opt" {
  let re_d = @re_frontend.Perl::compile_pat(@base.sb("a.b"), opts=[
    @re_frontend.PerlOpt::dotall(),
  ])
  assert_eq(@compile.execp(re_d, @base.sb("a\nb")), true)
  let re_no = @re_frontend.Perl::compile_pat(@base.sb("a.b"))
  assert_eq(@compile.execp(re_no, @base.sb("a\nb")), false)
  assert_eq(@compile.execp(re_no, @base.sb("axb")), true)
}

///|
test "perl multiline opt" {
  let re_m = @re_frontend.Perl::compile_pat(@base.sb("^abc$"), opts=[
    @re_frontend.PerlOpt::multiline(),
  ])
  assert_eq(@compile.execp(re_m, @base.sb("x\nabc\ny")), true)
  let re_no = @re_frontend.Perl::compile_pat(@base.sb("^abc$"))
  assert_eq(@compile.execp(re_no, @base.sb("x\nabc\ny")), false)
  assert_eq(@compile.execp(re_no, @base.sb("abc")), true)
}

///|
test "perl dollar_endonly opt" {
  let re_de = @re_frontend.Perl::compile_pat(@base.sb("abc$"), opts=[
    @re_frontend.PerlOpt::dollar_endonly(),
  ])
  assert_eq(@compile.execp(re_de, @base.sb("abc\n")), true)
  assert_eq(@compile.execp(re_de, @base.sb("abc")), true)
  let re_no = @re_frontend.Perl::compile_pat(@base.sb("abc$"))
  assert_eq(@compile.execp(re_no, @base.sb("abc\n")), false)
}

///|
test "perl ungreedy opt" {
  let re_u = @re_frontend.Perl::compile_pat(@base.sb("(a+)"), opts=[
    @re_frontend.PerlOpt::ungreedy(),
  ])
  match @compile.exec_opt(re_u, @base.sb("aaa")) {
    Some(g) => assert_eq(@base.bs(@compile.GroupT::get(g, 1).unwrap()), "a")
    None => assert_eq(true, false)
  }
  let re_no = @re_frontend.Perl::compile_pat(@base.sb("(a+)"))
  match @compile.exec_opt(re_no, @base.sb("aaa")) {
    Some(g) => assert_eq(@base.bs(@compile.GroupT::get(g, 1).unwrap()), "aaa")
    None => assert_eq(true, false)
  }
}

///|
test "pcre caseless flag" {
  let re_ci = @re_frontend.Pcre::regexp(@base.sb("hello"), flags=[
    @re_frontend.PcreFlag::caseless(),
  ])
  assert_eq(@re_frontend.Pcre::pmatch(re_ci, @base.sb("HELLO")), true)
  let re_no = @re_frontend.Pcre::regexp(@base.sb("hello"))
  assert_eq(@re_frontend.Pcre::pmatch(re_no, @base.sb("HELLO")), false)
}

///|
test "pcre multiline flag" {
  let re_ml = @re_frontend.Pcre::regexp(@base.sb("^abc$"), flags=[
    @re_frontend.PcreFlag::multiline_p(),
  ])
  assert_eq(@re_frontend.Pcre::pmatch(re_ml, @base.sb("x\nabc\ny")), true)
  let re_no = @re_frontend.Pcre::regexp(@base.sb("^abc$"))
  assert_eq(@re_frontend.Pcre::pmatch(re_no, @base.sb("x\nabc\ny")), false)
  assert_eq(@re_frontend.Pcre::pmatch(re_no, @base.sb("abc")), true)
}

///|
test "pcre anchored flag" {
  let re_a = @re_frontend.Pcre::regexp(@base.sb("hello"), flags=[
    @re_frontend.PcreFlag::anchored_p(),
  ])
  assert_eq(@re_frontend.Pcre::pmatch(re_a, @base.sb("hello world")), true)
  assert_eq(@re_frontend.Pcre::pmatch(re_a, @base.sb("say hello")), false)
  let re_no = @re_frontend.Pcre::regexp(@base.sb("hello"))
  assert_eq(@re_frontend.Pcre::pmatch(re_no, @base.sb("say hello")), true)
}

///|
test "pcre dotall flag" {
  let re_d = @re_frontend.Pcre::regexp(@base.sb("a.b"), flags=[
    @re_frontend.PcreFlag::dotall_p(),
  ])
  assert_eq(@re_frontend.Pcre::pmatch(re_d, @base.sb("a\nb")), true)
  let re_no = @re_frontend.Pcre::regexp(@base.sb("a.b"))
  assert_eq(@re_frontend.Pcre::pmatch(re_no, @base.sb("a\nb")), false)
  assert_eq(@re_frontend.Pcre::pmatch(re_no, @base.sb("axb")), true)
}

///|
test "str global_replace replaces all matches" {
  let re = @re_frontend.Str::regexp(@base.sb("o"))
  let repl = @base.sb("X")
  assert_eq(
    @base.bs(
      @re_frontend.Str::global_replace(re, repl, @base.sb("foo bar boo")),
    ),
    "fXX bar bXX",
  )
  assert_eq(
    @base.bs(@re_frontend.Str::global_replace(re, repl, @base.sb("xyz"))),
    "xyz",
  )
}

///|
test "str replace_first replaces first match" {
  let re = @re_frontend.Str::regexp(@base.sb("o"))
  let repl = @base.sb("X")
  assert_eq(
    @base.bs(@re_frontend.Str::replace_first(re, repl, @base.sb("foo"))),
    "fXo",
  )
  assert_eq(
    @base.bs(@re_frontend.Str::replace_first(re, repl, @base.sb("xyz"))),
    "xyz",
  )
}

///|
test "str full_split text and delim" {
  let re = @re_frontend.Str::regexp(@base.sb(","))
  let result = @re_frontend.Str::full_split(re, @base.sb("a,b,c"))
  assert_eq(result.length(), 5)
  match result[0] {
    StrText(t) => assert_eq(@base.bs(t), "a")
    StrDelim(_) => assert_eq(true, false)
  }
  match result[1] {
    StrText(_) => assert_eq(true, false)
    StrDelim(d) => assert_eq(@base.bs(d), ",")
  }
  match result[2] {
    StrText(t) => assert_eq(@base.bs(t), "b")
    StrDelim(_) => assert_eq(true, false)
  }
  match result[3] {
    StrText(_) => assert_eq(true, false)
    StrDelim(d) => assert_eq(@base.bs(d), ",")
  }
  match result[4] {
    StrText(t) => assert_eq(@base.bs(t), "c")
    StrDelim(_) => assert_eq(true, false)
  }
}

///|
test "str bounded_split limit" {
  let re = @re_frontend.Str::regexp(@base.sb(","))
  let text = @base.sb("a,b,c,d")
  let r0 = @re_frontend.Str::bounded_split(re, text, 0)
  assert_eq(r0.length(), 4)
  assert_eq(@base.bs(r0[0]), "a")
  assert_eq(@base.bs(r0[1]), "b")
  assert_eq(@base.bs(r0[2]), "c")
  assert_eq(@base.bs(r0[3]), "d")
  let r2 = @re_frontend.Str::bounded_split(re, text, 2)
  assert_eq(r2.length(), 2)
  assert_eq(@base.bs(r2[0]), "a")
  assert_eq(@base.bs(r2[1]), "b,c,d")
}

///|
test "str quote special chars" {
  assert_eq(@base.bs(@re_frontend.Str::quote(@base.sb("a.b"))), "a\\.b")
  assert_eq(@base.bs(@re_frontend.Str::quote(@base.sb("[*]"))), "\\[\\*\\]")
  assert_eq(@base.bs(@re_frontend.Str::quote(@base.sb("normal"))), "normal")
  assert_eq(@base.bs(@re_frontend.Str::quote(@base.sb("?+$^"))), "\\?\\+\\$\\^")
}

///|
test "str regexp_case_fold case insensitive" {
  let re = @re_frontend.Str::regexp_case_fold(@base.sb("hello"))
  assert_eq(
    @re_frontend.Str::string_match(re, @base.sb("HELLO world"), 0),
    true,
  )
  let re2 = @re_frontend.Str::regexp(@base.sb("hello"))
  assert_eq(
    @re_frontend.Str::string_match(re2, @base.sb("HELLO world"), 0),
    false,
  )
}

///|
test "str regexp_string_case_fold" {
  let re = @re_frontend.Str::regexp_string_case_fold(@base.sb("a.b"))
  assert_eq(@re_frontend.Str::string_match(re, @base.sb("A.B"), 0), true)
  assert_eq(@re_frontend.Str::string_match(re, @base.sb("axb"), 0), false)
}

///|
test "str search_backward" {
  let re = @re_frontend.Str::regexp(@base.sb("ab"))
  assert_eq(@re_frontend.Str::search_backward(re, @base.sb("xabxab"), 5), 4)
  assert_eq(@re_frontend.Str::search_backward(re, @base.sb("xabxab"), 3), 1)
  assert_eq(@re_frontend.Str::search_backward(re, @base.sb("xabxab"), 2), 1)
}

///|
test "str string_partial_match" {
  let re = @re_frontend.Str::regexp(@base.sb("abc"))
  assert_eq(@re_frontend.Str::string_partial_match(re, @base.sb("ab"), 0), true)
  assert_eq(
    @re_frontend.Str::string_partial_match(re, @base.sb("xyz"), 0),
    false,
  )
  assert_eq(
    @re_frontend.Str::string_partial_match(re, @base.sb("abc"), 0),
    true,
  )
}

///|
test "str replace_matched" {
  let re = @re_frontend.Str::regexp(@base.sb("\\(a\\)\\(b\\)"))
  ignore(@re_frontend.Str::search_forward(re, @base.sb("ab"), 0))
  assert_eq(
    @base.bs(
      @re_frontend.Str::replace_matched(@base.sb("\\0\\1\\2"), @base.sb("ab")),
    ),
    "abab",
  )
}

///|
test "str global_substitute" {
  let re = @re_frontend.Str::regexp(@base.sb("o"))
  let result = @re_frontend.Str::global_substitute(
    re,
    fn(_s) { @base.sb("X") },
    @base.sb("foo"),
  )
  assert_eq(@base.bs(result), "fXX")
}

///|
test "str substitute_first" {
  let re = @re_frontend.Str::regexp(@base.sb("o"))
  let result = @re_frontend.Str::substitute_first(
    re,
    fn(_s) { @base.sb("X") },
    @base.sb("foo"),
  )
  assert_eq(@base.bs(result), "fXo")
}

///|
test "str split_delim" {
  let re = @re_frontend.Str::regexp(@base.sb(","))
  let parts = @re_frontend.Str::split_delim(re, @base.sb(",a,b,"))
  assert_eq(parts.length(), 4)
  assert_eq(@base.bs(parts[0]), "")
  assert_eq(@base.bs(parts[1]), "a")
  assert_eq(@base.bs(parts[2]), "b")
  assert_eq(@base.bs(parts[3]), "")
}

///|
test "str bounded_split_delim" {
  let re = @re_frontend.Str::regexp(@base.sb(","))
  let parts = @re_frontend.Str::bounded_split_delim(re, @base.sb("a,b,c,d"), 2)
  assert_eq(parts.length(), 2)
  assert_eq(@base.bs(parts[0]), "a")
  assert_eq(@base.bs(parts[1]), "b,c,d")
}

///|
test "str bounded_full_split" {
  let re = @re_frontend.Str::regexp(@base.sb(","))
  let parts = @re_frontend.Str::bounded_full_split(re, @base.sb("a,b,c"), 2)
  assert_eq(parts.length(), 3)
  match parts[0] {
    StrText(t) => assert_eq(@base.bs(t), "a")
    StrDelim(_) => assert_eq(true, false)
  }
  match parts[1] {
    StrDelim(d) => assert_eq(@base.bs(d), ",")
    StrText(_) => assert_eq(true, false)
  }
  match parts[2] {
    StrText(t) => assert_eq(@base.bs(t), "b,c")
    StrDelim(_) => assert_eq(true, false)
  }
}

///|
test "str first_chars" {
  assert_eq(@base.bs(@re_frontend.Str::first_chars(@base.sb("hello"), 2)), "he")
  assert_eq(@base.bs(@re_frontend.Str::first_chars(@base.sb("hello"), 0)), "")
}

///|
test "str last_chars" {
  assert_eq(@base.bs(@re_frontend.Str::last_chars(@base.sb("hello"), 2)), "lo")
  assert_eq(@base.bs(@re_frontend.Str::last_chars(@base.sb("hello"), 0)), "")
}
