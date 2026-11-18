// crap_test.mbt — CRAP coverage tests for re_frontend
// Covers perl_atom, emacs_atom, posix_atom, glob, pcre, str, posix_class, cache

// === Perl atom escape coverage (perl_atom CRAP ~177) ===

///|
test "perl atom \\W \\S \\D classes" {
  let re_w = @re_frontend.Perl::compile_pat(@base.sb("\\W"))
  assert_eq(@compile.execp(re_w, @base.sb(" ")), true)
  assert_eq(@compile.execp(re_w, @base.sb("a")), false)
  let re_s = @re_frontend.Perl::compile_pat(@base.sb("\\S"))
  assert_eq(@compile.execp(re_s, @base.sb("a")), true)
  assert_eq(@compile.execp(re_s, @base.sb(" ")), false)
  let re_d = @re_frontend.Perl::compile_pat(@base.sb("\\D"))
  assert_eq(@compile.execp(re_d, @base.sb("a")), true)
  assert_eq(@compile.execp(re_d, @base.sb("1")), false)
}

///|
test "perl atom \\B \\A \\Z \\z \\G anchors" {
  let _re_b = @re_frontend.Perl::compile_pat(@base.sb("\\B"))
  let re_a = @re_frontend.Perl::compile_pat(@base.sb("\\Aabc"))
  assert_eq(@compile.execp(re_a, @base.sb("abc")), true)
  let _re_z = @re_frontend.Perl::compile_pat(@base.sb("abc\\Z"))
  let re_eos = @re_frontend.Perl::compile_pat(@base.sb("abc\\z"))
  assert_eq(@compile.execp(re_eos, @base.sb("abc")), true)
  let _re_g = @re_frontend.Perl::compile_pat(@base.sb("\\Gabc"))
}

///|
test "perl atom \\e \\f \\n \\r \\t escapes" {
  let _re_esc = @re_frontend.Perl::compile_pat(@base.sb("\\e"))
  let _re_ff = @re_frontend.Perl::compile_pat(@base.sb("\\f"))
  let re_nl = @re_frontend.Perl::compile_pat(@base.sb("\\n"))
  assert_eq(@compile.execp(re_nl, @base.sb("\n")), true)
  let _re_cr = @re_frontend.Perl::compile_pat(@base.sb("\\r"))
  let _re_tab = @re_frontend.Perl::compile_pat(@base.sb("\\t"))
}

///|
test "perl atom \\Q...\\E quote" {
  let re_q = @re_frontend.Perl::compile_pat(@base.sb("\\Qa.b\\E"))
  assert_eq(@compile.execp(re_q, @base.sb("a.b")), true)
  assert_eq(@compile.execp(re_q, @base.sb("axb")), false)
}

///|
test "perl atom \\x hex escapes" {
  let re_hex1 = @re_frontend.Perl::compile_pat(@base.sb("\\x{41}"))
  assert_eq(@compile.execp(re_hex1, @base.sb("A")), true)
  let re_hex2 = @re_frontend.Perl::compile_pat(@base.sb("\\x41"))
  assert_eq(@compile.execp(re_hex2, @base.sb("A")), true)
  let re_hex3 = @re_frontend.Perl::compile_pat(@base.sb("\\x{4F}"))
  assert_eq(@compile.execp(re_hex3, @base.sb("O")), true)
}

///|
test "perl atom \\o octal escapes" {
  let re_oct = @re_frontend.Perl::compile_pat(@base.sb("\\o{101}"))
  assert_eq(@compile.execp(re_oct, @base.sb("A")), true)
}

///|
test "perl atom octal escape \\NNN" {
  let re_oct_esc = @re_frontend.Perl::compile_pat(@base.sb("\\101"))
  assert_eq(@compile.execp(re_oct_esc, @base.sb("A")), true)
}

///|
test "perl atom (?:...) (?#...) (?<name>...)" {
  let re_nc = @re_frontend.Perl::compile_pat(@base.sb("(?:abc)"))
  assert_eq(@compile.execp(re_nc, @base.sb("abc")), true)
  let re_comment = @re_frontend.Perl::compile_pat(@base.sb("(?#comment)abc"))
  assert_eq(@compile.execp(re_comment, @base.sb("abc")), true)
  let re_named = @re_frontend.Perl::compile_pat(@base.sb("(?<foo>abc)"))
  assert_eq(@compile.execp(re_named, @base.sb("abc")), true)
}

///|
test "perl atom error paths" {
  let r1 = try {
    let _ = @re_frontend.Perl::compile_pat(@base.sb("\\E"))
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
  let r2 = try {
    let _ = @re_frontend.Perl::compile_pat(@base.sb("\\q"))
    false
  } catch {
    _ => true
  }
  assert_eq(r2, true)
  let r3 = try {
    let _ = @re_frontend.Perl::compile_pat(@base.sb("*"))
    false
  } catch {
    _ => true
  }
  assert_eq(r3, true)
  let r4 = try {
    let _ = @re_frontend.Perl::compile_pat(@base.sb("a{2,1}"))
    false
  } catch {
    _ => true
  }
  assert_eq(r4, true)
  let r5 = try {
    let _ = @re_frontend.Perl::compile_pat(@base.sb("a{1,2"))
    false
  } catch {
    _ => true
  }
  assert_eq(r5, true)
}

///|
test "perl piece { without integer" {
  let re = @re_frontend.Perl::compile_pat(@base.sb("a{"))
  assert_eq(@compile.execp(re, @base.sb("a{")), true)
}

///|
test "perl bracket PerlSet and dash at end" {
  let re = @re_frontend.Perl::compile_pat(@base.sb("[a-]"))
  assert_eq(@compile.execp(re, @base.sb("a")), true)
  assert_eq(@compile.execp(re, @base.sb("-")), true)
  let re2 = @re_frontend.Perl::compile_pat(@base.sb("[\\w]"))
  assert_eq(@compile.execp(re2, @base.sb("a")), true)
  let re3 = @re_frontend.Perl::compile_pat(@base.sb("[a-\\w]"))
  assert_eq(@compile.execp(re3, @base.sb("b")), true)
}

///|
test "perl char elem posix and collating" {
  let re = @re_frontend.Perl::compile_pat(@base.sb("[[:alpha:]]"))
  assert_eq(@compile.execp(re, @base.sb("a")), true)
  assert_eq(@compile.execp(re, @base.sb("1")), false)
}

///|
test "perl char elem backslash in bracket" {
  let re = @re_frontend.Perl::compile_pat(@base.sb("[\\b]"))
  assert_eq(@compile.execp(re, @base.sb("\u{0008}")), true)
  let re2 = @re_frontend.Perl::compile_pat(@base.sb("[\\n\\r\\t]"))
  assert_eq(@compile.execp(re2, @base.sb("\n")), true)
  let re3 = @re_frontend.Perl::compile_pat(@base.sb("[\\w\\s\\d]"))
  assert_eq(@compile.execp(re3, @base.sb("a")), true)
  let re4 = @re_frontend.Perl::compile_pat(@base.sb("[\\W\\S\\D]"))
  assert_eq(@compile.execp(re4, @base.sb(" ")), true)
}

///|
test "perl char elem error in bracket" {
  let r1 = try {
    let _ = @re_frontend.Perl::compile_pat(@base.sb("[\\q]"))
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
  let r2 = try {
    let _ = @re_frontend.Perl::compile_pat(@base.sb("[\\1]"))
    false
  } catch {
    _ => true
  }
  assert_eq(r2, true)
}

///|
test "perl comment unclosed" {
  let r1 = try {
    let _ = @re_frontend.Perl::compile_pat(@base.sb("(?#abc"))
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
}

///|
test "perl re not eos" {
  let r1 = try {
    let _ = @re_frontend.Perl::compile_pat(@base.sb("abc)"))
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
}

// === Emacs atom coverage (emacs_atom CRAP ~85) ===

///|
test "emacs atom dot bol eol" {
  let re_dot = @re_frontend.Emacs::compile_pat(@base.sb("."))
  assert_eq(@compile.execp(re_dot, @base.sb("a")), true)
  let re_bol = @re_frontend.Emacs::compile_pat(@base.sb("^abc"))
  assert_eq(@compile.execp(re_bol, @base.sb("abc")), true)
  let re_eol = @re_frontend.Emacs::compile_pat(@base.sb("abc$"))
  assert_eq(@compile.execp(re_eol, @base.sb("abc")), true)
}

///|
test "emacs atom complement bracket" {
  let re = @re_frontend.Emacs::compile_pat(@base.sb("[^abc]"))
  assert_eq(@compile.execp(re, @base.sb("d")), true)
  assert_eq(@compile.execp(re, @base.sb("a")), false)
}

///|
test "emacs atom backquote equals b B lt gt" {
  let _re_bq = @re_frontend.Emacs::compile_pat(@base.sb("\\`abc"))
  let _re_eq = @re_frontend.Emacs::compile_pat(@base.sb("\\="))
  let _re_b = @re_frontend.Emacs::compile_pat(@base.sb("\\b"))
  let _re_B = @re_frontend.Emacs::compile_pat(@base.sb("\\B"))
  let _re_lt = @re_frontend.Emacs::compile_pat(@base.sb("\\<"))
  let _re_gt = @re_frontend.Emacs::compile_pat(@base.sb("\\>"))
  let _re_sq = @re_frontend.Emacs::compile_pat(@base.sb("\\'abc"))
}

///|
test "emacs atom w W" {
  let re_w = @re_frontend.Emacs::compile_pat(@base.sb("\\w"))
  assert_eq(@compile.execp(re_w, @base.sb("a")), true)
  let re_W = @re_frontend.Emacs::compile_pat(@base.sb("\\W"))
  assert_eq(@compile.execp(re_W, @base.sb(" ")), true)
}

///|
test "emacs piece opt" {
  let re = @re_frontend.Emacs::compile_pat(@base.sb("ab?c"))
  assert_eq(@compile.execp(re, @base.sb("ac")), true)
  assert_eq(@compile.execp(re, @base.sb("abc")), true)
}

///|
test "emacs bracket dash at end" {
  let re = @re_frontend.Emacs::compile_pat(@base.sb("[a-]"))
  assert_eq(@compile.execp(re, @base.sb("a")), true)
  assert_eq(@compile.execp(re, @base.sb("-")), true)
}

///|
test "emacs atom error paths" {
  let r1 = try {
    let _ = @re_frontend.Emacs::compile_pat(@base.sb("\\1"))
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
  let r2 = try {
    let _ = @re_frontend.Emacs::compile_pat(@base.sb("*"))
    false
  } catch {
    _ => true
  }
  assert_eq(r2, true)
  let r3 = try {
    let _ = @re_frontend.Emacs::compile_pat(@base.sb(""))
    false
  } catch {
    _ => true
  }
  assert_eq(r3, true)
}

///|
test "emacs re_no_emacs non emacs char" {
  let re = @re_frontend.Emacs::re_no_emacs(@base.sb("\\q"), case=true)
  assert_eq(@compile.execp(@compile.compile(re), @base.sb("q")), true)
}

///|
test "emacs re_no_emacs error" {
  let r1 = try {
    let _ = @re_frontend.Emacs::re_no_emacs(@base.sb("\\1"), case=true)
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
  let r2 = try {
    let _ = @re_frontend.Emacs::re_no_emacs(@base.sb("abc)"), case=true)
    false
  } catch {
    _ => true
  }
  assert_eq(r2, true)
}

///|
test "emacs re case false" {
  let re = @re_frontend.Emacs::compile_pat(@base.sb("hello"), case=false)
  assert_eq(@compile.execp(re, @base.sb("HELLO")), true)
}

///|
test "emacs re_no_emacs case false" {
  let re = @re_frontend.Emacs::re_no_emacs(@base.sb("hello"), case=false)
  assert_eq(@compile.execp(@compile.compile(re), @base.sb("HELLO")), true)
}

///|
test "emacs regexp_ pipe branch" {
  let re = @re_frontend.Emacs::compile_pat(@base.sb("a\\|b"))
  assert_eq(@compile.execp(re, @base.sb("a")), true)
  assert_eq(@compile.execp(re, @base.sb("b")), true)
}

// === Posix atom coverage (posix_atom CRAP ~48) ===

///|
test "posix atom dot basic" {
  let re_no = @re_frontend.Posix::compile(@base.sb("."))
  assert_eq(@compile.execp(re_no, @base.sb("a")), true)
}

///|
test "posix atom anchors basic" {
  let re_bol_no = @re_frontend.Posix::compile(@base.sb("^abc"))
  assert_eq(@compile.execp(re_bol_no, @base.sb("abc")), true)
  let re_eol_no = @re_frontend.Posix::compile(@base.sb("abc$"))
  assert_eq(@compile.execp(re_eol_no, @base.sb("abc")), true)
}

///|
test "posix atom complement bracket" {
  let re = @re_frontend.Posix::compile(@base.sb("[^abc]"))
  assert_eq(@compile.execp(re, @base.sb("d")), true)
  assert_eq(@compile.execp(re, @base.sb("a")), false)
}

///|
test "posix atom backslash special and error" {
  let re = @re_frontend.Posix::compile(@base.sb("\\."))
  assert_eq(@compile.execp(re, @base.sb(".")), true)
  let r1 = try {
    let _ = @re_frontend.Posix::compile(@base.sb("\\q"))
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
  let r2 = try {
    let _ = @re_frontend.Posix::compile(@base.sb("\\"))
    false
  } catch {
    _ => true
  }
  assert_eq(r2, true)
}

///|
test "posix atom error paths" {
  let r1 = try {
    let _ = @re_frontend.Posix::compile(@base.sb(""))
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
  let r2 = try {
    let _ = @re_frontend.Posix::compile(@base.sb("*"))
    false
  } catch {
    _ => true
  }
  assert_eq(r2, true)
  let r3 = try {
    let _ = @re_frontend.Posix::compile(@base.sb("(abc"))
    false
  } catch {
    _ => true
  }
  assert_eq(r3, true)
}

///|
test "posix piece opt and repn" {
  let re_opt = @re_frontend.Posix::compile(@base.sb("ab?c"))
  assert_eq(@compile.execp(re_opt, @base.sb("ac")), true)
  assert_eq(@compile.execp(re_opt, @base.sb("abc")), true)
  let re_n = @re_frontend.Posix::compile(@base.sb("a{3}"))
  assert_eq(@compile.execp(re_n, @base.sb("aaa")), true)
  let re_nm = @re_frontend.Posix::compile(@base.sb("a{2,3}"))
  assert_eq(@compile.execp(re_nm, @base.sb("aa")), true)
  let re_n_open = @re_frontend.Posix::compile(@base.sb("a{2,}"))
  assert_eq(@compile.execp(re_n_open, @base.sb("aa")), true)
}

///|
test "posix piece brace without integer" {
  let re = @re_frontend.Posix::compile(@base.sb("a{"))
  assert_eq(@compile.execp(re, @base.sb("a{")), true)
}

///|
test "posix piece error paths" {
  let r1 = try {
    let _ = @re_frontend.Posix::compile(@base.sb("a{2,1}"))
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
  let r2 = try {
    let _ = @re_frontend.Posix::compile(@base.sb("a{1,2"))
    false
  } catch {
    _ => true
  }
  assert_eq(r2, true)
}

///|
test "posix bracket posix class and collating" {
  let re = @re_frontend.Posix::compile(@base.sb("[[:alpha:]]"))
  assert_eq(@compile.execp(re, @base.sb("a")), true)
  assert_eq(@compile.execp(re, @base.sb("1")), false)
  let re2 = @re_frontend.Posix::compile(@base.sb("[[.a.]]"))
  assert_eq(@compile.execp(re2, @base.sb("a")), true)
}

///|
test "posix bracket dash and set after dash" {
  let re = @re_frontend.Posix::compile(@base.sb("[a-]"))
  assert_eq(@compile.execp(re, @base.sb("a")), true)
  assert_eq(@compile.execp(re, @base.sb("-")), true)
  let re2 = @re_frontend.Posix::compile(@base.sb("[a-[:alpha:]]"))
  assert_eq(@compile.execp(re2, @base.sb("b")), true)
}

///|
test "posix compile_pat" {
  let re = @re_frontend.Posix::compile_pat(@base.sb("abc"))
  assert_eq(@compile.execp(re, @base.sb("abc")), true)
}

///|
test "posix re not eos" {
  let r1 = try {
    let _ = @re_frontend.Posix::compile(@base.sb("abc)"))
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
}

// === Glob coverage (glob CRAP ~22) ===

///|
test "glob char class and range" {
  let re = @re_frontend.Glob::compile(@base.sb("[abc]"))
  assert_eq(@compile.execp(re, @base.sb("a")), true)
  assert_eq(@compile.execp(re, @base.sb("d")), false)
  let re2 = @re_frontend.Glob::compile(@base.sb("[a-z]"))
  assert_eq(@compile.execp(re2, @base.sb("m")), true)
  assert_eq(@compile.execp(re2, @base.sb("9")), false)
}

///|
test "glob complement class" {
  let re = @re_frontend.Glob::compile(@base.sb("[!abc]"))
  assert_eq(@compile.execp(re, @base.sb("d")), true)
  assert_eq(@compile.execp(re, @base.sb("a")), false)
  let re2 = @re_frontend.Glob::compile(@base.sb("[^abc]"))
  assert_eq(@compile.execp(re2, @base.sb("d")), true)
}

///|
test "glob double star and slash" {
  let re = @re_frontend.Glob::compile(@base.sb("**"))
  assert_eq(@compile.execp(re, @base.sb("abc")), true)
  let re2 = @re_frontend.Glob::compile(@base.sb("a/**/b"))
  assert_eq(@compile.execp(re2, @base.sb("a/x/y/b")), true)
}

///|
test "glob backslashes and anchored" {
  let re_bs = @re_frontend.Glob::compile(
    @base.sb("a/b"),
    match_backslashes=true,
  )
  assert_eq(@compile.execp(re_bs, @base.sb("a/b")), true)
  let re_a = @re_frontend.Glob::compile(@base.sb("abc"), anchored=true)
  assert_eq(@compile.execp(re_a, @base.sb("abc")), true)
  assert_eq(@compile.execp(re_a, @base.sb("xabc")), false)
}

///|
test "glob period and pathname options" {
  let re_p = @re_frontend.Glob::compile(@base.sb("*.txt"), period=false)
  assert_eq(@compile.execp(re_p, @base.sb(".txt")), true)
  let re_np = @re_frontend.Glob::compile(@base.sb("abc"), pathname=false)
  assert_eq(@compile.execp(re_np, @base.sb("abc")), true)
}

///|
test "glob double asterisk disabled" {
  let re = @re_frontend.Glob::compile(@base.sb("**"), double_asterisk=false)
  assert_eq(@compile.execp(re, @base.sb("abc")), true)
}

///|
test "glob escape in class" {
  let re = @re_frontend.Glob::compile(@base.sb("[\\a]"))
  assert_eq(@compile.execp(re, @base.sb("a")), true)
}

///|
test "glob error paths" {
  let r1 = try {
    let _ = @re_frontend.Glob::compile(@base.sb("["))
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
  let r2 = try {
    let _ = @re_frontend.Glob::compile(@base.sb("[\\"))
    false
  } catch {
    _ => true
  }
  assert_eq(r2, true)
}

// === Pcre coverage (pcre CRAP ~14) ===

///|
test "pcre names and named substring" {
  let re = @re_frontend.Pcre::regexp(@base.sb("(?<foo>abc)"))
  let names = @re_frontend.Pcre::names(re)
  assert_eq(names.length() > 0, true)
  match @compile.exec_opt(re, @base.sb("abc")) {
    Some(g) => {
      let opt = @re_frontend.Pcre::get_named_substring_opt(re, "foo", g)
      match opt {
        Some(b) => assert_eq(@base.bs(b), "abc")
        None => assert_eq(true, false)
      }
      let ofs = @re_frontend.Pcre::get_substring_ofs(g, 0)
      ignore(ofs)
      let s = @re_frontend.Pcre::get_substring(g, 0)
      assert_eq(@base.bs(s), "abc")
    }
    None => assert_eq(true, false)
  }
}

///|
test "pcre split" {
  let re = @re_frontend.Pcre::regexp(@base.sb(","))
  let parts = @re_frontend.Pcre::split(re, @base.sb("a,b,c"))
  assert_eq(parts.length(), 3)
  assert_eq(@base.bs(parts[0]), "a")
  assert_eq(@base.bs(parts[1]), "b")
  assert_eq(@base.bs(parts[2]), "c")
}

///|
test "pcre full_split" {
  let re = @re_frontend.Pcre::regexp(@base.sb("(a)(b)"))
  let parts = @re_frontend.Pcre::full_split(re, @base.sb("xab"))
  assert_eq(parts.length() >= 2, true)
}

///|
test "pcre full_split empty" {
  let re = @re_frontend.Pcre::regexp(@base.sb(","))
  let parts = @re_frontend.Pcre::full_split(re, @base.sb(""))
  assert_eq(parts.length(), 0)
}

///|
test "pcre full_split max 1" {
  let re = @re_frontend.Pcre::regexp(@base.sb(","))
  let parts = @re_frontend.Pcre::full_split(re, @base.sb("a,b"), max=1)
  assert_eq(parts.length(), 1)
}

///|
test "pcre get_named_substring_opt not found" {
  let re = @re_frontend.Pcre::regexp(@base.sb("(?<foo>abc)"))
  match @compile.exec_opt(re, @base.sb("abc")) {
    Some(g) => {
      let opt = @re_frontend.Pcre::get_named_substring_opt(re, "bar", g)
      assert_eq(opt is None, true)
    }
    None => assert_eq(true, false)
  }
}

// === Str coverage (str CRAP ~15) ===

///|
test "str regexp_string and match helpers" {
  let re = @re_frontend.Str::regexp_string(@base.sb("a.b"))
  assert_eq(@re_frontend.Str::string_match(re, @base.sb("a.b"), 0), true)
  let re2 = @re_frontend.Str::regexp(@base.sb("\\(a\\)\\(b\\)"))
  assert_eq(@re_frontend.Str::string_match(re2, @base.sb("ab"), 0), true)
  let mb = @re_frontend.Str::match_beginning()
  assert_eq(mb, 0)
  let me = @re_frontend.Str::match_end()
  assert_eq(me, 2)
  let ms = @re_frontend.Str::matched_string(@base.sb("ab"))
  assert_eq(@base.bs(ms), "ab")
  let gb = @re_frontend.Str::group_beginning(1)
  assert_eq(gb, 0)
  let ge = @re_frontend.Str::group_end(1)
  assert_eq(ge, 1)
  let mg = @re_frontend.Str::matched_group(1, @base.sb("ab"))
  assert_eq(@base.bs(mg), "a")
}

///|
test "str string_after" {
  let r = @re_frontend.Str::string_after(@base.sb("hello"), 2)
  assert_eq(@base.bs(r), "llo")
  let r2 = @re_frontend.Str::string_after(@base.sb("hello"), 0)
  assert_eq(@base.bs(r2), "hello")
}

///|
test "str search_backward not found" {
  let re = @re_frontend.Str::regexp(@base.sb("xyz"))
  let r1 = try {
    let _ = @re_frontend.Str::search_backward(re, @base.sb("hello"), 4)
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
}

///|
test "str bounded_split empty match" {
  let re = @re_frontend.Str::regexp(@base.sb("a*"))
  let parts = @re_frontend.Str::bounded_split(re, @base.sb("aaa"), 2)
  assert_eq(parts.length() >= 1, true)
}

///|
test "str full_split empty match" {
  let re = @re_frontend.Str::regexp(@base.sb("a*"))
  let parts = @re_frontend.Str::full_split(re, @base.sb("aaa"))
  assert_eq(parts.length() >= 1, true)
}

///|
test "str bounded_split_delim empty text" {
  let re = @re_frontend.Str::regexp(@base.sb(","))
  let parts = @re_frontend.Str::bounded_split_delim(re, @base.sb(""), 2)
  assert_eq(parts.length(), 0)
}

///|
test "str bounded_split_delim empty match" {
  let re = @re_frontend.Str::regexp(@base.sb("a*"))
  let parts = @re_frontend.Str::bounded_split_delim(re, @base.sb("aaa"), 2)
  assert_eq(parts.length() >= 1, true)
}

///|
test "str bounded_full_split empty match" {
  let re = @re_frontend.Str::regexp(@base.sb("a*"))
  let parts = @re_frontend.Str::bounded_full_split(re, @base.sb("aaa"), 2)
  assert_eq(parts.length() >= 1, true)
}

///|
test "str global_substitute boundary" {
  let re = @re_frontend.Str::regexp(@base.sb("a*"))
  let result = @re_frontend.Str::global_substitute(
    re,
    fn(_s) { @base.sb("X") },
    @base.sb("aaa"),
  )
  assert_eq(@base.bs(result).length() > 0, true)
}

///|
test "str replace_matched backslash sequences" {
  let re = @re_frontend.Str::regexp(@base.sb("\\(a\\)\\(b\\)"))
  ignore(@re_frontend.Str::search_forward(re, @base.sb("ab"), 0))
  let r = @re_frontend.Str::replace_matched(@base.sb("\\0"), @base.sb("ab"))
  assert_eq(@base.bs(r), "ab")
}

///|
test "str replace_matched backslash escape" {
  let re = @re_frontend.Str::regexp(@base.sb("ab"))
  ignore(@re_frontend.Str::search_forward(re, @base.sb("ab"), 0))
  let r = @re_frontend.Str::replace_matched(@base.sb("\\\\"), @base.sb("ab"))
  assert_eq(@base.bs(r), "\\")
}

///|
test "str replace_matched backslash other" {
  let re = @re_frontend.Str::regexp(@base.sb("ab"))
  ignore(@re_frontend.Str::search_forward(re, @base.sb("ab"), 0))
  let r = @re_frontend.Str::replace_matched(@base.sb("\\x"), @base.sb("ab"))
  assert_eq(@base.bs(r), "\\x")
}

///|
test "str replace_matched illegal backslash" {
  let re = @re_frontend.Str::regexp(@base.sb("ab"))
  ignore(@re_frontend.Str::search_forward(re, @base.sb("ab"), 0))
  let r1 = try {
    let _ = @re_frontend.Str::replace_matched(@base.sb("\\"), @base.sb("ab"))
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
}

// === Cache coverage (cache CRAP ~10) ===

///|
test "cache perl opts byte" {
  let cache = @compile.ReCache::new()
  let re = @re_frontend.Perl::compile_pat_cached(cache, @base.sb("abc"), opts=[
    @re_frontend.PerlOpt::ungreedy(),
  ])
  assert_eq(@compile.execp(re, @base.sb("abc")), true)
}

///|
test "cache pcre flags byte" {
  let cache = @compile.ReCache::new()
  let re = @re_frontend.Pcre::regexp_cached(cache, @base.sb("abc"), flags=[
    @re_frontend.PcreFlag::caseless(),
  ])
  assert_eq(@re_frontend.Pcre::pmatch(re, @base.sb("ABC")), true)
}

///|
test "cache glob flags byte" {
  let cache = @compile.ReCache::new()
  let re = @re_frontend.Glob::compile_cached(
    cache,
    @base.sb("abc"),
    anchored=true,
    match_backslashes=true,
  )
  assert_eq(@compile.execp(re, @base.sb("abc")), true)
}
