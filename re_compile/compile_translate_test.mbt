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
  let re = @re_compile.compile(
    @ast.Ast::alt([
      @ast.Ast::str(@base.sb("foo")),
      @ast.Ast::str(@base.sb("bar")),
    ]),
  )
  assert_eq(@re_compile.execp(re, @base.sb("foo")), true)
  assert_eq(@re_compile.execp(re, @base.sb("bar")), true)
  assert_eq(@re_compile.execp(re, @base.sb("baz")), false)
}

///|
test "translate alt three branches" {
  let re = @re_compile.compile(
    @ast.Ast::alt([
      @ast.Ast::str(@base.sb("a")),
      @ast.Ast::str(@base.sb("b")),
      @ast.Ast::str(@base.sb("c")),
    ]),
  )
  assert_eq(@re_compile.execp(re, @base.sb("a")), true)
  assert_eq(@re_compile.execp(re, @base.sb("b")), true)
  assert_eq(@re_compile.execp(re, @base.sb("c")), true)
  assert_eq(@re_compile.execp(re, @base.sb("d")), false)
}

///|
test "translate alt empty" {
  let re = @re_compile.compile(@ast.Ast::alt([]))
  // alt [] = empty = matches nothing
  assert_eq(@re_compile.execp(re, @base.sb("")), false)
  assert_eq(@re_compile.execp(re, @base.sb("a")), false)
}

// === Seq (sequence) translation ===

///|
test "translate seq basic" {
  let re = @re_compile.compile(
    @ast.Ast::seq([@ast.Ast::str(@base.sb("ab")), @ast.Ast::str(@base.sb("cd"))]),
  )
  assert_eq(@re_compile.execp(re, @base.sb("abcd")), true)
  assert_eq(@re_compile.execp(re, @base.sb("ab")), false)
}

///|
test "translate seq empty" {
  let re = @re_compile.compile(@ast.Ast::seq([]))
  assert_eq(@re_compile.execp(re, @base.sb("")), true)
}

// === Rep (repetition) translation ===

///|
test "translate rep star" {
  let re = @re_compile.compile(@ast.Ast::rep(@ast.Ast::str(@base.sb("a"))))
  assert_eq(@re_compile.execp(re, @base.sb("")), true)
  assert_eq(@re_compile.execp(re, @base.sb("a")), true)
  assert_eq(@re_compile.execp(re, @base.sb("aaa")), true)
  // execp searches, so "aab" contains a match ("aa")
  assert_eq(@re_compile.execp(re, @base.sb("aab")), true)
  assert_eq(@re_compile.execp(re, @base.sb("b")), true)
}

///|
test "translate rep plus" {
  let re = @re_compile.compile(@ast.Ast::rep1(@ast.Ast::str(@base.sb("a"))))
  assert_eq(@re_compile.execp(re, @base.sb("")), false)
  assert_eq(@re_compile.execp(re, @base.sb("a")), true)
  assert_eq(@re_compile.execp(re, @base.sb("aaa")), true)
}

///|
test "translate rep opt" {
  let re = @re_compile.compile(@ast.Ast::opt(@ast.Ast::str(@base.sb("a"))))
  assert_eq(@re_compile.execp(re, @base.sb("")), true)
  assert_eq(@re_compile.execp(re, @base.sb("a")), true)
  // execp searches, so "aa" contains a match ("a" at pos 0)
  assert_eq(@re_compile.execp(re, @base.sb("aa")), true)
}

///|
test "translate repn" {
  let re = @re_compile.compile(
    @ast.Ast::repn(@ast.Ast::str(@base.sb("a")), 2, Some(3)),
  )
  assert_eq(@re_compile.execp(re, @base.sb("a")), false)
  assert_eq(@re_compile.execp(re, @base.sb("aa")), true)
  assert_eq(@re_compile.execp(re, @base.sb("aaa")), true)
  // execp searches, so "aaaa" contains "aaa" which matches
  assert_eq(@re_compile.execp(re, @base.sb("aaaa")), true)
  assert_eq(@re_compile.execp(re, @base.sb("b")), false)
}

// === Group translation ===

///|
test "translate group basic" {
  let re = @re_compile.compile(@ast.Ast::group(@ast.Ast::str(@base.sb("abc"))))
  match @re_compile.exec_opt(re, @base.sb("abc")) {
    Some(g) => {
      assert_eq(@re_compile.GroupT::nb_groups(g), 2)
      assert_eq(bs_ct(@re_compile.GroupT::get(g, 0).unwrap()), "abc")
      assert_eq(bs_ct(@re_compile.GroupT::get(g, 1).unwrap()), "abc")
    }
    None => fail("should match")
  }
}

///|
test "translate nested groups" {
  let re = @re_compile.compile(
    @ast.Ast::seq([
      @ast.Ast::group(@ast.Ast::str(@base.sb("a"))),
      @ast.Ast::group(
        @ast.Ast::seq([
          @ast.Ast::str(@base.sb("b")),
          @ast.Ast::group(@ast.Ast::str(@base.sb("c"))),
        ]),
      ),
    ]),
  )
  match @re_compile.exec_opt(re, @base.sb("abc")) {
    Some(g) => {
      assert_eq(@re_compile.GroupT::nb_groups(g), 4)
      assert_eq(bs_ct(@re_compile.GroupT::get(g, 1).unwrap()), "a")
      assert_eq(bs_ct(@re_compile.GroupT::get(g, 2).unwrap()), "bc")
      assert_eq(bs_ct(@re_compile.GroupT::get(g, 3).unwrap()), "c")
    }
    None => fail("should match")
  }
}

///|
test "translate no_group" {
  let re = @re_compile.compile(
    @ast.Ast::no_group(@ast.Ast::group(@ast.Ast::str(@base.sb("a")))),
  )
  match @re_compile.exec_opt(re, @base.sb("a")) {
    Some(g) => assert_eq(@re_compile.GroupT::nb_groups(g), 1)
    None => fail("should match")
  }
}

// === Sem (match semantics) translation ===

///|
test "translate longest" {
  let re = @re_compile.compile(
    @ast.Ast::longest(
      @ast.Ast::seq([
        @ast.Ast::rep(@ast.Ast::str(@base.sb("a"))),
        @ast.Ast::rep(@ast.Ast::str(@base.sb("a"))),
      ]),
    ),
  )
  match @re_compile.exec_opt(re, @base.sb("aaa")) {
    Some(g) => {
      assert_eq(@re_compile.GroupT::start(g, 0), 0)
      assert_eq(@re_compile.GroupT::stop(g, 0), 3)
    }
    None => fail("should match")
  }
}

///|
test "translate shortest" {
  let re = @re_compile.compile(
    @ast.Ast::shortest(
      @ast.Ast::seq([
        @ast.Ast::rep(@ast.Ast::str(@base.sb("a"))),
        @ast.Ast::rep(@ast.Ast::str(@base.sb("a"))),
      ]),
    ),
  )
  match @re_compile.exec_opt(re, @base.sb("aaa")) {
    Some(g) => assert_eq(@re_compile.GroupT::stop(g, 0), 0)
    None => fail("should match")
  }
}

// === Greedy / NonGreedy ===

///|
test "translate greedy" {
  let re = @re_compile.compile(
    @ast.Ast::greedy(@ast.Ast::rep(@ast.Ast::str(@base.sb("a")))),
  )
  match @re_compile.exec_opt(re, @base.sb("aaa")) {
    Some(g) => assert_eq(@re_compile.GroupT::stop(g, 0), 3)
    None => fail("should match")
  }
}

///|
test "translate non_greedy" {
  let re = @re_compile.compile(
    @ast.Ast::non_greedy(@ast.Ast::rep(@ast.Ast::str(@base.sb("a")))),
  )
  match @re_compile.exec_opt(re, @base.sb("aaa")) {
    Some(g) => assert_eq(@re_compile.GroupT::stop(g, 0), 0)
    None => fail("should match")
  }
}

// === Character sets ===

///|
test "translate cset range" {
  let re = @re_compile.compile(@ast.Ast::cset(@base.Cset::cseq('a', 'z')))
  assert_eq(@re_compile.execp(re, @base.sb("a")), true)
  assert_eq(@re_compile.execp(re, @base.sb("z")), true)
  assert_eq(@re_compile.execp(re, @base.sb("A")), false)
}

///|
test "translate cset digit" {
  let re = @re_compile.compile(@re_compile.Re::digit())
  assert_eq(@re_compile.execp(re, @base.sb("0")), true)
  assert_eq(@re_compile.execp(re, @base.sb("9")), true)
  assert_eq(@re_compile.execp(re, @base.sb("a")), false)
}

///|
test "translate cset inter" {
  let re = @re_compile.compile(
    @ast.Ast::inter([
      @ast.Ast::cset(@base.Cset::cseq('a', 'z')),
      @ast.Ast::cset(@base.Cset::cseq('a', 'm')),
    ]),
  )
  assert_eq(@re_compile.execp(re, @base.sb("a")), true)
  assert_eq(@re_compile.execp(re, @base.sb("m")), true)
  assert_eq(@re_compile.execp(re, @base.sb("n")), false)
}

///|
test "translate cset diff" {
  let re = @re_compile.compile(
    @ast.Ast::diff(
      @ast.Ast::cset(@base.Cset::cseq('a', 'z')),
      @ast.Ast::cset(@base.Cset::cseq('a', 'm')),
    ),
  )
  assert_eq(@re_compile.execp(re, @base.sb("a")), false)
  assert_eq(@re_compile.execp(re, @base.sb("n")), true)
  assert_eq(@re_compile.execp(re, @base.sb("z")), true)
}

// === Anchors ===

///|
test "translate bol" {
  let re = @re_compile.compile(
    @ast.Ast::seq([@ast.Ast::bol(), @ast.Ast::str(@base.sb("a"))]),
  )
  assert_eq(@re_compile.execp(re, @base.sb("a")), true)
}

///|
test "translate eos" {
  let re = @re_compile.compile(
    @ast.Ast::seq([@ast.Ast::str(@base.sb("a")), @ast.Ast::eos()]),
  )
  assert_eq(@re_compile.execp(re, @base.sb("a")), true)
  assert_eq(@re_compile.execp(re, @base.sb("ab")), false)
}

// === Case modifiers ===

///|
test "translate no_case" {
  let re = @re_compile.compile(
    @ast.Ast::no_case(@ast.Ast::str(@base.sb("hello"))),
  )
  assert_eq(@re_compile.execp(re, @base.sb("HELLO")), true)
  assert_eq(@re_compile.execp(re, @base.sb("hello")), true)
  assert_eq(@re_compile.execp(re, @base.sb("HeLLo")), true)
}

///|
test "translate case" {
  let re = @re_compile.compile(@ast.Ast::case(@ast.Ast::str(@base.sb("hello"))))
  assert_eq(@re_compile.execp(re, @base.sb("hello")), true)
  assert_eq(@re_compile.execp(re, @base.sb("HELLO")), false)
}

// === Nest ===

///|
test "translate nest" {
  let re = @re_compile.compile(
    @ast.Ast::rep1(
      @ast.Ast::nest(
        @ast.Ast::alt([
          @ast.Ast::group(@ast.Ast::str(@base.sb("a"))),
          @ast.Ast::str(@base.sb("b")),
        ]),
      ),
    ),
  )
  match @re_compile.exec_opt(re, @base.sb("ab")) {
    Some(g) => assert_eq(@re_compile.GroupT::get_opt(g, 1), None)
    None => fail("should match")
  }
}
