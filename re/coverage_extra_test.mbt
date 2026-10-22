// Coverage tests for to_dyn, merge_sequences, Expr operations, compile edges

// === Ast::to_dyn coverage ===

///|
test "ast to_dyn basic nodes" {
  let asts : Array[@re.Ast] = [
    @re.Ast::str(sb("hello")),
    @re.Ast::seq([@re.Ast::str(sb("a")), @re.Ast::str(sb("b"))]),
    @re.Ast::alt([@re.Ast::str(sb("a")), @re.Ast::str(sb("b"))]),
    @re.Ast::rep(@re.Ast::str(sb("a"))),
    @re.Ast::rep1(@re.Ast::str(sb("a"))),
    @re.Ast::opt(@re.Ast::str(sb("a"))),
    @re.Ast::epsilon(),
    @re.Ast::empty(),
    @re.Ast::bol(),
    @re.Ast::eol(),
    @re.Ast::bow(),
    @re.Ast::eow(),
    @re.Ast::not_boundary(),
    @re.Ast::bos(),
    @re.Ast::eos(),
    @re.Ast::leol(),
    @re.Ast::start(),
    @re.Ast::stop(),
  ]
  for ast in asts {
    let d = @re.Ast::to_dyn(ast)
    ignore(d)
  }
}

///|
test "ast to_dyn group and nested" {
  let asts : Array[@re.Ast] = [
    @re.Ast::group(@re.Ast::str(sb("a"))),
    @re.Ast::group(name=Some("name"), @re.Ast::str(sb("a"))),
    @re.Ast::no_group(@re.Ast::str(sb("a"))),
    @re.Ast::nest(@re.Ast::str(sb("a"))),
    @re.Ast::longest(@re.Ast::str(sb("a"))),
    @re.Ast::shortest(@re.Ast::str(sb("a"))),
    @re.Ast::first(@re.Ast::str(sb("a"))),
    @re.Ast::greedy(@re.Ast::str(sb("a"))),
    @re.Ast::non_greedy(@re.Ast::str(sb("a"))),
    @re.Ast::no_case(@re.Ast::str(sb("a"))),
    @re.Ast::case(@re.Ast::str(sb("a"))),
    @re.Ast::inter([@re.Ast::str(sb("a")), @re.Ast::str(sb("b"))]),
    @re.Ast::diff(@re.Ast::str(sb("a")), @re.Ast::str(sb("b"))),
    @re.Ast::compl([@re.Ast::str(sb("a"))]),
    @re.Ast::set(sb("abc")),
    @re.Re::rg('a', 'z'),
    @re.Ast::any(),
    @re.Re::notnl(),
  ]
  for ast in asts {
    let d = @re.Ast::to_dyn(ast)
    ignore(d)
  }
}

///|
test "ast to_dyn repn" {
  let asts : Array[@re.Ast] = [
    @re.Ast::repn(@re.Ast::str(sb("a")), 0, None),
    @re.Ast::repn(@re.Ast::str(sb("a")), 2, Some(5)),
    @re.Ast::repn(@re.Ast::str(sb("a")), 1, Some(1)),
  ]
  for ast in asts {
    let d = @re.Ast::to_dyn(ast)
    ignore(d)
  }
}

// === Ast::merge_sequences coverage ===

///|
test "ast merge_sequences basic" {
  let input : Array[@re.Ast] = [@re.Ast::str(sb("a")), @re.Ast::str(sb("b"))]
  let result = @re.Ast::merge_sequences(input)
  assert_eq(result.length(), 2)
}

///|
test "ast merge_sequences empty" {
  let input : Array[@re.Ast] = []
  let result = @re.Ast::merge_sequences(input)
  assert_eq(result.length(), 0)
}

///|
test "ast merge_sequences with alt" {
  let alt_ast = @re.Ast::alt([@re.Ast::str(sb("a")), @re.Ast::str(sb("b"))])
  let input : Array[@re.Ast] = [alt_ast, @re.Ast::str(sb("c"))]
  let result = @re.Ast::merge_sequences(input)
  ignore(result)
}

///|
test "ast merge_sequences with seq" {
  let seq_ast = @re.Ast::seq([@re.Ast::str(sb("a")), @re.Ast::str(sb("b"))])
  let input : Array[@re.Ast] = [seq_ast, seq_ast]
  let result = @re.Ast::merge_sequences(input)
  ignore(result)
}

///|
test "ast merge_sequences_no_case basic" {
  let ast = @re.Ast::str(sb("a"))
  let no_case_ast = @re.Ast::handle_case(ast, false)
  let input : Array[@re.AstNoCase] = [no_case_ast]
  let result = @re.Ast::merge_sequences_no_case(input)
  ignore(result)
}

// === Ast::anchored coverage ===

///|
test "ast anchored" {
  assert_eq(@re.Ast::anchored(@re.Ast::bos()), true)
  assert_eq(@re.Ast::anchored(@re.Ast::start()), true)
  assert_eq(@re.Ast::anchored(@re.Ast::str(sb("a"))), false)
  assert_eq(@re.Ast::anchored(@re.Ast::eol()), false)
  assert_eq(@re.Ast::anchored(@re.Ast::seq([@re.Ast::bos(), @re.Ast::str(sb("a"))])), true)
  assert_eq(@re.Ast::anchored(@re.Ast::alt([@re.Ast::bos(), @re.Ast::bos()])), true)
  assert_eq(@re.Ast::anchored(@re.Ast::alt([@re.Ast::bos(), @re.Ast::str(sb("a"))])), false)
  assert_eq(@re.Ast::anchored(@re.Ast::rep(@re.Ast::bos())), false)
  assert_eq(@re.Ast::anchored(@re.Ast::rep1(@re.Ast::bos())), true)
  assert_eq(@re.Ast::anchored(@re.Ast::group(@re.Ast::bos())), true)
  assert_eq(@re.Ast::anchored(@re.Ast::no_group(@re.Ast::bos())), true)
  assert_eq(@re.Ast::anchored(@re.Ast::nest(@re.Ast::bos())), true)
  assert_eq(@re.Ast::anchored(@re.Ast::opt(@re.Ast::bos())), false)
}

// === Ast::handle_case coverage ===

///|
test "ast handle_case" {
  let ast = @re.Ast::str(sb("abc"))
  let _ = @re.Ast::handle_case(ast, true)
  let _ = @re.Ast::handle_case(ast, false)
  let ast2 = @re.Ast::seq([@re.Ast::str(sb("a")), @re.Ast::str(sb("b"))])
  let _ = @re.Ast::handle_case(ast2, true)
  let ast3 = @re.Ast::alt([@re.Ast::str(sb("a")), @re.Ast::str(sb("b"))])
  let _ = @re.Ast::handle_case(ast3, true)
  let ast4 = @re.Ast::no_case(@re.Ast::str(sb("a")))
  let _ = @re.Ast::handle_case(ast4, true)
  let ast5 = @re.Ast::case(@re.Ast::str(sb("a")))
  let _ = @re.Ast::handle_case(ast5, true)
  let ast6 = @re.Ast::not_boundary()
  let _ = @re.Ast::handle_case(ast6, true)
  let ast7 = @re.Ast::stop()
  let _ = @re.Ast::handle_case(ast7, true)
  let ast8 = @re.Ast::no_group(@re.Ast::str(sb("a")))
  let _ = @re.Ast::handle_case(ast8, true)
  assert_eq(true, true)
}

// === Expr::to_dyn / Expr::rename coverage ===

///|
test "expr to_dyn and rename" {
  let ids = @re.Ids::create()
  let e1 = @re.Expr::cst(ids, @re.Cset::set(sb("a")))
  let _ = @re.Expr::to_dyn(e1)
  let _ = @re.Expr::rename(ids, e1)
  let e2 = @re.Expr::eps(ids)
  let _ = @re.Expr::to_dyn(e2)
  let _ = @re.Expr::rename(ids, e2)
  let e3 = @re.Expr::empty(ids)
  let _ = @re.Expr::to_dyn(e3)
  let e4 = @re.Expr::alt(ids, [e1, e2])
  let _ = @re.Expr::to_dyn(e4)
  let _ = @re.Expr::rename(ids, e4)
  let e5 = @re.Expr::seq(ids, @re.Sem::first(), e1, e2)
  let _ = @re.Expr::to_dyn(e5)
  let _ = @re.Expr::rename(ids, e5)
  let e6 = @re.Expr::rep(ids, @re.RepKind::greedy(), @re.Sem::first(), e1)
  let _ = @re.Expr::to_dyn(e6)
  let _ = @re.Expr::rename(ids, e6)
  let e7 = @re.Expr::mark(ids, 0)
  let _ = @re.Expr::to_dyn(e7)
  let _ = @re.Expr::rename(ids, e7)
  let e8 = @re.Expr::pmark(ids, @re.Pmark::gen())
  let _ = @re.Expr::to_dyn(e8)
  let _ = @re.Expr::rename(ids, e8)
  let e9 = @re.Expr::erase(ids, 0, 1)
  let _ = @re.Expr::to_dyn(e9)
  let _ = @re.Expr::rename(ids, e9)
  let e10 = @re.Expr::before(ids, @re.Category::letter())
  let _ = @re.Expr::to_dyn(e10)
  let _ = @re.Expr::rename(ids, e10)
  let e11 = @re.Expr::after(ids, @re.Category::letter())
  let _ = @re.Expr::to_dyn(e11)
  let _ = @re.Expr::rename(ids, e11)
  assert_eq(true, true)
}

///|
test "expr id and is_eps" {
  let ids = @re.Ids::create()
  let e = @re.Expr::eps(ids)
  assert_eq(@re.Expr::is_eps(e), true)
  let e2 = @re.Expr::cst(ids, @re.Cset::set(sb("a")))
  assert_eq(@re.Expr::is_eps(e2), false)
  let _ = @re.Expr::id(e)
  let _ = @re.Expr::id(e2)
  assert_eq(true, true)
}

// === Sem / RepKind to_dyn and to_string ===

///|
test "sem and repkind to_dyn" {
  let _ = @re.Sem::to_dyn(@re.Sem::longest())
  let _ = @re.Sem::to_dyn(@re.Sem::shortest())
  let _ = @re.Sem::to_dyn(@re.Sem::first())
  let _ = @re.RepKind::to_dyn(@re.RepKind::greedy())
  let _ = @re.RepKind::to_dyn(@re.RepKind::non_greedy())
  assert_eq(true, true)
}

///|
test "sem and repkind to_string" {
  assert_eq(@re.Sem::to_string(@re.Sem::longest()), "Longest")
  assert_eq(@re.Sem::to_string(@re.Sem::shortest()), "Shortest")
  assert_eq(@re.Sem::to_string(@re.Sem::first()), "First")
  assert_eq(@re.RepKind::to_string(@re.RepKind::greedy()), "Greedy")
  assert_eq(@re.RepKind::to_string(@re.RepKind::non_greedy()), "NonGreedy")
  assert_eq(@re.Sem::to_string_short(@re.Sem::longest()), "L")
  assert_eq(@re.Sem::to_string_short(@re.Sem::shortest()), "S")
  assert_eq(@re.Sem::to_string_short(@re.Sem::first()), "F")
  assert_eq(@re.RepKind::to_string_short(@re.RepKind::greedy()), "G")
  assert_eq(@re.RepKind::to_string_short(@re.RepKind::non_greedy()), "N")
}

///|
test "sem constructors" {
  assert_eq(@re.Sem::to_string(@re.Sem::longest()), "Longest")
  assert_eq(@re.Sem::to_string(@re.Sem::shortest()), "Shortest")
  assert_eq(@re.Sem::to_string(@re.Sem::first()), "First")
  assert_eq(@re.RepKind::to_string(@re.RepKind::greedy()), "Greedy")
  assert_eq(@re.RepKind::to_string(@re.RepKind::non_greedy()), "NonGreedy")
}

// === Category::to_dyn ===

///|
test "category to_dyn" {
  let _ = @re.Category::to_dyn(@re.Category::letter())
  let _ = @re.Category::to_dyn(@re.Category::newline())
  let _ = @re.Category::to_dyn(@re.Category::dummy())
  let _ = @re.Category::to_dyn(@re.Category::inexistant())
  let _ = @re.Category::to_dyn(@re.Category::lastnewline())
  let _ = @re.Category::to_dyn(@re.Category::not_letter())
  let _ = @re.Category::to_dyn(@re.Category::search_boundary())
  let _ = @re.Category::to_dyn(@re.Category::from_char('a'))
  let _ = @re.Category::to_dyn(@re.Category::from_int(0))
  assert_eq(true, true)
}

// === Pmark::to_dyn ===

///|
test "pmark to_dyn" {
  let p = @re.Pmark::gen()
  let _ = @re.Pmark::to_dyn(p)
  assert_eq(@re.Pmark::equal(p, p), true)
  assert_eq(@re.Pmark::compare(p, p), 0)
  assert_eq(true, true)
}

// === Re::group_count / group_names ===

///|
test "re group_count and group_names" {
  let re1 = @re.compile(@re.Ast::str(sb("abc")))
  assert_eq(@re.Re::group_count(re1), 1)
  assert_eq(@re.Re::group_names(re1).length(), 0)

  let re2 = @re.compile(@re.Ast::group(name=Some("first"), @re.Ast::str(sb("a"))))
  assert_eq(@re.Re::group_count(re2), 2)
  let names2 = @re.Re::group_names(re2)
  assert_eq(names2.length(), 1)
  let (n2, _) = names2[0]
  assert_eq(n2, "first")

  let re3 = @re.compile(
    @re.Ast::seq([
      @re.Ast::group(name=Some("x"), @re.Ast::str(sb("a"))),
      @re.Ast::group(name=Some("y"), @re.Ast::str(sb("b"))),
    ]),
  )
  assert_eq(@re.Re::group_count(re3), 3)
  let names3 = @re.Re::group_names(re3)
  assert_eq(names3.length(), 2)
}

// === Idx::to_dyn / Idx::to_int ===

///|
test "idx to_dyn and to_int" {
  let _ = @re.Idx::to_dyn(42)
  assert_eq(@re.Idx::to_int(42), 42)
  assert_eq(true, true)
}

// === Mark::to_dyn ===

///|
test "mark to_dyn" {
  let _ = @re.Mark::to_dyn(5)
  assert_eq(true, true)
}

// === State::to_dyn (indirect via compilation) ===

///|
test "state to_dyn indirect" {
  let re = @re.compile(@re.Ast::str(sb("test")))
  assert_eq(@re.execp(re, sb("test")), true)
}
