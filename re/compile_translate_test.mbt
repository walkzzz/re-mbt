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
  let re = @re.compile(@re.Ast::alt([@re.Ast::str(sb("foo")), @re.Ast::str(sb("bar"))]))
  assert_eq(@re.execp(re, sb("foo")), true)
  assert_eq(@re.execp(re, sb("bar")), true)
  assert_eq(@re.execp(re, sb("baz")), false)
}

///|
test "translate alt three branches" {
  let re = @re.compile(
    @re.Ast::alt([@re.Ast::str(sb("a")), @re.Ast::str(sb("b")), @re.Ast::str(sb("c"))]),
  )
  assert_eq(@re.execp(re, sb("a")), true)
  assert_eq(@re.execp(re, sb("b")), true)
  assert_eq(@re.execp(re, sb("c")), true)
  assert_eq(@re.execp(re, sb("d")), false)
}

///|
test "translate alt empty" {
  let re = @re.compile(@re.Ast::alt([]))
  // alt [] = empty = matches nothing
  assert_eq(@re.execp(re, sb("")), false)
  assert_eq(@re.execp(re, sb("a")), false)
}

// === Seq (sequence) translation ===

///|
test "translate seq basic" {
  let re = @re.compile(@re.Ast::seq([@re.Ast::str(sb("ab")), @re.Ast::str(sb("cd"))]))
  assert_eq(@re.execp(re, sb("abcd")), true)
  assert_eq(@re.execp(re, sb("ab")), false)
}

///|
test "translate seq empty" {
  let re = @re.compile(@re.Ast::seq([]))
  assert_eq(@re.execp(re, sb("")), true)
}

// === Rep (repetition) translation ===

///|
test "translate rep star" {
  let re = @re.compile(@re.Ast::rep(@re.Ast::str(sb("a"))))
  assert_eq(@re.execp(re, sb("")), true)
  assert_eq(@re.execp(re, sb("a")), true)
  assert_eq(@re.execp(re, sb("aaa")), true)
  // execp searches, so "aab" contains a match ("aa")
  assert_eq(@re.execp(re, sb("aab")), true)
  assert_eq(@re.execp(re, sb("b")), true)
}

///|
test "translate rep plus" {
  let re = @re.compile(@re.Ast::rep1(@re.Ast::str(sb("a"))))
  assert_eq(@re.execp(re, sb("")), false)
  assert_eq(@re.execp(re, sb("a")), true)
  assert_eq(@re.execp(re, sb("aaa")), true)
}

///|
test "translate rep opt" {
  let re = @re.compile(@re.Ast::opt(@re.Ast::str(sb("a"))))
  assert_eq(@re.execp(re, sb("")), true)
  assert_eq(@re.execp(re, sb("a")), true)
  // execp searches, so "aa" contains a match ("a" at pos 0)
  assert_eq(@re.execp(re, sb("aa")), true)
}

///|
test "translate repn" {
  let re = @re.compile(@re.Ast::repn(@re.Ast::str(sb("a")), 2, Some(3)))
  assert_eq(@re.execp(re, sb("a")), false)
  assert_eq(@re.execp(re, sb("aa")), true)
  assert_eq(@re.execp(re, sb("aaa")), true)
  // execp searches, so "aaaa" contains "aaa" which matches
  assert_eq(@re.execp(re, sb("aaaa")), true)
  assert_eq(@re.execp(re, sb("b")), false)
}

// === Group translation ===

///|
test "translate group basic" {
  let re = @re.compile(@re.Ast::group(@re.Ast::str(sb("abc"))))
  match @re.exec_opt(re, sb("abc")) {
    Some(g) => {
      assert_eq(@re.GroupT::nb_groups(g), 2)
      assert_eq(bs_ct(@re.GroupT::get(g, 0).unwrap()), "abc")
      assert_eq(bs_ct(@re.GroupT::get(g, 1).unwrap()), "abc")
    }
    None => fail("should match")
  }
}

///|
test "translate nested groups" {
  let re = @re.compile(
    @re.Ast::seq([
      @re.Ast::group(@re.Ast::str(sb("a"))),
      @re.Ast::group(@re.Ast::seq([@re.Ast::str(sb("b")), @re.Ast::group(@re.Ast::str(sb("c")))])),
    ]),
  )
  match @re.exec_opt(re, sb("abc")) {
    Some(g) => {
      assert_eq(@re.GroupT::nb_groups(g), 4)
      assert_eq(bs_ct(@re.GroupT::get(g, 1).unwrap()), "a")
      assert_eq(bs_ct(@re.GroupT::get(g, 2).unwrap()), "bc")
      assert_eq(bs_ct(@re.GroupT::get(g, 3).unwrap()), "c")
    }
    None => fail("should match")
  }
}

///|
test "translate no_group" {
  let re = @re.compile(@re.Ast::no_group(@re.Ast::group(@re.Ast::str(sb("a")))))
  match @re.exec_opt(re, sb("a")) {
    Some(g) => assert_eq(@re.GroupT::nb_groups(g), 1)
    None => fail("should match")
  }
}

// === Sem (match semantics) translation ===

///|
test "translate longest" {
  let re = @re.compile(
    @re.Ast::longest(
      @re.Ast::seq([@re.Ast::rep(@re.Ast::str(sb("a"))), @re.Ast::rep(@re.Ast::str(sb("a")))]),
    ),
  )
  match @re.exec_opt(re, sb("aaa")) {
    Some(g) => {
      assert_eq(@re.GroupT::start(g, 0), 0)
      assert_eq(@re.GroupT::stop(g, 0), 3)
    }
    None => fail("should match")
  }
}

///|
test "translate shortest" {
  let re = @re.compile(
    @re.Ast::shortest(
      @re.Ast::seq([@re.Ast::rep(@re.Ast::str(sb("a"))), @re.Ast::rep(@re.Ast::str(sb("a")))]),
    ),
  )
  match @re.exec_opt(re, sb("aaa")) {
    Some(g) => assert_eq(@re.GroupT::stop(g, 0), 0)
    None => fail("should match")
  }
}

// === Greedy / NonGreedy ===

///|
test "translate greedy" {
  let re = @re.compile(@re.Ast::greedy(@re.Ast::rep(@re.Ast::str(sb("a")))))
  match @re.exec_opt(re, sb("aaa")) {
    Some(g) => assert_eq(@re.GroupT::stop(g, 0), 3)
    None => fail("should match")
  }
}

///|
test "translate non_greedy" {
  let re = @re.compile(@re.Ast::non_greedy(@re.Ast::rep(@re.Ast::str(sb("a")))))
  match @re.exec_opt(re, sb("aaa")) {
    Some(g) => assert_eq(@re.GroupT::stop(g, 0), 0)
    None => fail("should match")
  }
}

// === Character sets ===

///|
test "translate cset range" {
  let re = @re.compile(@re.Ast::cset(@re.Cset::cseq('a', 'z')))
  assert_eq(@re.execp(re, sb("a")), true)
  assert_eq(@re.execp(re, sb("z")), true)
  assert_eq(@re.execp(re, sb("A")), false)
}

///|
test "translate cset digit" {
  let re = @re.compile(@re.Re::digit())
  assert_eq(@re.execp(re, sb("0")), true)
  assert_eq(@re.execp(re, sb("9")), true)
  assert_eq(@re.execp(re, sb("a")), false)
}

///|
test "translate cset inter" {
  let re = @re.compile(
    @re.Ast::inter([
      @re.Ast::cset(@re.Cset::cseq('a', 'z')),
      @re.Ast::cset(@re.Cset::cseq('a', 'm')),
    ]),
  )
  assert_eq(@re.execp(re, sb("a")), true)
  assert_eq(@re.execp(re, sb("m")), true)
  assert_eq(@re.execp(re, sb("n")), false)
}

///|
test "translate cset diff" {
  let re = @re.compile(
    @re.Ast::diff(@re.Ast::cset(@re.Cset::cseq('a', 'z')), @re.Ast::cset(@re.Cset::cseq('a', 'm'))),
  )
  assert_eq(@re.execp(re, sb("a")), false)
  assert_eq(@re.execp(re, sb("n")), true)
  assert_eq(@re.execp(re, sb("z")), true)
}

// === Anchors ===

///|
test "translate bol" {
  let re = @re.compile(@re.Ast::seq([@re.Ast::bol(), @re.Ast::str(sb("a"))]))
  assert_eq(@re.execp(re, sb("a")), true)
}

///|
test "translate eos" {
  let re = @re.compile(@re.Ast::seq([@re.Ast::str(sb("a")), @re.Ast::eos()]))
  assert_eq(@re.execp(re, sb("a")), true)
  assert_eq(@re.execp(re, sb("ab")), false)
}

// === Case modifiers ===

///|
test "translate no_case" {
  let re = @re.compile(@re.Ast::no_case(@re.Ast::str(sb("hello"))))
  assert_eq(@re.execp(re, sb("HELLO")), true)
  assert_eq(@re.execp(re, sb("hello")), true)
  assert_eq(@re.execp(re, sb("HeLLo")), true)
}

///|
test "translate case" {
  let re = @re.compile(@re.Ast::case(@re.Ast::str(sb("hello"))))
  assert_eq(@re.execp(re, sb("hello")), true)
  assert_eq(@re.execp(re, sb("HELLO")), false)
}

// === Nest ===

///|
test "translate nest" {
  let re = @re.compile(
    @re.Ast::rep1(
      @re.Ast::nest(@re.Ast::alt([@re.Ast::group(@re.Ast::str(sb("a"))), @re.Ast::str(sb("b"))])),
    ),
  )
  match @re.exec_opt(re, sb("ab")) {
    Some(g) => assert_eq(@re.GroupT::get_opt(g, 1), None)
    None => fail("should match")
  }
}
