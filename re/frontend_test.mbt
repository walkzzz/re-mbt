// Tests for frontends: Perl, Emacs, Posix, Glob, Pcre, Str

///|
test "perl basic match" {
  let re = Perl::compile_pat(sb("hello"))
  assert_eq(execp(re, sb("hello world")), true)
  assert_eq(execp(re, sb("goodbye")), false)
}

///|
test "perl alternation" {
  let re = Perl::compile_pat(sb("cat|dog|bird"))
  assert_eq(execp(re, sb("I have a cat")), true)
  assert_eq(execp(re, sb("I have a dog")), true)
  assert_eq(execp(re, sb("I have a bird")), true)
  assert_eq(execp(re, sb("I have a fish")), false)
}

///|
test "perl groups" {
  let re = Perl::compile_pat(sb("(a)(b)(c)"))
  match exec_opt(re, sb("abc")) {
    Some(g) => {
      assert_eq(bs(GroupT::get(g, 0).unwrap()), "abc")
      assert_eq(bs(GroupT::get(g, 1).unwrap()), "a")
      assert_eq(bs(GroupT::get(g, 2).unwrap()), "b")
      assert_eq(bs(GroupT::get(g, 3).unwrap()), "c")
    }
    None => assert_eq(true, false)
  }
}

///|
test "perl star" {
  let re = Perl::compile_pat(sb("ab*c"))
  assert_eq(execp(re, sb("ac")), true)
  assert_eq(execp(re, sb("abc")), true)
  assert_eq(execp(re, sb("abbbbc")), true)
  assert_eq(execp(re, sb("adc")), false)
}

///|
test "perl plus" {
  let re = Perl::compile_pat(sb("ab+c"))
  assert_eq(execp(re, sb("ac")), false)
  assert_eq(execp(re, sb("abc")), true)
  assert_eq(execp(re, sb("abbbbc")), true)
}

///|
test "perl char class" {
  let re = Perl::compile_pat(sb("[abc]"))
  assert_eq(execp(re, sb("a")), true)
  assert_eq(execp(re, sb("b")), true)
  assert_eq(execp(re, sb("c")), true)
  assert_eq(execp(re, sb("d")), false)
}

///|
test "perl char class range" {
  let re = Perl::compile_pat(sb("[0-9]+"))
  assert_eq(execp(re, sb("abc123")), true)
  assert_eq(execp(re, sb("abc")), false)
}

///|
test "perl escaped chars" {
  let re = Perl::compile_pat(sb("a\\.b"))
  assert_eq(execp(re, sb("a.b")), true)
  assert_eq(execp(re, sb("axb")), false)
}

///|
test "perl digit class" {
  let re = Perl::compile_pat(sb("\\d+"))
  assert_eq(execp(re, sb("abc123")), true)
  assert_eq(execp(re, sb("abc")), false)
}

///|
test "perl word boundary" {
  let re = Perl::compile_pat(sb("\\bword\\b"))
  assert_eq(execp(re, sb("a word here")), true)
  assert_eq(execp(re, sb("a wordy here")), false)
}

///|
test "emacs basic" {
  let re = Emacs::compile_pat(sb("hello"))
  assert_eq(execp(re, sb("hello world")), true)
  assert_eq(execp(re, sb("goodbye")), false)
}

///|
test "emacs groups" {
  let re = Emacs::compile_pat(sb("\\(ab\\)*c"))
  assert_eq(execp(re, sb("c")), true)
  assert_eq(execp(re, sb("abc")), true)
  assert_eq(execp(re, sb("ababc")), true)
}

///|
test "posix basic" {
  let re = Posix::compile(sb("ab*c"))
  assert_eq(execp(re, sb("ac")), true)
  assert_eq(execp(re, sb("abbbbc")), true)
  assert_eq(execp(re, sb("adc")), false)
}

///|
test "posix groups" {
  let re = Posix::compile(sb("(ab)*c"))
  assert_eq(execp(re, sb("c")), true)
  assert_eq(execp(re, sb("abc")), true)
  assert_eq(execp(re, sb("ababc")), true)
}

///|
test "glob basic" {
  let re = Glob::compile(sb("*.txt"))
  assert_eq(execp(re, sb("hello.txt")), true)
  assert_eq(execp(re, sb("hello.py")), false)
}

///|
test "glob star match" {
  let re = Glob::compile(sb("a*b"))
  assert_eq(execp(re, sb("ab")), true)
  assert_eq(execp(re, sb("axxxb")), true)
  assert_eq(execp(re, sb("axxc")), false)
}

///|
test "glob question mark" {
  let re = Glob::compile(sb("a?b"))
  assert_eq(execp(re, sb("axb")), true)
  assert_eq(execp(re, sb("ab")), false)
}

///|
test "pcre basic" {
  let re = Pcre::regexp(sb("hello"))
  assert_eq(Pcre::pmatch(re, sb("hello world")), true)
  assert_eq(Pcre::pmatch(re, sb("goodbye")), false)
}

///|
test "pcre extract" {
  let re = Pcre::regexp(sb("(a)(b)"))
  let groups = Pcre::extract(re, sb("ab"))
  assert_eq(groups.length(), 3)
  assert_eq(bs(groups[0]), "ab")
  assert_eq(bs(groups[1]), "a")
  assert_eq(bs(groups[2]), "b")
}

///|
test "str basic match" {
  let re = Str::regexp(sb("hello"))
  assert_eq(Str::string_match(re, sb("hello world"), 0), true)
  assert_eq(Str::string_match(re, sb("goodbye"), 0), false)
}

///|
test "str search" {
  let re = Str::regexp(sb("world"))
  let pos = Str::search_forward(re, sb("hello world"), 0)
  assert_eq(pos, 6)
}

///|
test "str split" {
  let re = Str::regexp(sb(","))
  let parts = Str::split(re, sb("a,b,c"))
  assert_eq(parts.length(), 3)
  assert_eq(bs(parts[0]), "a")
  assert_eq(bs(parts[1]), "b")
  assert_eq(bs(parts[2]), "c")
}

///|
test "perl non-greedy" {
  let re = Perl::compile_pat(sb("a.*?b"))
  match exec_opt(re, sb("axxbxxb")) {
    Some(g) => assert_eq(bs(GroupT::get(g, 0).unwrap()), "axxb")
    None => assert_eq(true, false)
  }
}

///|
test "perl {n,m}" {
  let re = Perl::compile_pat(sb("a{2,3}"))
  assert_eq(execp(re, sb("a")), false)
  assert_eq(execp(re, sb("aa")), true)
  assert_eq(execp(re, sb("aaa")), true)
  assert_eq(execp(re, sb("aaaa")), true)
}

///|
test "perl caseless" {
  let re = Perl::compile_pat(sb("hello"), opts=[PerlOpt::caseless()])
  assert_eq(execp(re, sb("HELLO")), true)
  assert_eq(execp(re, sb("Hello")), true)
}

///|
test "perl unclosed paren raise" {
  let r1 = try {
    let _ = Perl::compile_pat(sb("("))
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
  let r2 = try {
    let _ = Perl::compile_pat(sb("(abc"))
    false
  } catch {
    _ => true
  }
  assert_eq(r2, true)
}

///|
test "perl invalid escape raise" {
  let r1 = try {
    let _ = Perl::compile_pat(sb("\\"))
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
  let r2 = try {
    let _ = Perl::compile_pat(sb("\\8"))
    false
  } catch {
    _ => true
  }
  assert_eq(r2, true)
}

///|
test "perl unclosed bracket raise" {
  let r1 = try {
    let _ = Perl::compile_pat(sb("["))
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
  let r2 = try {
    let _ = Perl::compile_pat(sb("[abc"))
    false
  } catch {
    _ => true
  }
  assert_eq(r2, true)
}

///|
test "emacs unclosed paren raise" {
  let r1 = try {
    let _ = Emacs::compile_pat(sb("\\("))
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
  let r2 = try {
    let _ = Emacs::compile_pat(sb("\\(abc"))
    false
  } catch {
    _ => true
  }
  assert_eq(r2, true)
}

///|
test "emacs invalid escape raise" {
  let r1 = try {
    let _ = Emacs::compile_pat(sb("\\"))
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
}

///|
test "pcre unclosed paren raise" {
  let r1 = try {
    let _ = Pcre::regexp(sb("("))
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
  let r2 = try {
    let _ = Pcre::regexp(sb("(abc"))
    false
  } catch {
    _ => true
  }
  assert_eq(r2, true)
}

///|
test "pcre invalid escape raise" {
  let r1 = try {
    let _ = Pcre::regexp(sb("\\8"))
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
}
