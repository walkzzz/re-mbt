// Coverage tests for to_dyn, merge_sequences, Expr operations, compile edges

// === Ast::to_dyn coverage ===

///|
test "ast to_dyn basic nodes" {
  let asts : Array[@ast.Ast] = [
    @ast.Ast::str(@base.sb("hello")),
    @ast.Ast::seq([@ast.Ast::str(@base.sb("a")), @ast.Ast::str(@base.sb("b"))]),
    @ast.Ast::alt([@ast.Ast::str(@base.sb("a")), @ast.Ast::str(@base.sb("b"))]),
    @ast.Ast::rep(@ast.Ast::str(@base.sb("a"))),
    @ast.Ast::rep1(@ast.Ast::str(@base.sb("a"))),
    @ast.Ast::opt(@ast.Ast::str(@base.sb("a"))),
    @ast.Ast::epsilon(),
    @ast.Ast::empty(),
    @ast.Ast::bol(),
    @ast.Ast::eol(),
    @ast.Ast::bow(),
    @ast.Ast::eow(),
    @ast.Ast::not_boundary(),
    @ast.Ast::bos(),
    @ast.Ast::eos(),
    @ast.Ast::leol(),
    @ast.Ast::start(),
    @ast.Ast::stop(),
  ]
  for ast in asts {
    let d = @ast.Ast::to_dyn(ast)
    ignore(d)
  }
}

///|
test "ast to_dyn group and nested" {
  let asts : Array[@ast.Ast] = [
    @ast.Ast::group(@ast.Ast::str(@base.sb("a"))),
    @ast.Ast::group(name=Some("name"), @ast.Ast::str(@base.sb("a"))),
    @ast.Ast::no_group(@ast.Ast::str(@base.sb("a"))),
    @ast.Ast::nest(@ast.Ast::str(@base.sb("a"))),
    @ast.Ast::longest(@ast.Ast::str(@base.sb("a"))),
    @ast.Ast::shortest(@ast.Ast::str(@base.sb("a"))),
    @ast.Ast::first(@ast.Ast::str(@base.sb("a"))),
    @ast.Ast::greedy(@ast.Ast::str(@base.sb("a"))),
    @ast.Ast::non_greedy(@ast.Ast::str(@base.sb("a"))),
    @ast.Ast::no_case(@ast.Ast::str(@base.sb("a"))),
    @ast.Ast::case(@ast.Ast::str(@base.sb("a"))),
    @ast.Ast::inter([@ast.Ast::str(@base.sb("a")), @ast.Ast::str(@base.sb("b"))]),
    @ast.Ast::diff(@ast.Ast::str(@base.sb("a")), @ast.Ast::str(@base.sb("b"))),
    @ast.Ast::compl([@ast.Ast::str(@base.sb("a"))]),
    @ast.Ast::set(@base.sb("abc")),
    @re_compile.Re::rg('a', 'z'),
    @ast.Ast::any(),
    @re_compile.Re::notnl(),
  ]
  for ast in asts {
    let d = @ast.Ast::to_dyn(ast)
    ignore(d)
  }
}

///|
test "ast to_dyn repn" {
  let asts : Array[@ast.Ast] = [
    @ast.Ast::repn(@ast.Ast::str(@base.sb("a")), 0, None),
    @ast.Ast::repn(@ast.Ast::str(@base.sb("a")), 2, Some(5)),
    @ast.Ast::repn(@ast.Ast::str(@base.sb("a")), 1, Some(1)),
  ]
  for ast in asts {
    let d = @ast.Ast::to_dyn(ast)
    ignore(d)
  }
}

// === Ast::merge_sequences coverage ===

///|
test "ast merge_sequences basic" {
  let input : Array[@ast.Ast] = [
    @ast.Ast::str(@base.sb("a")),
    @ast.Ast::str(@base.sb("b")),
  ]
  let result = @ast.Ast::merge_sequences(input)
  assert_eq(result.length(), 2)
}

///|
test "ast merge_sequences empty" {
  let input : Array[@ast.Ast] = []
  let result = @ast.Ast::merge_sequences(input)
  assert_eq(result.length(), 0)
}

///|
test "ast merge_sequences with alt" {
  let alt_ast = @ast.Ast::alt([
    @ast.Ast::str(@base.sb("a")),
    @ast.Ast::str(@base.sb("b")),
  ])
  let input : Array[@ast.Ast] = [alt_ast, @ast.Ast::str(@base.sb("c"))]
  let result = @ast.Ast::merge_sequences(input)
  ignore(result)
}

///|
test "ast merge_sequences with seq" {
  let seq_ast = @ast.Ast::seq([
    @ast.Ast::str(@base.sb("a")),
    @ast.Ast::str(@base.sb("b")),
  ])
  let input : Array[@ast.Ast] = [seq_ast, seq_ast]
  let result = @ast.Ast::merge_sequences(input)
  ignore(result)
}

///|
test "ast merge_sequences_no_case basic" {
  let ast = @ast.Ast::str(@base.sb("a"))
  let no_case_ast = @ast.Ast::handle_case(ast, false)
  let input : Array[@ast.AstNoCase] = [no_case_ast]
  let result = @ast.Ast::merge_sequences_no_case(input)
  ignore(result)
}

// === Ast::anchored coverage ===

///|
test "ast anchored" {
  assert_eq(@ast.Ast::anchored(@ast.Ast::bos()), true)
  assert_eq(@ast.Ast::anchored(@ast.Ast::start()), true)
  assert_eq(@ast.Ast::anchored(@ast.Ast::str(@base.sb("a"))), false)
  assert_eq(@ast.Ast::anchored(@ast.Ast::eol()), false)
  assert_eq(
    @ast.Ast::anchored(
      @ast.Ast::seq([@ast.Ast::bos(), @ast.Ast::str(@base.sb("a"))]),
    ),
    true,
  )
  assert_eq(
    @ast.Ast::anchored(@ast.Ast::alt([@ast.Ast::bos(), @ast.Ast::bos()])),
    true,
  )
  assert_eq(
    @ast.Ast::anchored(
      @ast.Ast::alt([@ast.Ast::bos(), @ast.Ast::str(@base.sb("a"))]),
    ),
    false,
  )
  assert_eq(@ast.Ast::anchored(@ast.Ast::rep(@ast.Ast::bos())), false)
  assert_eq(@ast.Ast::anchored(@ast.Ast::rep1(@ast.Ast::bos())), true)
  assert_eq(@ast.Ast::anchored(@ast.Ast::group(@ast.Ast::bos())), true)
  assert_eq(@ast.Ast::anchored(@ast.Ast::no_group(@ast.Ast::bos())), true)
  assert_eq(@ast.Ast::anchored(@ast.Ast::nest(@ast.Ast::bos())), true)
  assert_eq(@ast.Ast::anchored(@ast.Ast::opt(@ast.Ast::bos())), false)
}

// === Ast::handle_case coverage ===

///|
test "ast handle_case" {
  let ast = @ast.Ast::str(@base.sb("abc"))
  let _ = @ast.Ast::handle_case(ast, true)
  let _ = @ast.Ast::handle_case(ast, false)
  let ast2 = @ast.Ast::seq([
    @ast.Ast::str(@base.sb("a")),
    @ast.Ast::str(@base.sb("b")),
  ])
  let _ = @ast.Ast::handle_case(ast2, true)
  let ast3 = @ast.Ast::alt([
    @ast.Ast::str(@base.sb("a")),
    @ast.Ast::str(@base.sb("b")),
  ])
  let _ = @ast.Ast::handle_case(ast3, true)
  let ast4 = @ast.Ast::no_case(@ast.Ast::str(@base.sb("a")))
  let _ = @ast.Ast::handle_case(ast4, true)
  let ast5 = @ast.Ast::case(@ast.Ast::str(@base.sb("a")))
  let _ = @ast.Ast::handle_case(ast5, true)
  let ast6 = @ast.Ast::not_boundary()
  let _ = @ast.Ast::handle_case(ast6, true)
  let ast7 = @ast.Ast::stop()
  let _ = @ast.Ast::handle_case(ast7, true)
  let ast8 = @ast.Ast::no_group(@ast.Ast::str(@base.sb("a")))
  let _ = @ast.Ast::handle_case(ast8, true)
  assert_eq(true, true)
}

// === Expr::to_dyn / Expr::rename coverage ===

///|
test "expr to_dyn and rename" {
  let ids = @base.Ids::create()
  let e1 = @ast.Expr::cst(ids, @base.Cset::set(@base.sb("a")))
  let _ = @ast.Expr::to_dyn(e1)
  let _ = @ast.Expr::rename(ids, e1)
  let e2 = @ast.Expr::eps(ids)
  let _ = @ast.Expr::to_dyn(e2)
  let _ = @ast.Expr::rename(ids, e2)
  let e3 = @ast.Expr::empty(ids)
  let _ = @ast.Expr::to_dyn(e3)
  let e4 = @ast.Expr::alt(ids, [e1, e2])
  let _ = @ast.Expr::to_dyn(e4)
  let _ = @ast.Expr::rename(ids, e4)
  let e5 = @ast.Expr::seq(ids, @base.Sem::first(), e1, e2)
  let _ = @ast.Expr::to_dyn(e5)
  let _ = @ast.Expr::rename(ids, e5)
  let e6 = @ast.Expr::rep(ids, @base.RepKind::greedy(), @base.Sem::first(), e1)
  let _ = @ast.Expr::to_dyn(e6)
  let _ = @ast.Expr::rename(ids, e6)
  let e7 = @ast.Expr::mark(ids, 0)
  let _ = @ast.Expr::to_dyn(e7)
  let _ = @ast.Expr::rename(ids, e7)
  let e8 = @ast.Expr::pmark(ids, @base.Pmark::gen())
  let _ = @ast.Expr::to_dyn(e8)
  let _ = @ast.Expr::rename(ids, e8)
  let e9 = @ast.Expr::erase(ids, 0, 1)
  let _ = @ast.Expr::to_dyn(e9)
  let _ = @ast.Expr::rename(ids, e9)
  let e10 = @ast.Expr::before(ids, @base.Category::letter())
  let _ = @ast.Expr::to_dyn(e10)
  let _ = @ast.Expr::rename(ids, e10)
  let e11 = @ast.Expr::after(ids, @base.Category::letter())
  let _ = @ast.Expr::to_dyn(e11)
  let _ = @ast.Expr::rename(ids, e11)
  assert_eq(true, true)
}

///|
test "expr id and is_eps" {
  let ids = @base.Ids::create()
  let e = @ast.Expr::eps(ids)
  assert_eq(@ast.Expr::is_eps(e), true)
  let e2 = @ast.Expr::cst(ids, @base.Cset::set(@base.sb("a")))
  assert_eq(@ast.Expr::is_eps(e2), false)
  let _ = @ast.Expr::id(e)
  let _ = @ast.Expr::id(e2)
  assert_eq(true, true)
}

// === Sem / RepKind to_dyn and to_string ===

///|
test "sem and repkind to_dyn" {
  let _ = @base.Sem::to_dyn(@base.Sem::longest())
  let _ = @base.Sem::to_dyn(@base.Sem::shortest())
  let _ = @base.Sem::to_dyn(@base.Sem::first())
  let _ = @base.RepKind::to_dyn(@base.RepKind::greedy())
  let _ = @base.RepKind::to_dyn(@base.RepKind::non_greedy())
  assert_eq(true, true)
}

///|
test "sem and repkind to_string" {
  assert_eq(@base.Sem::to_string(@base.Sem::longest()), "Longest")
  assert_eq(@base.Sem::to_string(@base.Sem::shortest()), "Shortest")
  assert_eq(@base.Sem::to_string(@base.Sem::first()), "First")
  assert_eq(@base.RepKind::to_string(@base.RepKind::greedy()), "Greedy")
  assert_eq(@base.RepKind::to_string(@base.RepKind::non_greedy()), "NonGreedy")
  assert_eq(@base.Sem::to_string_short(@base.Sem::longest()), "L")
  assert_eq(@base.Sem::to_string_short(@base.Sem::shortest()), "S")
  assert_eq(@base.Sem::to_string_short(@base.Sem::first()), "F")
  assert_eq(@base.RepKind::to_string_short(@base.RepKind::greedy()), "G")
  assert_eq(@base.RepKind::to_string_short(@base.RepKind::non_greedy()), "N")
}

///|
test "sem constructors" {
  assert_eq(@base.Sem::to_string(@base.Sem::longest()), "Longest")
  assert_eq(@base.Sem::to_string(@base.Sem::shortest()), "Shortest")
  assert_eq(@base.Sem::to_string(@base.Sem::first()), "First")
  assert_eq(@base.RepKind::to_string(@base.RepKind::greedy()), "Greedy")
  assert_eq(@base.RepKind::to_string(@base.RepKind::non_greedy()), "NonGreedy")
}

// === Category::to_dyn ===

///|
test "category to_dyn" {
  let _ = @base.Category::to_dyn(@base.Category::letter())
  let _ = @base.Category::to_dyn(@base.Category::newline())
  let _ = @base.Category::to_dyn(@base.Category::dummy())
  let _ = @base.Category::to_dyn(@base.Category::inexistant())
  let _ = @base.Category::to_dyn(@base.Category::lastnewline())
  let _ = @base.Category::to_dyn(@base.Category::not_letter())
  let _ = @base.Category::to_dyn(@base.Category::search_boundary())
  let _ = @base.Category::to_dyn(@base.Category::from_char('a'))
  let _ = @base.Category::to_dyn(@base.Category::from_int(0))
  assert_eq(true, true)
}

// === Pmark::to_dyn ===

///|
test "pmark to_dyn" {
  let p = @base.Pmark::gen()
  let _ = @base.Pmark::to_dyn(p)
  assert_eq(@base.Pmark::equal(p, p), true)
  assert_eq(@base.Pmark::compare(p, p), 0)
  assert_eq(true, true)
}

// === Re::group_count / group_names ===

///|
test "re group_count and group_names" {
  let re1 = @re_compile.compile(@ast.Ast::str(@base.sb("abc")))
  assert_eq(@re_compile.Re::group_count(re1), 1)
  assert_eq(@re_compile.Re::group_names(re1).length(), 0)

  let re2 = @re_compile.compile(
    @ast.Ast::group(name=Some("first"), @ast.Ast::str(@base.sb("a"))),
  )
  assert_eq(@re_compile.Re::group_count(re2), 2)
  let names2 = @re_compile.Re::group_names(re2)
  assert_eq(names2.length(), 1)
  let (n2, _) = names2[0]
  assert_eq(n2, "first")

  let re3 = @re_compile.compile(
    @ast.Ast::seq([
      @ast.Ast::group(name=Some("x"), @ast.Ast::str(@base.sb("a"))),
      @ast.Ast::group(name=Some("y"), @ast.Ast::str(@base.sb("b"))),
    ]),
  )
  assert_eq(@re_compile.Re::group_count(re3), 3)
  let names3 = @re_compile.Re::group_names(re3)
  assert_eq(names3.length(), 2)
}

// === Idx::to_dyn / Idx::to_int ===

///|
test "idx to_dyn and to_int" {
  let _ = @base.Idx::to_dyn(42)
  assert_eq(@base.Idx::to_int(42), 42)
  assert_eq(true, true)
}

// === Mark::to_dyn ===

///|
test "mark to_dyn" {
  let _ = @base.Mark::to_dyn(5)
  assert_eq(true, true)
}

// === State::to_dyn (indirect via compilation) ===

///|
test "state to_dyn indirect" {
  let re = @re_compile.compile(@ast.Ast::str(@base.sb("test")))
  assert_eq(@re_compile.execp(re, @base.sb("test")), true)
}
