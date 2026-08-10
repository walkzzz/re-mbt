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
  let re = compile(Ast::str(sb("hello")))
  let s = sb("hello world")
  match exec_opt(re, s) {
    Some(g) => assert_eq(GroupT::start(g, 0), 0)
    None => assert_eq(true, false)
  }
}

///|
test "exec_opt no match" {
  let re = compile(Ast::str(sb("xyz")))
  let s = sb("hello world")
  match exec_opt(re, s) {
    Some(_) => assert_eq(true, false)
    None => assert_eq(true, true)
  }
}

///|
test "exec_opt with pos" {
  let re = compile(Ast::str(sb("ab")))
  let s = sb("xabc")
  match exec_opt(re, s, pos=1) {
    Some(g) => assert_eq(GroupT::start(g, 0), 1)
    None => assert_eq(true, false)
  }
}

///|
test "execp basic" {
  let re = compile(Ast::str(sb("test")))
  assert_eq(execp(re, sb("a test string")), true)
  assert_eq(execp(re, sb("no match")), false)
}

///|
test "execp with pos" {
  let re = compile(Ast::str(sb("ab")))
  assert_eq(execp(re, sb("xab"), pos=1), true)
  assert_eq(execp(re, sb("xab"), pos=2), false)
}

// === Group operations ===

///|
test "group get and offsets" {
  let re = compile(
    Ast::seq([
      Ast::str(sb("a")),
      Ast::group(Ast::str(sb("b"))),
      Ast::str(sb("c")),
    ]),
  )
  let s = sb("abc")
  match exec_opt(re, s) {
    Some(g) => {
      assert_eq(GroupT::start(g, 0), 0)
      assert_eq(GroupT::stop(g, 0), 3)
      assert_eq(GroupT::start(g, 1), 1)
      assert_eq(GroupT::stop(g, 1), 2)
      assert_eq(bs(GroupT::get(g, 0).unwrap()), "abc")
      assert_eq(bs(GroupT::get(g, 1).unwrap()), "b")
    }
    None => assert_eq(true, false)
  }
}

///|
test "group matched and nb_groups" {
  let re = compile(
    Ast::seq([
      Ast::group(Ast::str(sb("a"))),
      Ast::group(Ast::opt(Ast::str(sb("b")))),
    ]),
  )
  let s = sb("a")
  match exec_opt(re, s) {
    Some(g) => {
      assert_eq(GroupT::nb_groups(g), 3)
      assert_eq(GroupT::matched(g, 0), true)
      assert_eq(GroupT::matched(g, 1), true)
    }
    None => assert_eq(true, false)
  }
}

///|
test "group all" {
  let re = compile(
    Ast::seq([Ast::group(Ast::str(sb("a"))), Ast::group(Ast::str(sb("b")))]),
  )
  let s = sb("ab")
  match exec_opt(re, s) {
    Some(g) => {
      let all = GroupT::all(g)
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
  let re = compile(
    Ast::seq([Ast::group(Ast::str(sb("a"))), Ast::group(Ast::str(sb("b")))]),
  )
  let s = sb("xab")
  match exec_opt(re, s) {
    Some(g) => {
      let offs = GroupT::all_offset(g)
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
  let re = compile(Ast::str(sb("ab")))
  let s = sb("ab_ab_ab")
  let groups = Search::all(re, s)
  assert_eq(groups.length(), 3)
}

///|
test "search matches basic" {
  let re = compile(Ast::str(sb("my")))
  let s = sb("my head, my shoulders")
  let matches = Search::matches(re, s)
  assert_eq(matches.length(), 2)
  assert_eq(bs(matches[0]), "my")
  assert_eq(bs(matches[1]), "my")
}

///|
test "search all with groups" {
  let re = compile(
    Ast::seq([Ast::str(sb("my")), Re::blank(), Ast::word(Ast::rep(Re::alpha()))]),
  )
  let s = sb("my head, my shoulders, my knees")
  let groups = Search::all(re, s)
  assert_eq(groups.length(), 3)
}

// === Search::split / split_delim / split_full ===

///|
test "search split basic" {
  let re = compile(Ast::char(','))
  let s = sb("Re,Ocaml,Jerome")
  let parts = Search::split(re, s)
  assert_eq(parts.length(), 3)
  assert_eq(bs(parts[0]), "Re")
  assert_eq(bs(parts[1]), "Ocaml")
  assert_eq(bs(parts[2]), "Jerome")
}

///|
test "search split no delimiter" {
  let re = compile(Ast::char(','))
  let s = sb("No commas here")
  let parts = Search::split(re, s)
  assert_eq(parts.length(), 1)
  assert_eq(bs(parts[0]), "No commas here")
}

///|
test "search split with leading/trailing delim" {
  let re = compile(Ast::char(','))
  let s = sb(",1,2,")
  let parts = Search::split(re, s)
  assert_eq(parts.length(), 2)
  assert_eq(bs(parts[0]), "1")
  assert_eq(bs(parts[1]), "2")
}

///|
test "search split_delim with leading/trailing" {
  let re = compile(Ast::char(','))
  let s = sb(",1,2,")
  let parts = Search::split_delim(re, s)
  assert_eq(parts.length(), 4)
  assert_eq(bs(parts[0]), "")
  assert_eq(bs(parts[1]), "1")
  assert_eq(bs(parts[2]), "2")
  assert_eq(bs(parts[3]), "")
}

///|
test "search split_full basic" {
  let re = compile(Ast::char(','))
  let s = sb("a,b,c")
  let parts = Search::split_full(re, s)
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
  let re = compile(Ast::char(','))
  let s = sb("[1,2,3,4,5]")
  let result = Replace::replace_string(re, s, by=sb(";"))
  assert_eq(bs(result), "[1;2;3;4;5]")
}

///|
test "replace_string first only" {
  let re = compile(Ast::char(','))
  let s = sb("[1,2,3,4,5]")
  let result = Replace::replace_string(re, s, by=sb(";"), all=false)
  assert_eq(bs(result), "[1;2,3,4,5]")
}

///|
test "replace with function" {
  let re = compile(Ast::rep1(Re::digit()))
  let s = sb("abc123def456")
  let result = Replace::replace(re, s, f=fn(g : GroupT) {
    let matched = GroupT::get(g, 0).unwrap()
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
  let re = compile(Ast::seq([Ast::bos(), Ast::str(sb("hello"))]))
  let result = exec_partial(re, sb("hello"))
  assert_eq(result, ExecPartialResult::full())
}

///|
test "exec_partial mismatch" {
  let re = compile(Ast::seq([Ast::bos(), Ast::str(sb("hello"))]))
  let result = exec_partial(re, sb("world"))
  assert_eq(result, ExecPartialResult::mismatch())
}

///|
test "exec_partial_detailed full" {
  let re = compile(Ast::seq([Ast::bos(), Ast::str(sb("hello"))]))
  let result = exec_partial_detailed(re, sb("hello"))
  match result {
    FullD(_) => assert_eq(true, true)
    _ => assert_eq(true, false)
  }
}

// === Character class shortcuts ===

///|
test "char class digit" {
  let re = compile(Re::digit())
  assert_eq(execp(re, sb("a1b")), true)
  assert_eq(execp(re, sb("abc")), false)
}

///|
test "char class alpha" {
  let re = compile(Re::alpha())
  assert_eq(execp(re, sb("1a2")), true)
  assert_eq(execp(re, sb("123")), false)
}

///|
test "char class space" {
  let re = compile(Re::space())
  assert_eq(execp(re, sb("a b")), true)
  assert_eq(execp(re, sb("abc")), false)
}

// === Edge cases ===

///|
test "exec_opt empty string match" {
  let re = compile(Ast::epsilon())
  match exec_opt(re, sb("")) {
    Some(_) => assert_eq(true, true)
    None => assert_eq(true, false)
  }
}

///|
test "search matches empty pattern" {
  let re = compile(Ast::char('a'))
  let parts = Search::split(re, sb("a"))
  assert_eq(parts.length(), 0)
}

///|
test "replace no match" {
  let re = compile(Ast::str(sb("xyz")))
  let s = sb("hello world")
  let result = Replace::replace_string(re, s, by=sb("REPLACED"))
  assert_eq(bs(result), "hello world")
}
