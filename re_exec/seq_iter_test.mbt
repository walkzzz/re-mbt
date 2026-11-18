// Search::iter_* 与物化版语义一致性测试 | consistency tests between iter_* and materialized APIs

///|
test "iter_matches equals matches" {
  let re = @compile.compile(@ast.Ast::char('o'))
  let s = @base.sb("foo bar boo")
  let eager = @re_exec.Search::matches(re, s)
  let lazy_ = @re_exec.Search::iter_matches(re, s).collect()
  assert_eq(lazy_, eager)
}

///|
test "iter_all equals all" {
  let digits = @ast.Ast::rep1(@ast.Ast::cset(@base.Cset::cseq('0', '9')))
  let re = @compile.compile(digits)
  let s = @base.sb("a1b22c333")
  let eager = @re_exec.Search::all(re, s)
  let lazy_ = @re_exec.Search::iter_all(re, s).collect()
  assert_eq(lazy_.length(), eager.length())
  assert_eq(lazy_.length(), 3)
}

///|
test "iter_split equals split" {
  let re = @compile.compile(@ast.Ast::char(','))
  let s = @base.sb("a,b,c")
  let eager = @re_exec.Search::split(re, s)
  let lazy_ = @re_exec.Search::iter_split(re, s).collect()
  assert_eq(lazy_, eager)
}
