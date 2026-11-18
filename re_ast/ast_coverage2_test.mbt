// 覆盖率长尾补测 — ast_to_dyn 调试序列化分支 + colorize Case 分支
// coverage tail tests for ast_to_dyn debug branches and colorize Case branch

///|
test "to_dyn no_group branch" {
  let r = @re_ast.Ast::no_group(@re_ast.Ast::char('a')).to_dyn().to_repr().to_string()
  assert_true(r.length() > 0)
}

///|
test "to_dyn sem branch" {
  let r = @re_ast.Ast::longest(@re_ast.Ast::char('a')).to_dyn().to_repr().to_string()
  assert_true(r.length() > 0)
}

///|
test "to_dyn no_case branch" {
  let r = @re_ast.Ast::no_case(@re_ast.Ast::char('a')).to_dyn().to_repr().to_string()
  assert_true(r.contains("No_case"))
}

///|
test "colorize case branch" {
  // no_case → handle_case → Case 节点 → colorize 的 Case 分支
  let r = @re_ast.Ast::no_case(
    @re_ast.Ast::alt([@re_ast.Ast::char('a'), @re_ast.Ast::char('b')]),
  )
  let cm = @re_ast.ColorMap::make()
  let rnc = @re_ast.Ast::handle_case(r, false)
  let _lnl = @re_ast.Ast::colorize(cm, rnc)
  let (_t, _bt, rep) = @re_ast.ColorMap::flatten(cm)
  assert_true(@re_ast.ColorRepr::length(rep) > 0)
}

///|
test "colorize sequence of chars" {
  // colorize 的 Sequence 分支（长尾 372/376 行）
  let r = @re_ast.Ast::seq([@re_ast.Ast::char('a'), @re_ast.Ast::char('b')])
  let cm = @re_ast.ColorMap::make()
  let rnc = @re_ast.Ast::handle_case(r, false)
  let _lnl = @re_ast.Ast::colorize(cm, rnc)
  let (_t, _bt, rep) = @re_ast.ColorMap::flatten(cm)
  assert_true(@re_ast.ColorRepr::length(rep) > 0)
}

///|
test "cset equal different endpoints returns false" {
  // Cset::equal 的逐区间端点比较分支
  assert_eq(
    @base.Cset::equal(@base.Cset::single(97), @base.Cset::single(98)),
    false,
  )
  assert_eq(
    @base.Cset::equal(@base.Cset::single(97), @base.Cset::single(97)),
    true,
  )
}
