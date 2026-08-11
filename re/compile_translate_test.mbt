// Tests for compile_translate — indirect testing via compilation of various AST patterns

///|
fn bs_ct(b : Bytes) -> String {
  let mut s = ""
  for i in 0..<b.length() {
    s = s + b[i].to_int().unsafe_to_char().to_string()
  }
  s
}

// === Alt (alternation) translation ===

///|
test "translate alt basic" {
  let re = compile(Ast::alt([Ast::str(sb("foo")), Ast::str(sb("bar"))]))
  assert_eq(execp(re, sb("foo")), true)
  assert_eq(execp(re, sb("bar")), true)
  assert_eq(execp(re, sb("baz")), false)
}

///|
test "translate alt three branches" {
  let re = compile(
    Ast::alt([Ast::str(sb("a")), Ast::str(sb("b")), Ast::str(sb("c"))]),
  )
  assert_eq(execp(re, sb("a")), true)
  assert_eq(execp(re, sb("b")), true)
  assert_eq(execp(re, sb("c")), true)
  assert_eq(execp(re, sb("d")), false)
}

///|
test "translate alt empty" {
  let re = compile(Ast::alt([]))
  // alt [] = empty = matches nothing
  assert_eq(execp(re, sb("")), false)
  assert_eq(execp(re, sb("a")), false)
}

// === Seq (sequence) translation ===

///|
test "translate seq basic" {
  let re = compile(Ast::seq([Ast::str(sb("ab")), Ast::str(sb("cd"))]))
  assert_eq(execp(re, sb("abcd")), true)
  assert_eq(execp(re, sb("ab")), false)
}

///|
test "translate seq empty" {
  let re = compile(Ast::seq([]))
  assert_eq(execp(re, sb("")), true)
}

// === Rep (repetition) translation ===

///|
test "translate rep star" {
  let re = compile(Ast::rep(Ast::str(sb("a"))))
  assert_eq(execp(re, sb("")), true)
  assert_eq(execp(re, sb("a")), true)
  assert_eq(execp(re, sb("aaa")), true)
  // execp searches, so "aab" contains a match ("aa")
  assert_eq(execp(re, sb("aab")), true)
  assert_eq(execp(re, sb("b")), true)
}

///|
test "translate rep plus" {
  let re = compile(Ast::rep1(Ast::str(sb("a"))))
  assert_eq(execp(re, sb("")), false)
  assert_eq(execp(re, sb("a")), true)
  assert_eq(execp(re, sb("aaa")), true)
}

///|
test "translate rep opt" {
  let re = compile(Ast::opt(Ast::str(sb("a"))))
  assert_eq(execp(re, sb("")), true)
  assert_eq(execp(re, sb("a")), true)
  // execp searches, so "aa" contains a match ("a" at pos 0)
  assert_eq(execp(re, sb("aa")), true)
}

///|
test "translate repn" {
  let re = compile(Ast::repn(Ast::str(sb("a")), 2, Some(3)))
  assert_eq(execp(re, sb("a")), false)
  assert_eq(execp(re, sb("aa")), true)
  assert_eq(execp(re, sb("aaa")), true)
  // execp searches, so "aaaa" contains "aaa" which matches
  assert_eq(execp(re, sb("aaaa")), true)
  assert_eq(execp(re, sb("b")), false)
}

// === Group translation ===

///|
test "translate group basic" {
  let re = compile(Ast::group(Ast::str(sb("abc"))))
  match exec_opt(re, sb("abc")) {
    Some(g) => {
      assert_eq(GroupT::nb_groups(g), 2)
      assert_eq(bs_ct(GroupT::get(g, 0).unwrap()), "abc")
      assert_eq(bs_ct(GroupT::get(g, 1).unwrap()), "abc")
    }
    None => fail("should match")
  }
}

///|
test "translate nested groups" {
  let re = compile(
    Ast::seq([
      Ast::group(Ast::str(sb("a"))),
      Ast::group(Ast::seq([Ast::str(sb("b")), Ast::group(Ast::str(sb("c")))])),
    ]),
  )
  match exec_opt(re, sb("abc")) {
    Some(g) => {
      assert_eq(GroupT::nb_groups(g), 4)
      assert_eq(bs_ct(GroupT::get(g, 1).unwrap()), "a")
      assert_eq(bs_ct(GroupT::get(g, 2).unwrap()), "bc")
      assert_eq(bs_ct(GroupT::get(g, 3).unwrap()), "c")
    }
    None => fail("should match")
  }
}

///|
test "translate no_group" {
  let re = compile(Ast::no_group(Ast::group(Ast::str(sb("a")))))
  match exec_opt(re, sb("a")) {
    Some(g) => assert_eq(GroupT::nb_groups(g), 1)
    None => fail("should match")
  }
}

// === Sem (match semantics) translation ===

///|
test "translate longest" {
  let re = compile(
    Ast::longest(
      Ast::seq([Ast::rep(Ast::str(sb("a"))), Ast::rep(Ast::str(sb("a")))]),
    ),
  )
  match exec_opt(re, sb("aaa")) {
    Some(g) => {
      assert_eq(GroupT::start(g, 0), 0)
      assert_eq(GroupT::stop(g, 0), 3)
    }
    None => fail("should match")
  }
}

///|
test "translate shortest" {
  let re = compile(
    Ast::shortest(
      Ast::seq([Ast::rep(Ast::str(sb("a"))), Ast::rep(Ast::str(sb("a")))]),
    ),
  )
  match exec_opt(re, sb("aaa")) {
    Some(g) => assert_eq(GroupT::stop(g, 0), 0)
    None => fail("should match")
  }
}

// === Greedy / NonGreedy ===

///|
test "translate greedy" {
  let re = compile(Ast::greedy(Ast::rep(Ast::str(sb("a")))))
  match exec_opt(re, sb("aaa")) {
    Some(g) => assert_eq(GroupT::stop(g, 0), 3)
    None => fail("should match")
  }
}

///|
test "translate non_greedy" {
  let re = compile(Ast::non_greedy(Ast::rep(Ast::str(sb("a")))))
  match exec_opt(re, sb("aaa")) {
    Some(g) => assert_eq(GroupT::stop(g, 0), 0)
    None => fail("should match")
  }
}

// === Character sets ===

///|
test "translate cset range" {
  let re = compile(Ast::cset(Cset::cseq('a', 'z')))
  assert_eq(execp(re, sb("a")), true)
  assert_eq(execp(re, sb("z")), true)
  assert_eq(execp(re, sb("A")), false)
}

///|
test "translate cset digit" {
  let re = compile(Re::digit())
  assert_eq(execp(re, sb("0")), true)
  assert_eq(execp(re, sb("9")), true)
  assert_eq(execp(re, sb("a")), false)
}

///|
test "translate cset inter" {
  let re = compile(
    Ast::inter([
      Ast::cset(Cset::cseq('a', 'z')),
      Ast::cset(Cset::cseq('a', 'm')),
    ]),
  )
  assert_eq(execp(re, sb("a")), true)
  assert_eq(execp(re, sb("m")), true)
  assert_eq(execp(re, sb("n")), false)
}

///|
test "translate cset diff" {
  let re = compile(
    Ast::diff(Ast::cset(Cset::cseq('a', 'z')), Ast::cset(Cset::cseq('a', 'm'))),
  )
  assert_eq(execp(re, sb("a")), false)
  assert_eq(execp(re, sb("n")), true)
  assert_eq(execp(re, sb("z")), true)
}

// === Anchors ===

///|
test "translate bol" {
  let re = compile(Ast::seq([Ast::bol(), Ast::str(sb("a"))]))
  assert_eq(execp(re, sb("a")), true)
}

///|
test "translate eos" {
  let re = compile(Ast::seq([Ast::str(sb("a")), Ast::eos()]))
  assert_eq(execp(re, sb("a")), true)
  assert_eq(execp(re, sb("ab")), false)
}

// === Case modifiers ===

///|
test "translate no_case" {
  let re = compile(Ast::no_case(Ast::str(sb("hello"))))
  assert_eq(execp(re, sb("HELLO")), true)
  assert_eq(execp(re, sb("hello")), true)
  assert_eq(execp(re, sb("HeLLo")), true)
}

///|
test "translate case" {
  let re = compile(Ast::case(Ast::str(sb("hello"))))
  assert_eq(execp(re, sb("hello")), true)
  assert_eq(execp(re, sb("HELLO")), false)
}

// === Nest ===

///|
test "translate nest" {
  let re = compile(
    Ast::rep1(
      Ast::nest(Ast::alt([Ast::group(Ast::str(sb("a"))), Ast::str(sb("b"))])),
    ),
  )
  match exec_opt(re, sb("ab")) {
    Some(g) => assert_eq(GroupT::get_opt(g, 1), None)
    None => fail("should match")
  }
}
