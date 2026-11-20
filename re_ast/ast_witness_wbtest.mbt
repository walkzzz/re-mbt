///|
/// 覆盖率补强 — Ast::witness 全分支（cset 代数、序列、重复 clamp、零宽、包装器、不可匹配）
/// Coverage-gap tests for Ast::witness.

///|
test "witness: set single char and multi-byte sequence" {
  let a = @base.Cset::single(97)
  let b = @base.Cset::single(98)
  assert_eq(Ast::witness(Set(CsetOf(a))), Some(b"a"))
  assert_eq(
    Ast::witness(Sequence([Set(CsetOf(a)), Set(CsetOf(b))])),
    Some(b"ab"),
  )
}

///|
test "witness: cset algebra (intersection/complement/difference/cast)" {
  let a = @base.Cset::single(97)
  let b = @base.Cset::single(98)
  assert_true(
    Ast::witness(Set(Intersection([CsetOf(a), CsetOf(a)]))) is Some(_),
  )
  assert_true(Ast::witness(Set(Complement([CsetOf(a)]))) is Some(_))
  assert_true(Ast::witness(Set(Difference(CsetOf(a), CsetOf(b)))) is Some(_))
  assert_true(
    Ast::witness(Set(Cast(Alternative([CsetOf(a), CsetOf(b)])))) is Some(_),
  )
  assert_true(Ast::witness(Set(Cast(NoCase(CsetOf(a))))) is Some(_))
  assert_true(Ast::witness(Set(Cast(Case(CsetOf(a))))) is Some(_))
}

///|
test "witness: impossible csets return None" {
  assert_eq(Ast::witness(Set(CsetOf(@base.Cset::empty()))), None)
  assert_eq(
    Ast::witness(
      Set(
        Intersection([
          CsetOf(@base.Cset::empty()),
          CsetOf(@base.Cset::single(97)),
        ]),
      ),
    ),
    None,
  )
  assert_eq(
    Ast::witness(Set(Complement([CsetOf(@base.Cset::empty())]))) is Some(_),
    true,
  )
  assert_eq(Ast::witness(Set(Cast(Alternative([])))), None)
}

///|
test "witness: repeat clamps to [0..max] with at least one when possible" {
  let a = @base.Cset::single(97)
  let gen = Set(CsetOf(a))
  assert_eq(Ast::witness(Repeat(gen, 0, Some(0))), Some(b""))
  assert_eq(Ast::witness(Repeat(gen, 0, None)), Some(b"a"))
  assert_eq(Ast::witness(Repeat(gen, 2, Some(2))), Some(b"aa"))
  assert_eq(Ast::witness(Repeat(gen, 0, Some(3))), Some(b"a"))
}

///|
test "witness: zero-width anchors produce empty bytes" {
  for
    e in [
      BegOfLine,
      EndOfLine,
      BegOfWord,
      EndOfWord,
      NotBound,
      BegOfStr,
      EndOfStr,
      LastEndOfLine,
      Start,
      Stop,
    ] {
    assert_eq(Ast::witness(e), Some(b""))
  }
}

///|
test "witness: wrappers, empty alternatives and propagation of None" {
  let a = Set(CsetOf(@base.Cset::single(97)))
  let pm = @base.Pmark::gen()
  assert_eq(Ast::witness(Group(Some("g"), a)), Some(b"a"))
  assert_eq(Ast::witness(Group(None, a)), Some(b"a"))
  assert_eq(Ast::witness(NoGroup(a)), Some(b"a"))
  assert_eq(Ast::witness(Nest(a)), Some(b"a"))
  assert_eq(Ast::witness(Pmark(pm, a)), Some(b"a"))
  assert_eq(Ast::witness(Sem(@base.Sem::Longest, a)), Some(b"a"))
  assert_eq(Ast::witness(SemGreedy(@base.RepKind::Greedy, a)), Some(b"a"))
  assert_eq(Ast::witness(AstNode(Alternative([]))), None)
  assert_eq(Ast::witness(AstNode(NoCase(a))), Some(b"a"))
  assert_eq(Ast::witness(AstNode(Case(a))), Some(b"a"))
  assert_eq(Ast::witness(Sequence([a, AstNode(Alternative([]))])), None)
  assert_eq(
    Ast::witness(Repeat(Set(CsetOf(@base.Cset::empty())), 1, None)),
    None,
  )
  assert_eq(Ast::witness(Sequence([a, Set(CsetOf(@base.Cset::empty()))])), None)
}
