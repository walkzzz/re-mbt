// 覆盖率长尾补测 — posix_class alnum、perl ungreedy（SemGreedy delta）、emacs word boundary
// coverage tail tests for posix_class alnum, perl ungreedy, emacs word boundary

///|
test "perl posix alnum class" {
  let re = @re_frontend.Perl::compile_pat(@base.sb("[[:alnum:]]"))
  assert_eq(@compile.execp(re, @base.sb("5")), true)
  assert_eq(@compile.execp(re, @base.sb("!")), false)
}

///|
test "perl ungreedy sem_greedy delta" {
  // opts.ungreedy → SemGreedy 节点 → delta 的 SemGreedyT 分支
  let re = @re_frontend.Perl::compile_pat(
    @base.sb("a.*?b"),
    opts=[@re_frontend.PerlOpt::ungreedy()],
  )
  match @compile.exec_opt(re, @base.sb("axxbxxb")) {
    Some(g) =>
      assert_eq(@base.bs(@compile.GroupT::get(g, 0).unwrap()), "axxbxxb")
    None => assert_eq(true, false)
  }
}

///|
test "emacs word boundary delta" {
  let re = @re_frontend.Emacs::compile_pat(@base.sb("\\bcat\\b"))
  assert_eq(@compile.execp(re, @base.sb("cat")), true)
  assert_eq(@compile.execp(re, @base.sb("acat")), false)
}
