// crap_wbtest.mbt — Whitebox CRAP coverage tests for re_frontend
// Covers PosixOpt branches (Newline, ICase, NoSub)

///|
test "wb posix atom dot newline" {
  let re_nl = Posix::compile(@base.sb("."), opts=[Newline])
  assert_eq(@compile.execp(re_nl, @base.sb("a")), true)
}

///|
test "wb posix atom anchors newline" {
  let re_bol_nl = Posix::compile(@base.sb("^abc"), opts=[Newline])
  assert_eq(@compile.execp(re_bol_nl, @base.sb("abc")), true)
  let re_eol_nl = Posix::compile(@base.sb("abc$"), opts=[Newline])
  assert_eq(@compile.execp(re_eol_nl, @base.sb("abc")), true)
}

///|
test "wb posix has opt and re opts" {
  let re_icase = Posix::compile(@base.sb("abc"), opts=[ICase])
  assert_eq(@compile.execp(re_icase, @base.sb("ABC")), true)
  let re_nosub = Posix::compile(@base.sb("abc"), opts=[NoSub])
  assert_eq(@compile.execp(re_nosub, @base.sb("abc")), true)
}

///|
test "wb posix complement bracket newline" {
  let re = Posix::compile(@base.sb("[^abc]"), opts=[Newline])
  assert_eq(@compile.execp(re, @base.sb("d")), true)
}
