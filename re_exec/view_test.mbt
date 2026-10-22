// view_test.mbt — tests for View module

///|
test "view char" {
  let r = @ast.Ast::char('a')
  match @re_exec.View::view(r) {
    SetT(c) => assert_eq(c.intervals, [(97, 97)])
    _ => assert_eq(true, false)
  }
}

///|
test "view sequence" {
  let r = @ast.Ast::seq([@ast.Ast::char('a'), @ast.Ast::char('b')])
  match @re_exec.View::view(r) {
    SequenceT(xs) => assert_eq(xs.length(), 2)
    _ => assert_eq(true, false)
  }
}

///|
test "view alternative" {
  let r = @ast.Ast::alt([@ast.Ast::char('a'), @ast.Ast::char('b')])
  match @re_exec.View::view(r) {
    AlternativeT(xs) => assert_eq(xs.length(), 2)
    _ => assert_eq(true, false)
  }
}

///|
test "view repeat" {
  let r = @ast.Ast::rep(@ast.Ast::char('a'))
  match @re_exec.View::view(r) {
    RepeatT(_, 0, None) => assert_eq(true, true)
    _ => assert_eq(true, false)
  }
}

///|
test "view anchors" {
  assert_eq(@re_exec.View::view(@ast.Ast::bos()) is BegOfStrT, true)
  assert_eq(@re_exec.View::view(@ast.Ast::eos()) is EndOfStrT, true)
  assert_eq(@re_exec.View::view(@ast.Ast::bol()) is BegOfLineT, true)
  assert_eq(@re_exec.View::view(@ast.Ast::eol()) is EndOfLineT, true)
  assert_eq(@re_exec.View::view(@ast.Ast::start()) is StartT, true)
  assert_eq(@re_exec.View::view(@ast.Ast::stop()) is StopT, true)
}

///|
test "view group" {
  let r = @ast.Ast::group(@ast.Ast::char('a'))
  match @re_exec.View::view(r) {
    GroupT(None, _) => assert_eq(true, true)
    _ => assert_eq(true, false)
  }
}

///|
test "view named group" {
  let r = @ast.Ast::group(name=Some("foo"), @ast.Ast::char('a'))
  match @re_exec.View::view(r) {
    GroupT(Some(n), _) => assert_eq(n, "foo")
    _ => assert_eq(true, false)
  }
}

///|
test "view nest" {
  let r = @ast.Ast::nest(@ast.Ast::char('a'))
  match @re_exec.View::view(r) {
    NestT(_) => assert_eq(true, true)
    _ => assert_eq(true, false)
  }
}

///|
test "view no_group" {
  let r = @ast.Ast::no_group(
    @ast.Ast::seq([@ast.Ast::char('a'), @ast.Ast::char('b')]),
  )
  match @re_exec.View::view(r) {
    NoGroupT(_) => assert_eq(true, true)
    _ => assert_eq(true, false)
  }
}

///|
test "view sem" {
  let r = @ast.Ast::seq([@ast.Ast::char('a'), @ast.Ast::char('b')])
  let r2 = @ast.Ast::longest(r)
  match @re_exec.View::view(r2) {
    SemT(sem, _) => assert_eq(sem, @base.Sem::longest())
    _ => assert_eq(true, false)
  }
}

///|
test "cset view" {
  let c = @base.Cset::char('a')
  let ranges = @re_exec.CsetView::view(c)
  assert_eq(ranges.length(), 1)
  assert_eq(@re_exec.ViewRange::first(ranges[0]), 'a')
  assert_eq(@re_exec.ViewRange::last(ranges[0]), 'a')
}

///|
test "cset view range" {
  let c = @base.Cset::rg('a', 'z')
  let ranges = @re_exec.CsetView::view(c)
  assert_eq(ranges.length(), 1)
  assert_eq(@re_exec.ViewRange::first(ranges[0]), 'a')
  assert_eq(@re_exec.ViewRange::last(ranges[0]), 'z')
}

///|
test "cset view empty" {
  let c = @base.Cset::empty()
  let ranges = @re_exec.CsetView::view(c)
  assert_eq(ranges.length(), 0)
}

///|
test "cset view union" {
  let c = @base.Cset::union(@base.Cset::char('a'), @base.Cset::char('c'))
  let ranges = @re_exec.CsetView::view(c)
  assert_eq(ranges.length(), 2)
}
