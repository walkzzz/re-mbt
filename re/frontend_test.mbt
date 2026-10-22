// Tests for frontends: Perl, Emacs, Posix, Glob, Pcre, Str

///|
test "perl basic match" {
  let re = @re.Perl::compile_pat(sb("hello"))
  assert_eq(@re.execp(re, sb("hello world")), true)
  assert_eq(@re.execp(re, sb("goodbye")), false)
}

///|
test "perl alternation" {
  let re = @re.Perl::compile_pat(sb("cat|dog|bird"))
  assert_eq(@re.execp(re, sb("I have a cat")), true)
  assert_eq(@re.execp(re, sb("I have a dog")), true)
  assert_eq(@re.execp(re, sb("I have a bird")), true)
  assert_eq(@re.execp(re, sb("I have a fish")), false)
}

///|
test "perl groups" {
  let re = @re.Perl::compile_pat(sb("(a)(b)(c)"))
  match @re.exec_opt(re, sb("abc")) {
    Some(g) => {
      assert_eq(bs(@re.GroupT::get(g, 0).unwrap()), "abc")
      assert_eq(bs(@re.GroupT::get(g, 1).unwrap()), "a")
      assert_eq(bs(@re.GroupT::get(g, 2).unwrap()), "b")
      assert_eq(bs(@re.GroupT::get(g, 3).unwrap()), "c")
    }
    None => assert_eq(true, false)
  }
}

///|
test "perl star" {
  let re = @re.Perl::compile_pat(sb("ab*c"))
  assert_eq(@re.execp(re, sb("ac")), true)
  assert_eq(@re.execp(re, sb("abc")), true)
  assert_eq(@re.execp(re, sb("abbbbc")), true)
  assert_eq(@re.execp(re, sb("adc")), false)
}

///|
test "perl plus" {
  let re = @re.Perl::compile_pat(sb("ab+c"))
  assert_eq(@re.execp(re, sb("ac")), false)
  assert_eq(@re.execp(re, sb("abc")), true)
  assert_eq(@re.execp(re, sb("abbbbc")), true)
}

///|
test "perl char class" {
  let re = @re.Perl::compile_pat(sb("[abc]"))
  assert_eq(@re.execp(re, sb("a")), true)
  assert_eq(@re.execp(re, sb("b")), true)
  assert_eq(@re.execp(re, sb("c")), true)
  assert_eq(@re.execp(re, sb("d")), false)
}

///|
test "perl char class range" {
  let re = @re.Perl::compile_pat(sb("[0-9]+"))
  assert_eq(@re.execp(re, sb("abc123")), true)
  assert_eq(@re.execp(re, sb("abc")), false)
}

///|
test "perl escaped chars" {
  let re = @re.Perl::compile_pat(sb("a\\.b"))
  assert_eq(@re.execp(re, sb("a.b")), true)
  assert_eq(@re.execp(re, sb("axb")), false)
}

///|
test "perl digit class" {
  let re = @re.Perl::compile_pat(sb("\\d+"))
  assert_eq(@re.execp(re, sb("abc123")), true)
  assert_eq(@re.execp(re, sb("abc")), false)
}

///|
test "perl word boundary" {
  let re = @re.Perl::compile_pat(sb("\\bword\\b"))
  assert_eq(@re.execp(re, sb("a word here")), true)
  assert_eq(@re.execp(re, sb("a wordy here")), false)
}

///|
test "emacs basic" {
  let re = @re.Emacs::compile_pat(sb("hello"))
  assert_eq(@re.execp(re, sb("hello world")), true)
  assert_eq(@re.execp(re, sb("goodbye")), false)
}

///|
test "emacs groups" {
  let re = @re.Emacs::compile_pat(sb("\\(ab\\)*c"))
  assert_eq(@re.execp(re, sb("c")), true)
  assert_eq(@re.execp(re, sb("abc")), true)
  assert_eq(@re.execp(re, sb("ababc")), true)
}

///|
test "posix basic" {
  let re = @re.Posix::compile(sb("ab*c"))
  assert_eq(@re.execp(re, sb("ac")), true)
  assert_eq(@re.execp(re, sb("abbbbc")), true)
  assert_eq(@re.execp(re, sb("adc")), false)
}

///|
test "posix groups" {
  let re = @re.Posix::compile(sb("(ab)*c"))
  assert_eq(@re.execp(re, sb("c")), true)
  assert_eq(@re.execp(re, sb("abc")), true)
  assert_eq(@re.execp(re, sb("ababc")), true)
}

///|
test "glob basic" {
  let re = @re.Glob::compile(sb("*.txt"))
  assert_eq(@re.execp(re, sb("hello.txt")), true)
  assert_eq(@re.execp(re, sb("hello.py")), false)
}

///|
test "glob star match" {
  let re = @re.Glob::compile(sb("a*b"))
  assert_eq(@re.execp(re, sb("ab")), true)
  assert_eq(@re.execp(re, sb("axxxb")), true)
  assert_eq(@re.execp(re, sb("axxc")), false)
}

///|
test "glob question mark" {
  let re = @re.Glob::compile(sb("a?b"))
  assert_eq(@re.execp(re, sb("axb")), true)
  assert_eq(@re.execp(re, sb("ab")), false)
}

///|
test "pcre basic" {
  let re = @re.Pcre::regexp(sb("hello"))
  assert_eq(@re.Pcre::pmatch(re, sb("hello world")), true)
  assert_eq(@re.Pcre::pmatch(re, sb("goodbye")), false)
}

///|
test "pcre extract" {
  let re = @re.Pcre::regexp(sb("(a)(b)"))
  let groups = @re.Pcre::extract(re, sb("ab"))
  assert_eq(groups.length(), 3)
  assert_eq(bs(groups[0]), "ab")
  assert_eq(bs(groups[1]), "a")
  assert_eq(bs(groups[2]), "b")
}

///|
test "str basic match" {
  let re = @re.Str::regexp(sb("hello"))
  assert_eq(@re.Str::string_match(re, sb("hello world"), 0), true)
  assert_eq(@re.Str::string_match(re, sb("goodbye"), 0), false)
}

///|
test "str search" {
  let re = @re.Str::regexp(sb("world"))
  let pos = @re.Str::search_forward(re, sb("hello world"), 0)
  assert_eq(pos, 6)
}

///|
test "str split" {
  let re = @re.Str::regexp(sb(","))
  let parts = @re.Str::split(re, sb("a,b,c"))
  assert_eq(parts.length(), 3)
  assert_eq(bs(parts[0]), "a")
  assert_eq(bs(parts[1]), "b")
  assert_eq(bs(parts[2]), "c")
}

///|
test "perl non-greedy" {
  let re = @re.Perl::compile_pat(sb("a.*?b"))
  match @re.exec_opt(re, sb("axxbxxb")) {
    Some(g) => assert_eq(bs(@re.GroupT::get(g, 0).unwrap()), "axxb")
    None => assert_eq(true, false)
  }
}

///|
test "perl {n,m}" {
  let re = @re.Perl::compile_pat(sb("a{2,3}"))
  assert_eq(@re.execp(re, sb("a")), false)
  assert_eq(@re.execp(re, sb("aa")), true)
  assert_eq(@re.execp(re, sb("aaa")), true)
  assert_eq(@re.execp(re, sb("aaaa")), true)
}

///|
test "perl caseless" {
  let re = @re.Perl::compile_pat(sb("hello"), opts=[@re.PerlOpt::caseless()])
  assert_eq(@re.execp(re, sb("HELLO")), true)
  assert_eq(@re.execp(re, sb("Hello")), true)
}

///|
test "perl unclosed paren raise" {
  let r1 = try {
    let _ = @re.Perl::compile_pat(sb("("))
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
  let r2 = try {
    let _ = @re.Perl::compile_pat(sb("(abc"))
    false
  } catch {
    _ => true
  }
  assert_eq(r2, true)
}

///|
test "perl invalid escape raise" {
  let r1 = try {
    let _ = @re.Perl::compile_pat(sb("\\"))
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
  let r2 = try {
    let _ = @re.Perl::compile_pat(sb("\\8"))
    false
  } catch {
    _ => true
  }
  assert_eq(r2, true)
}

///|
test "perl unclosed bracket raise" {
  let r1 = try {
    let _ = @re.Perl::compile_pat(sb("["))
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
  let r2 = try {
    let _ = @re.Perl::compile_pat(sb("[abc"))
    false
  } catch {
    _ => true
  }
  assert_eq(r2, true)
}

///|
test "emacs unclosed paren raise" {
  let r1 = try {
    let _ = @re.Emacs::compile_pat(sb("\\("))
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
  let r2 = try {
    let _ = @re.Emacs::compile_pat(sb("\\(abc"))
    false
  } catch {
    _ => true
  }
  assert_eq(r2, true)
}

///|
test "emacs invalid escape raise" {
  let r1 = try {
    let _ = @re.Emacs::compile_pat(sb("\\"))
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
}

///|
test "pcre unclosed paren raise" {
  let r1 = try {
    let _ = @re.Pcre::regexp(sb("("))
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
  let r2 = try {
    let _ = @re.Pcre::regexp(sb("(abc"))
    false
  } catch {
    _ => true
  }
  assert_eq(r2, true)
}

///|
test "pcre invalid escape raise" {
  let r1 = try {
    let _ = @re.Pcre::regexp(sb("\\8"))
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
}

///|
test "perl anchored opt" {
  let re_a = @re.Perl::compile_pat(sb("hello"), opts=[@re.PerlOpt::anchored()])
  assert_eq(@re.execp(re_a, sb("hello world")), true)
  assert_eq(@re.execp(re_a, sb("say hello")), false)
  let re_no = @re.Perl::compile_pat(sb("hello"))
  assert_eq(@re.execp(re_no, sb("say hello")), true)
}

///|
test "perl dotall opt" {
  let re_d = @re.Perl::compile_pat(sb("a.b"), opts=[@re.PerlOpt::dotall()])
  assert_eq(@re.execp(re_d, sb("a\nb")), true)
  let re_no = @re.Perl::compile_pat(sb("a.b"))
  assert_eq(@re.execp(re_no, sb("a\nb")), false)
  assert_eq(@re.execp(re_no, sb("axb")), true)
}

///|
test "perl multiline opt" {
  let re_m = @re.Perl::compile_pat(sb("^abc$"), opts=[@re.PerlOpt::multiline()])
  assert_eq(@re.execp(re_m, sb("x\nabc\ny")), true)
  let re_no = @re.Perl::compile_pat(sb("^abc$"))
  assert_eq(@re.execp(re_no, sb("x\nabc\ny")), false)
  assert_eq(@re.execp(re_no, sb("abc")), true)
}

///|
test "perl dollar_endonly opt" {
  let re_de = @re.Perl::compile_pat(sb("abc$"), opts=[
    @re.PerlOpt::dollar_endonly(),
  ])
  assert_eq(@re.execp(re_de, sb("abc\n")), true)
  assert_eq(@re.execp(re_de, sb("abc")), true)
  let re_no = @re.Perl::compile_pat(sb("abc$"))
  assert_eq(@re.execp(re_no, sb("abc\n")), false)
}

///|
test "perl ungreedy opt" {
  let re_u = @re.Perl::compile_pat(sb("(a+)"), opts=[@re.PerlOpt::ungreedy()])
  match @re.exec_opt(re_u, sb("aaa")) {
    Some(g) => assert_eq(bs(@re.GroupT::get(g, 1).unwrap()), "a")
    None => assert_eq(true, false)
  }
  let re_no = @re.Perl::compile_pat(sb("(a+)"))
  match @re.exec_opt(re_no, sb("aaa")) {
    Some(g) => assert_eq(bs(@re.GroupT::get(g, 1).unwrap()), "aaa")
    None => assert_eq(true, false)
  }
}

///|
test "pcre caseless flag" {
  let re_ci = @re.Pcre::regexp(sb("hello"), flags=[@re.PcreFlag::caseless()])
  assert_eq(@re.Pcre::pmatch(re_ci, sb("HELLO")), true)
  let re_no = @re.Pcre::regexp(sb("hello"))
  assert_eq(@re.Pcre::pmatch(re_no, sb("HELLO")), false)
}

///|
test "pcre multiline flag" {
  let re_ml = @re.Pcre::regexp(sb("^abc$"), flags=[@re.PcreFlag::multiline_p()])
  assert_eq(@re.Pcre::pmatch(re_ml, sb("x\nabc\ny")), true)
  let re_no = @re.Pcre::regexp(sb("^abc$"))
  assert_eq(@re.Pcre::pmatch(re_no, sb("x\nabc\ny")), false)
  assert_eq(@re.Pcre::pmatch(re_no, sb("abc")), true)
}

///|
test "pcre anchored flag" {
  let re_a = @re.Pcre::regexp(sb("hello"), flags=[@re.PcreFlag::anchored_p()])
  assert_eq(@re.Pcre::pmatch(re_a, sb("hello world")), true)
  assert_eq(@re.Pcre::pmatch(re_a, sb("say hello")), false)
  let re_no = @re.Pcre::regexp(sb("hello"))
  assert_eq(@re.Pcre::pmatch(re_no, sb("say hello")), true)
}

///|
test "pcre dotall flag" {
  let re_d = @re.Pcre::regexp(sb("a.b"), flags=[@re.PcreFlag::dotall_p()])
  assert_eq(@re.Pcre::pmatch(re_d, sb("a\nb")), true)
  let re_no = @re.Pcre::regexp(sb("a.b"))
  assert_eq(@re.Pcre::pmatch(re_no, sb("a\nb")), false)
  assert_eq(@re.Pcre::pmatch(re_no, sb("axb")), true)
}

///|
test "str global_replace replaces all matches" {
  let re = @re.Str::regexp(sb("o"))
  let repl = sb("X")
  assert_eq(
    bs(@re.Str::global_replace(re, repl, sb("foo bar boo"))),
    "fXX bar bXX",
  )
  assert_eq(bs(@re.Str::global_replace(re, repl, sb("xyz"))), "xyz")
}

///|
test "str replace_first replaces first match" {
  let re = @re.Str::regexp(sb("o"))
  let repl = sb("X")
  assert_eq(bs(@re.Str::replace_first(re, repl, sb("foo"))), "fXo")
  assert_eq(bs(@re.Str::replace_first(re, repl, sb("xyz"))), "xyz")
}

///|
test "str full_split text and delim" {
  let re = @re.Str::regexp(sb(","))
  let result = @re.Str::full_split(re, sb("a,b,c"))
  assert_eq(result.length(), 5)
  match result[0] {
    StrText(t) => assert_eq(bs(t), "a")
    StrDelim(_) => assert_eq(true, false)
  }
  match result[1] {
    StrText(_) => assert_eq(true, false)
    StrDelim(d) => assert_eq(bs(d), ",")
  }
  match result[2] {
    StrText(t) => assert_eq(bs(t), "b")
    StrDelim(_) => assert_eq(true, false)
  }
  match result[3] {
    StrText(_) => assert_eq(true, false)
    StrDelim(d) => assert_eq(bs(d), ",")
  }
  match result[4] {
    StrText(t) => assert_eq(bs(t), "c")
    StrDelim(_) => assert_eq(true, false)
  }
}

///|
test "str bounded_split limit" {
  let re = @re.Str::regexp(sb(","))
  let text = sb("a,b,c,d")
  let r0 = @re.Str::bounded_split(re, text, 0)
  assert_eq(r0.length(), 4)
  assert_eq(bs(r0[0]), "a")
  assert_eq(bs(r0[1]), "b")
  assert_eq(bs(r0[2]), "c")
  assert_eq(bs(r0[3]), "d")
  let r2 = @re.Str::bounded_split(re, text, 2)
  assert_eq(r2.length(), 2)
  assert_eq(bs(r2[0]), "a")
  assert_eq(bs(r2[1]), "b,c,d")
}

///|
test "str quote special chars" {
  assert_eq(bs(@re.Str::quote(sb("a.b"))), "a\\.b")
  assert_eq(bs(@re.Str::quote(sb("[*]"))), "\\[\\*\\]")
  assert_eq(bs(@re.Str::quote(sb("normal"))), "normal")
  assert_eq(bs(@re.Str::quote(sb("?+$^"))), "\\?\\+\\$\\^")
}

///|
test "str regexp_case_fold case insensitive" {
  let re = @re.Str::regexp_case_fold(sb("hello"))
  assert_eq(@re.Str::string_match(re, sb("HELLO world"), 0), true)
  let re2 = @re.Str::regexp(sb("hello"))
  assert_eq(@re.Str::string_match(re2, sb("HELLO world"), 0), false)
}

///|
test "str regexp_string_case_fold" {
  let re = @re.Str::regexp_string_case_fold(sb("a.b"))
  assert_eq(@re.Str::string_match(re, sb("A.B"), 0), true)
  assert_eq(@re.Str::string_match(re, sb("axb"), 0), false)
}

///|
test "str search_backward" {
  let re = @re.Str::regexp(sb("ab"))
  assert_eq(@re.Str::search_backward(re, sb("xabxab"), 5), 4)
  assert_eq(@re.Str::search_backward(re, sb("xabxab"), 3), 1)
  assert_eq(@re.Str::search_backward(re, sb("xabxab"), 2), 1)
}

///|
test "str string_partial_match" {
  let re = @re.Str::regexp(sb("abc"))
  assert_eq(@re.Str::string_partial_match(re, sb("ab"), 0), true)
  assert_eq(@re.Str::string_partial_match(re, sb("xyz"), 0), false)
  assert_eq(@re.Str::string_partial_match(re, sb("abc"), 0), true)
}

///|
test "str replace_matched" {
  let re = @re.Str::regexp(sb("\\(a\\)\\(b\\)"))
  ignore(@re.Str::search_forward(re, sb("ab"), 0))
  assert_eq(bs(@re.Str::replace_matched(sb("\\0\\1\\2"), sb("ab"))), "abab")
}

///|
test "str global_substitute" {
  let re = @re.Str::regexp(sb("o"))
  let result = @re.Str::global_substitute(re, fn(_s) { sb("X") }, sb("foo"))
  assert_eq(bs(result), "fXX")
}

///|
test "str substitute_first" {
  let re = @re.Str::regexp(sb("o"))
  let result = @re.Str::substitute_first(re, fn(_s) { sb("X") }, sb("foo"))
  assert_eq(bs(result), "fXo")
}

///|
test "str split_delim" {
  let re = @re.Str::regexp(sb(","))
  let parts = @re.Str::split_delim(re, sb(",a,b,"))
  assert_eq(parts.length(), 4)
  assert_eq(bs(parts[0]), "")
  assert_eq(bs(parts[1]), "a")
  assert_eq(bs(parts[2]), "b")
  assert_eq(bs(parts[3]), "")
}

///|
test "str bounded_split_delim" {
  let re = @re.Str::regexp(sb(","))
  let parts = @re.Str::bounded_split_delim(re, sb("a,b,c,d"), 2)
  assert_eq(parts.length(), 2)
  assert_eq(bs(parts[0]), "a")
  assert_eq(bs(parts[1]), "b,c,d")
}

///|
test "str bounded_full_split" {
  let re = @re.Str::regexp(sb(","))
  let parts = @re.Str::bounded_full_split(re, sb("a,b,c"), 2)
  assert_eq(parts.length(), 3)
  match parts[0] {
    StrText(t) => assert_eq(bs(t), "a")
    StrDelim(_) => assert_eq(true, false)
  }
  match parts[1] {
    StrDelim(d) => assert_eq(bs(d), ",")
    StrText(_) => assert_eq(true, false)
  }
  match parts[2] {
    StrText(t) => assert_eq(bs(t), "b,c")
    StrDelim(_) => assert_eq(true, false)
  }
}

///|
test "str first_chars" {
  assert_eq(bs(@re.Str::first_chars(sb("hello"), 2)), "he")
  assert_eq(bs(@re.Str::first_chars(sb("hello"), 0)), "")
}

///|
test "str last_chars" {
  assert_eq(bs(@re.Str::last_chars(sb("hello"), 2)), "lo")
  assert_eq(bs(@re.Str::last_chars(sb("hello"), 0)), "")
}
