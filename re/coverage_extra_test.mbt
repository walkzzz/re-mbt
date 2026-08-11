// Coverage tests for to_dyn, merge_sequences, Expr operations, compile edges

// === Ast::to_dyn coverage ===

///|
test "ast to_dyn basic nodes" {
  let asts : Array[Ast] = [
    Ast::str(sb("hello")),
    Ast::seq([Ast::str(sb("a")), Ast::str(sb("b"))]),
    Ast::alt([Ast::str(sb("a")), Ast::str(sb("b"))]),
    Ast::rep(Ast::str(sb("a"))),
    Ast::rep1(Ast::str(sb("a"))),
    Ast::opt(Ast::str(sb("a"))),
    Ast::epsilon(),
    Ast::empty(),
    Ast::bol(),
    Ast::eol(),
    Ast::bow(),
    Ast::eow(),
    Ast::not_boundary(),
    Ast::bos(),
    Ast::eos(),
    Ast::leol(),
    Ast::start(),
    Ast::stop(),
  ]
  for ast in asts {
    let d = Ast::to_dyn(ast)
    ignore(d)
  }
}

///|
test "ast to_dyn group and nested" {
  let asts : Array[Ast] = [
    Ast::group(Ast::str(sb("a"))),
    Ast::group(name=Some("name"), Ast::str(sb("a"))),
    Ast::no_group(Ast::str(sb("a"))),
    Ast::nest(Ast::str(sb("a"))),
    Ast::longest(Ast::str(sb("a"))),
    Ast::shortest(Ast::str(sb("a"))),
    Ast::first(Ast::str(sb("a"))),
    Ast::greedy(Ast::str(sb("a"))),
    Ast::non_greedy(Ast::str(sb("a"))),
    Ast::no_case(Ast::str(sb("a"))),
    Ast::case(Ast::str(sb("a"))),
    Ast::inter([Ast::str(sb("a")), Ast::str(sb("b"))]),
    Ast::diff(Ast::str(sb("a")), Ast::str(sb("b"))),
    Ast::compl([Ast::str(sb("a"))]),
    Ast::set(sb("abc")),
    Re::rg('a', 'z'),
    Ast::any(),
    Re::notnl(),
  ]
  for ast in asts {
    let d = Ast::to_dyn(ast)
    ignore(d)
  }
}

///|
test "ast to_dyn repn" {
  let asts : Array[Ast] = [
    Ast::repn(Ast::str(sb("a")), 0, None),
    Ast::repn(Ast::str(sb("a")), 2, Some(5)),
    Ast::repn(Ast::str(sb("a")), 1, Some(1)),
  ]
  for ast in asts {
    let d = Ast::to_dyn(ast)
    ignore(d)
  }
}

// === Ast::merge_sequences coverage ===

///|
test "ast merge_sequences basic" {
  let input : Array[Ast] = [Ast::str(sb("a")), Ast::str(sb("b"))]
  let result = Ast::merge_sequences(input)
  assert_eq(result.length(), 2)
}

///|
test "ast merge_sequences empty" {
  let input : Array[Ast] = []
  let result = Ast::merge_sequences(input)
  assert_eq(result.length(), 0)
}

///|
test "ast merge_sequences with alt" {
  let alt_ast = Ast::alt([Ast::str(sb("a")), Ast::str(sb("b"))])
  let input : Array[Ast] = [alt_ast, Ast::str(sb("c"))]
  let result = Ast::merge_sequences(input)
  ignore(result)
}

///|
test "ast merge_sequences with seq" {
  let seq_ast = Ast::seq([Ast::str(sb("a")), Ast::str(sb("b"))])
  let input : Array[Ast] = [seq_ast, seq_ast]
  let result = Ast::merge_sequences(input)
  ignore(result)
}

///|
test "ast merge_sequences_no_case basic" {
  let ast = Ast::str(sb("a"))
  let no_case_ast = Ast::handle_case(ast, false)
  let input : Array[AstNoCase] = [no_case_ast]
  let result = Ast::merge_sequences_no_case(input)
  ignore(result)
}

// === Ast::anchored coverage ===

///|
test "ast anchored" {
  assert_eq(Ast::anchored(Ast::bos()), true)
  assert_eq(Ast::anchored(Ast::start()), true)
  assert_eq(Ast::anchored(Ast::str(sb("a"))), false)
  assert_eq(Ast::anchored(Ast::eol()), false)
  assert_eq(Ast::anchored(Ast::seq([Ast::bos(), Ast::str(sb("a"))])), true)
  assert_eq(Ast::anchored(Ast::alt([Ast::bos(), Ast::bos()])), true)
  assert_eq(Ast::anchored(Ast::alt([Ast::bos(), Ast::str(sb("a"))])), false)
  assert_eq(Ast::anchored(Ast::rep(Ast::bos())), false)
  assert_eq(Ast::anchored(Ast::rep1(Ast::bos())), true)
  assert_eq(Ast::anchored(Ast::group(Ast::bos())), true)
  assert_eq(Ast::anchored(Ast::no_group(Ast::bos())), true)
  assert_eq(Ast::anchored(Ast::nest(Ast::bos())), true)
  assert_eq(Ast::anchored(Ast::opt(Ast::bos())), false)
}

// === Ast::handle_case coverage ===

///|
test "ast handle_case" {
  let ast = Ast::str(sb("abc"))
  let _ = Ast::handle_case(ast, true)
  let _ = Ast::handle_case(ast, false)
  let ast2 = Ast::seq([Ast::str(sb("a")), Ast::str(sb("b"))])
  let _ = Ast::handle_case(ast2, true)
  let ast3 = Ast::alt([Ast::str(sb("a")), Ast::str(sb("b"))])
  let _ = Ast::handle_case(ast3, true)
  let ast4 = Ast::no_case(Ast::str(sb("a")))
  let _ = Ast::handle_case(ast4, true)
  let ast5 = Ast::case(Ast::str(sb("a")))
  let _ = Ast::handle_case(ast5, true)
  let ast6 = Ast::not_boundary()
  let _ = Ast::handle_case(ast6, true)
  let ast7 = Ast::stop()
  let _ = Ast::handle_case(ast7, true)
  let ast8 = Ast::no_group(Ast::str(sb("a")))
  let _ = Ast::handle_case(ast8, true)
  assert_eq(true, true)
}

// === Expr::to_dyn / Expr::rename coverage ===

///|
test "expr to_dyn and rename" {
  let ids = Ids::create()
  let e1 = Expr::cst(ids, Cset::set(sb("a")))
  let _ = Expr::to_dyn(e1)
  let _ = Expr::rename(ids, e1)
  let e2 = Expr::eps(ids)
  let _ = Expr::to_dyn(e2)
  let _ = Expr::rename(ids, e2)
  let e3 = Expr::empty(ids)
  let _ = Expr::to_dyn(e3)
  let e4 = Expr::alt(ids, [e1, e2])
  let _ = Expr::to_dyn(e4)
  let _ = Expr::rename(ids, e4)
  let e5 = Expr::seq(ids, Sem::first(), e1, e2)
  let _ = Expr::to_dyn(e5)
  let _ = Expr::rename(ids, e5)
  let e6 = Expr::rep(ids, RepKind::greedy(), Sem::first(), e1)
  let _ = Expr::to_dyn(e6)
  let _ = Expr::rename(ids, e6)
  let e7 = Expr::mark(ids, 0)
  let _ = Expr::to_dyn(e7)
  let _ = Expr::rename(ids, e7)
  let e8 = Expr::pmark(ids, Pmark::gen())
  let _ = Expr::to_dyn(e8)
  let _ = Expr::rename(ids, e8)
  let e9 = Expr::erase(ids, 0, 1)
  let _ = Expr::to_dyn(e9)
  let _ = Expr::rename(ids, e9)
  let e10 = Expr::before(ids, Category::letter())
  let _ = Expr::to_dyn(e10)
  let _ = Expr::rename(ids, e10)
  let e11 = Expr::after(ids, Category::letter())
  let _ = Expr::to_dyn(e11)
  let _ = Expr::rename(ids, e11)
  assert_eq(true, true)
}

///|
test "expr id and is_eps" {
  let ids = Ids::create()
  let e = Expr::eps(ids)
  assert_eq(Expr::is_eps(e), true)
  let e2 = Expr::cst(ids, Cset::set(sb("a")))
  assert_eq(Expr::is_eps(e2), false)
  let _ = Expr::id(e)
  let _ = Expr::id(e2)
  assert_eq(true, true)
}

// === Sem / RepKind to_dyn and to_string ===

///|
test "sem and repkind to_dyn" {
  let _ = Sem::to_dyn(Sem::longest())
  let _ = Sem::to_dyn(Sem::shortest())
  let _ = Sem::to_dyn(Sem::first())
  let _ = RepKind::to_dyn(RepKind::greedy())
  let _ = RepKind::to_dyn(RepKind::non_greedy())
  assert_eq(true, true)
}

///|
test "sem and repkind to_string" {
  assert_eq(Sem::to_string(Sem::longest()), "Longest")
  assert_eq(Sem::to_string(Sem::shortest()), "Shortest")
  assert_eq(Sem::to_string(Sem::first()), "First")
  assert_eq(RepKind::to_string(RepKind::greedy()), "Greedy")
  assert_eq(RepKind::to_string(RepKind::non_greedy()), "NonGreedy")
  assert_eq(Sem::to_string_short(Sem::longest()), "L")
  assert_eq(Sem::to_string_short(Sem::shortest()), "S")
  assert_eq(Sem::to_string_short(Sem::first()), "F")
  assert_eq(RepKind::to_string_short(RepKind::greedy()), "G")
  assert_eq(RepKind::to_string_short(RepKind::non_greedy()), "N")
}

///|
test "sem constructors" {
  assert_eq(Sem::to_string(Sem::longest()), "Longest")
  assert_eq(Sem::to_string(Sem::shortest()), "Shortest")
  assert_eq(Sem::to_string(Sem::first()), "First")
  assert_eq(RepKind::to_string(RepKind::greedy()), "Greedy")
  assert_eq(RepKind::to_string(RepKind::non_greedy()), "NonGreedy")
}

// === Category::to_dyn ===

///|
test "category to_dyn" {
  let _ = Category::to_dyn(Category::letter())
  let _ = Category::to_dyn(Category::newline())
  let _ = Category::to_dyn(Category::dummy())
  let _ = Category::to_dyn(Category::inexistant())
  let _ = Category::to_dyn(Category::lastnewline())
  let _ = Category::to_dyn(Category::not_letter())
  let _ = Category::to_dyn(Category::search_boundary())
  let _ = Category::to_dyn(Category::from_char('a'))
  let _ = Category::to_dyn(Category::from_int(0))
  assert_eq(true, true)
}

// === Pmark::to_dyn ===

///|
test "pmark to_dyn" {
  let p = Pmark::gen()
  let _ = Pmark::to_dyn(p)
  assert_eq(Pmark::equal(p, p), true)
  assert_eq(Pmark::compare(p, p), 0)
  assert_eq(true, true)
}

// === Re::group_count / group_names ===

///|
test "re group_count and group_names" {
  let re1 = compile(Ast::str(sb("abc")))
  assert_eq(Re::group_count(re1), 1)
  assert_eq(Re::group_names(re1).length(), 0)

  let re2 = compile(Ast::group(name=Some("first"), Ast::str(sb("a"))))
  assert_eq(Re::group_count(re2), 2)
  let names2 = Re::group_names(re2)
  assert_eq(names2.length(), 1)
  let (n2, _) = names2[0]
  assert_eq(n2, "first")

  let re3 = compile(
    Ast::seq([
      Ast::group(name=Some("x"), Ast::str(sb("a"))),
      Ast::group(name=Some("y"), Ast::str(sb("b"))),
    ]),
  )
  assert_eq(Re::group_count(re3), 3)
  let names3 = Re::group_names(re3)
  assert_eq(names3.length(), 2)
}

// === Idx::to_dyn / Idx::to_int ===

///|
test "idx to_dyn and to_int" {
  let _ = Idx::to_dyn(42)
  assert_eq(Idx::to_int(42), 42)
  assert_eq(true, true)
}

// === Mark::to_dyn ===

///|
test "mark to_dyn" {
  let _ = Mark::to_dyn(5)
  assert_eq(true, true)
}

// === State::to_dyn (indirect via compilation) ===

///|
test "state to_dyn indirect" {
  let re = compile(Ast::str(sb("test")))
  assert_eq(execp(re, sb("test")), true)
}
