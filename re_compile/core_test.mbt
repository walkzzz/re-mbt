// Tests for Core/Group/Search/Replace (Phase 5)

///|
fn bs(b : Bytes) -> String {
  let mut s = ""
  for i in 0..<b.length() {
    s = s + b[i].to_int().unsafe_to_char().to_string()
  }
  s
}

// === exec_opt / exec / execp ===

///|
test "exec_opt basic match" {
  let re = @re_compile.compile(@ast.Ast::str(@base.sb("hello")))
  let s = @base.sb("hello world")
  match @re_compile.exec_opt(re, s) {
    Some(g) => assert_eq(@re_compile.GroupT::start(g, 0), 0)
    None => assert_eq(true, false)
  }
}

///|
test "exec_opt no match" {
  let re = @re_compile.compile(@ast.Ast::str(@base.sb("xyz")))
  let s = @base.sb("hello world")
  match @re_compile.exec_opt(re, s) {
    Some(_) => assert_eq(true, false)
    None => assert_eq(true, true)
  }
}

///|
test "exec_opt with pos" {
  let re = @re_compile.compile(@ast.Ast::str(@base.sb("ab")))
  let s = @base.sb("xabc")
  match @re_compile.exec_opt(re, s, pos=1) {
    Some(g) => assert_eq(@re_compile.GroupT::start(g, 0), 1)
    None => assert_eq(true, false)
  }
}

///|
test "execp basic" {
  let re = @re_compile.compile(@ast.Ast::str(@base.sb("test")))
  assert_eq(@re_compile.execp(re, @base.sb("a test string")), true)
  assert_eq(@re_compile.execp(re, @base.sb("no match")), false)
}

///|
test "execp with pos" {
  let re = @re_compile.compile(@ast.Ast::str(@base.sb("ab")))
  assert_eq(@re_compile.execp(re, @base.sb("xab"), pos=1), true)
  assert_eq(@re_compile.execp(re, @base.sb("xab"), pos=2), false)
}

// === Group operations ===

///|
test "group get and offsets" {
  let re = @re_compile.compile(
    @ast.Ast::seq([
      @ast.Ast::str(@base.sb("a")),
      @ast.Ast::group(@ast.Ast::str(@base.sb("b"))),
      @ast.Ast::str(@base.sb("c")),
    ]),
  )
  let s = @base.sb("abc")
  match @re_compile.exec_opt(re, s) {
    Some(g) => {
      assert_eq(@re_compile.GroupT::start(g, 0), 0)
      assert_eq(@re_compile.GroupT::stop(g, 0), 3)
      assert_eq(@re_compile.GroupT::start(g, 1), 1)
      assert_eq(@re_compile.GroupT::stop(g, 1), 2)
      assert_eq(bs(@re_compile.GroupT::get(g, 0).unwrap()), "abc")
      assert_eq(bs(@re_compile.GroupT::get(g, 1).unwrap()), "b")
    }
    None => assert_eq(true, false)
  }
}

///|
test "group matched and nb_groups" {
  let re = @re_compile.compile(
    @ast.Ast::seq([
      @ast.Ast::group(@ast.Ast::str(@base.sb("a"))),
      @ast.Ast::group(@ast.Ast::opt(@ast.Ast::str(@base.sb("b")))),
    ]),
  )
  let s = @base.sb("a")
  match @re_compile.exec_opt(re, s) {
    Some(g) => {
      assert_eq(@re_compile.GroupT::nb_groups(g), 3)
      assert_eq(@re_compile.GroupT::matched(g, 0), true)
      assert_eq(@re_compile.GroupT::matched(g, 1), true)
    }
    None => assert_eq(true, false)
  }
}

///|
test "group all" {
  let re = @re_compile.compile(
    @ast.Ast::seq([
      @ast.Ast::group(@ast.Ast::str(@base.sb("a"))),
      @ast.Ast::group(@ast.Ast::str(@base.sb("b"))),
    ]),
  )
  let s = @base.sb("ab")
  match @re_compile.exec_opt(re, s) {
    Some(g) => {
      let all = @re_compile.GroupT::all(g)
      assert_eq(all.length(), 3)
      assert_eq(bs(all[0]), "ab")
      assert_eq(bs(all[1]), "a")
      assert_eq(bs(all[2]), "b")
    }
    None => assert_eq(true, false)
  }
}

///|
test "group all_offset" {
  let re = @re_compile.compile(
    @ast.Ast::seq([
      @ast.Ast::group(@ast.Ast::str(@base.sb("a"))),
      @ast.Ast::group(@ast.Ast::str(@base.sb("b"))),
    ]),
  )
  let s = @base.sb("xab")
  match @re_compile.exec_opt(re, s) {
    Some(g) => {
      let offs = @re_compile.GroupT::all_offset(g)
      assert_eq(offs.length(), 3)
      assert_eq(offs[0], (1, 3))
      assert_eq(offs[1], (1, 2))
      assert_eq(offs[2], (2, 3))
    }
    None => assert_eq(true, false)
  }
}

// === Search::all / Search::matches ===

///|
test "search all basic" {
  let re = @re_compile.compile(@ast.Ast::str(@base.sb("ab")))
  let s = @base.sb("ab_ab_ab")
  let groups = @exec.Search::all(re, s)
  assert_eq(groups.length(), 3)
}

///|
test "search matches basic" {
  let re = @re_compile.compile(@ast.Ast::str(@base.sb("my")))
  let s = @base.sb("my head, my shoulders")
  let matches = @exec.Search::matches(re, s)
  assert_eq(matches.length(), 2)
  assert_eq(bs(matches[0]), "my")
  assert_eq(bs(matches[1]), "my")
}

///|
test "search all with groups" {
  let re = @re_compile.compile(
    @ast.Ast::seq([
      @ast.Ast::str(@base.sb("my")),
      @re_compile.Re::blank(),
      @ast.Ast::word(@ast.Ast::rep(@re_compile.Re::alpha())),
    ]),
  )
  let s = @base.sb("my head, my shoulders, my knees")
  let groups = @exec.Search::all(re, s)
  assert_eq(groups.length(), 3)
}

// === Search::split / split_delim / split_full ===

///|
test "search split basic" {
  let re = @re_compile.compile(@ast.Ast::char(','))
  let s = @base.sb("Re,Ocaml,Jerome")
  let parts = @exec.Search::split(re, s)
  assert_eq(parts.length(), 3)
  assert_eq(bs(parts[0]), "Re")
  assert_eq(bs(parts[1]), "Ocaml")
  assert_eq(bs(parts[2]), "Jerome")
}

///|
test "search split no delimiter" {
  let re = @re_compile.compile(@ast.Ast::char(','))
  let s = @base.sb("No commas here")
  let parts = @exec.Search::split(re, s)
  assert_eq(parts.length(), 1)
  assert_eq(bs(parts[0]), "No commas here")
}

///|
test "search split with leading/trailing delim" {
  let re = @re_compile.compile(@ast.Ast::char(','))
  let s = @base.sb(",1,2,")
  let parts = @exec.Search::split(re, s)
  assert_eq(parts.length(), 2)
  assert_eq(bs(parts[0]), "1")
  assert_eq(bs(parts[1]), "2")
}

///|
test "search split_delim with leading/trailing" {
  let re = @re_compile.compile(@ast.Ast::char(','))
  let s = @base.sb(",1,2,")
  let parts = @exec.Search::split_delim(re, s)
  assert_eq(parts.length(), 4)
  assert_eq(bs(parts[0]), "")
  assert_eq(bs(parts[1]), "1")
  assert_eq(bs(parts[2]), "2")
  assert_eq(bs(parts[3]), "")
}

///|
test "search split_full basic" {
  let re = @re_compile.compile(@ast.Ast::char(','))
  let s = @base.sb("a,b,c")
  let parts = @exec.Search::split_full(re, s)
  assert_eq(parts.length(), 5)
  match parts[0] {
    SplitText(t) => assert_eq(bs(t), "a")
    _ => assert_eq(true, false)
  }
  match parts[1] {
    SplitDelim(_) => assert_eq(true, true)
    _ => assert_eq(true, false)
  }
  match parts[2] {
    SplitText(t) => assert_eq(bs(t), "b")
    _ => assert_eq(true, false)
  }
}

// === Replace::replace / replace_string ===

///|
test "replace_string all" {
  let re = @re_compile.compile(@ast.Ast::char(','))
  let s = @base.sb("[1,2,3,4,5]")
  let result = @exec.Replace::replace_string(re, s, by=@base.sb(";"))
  assert_eq(bs(result), "[1;2;3;4;5]")
}

///|
test "replace_string first only" {
  let re = @re_compile.compile(@ast.Ast::char(','))
  let s = @base.sb("[1,2,3,4,5]")
  let result = @exec.Replace::replace_string(re, s, by=@base.sb(";"), all=false)
  assert_eq(bs(result), "[1;2,3,4,5]")
}

///|
test "replace with function" {
  let re = @re_compile.compile(@ast.Ast::rep1(@re_compile.Re::digit()))
  let s = @base.sb("abc123def456")
  let result = @exec.Replace::replace(re, s, f=fn(g : @re_compile.GroupT) {
    let matched = @re_compile.GroupT::get(g, 0).unwrap()
    let buf : Array[Byte] = []
    buf.push('['.to_int().to_byte())
    for i in 0..<matched.length() {
      buf.push(matched[i])
    }
    buf.push(']'.to_int().to_byte())
    Bytes::from_array(buf)
  })
  assert_eq(bs(result), "abc[123]def[456]")
}

// === exec_partial ===

///|
test "exec_partial full match" {
  let re = @re_compile.compile(
    @ast.Ast::seq([@ast.Ast::bos(), @ast.Ast::str(@base.sb("hello"))]),
  )
  let result = @re_compile.exec_partial(re, @base.sb("hello"))
  assert_eq(result, @re_compile.ExecPartialResult::full())
}

///|
test "exec_partial mismatch" {
  let re = @re_compile.compile(
    @ast.Ast::seq([@ast.Ast::bos(), @ast.Ast::str(@base.sb("hello"))]),
  )
  let result = @re_compile.exec_partial(re, @base.sb("world"))
  assert_eq(result, @re_compile.ExecPartialResult::mismatch())
}

///|
test "exec_partial_detailed full" {
  let re = @re_compile.compile(
    @ast.Ast::seq([@ast.Ast::bos(), @ast.Ast::str(@base.sb("hello"))]),
  )
  let result = @re_compile.exec_partial_detailed(re, @base.sb("hello"))
  match result {
    FullD(_) => assert_eq(true, true)
    _ => assert_eq(true, false)
  }
}

// === Character class shortcuts ===

///|
test "char class digit" {
  let re = @re_compile.compile(@re_compile.Re::digit())
  assert_eq(@re_compile.execp(re, @base.sb("a1b")), true)
  assert_eq(@re_compile.execp(re, @base.sb("abc")), false)
}

///|
test "char class alpha" {
  let re = @re_compile.compile(@re_compile.Re::alpha())
  assert_eq(@re_compile.execp(re, @base.sb("1a2")), true)
  assert_eq(@re_compile.execp(re, @base.sb("123")), false)
}

///|
test "char class space" {
  let re = @re_compile.compile(@re_compile.Re::space())
  assert_eq(@re_compile.execp(re, @base.sb("a b")), true)
  assert_eq(@re_compile.execp(re, @base.sb("abc")), false)
}

// === Edge cases ===

///|
test "exec_opt empty string match" {
  let re = @re_compile.compile(@ast.Ast::epsilon())
  match @re_compile.exec_opt(re, @base.sb("")) {
    Some(_) => assert_eq(true, true)
    None => assert_eq(true, false)
  }
}

///|
test "search matches empty pattern" {
  let re = @re_compile.compile(@ast.Ast::char('a'))
  let parts = @exec.Search::split(re, @base.sb("a"))
  assert_eq(parts.length(), 0)
}

///|
test "replace no match" {
  let re = @re_compile.compile(@ast.Ast::str(@base.sb("xyz")))
  let s = @base.sb("hello world")
  let result = @exec.Replace::replace_string(re, s, by=@base.sb("REPLACED"))
  assert_eq(bs(result), "hello world")
}

// === Re::pp / Re::pp_re ===

///|
test "Re::pp basic" {
  let ast = @ast.Ast::str(@base.sb("hello"))
  let s = @re_compile.Re::pp(ast)
  assert_eq(s.length() > 0, true)
}

///|
test "Re::pp complex ast" {
  let ast = @ast.Ast::seq([
    @ast.Ast::group(@ast.Ast::rep1(@re_compile.Re::digit())),
    @ast.Ast::str(@base.sb("-")),
    @ast.Ast::group(@ast.Ast::rep1(@re_compile.Re::digit())),
  ])
  let s = @re_compile.Re::pp(ast)
  assert_eq(s.length() > 0, true)
}

///|
test "Re::pp_re basic" {
  let re = @re_compile.compile(@ast.Ast::str(@base.sb("hello")))
  let s = @re_compile.Re::pp_re(re)
  assert_eq(s.length() > 0, true)
}

///|
test "Re::pp_re with groups" {
  let re = @re_compile.compile(
    @ast.Ast::group(name=Some("first"), @ast.Ast::str(@base.sb("a"))),
  )
  let s = @re_compile.Re::pp_re(re)
  assert_eq(s.length() > 0, true)
}

///|
test "Re::pp_re multiple named groups" {
  let re = @re_compile.compile(
    @ast.Ast::seq([
      @ast.Ast::group(name=Some("x"), @ast.Ast::str(@base.sb("a"))),
      @ast.Ast::group(name=Some("y"), @ast.Ast::str(@base.sb("b"))),
    ]),
  )
  let s = @re_compile.Re::pp_re(re)
  assert_eq(s.length() > 0, true)
}
