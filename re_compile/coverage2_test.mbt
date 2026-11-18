// 覆盖率长尾补测 — get_color lnl/null_char、translate NoCase、status、posix_class
// coverage tail tests for get_color lnl/null_char, NoCase translate, status, posix_class

///|
test "execp last newline with dollar" {
  // 模式以 $ 结尾 + 文本末尾换行 → get_color 的 lnl 分支
  let ast = @ast.Ast::seq([@ast.Ast::char('a'), @ast.Ast::eol()])
  let re = @re_compile.compile(ast)
  assert_eq(@re_compile.execp(re, @base.sb("a\n")), true)
}

///|
test "exec_opt returns None on no match" {
  let re = @re_compile.compile(@ast.Ast::char('z'))
  match @re_compile.exec_opt(re, @base.sb("abc")) {
    Some(_) => assert_eq(true, false)
    None => assert_eq(true, true)
  }
}

///|
test "compile no_case translates case nodes" {
  // handle_case 产出 Case/NoCase 节点 → translate 的 NoCase/Case 分支
  let ast = @ast.Ast::no_case(@ast.Ast::char('a'))
  let re = @re_compile.compile(ast)
  assert_eq(@re_compile.execp(re, @base.sb("A")), true)
  assert_eq(@re_compile.execp(re, @base.sb("a")), true)
}

///|
test "execp word boundary" {
  // bow/eow → delta 的 EndOfWord 分支
  let ast = @ast.Ast::seq([
    @ast.Ast::bow(),
    @ast.Ast::char('w'),
    @ast.Ast::eow(),
  ])
  let re = @re_compile.compile(ast)
  assert_eq(@re_compile.execp(re, @base.sb("w")), true)
}
