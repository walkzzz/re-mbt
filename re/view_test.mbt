// view_test.mbt — tests for View module

///|
test "view char" {
  let r = Ast::char('a')
  match View::view(r) {
    SetT(c) => assert_eq(c.intervals, [(97, 97)])
    _ => assert_eq(true, false)
  }
}

///|
test "view sequence" {
  let r = Ast::seq([Ast::char('a'), Ast::char('b')])
  match View::view(r) {
    SequenceT(xs) => assert_eq(xs.length(), 2)
    _ => assert_eq(true, false)
  }
}

///|
test "view alternative" {
  let r = Ast::alt([Ast::char('a'), Ast::char('b')])
  match View::view(r) {
    AlternativeT(xs) => assert_eq(xs.length(), 2)
    _ => assert_eq(true, false)
  }
}

///|
test "view repeat" {
  let r = Ast::rep(Ast::char('a'))
  match View::view(r) {
    RepeatT(_, 0, None) => assert_eq(true, true)
    _ => assert_eq(true, false)
  }
}

///|
test "view anchors" {
  assert_eq(View::view(Ast::bos()) is BegOfStrT, true)
  assert_eq(View::view(Ast::eos()) is EndOfStrT, true)
  assert_eq(View::view(Ast::bol()) is BegOfLineT, true)
  assert_eq(View::view(Ast::eol()) is EndOfLineT, true)
  assert_eq(View::view(Ast::start()) is StartT, true)
  assert_eq(View::view(Ast::stop()) is StopT, true)
}

///|
test "view group" {
  let r = Ast::group(Ast::char('a'))
  match View::view(r) {
    GroupT(None, _) => assert_eq(true, true)
    _ => assert_eq(true, false)
  }
}

///|
test "view named group" {
  let r = Ast::group(name=Some("foo"), Ast::char('a'))
  match View::view(r) {
    GroupT(Some(n), _) => assert_eq(n, "foo")
    _ => assert_eq(true, false)
  }
}

///|
test "view nest" {
  let r = Ast::nest(Ast::char('a'))
  match View::view(r) {
    NestT(_) => assert_eq(true, true)
    _ => assert_eq(true, false)
  }
}

///|
test "view no_group" {
  let r = Ast::no_group(Ast::seq([Ast::char('a'), Ast::char('b')]))
  match View::view(r) {
    NoGroupT(_) => assert_eq(true, true)
    _ => assert_eq(true, false)
  }
}

///|
test "view sem" {
  let r = Ast::seq([Ast::char('a'), Ast::char('b')])
  let r2 = Ast::longest(r)
  match View::view(r2) {
    SemT(sem, _) => assert_eq(sem, Sem::longest())
    _ => assert_eq(true, false)
  }
}

///|
test "cset view" {
  let c = Cset::char('a')
  let ranges = CsetView::view(c)
  assert_eq(ranges.length(), 1)
  assert_eq(ViewRange::first(ranges[0]), 'a')
  assert_eq(ViewRange::last(ranges[0]), 'a')
}

///|
test "cset view range" {
  let c = Cset::rg('a', 'z')
  let ranges = CsetView::view(c)
  assert_eq(ranges.length(), 1)
  assert_eq(ViewRange::first(ranges[0]), 'a')
  assert_eq(ViewRange::last(ranges[0]), 'z')
}

///|
test "cset view empty" {
  let c = Cset::empty()
  let ranges = CsetView::view(c)
  assert_eq(ranges.length(), 0)
}

///|
test "cset view union" {
  let c = Cset::union(Cset::char('a'), Cset::char('c'))
  let ranges = CsetView::view(c)
  assert_eq(ranges.length(), 2)
}
