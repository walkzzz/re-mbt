// view_test.mbt — tests for View module

///|
test "view char" {
  let r = @re.Ast::char('a')
  match @re.View::view(r) {
    SetT(c) => assert_eq(c.intervals, [(97, 97)])
    _ => assert_eq(true, false)
  }
}

///|
test "view sequence" {
  let r = @re.Ast::seq([@re.Ast::char('a'), @re.Ast::char('b')])
  match @re.View::view(r) {
    SequenceT(xs) => assert_eq(xs.length(), 2)
    _ => assert_eq(true, false)
  }
}

///|
test "view alternative" {
  let r = @re.Ast::alt([@re.Ast::char('a'), @re.Ast::char('b')])
  match @re.View::view(r) {
    AlternativeT(xs) => assert_eq(xs.length(), 2)
    _ => assert_eq(true, false)
  }
}

///|
test "view repeat" {
  let r = @re.Ast::rep(@re.Ast::char('a'))
  match @re.View::view(r) {
    RepeatT(_, 0, None) => assert_eq(true, true)
    _ => assert_eq(true, false)
  }
}

///|
test "view anchors" {
  assert_eq(@re.View::view(@re.Ast::bos()) is BegOfStrT, true)
  assert_eq(@re.View::view(@re.Ast::eos()) is EndOfStrT, true)
  assert_eq(@re.View::view(@re.Ast::bol()) is BegOfLineT, true)
  assert_eq(@re.View::view(@re.Ast::eol()) is EndOfLineT, true)
  assert_eq(@re.View::view(@re.Ast::start()) is StartT, true)
  assert_eq(@re.View::view(@re.Ast::stop()) is StopT, true)
}

///|
test "view group" {
  let r = @re.Ast::group(@re.Ast::char('a'))
  match @re.View::view(r) {
    @re.GroupT(None, _) => assert_eq(true, true)
    _ => assert_eq(true, false)
  }
}

///|
test "view named group" {
  let r = @re.Ast::group(name=Some("foo"), @re.Ast::char('a'))
  match @re.View::view(r) {
    @re.GroupT(Some(n), _) => assert_eq(n, "foo")
    _ => assert_eq(true, false)
  }
}

///|
test "view nest" {
  let r = @re.Ast::nest(@re.Ast::char('a'))
  match @re.View::view(r) {
    NestT(_) => assert_eq(true, true)
    _ => assert_eq(true, false)
  }
}

///|
test "view no_group" {
  let r = @re.Ast::no_group(
    @re.Ast::seq([@re.Ast::char('a'), @re.Ast::char('b')]),
  )
  match @re.View::view(r) {
    NoGroupT(_) => assert_eq(true, true)
    _ => assert_eq(true, false)
  }
}

///|
test "view sem" {
  let r = @re.Ast::seq([@re.Ast::char('a'), @re.Ast::char('b')])
  let r2 = @re.Ast::longest(r)
  match @re.View::view(r2) {
    SemT(sem, _) => assert_eq(sem, @re.Sem::longest())
    _ => assert_eq(true, false)
  }
}

///|
test "cset view" {
  let c = @re.Cset::char('a')
  let ranges = @re.CsetView::view(c)
  assert_eq(ranges.length(), 1)
  assert_eq(@re.ViewRange::first(ranges[0]), 'a')
  assert_eq(@re.ViewRange::last(ranges[0]), 'a')
}

///|
test "cset view range" {
  let c = @re.Cset::rg('a', 'z')
  let ranges = @re.CsetView::view(c)
  assert_eq(ranges.length(), 1)
  assert_eq(@re.ViewRange::first(ranges[0]), 'a')
  assert_eq(@re.ViewRange::last(ranges[0]), 'z')
}

///|
test "cset view empty" {
  let c = @re.Cset::empty()
  let ranges = @re.CsetView::view(c)
  assert_eq(ranges.length(), 0)
}

///|
test "cset view union" {
  let c = @re.Cset::union(@re.Cset::char('a'), @re.Cset::char('c'))
  let ranges = @re.CsetView::view(c)
  assert_eq(ranges.length(), 2)
}
