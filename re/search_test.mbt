// Tests for Search operations (search.mbt)

///|
fn bs_s(b : Bytes) -> String {
  let mut s = ""
  for i in 0..<b.length() {
    s = s + b[i].to_int().unsafe_to_char().to_string()
  }
  s
}

// === Search::all ===

///|
test "search all basic" {
  let re = compile(Ast::str(sb("ab")))
  let results = Search::all(re, sb("ab_ab_ab"))
  assert_eq(results.length(), 3)
}

///|
test "search all no match" {
  let re = compile(Ast::str(sb("xyz")))
  let results = Search::all(re, sb("abcdef"))
  assert_eq(results.length(), 0)
}

///|
test "search all empty string" {
  let re = compile(Ast::str(sb("a")))
  let results = Search::all(re, sb(""))
  assert_eq(results.length(), 0)
}

///|
test "search all with pos" {
  let re = compile(Ast::str(sb("a")))
  let results = Search::all(re, sb("aaa"), pos=1)
  assert_eq(results.length(), 2)
}

///|
test "search all overlapping pattern" {
  let re = compile(Ast::seq([Ast::str(sb("a")), Ast::str(sb("a"))]))
  let results = Search::all(re, sb("aaaa"))
  assert_eq(results.length(), 2)
}

// === Search::matches ===

///|
test "search matches basic" {
  let re = compile(Ast::str(sb("ab")))
  let results = Search::matches(re, sb("ab_ab_ab"))
  assert_eq(results.length(), 3)
  for r in results {
    assert_eq(bs_s(r), "ab")
  }
}

///|
test "search matches no match" {
  let re = compile(Ast::str(sb("xyz")))
  let results = Search::matches(re, sb("abc"))
  assert_eq(results.length(), 0)
}

///|
test "search matches with groups" {
  let re = compile(Ast::rep1(Re::digit()))
  let results = Search::matches(re, sb("a12b34c"))
  assert_eq(results.length(), 2)
  assert_eq(bs_s(results[0]), "12")
  assert_eq(bs_s(results[1]), "34")
}

// === Search::split ===

///|
test "search split basic" {
  let re = compile(Ast::str(sb(",")))
  let parts = Search::split(re, sb("a,b,c"))
  assert_eq(parts.length(), 3)
  assert_eq(bs_s(parts[0]), "a")
  assert_eq(bs_s(parts[1]), "b")
  assert_eq(bs_s(parts[2]), "c")
}

///|
test "search split no delimiter" {
  let re = compile(Ast::str(sb(",")))
  let parts = Search::split(re, sb("abc"))
  assert_eq(parts.length(), 1)
  assert_eq(bs_s(parts[0]), "abc")
}

///|
test "search split leading trailing delim" {
  let re = compile(Ast::str(sb(",")))
  let parts = Search::split(re, sb(",a,b,"))
  assert_eq(parts.length(), 2)
  assert_eq(bs_s(parts[0]), "a")
  assert_eq(bs_s(parts[1]), "b")
}

///|
test "search split with pos" {
  let re = compile(Ast::str(sb(",")))
  let parts = Search::split(re, sb("a,b,c"), pos=2)
  assert_eq(parts.length(), 2)
  assert_eq(bs_s(parts[0]), "b")
  assert_eq(bs_s(parts[1]), "c")
}

// === Search::split_delim ===

///|
test "search split_delim basic" {
  let re = compile(Ast::str(sb(",")))
  let parts = Search::split_delim(re, sb("a,b,c"))
  assert_eq(parts.length(), 3)
  assert_eq(bs_s(parts[0]), "a")
  assert_eq(bs_s(parts[1]), "b")
  assert_eq(bs_s(parts[2]), "c")
}

///|
test "search split_delim leading trailing" {
  let re = compile(Ast::str(sb(",")))
  let parts = Search::split_delim(re, sb(",a,b,"))
  assert_eq(parts.length(), 4)
  assert_eq(bs_s(parts[0]), "")
  assert_eq(bs_s(parts[1]), "a")
  assert_eq(bs_s(parts[2]), "b")
  assert_eq(bs_s(parts[3]), "")
}

///|
test "search split_delim no delimiter" {
  let re = compile(Ast::str(sb(",")))
  let parts = Search::split_delim(re, sb("abc"))
  assert_eq(parts.length(), 1)
  assert_eq(bs_s(parts[0]), "abc")
}

// === Search::split_full ===

///|
test "search split_full basic" {
  let re = compile(Ast::str(sb(",")))
  let tokens = Search::split_full(re, sb("a,b"))
  assert_eq(tokens.length(), 3)
  match tokens[0] {
    SplitText(t) => assert_eq(bs_s(t), "a")
    _ => fail("expected SplitText")
  }
  match tokens[1] {
    SplitDelim(_) => assert_eq(true, true)
    _ => fail("expected SplitDelim")
  }
  match tokens[2] {
    SplitText(t) => assert_eq(bs_s(t), "b")
    _ => fail("expected SplitText")
  }
}

///|
test "search split_full no delimiter" {
  let re = compile(Ast::str(sb(",")))
  let tokens = Search::split_full(re, sb("abc"))
  assert_eq(tokens.length(), 1)
  match tokens[0] {
    SplitText(t) => assert_eq(bs_s(t), "abc")
    _ => fail("expected SplitText")
  }
}

///|
test "search split_full multiple" {
  let re = compile(Ast::str(sb(",")))
  let tokens = Search::split_full(re, sb("a,b,c"))
  assert_eq(tokens.length(), 5)
}

// === Edge cases: invalid pos/len ===

///|
test "search all invalid pos raises" {
  let re = compile(Ast::str(sb("a")))
  try Search::all(re, sb("aaa"), pos=-1) catch {
    _ => assert_eq(true, true)
  } noraise {
    _ => fail("should raise")
  }
}

///|
test "search split invalid pos raises" {
  let re = compile(Ast::str(sb(",")))
  try Search::split(re, sb("a,b"), pos=-1) catch {
    _ => assert_eq(true, true)
  } noraise {
    _ => fail("should raise")
  }
}
