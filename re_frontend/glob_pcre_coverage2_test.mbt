// 覆盖率长尾补测 — glob.mbt 转义/范围分支 + GlobState component 转换 + pcre 标志
// coverage tail tests for glob.mbt escape/range branches, GlobState components, pcre flags

///|
test "glob escaped char then range" {
  let re = @re_frontend.Glob::compile(@base.sb("[\\a-\\z]"))
  assert_eq(@compile.execp(re, @base.sb("m")), true)
  assert_eq(@compile.execp(re, @base.sb("9")), false)
}

///|
test "glob char then escaped dash at end" {
  let re = @re_frontend.Glob::compile(@base.sb("[a\\-]"))
  assert_eq(@compile.execp(re, @base.sb("a")), true)
  assert_eq(@compile.execp(re, @base.sb("-")), true)
}

///|
test "glob escaped char with dash range" {
  let re = @re_frontend.Glob::compile(@base.sb("[\\q-\\t]"))
  assert_eq(@compile.execp(re, @base.sb("r")), true)
}

///|
test "glob question and star combined" {
  let re = @re_frontend.Glob::compile(@base.sb("*.?x"))
  assert_eq(@compile.execp(re, @base.sb("abc.zx")), true)
}

///|
test "glob anybut with component" {
  let re = @re_frontend.Glob::compile(@base.sb("[!a]bc"))
  assert_eq(@compile.execp(re, @base.sb("xbc")), true)
  assert_eq(@compile.execp(re, @base.sb("abc")), false)
}

///|
test "glob double star non terminator" {
  let re = @re_frontend.Glob::compile(@base.sb("a**b"))
  assert_eq(@compile.execp(re, @base.sb("axxb")), true)
}

///|
test "glob double star with terminator nested" {
  let re = @re_frontend.Glob::compile(@base.sb("**/a/**/b"))
  assert_eq(@compile.execp(re, @base.sb("x/a/y/b")), true)
}

///|
test "glob complement double star mix" {
  let re = @re_frontend.Glob::compile(@base.sb("[!x]*/y"))
  assert_eq(@compile.execp(re, @base.sb("ab/y")), true)
}

///|
test "pcre dotall flag" {
  let re = @re_frontend.Pcre::regexp(@base.sb("a.b"), flags=[
    @re_frontend.PcreFlag::dotall_p(),
  ])
  assert_eq(@re_frontend.Pcre::pmatch(re, @base.sb("a\nb")), true)
}

///|
test "pcre caseless and multiline flags" {
  let re = @re_frontend.Pcre::regexp(@base.sb("^abc$"), flags=[
    @re_frontend.PcreFlag::caseless(),
    @re_frontend.PcreFlag::multiline_p(),
  ])
  assert_eq(@re_frontend.Pcre::pmatch(re, @base.sb("x\nAbC\ny")), true)
}

///|
test "pcre anchored flag" {
  let re = @re_frontend.Pcre::regexp(@base.sb("abc"), flags=[
    @re_frontend.PcreFlag::anchored_p(),
  ])
  assert_eq(@re_frontend.Pcre::pmatch(re, @base.sb("abc")), true)
}
