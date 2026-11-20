///|
/// 覆盖率补强 — AST to_dyn 的包装器分支（NoGroup/Sem/SemGreedy/NoCase）
/// Coverage-gap tests for ast_to_dyn wrappers.

///|
test "ast_to_dyn: wrappers render without panic" {
  let a = Set(CsetOf(@base.Cset::single(97)))
  ignore(ast_to_dyn(NoGroup(a)))
  ignore(ast_to_dyn(Sem(@base.Sem::Longest, a)))
  ignore(ast_to_dyn(SemGreedy(@base.RepKind::Greedy, a)))
  ignore(ast_alt_to_dyn_ast(NoCase(a)))
  ignore(ast_alt_to_dyn_ast(Case(a)))
  ignore(ast_to_dyn(Group(None, a)))
  ignore(ast_to_dyn(Group(Some("g"), a)))
}
