///|
test "cset empty" {
  assert_eq(@re_base.Cset::empty().intervals.length(), 0)
  assert_eq(@re_base.Cset::is_empty(@re_base.Cset::empty()), true)
}

///|
test "cset single" {
  let s = @re_base.Cset::single(65)
  assert_eq(s.intervals, [(65, 65)])
  assert_eq(@re_base.Cset::mem(65, s), true)
  assert_eq(@re_base.Cset::mem(66, s), false)
}

///|
test "cset cany" {
  let any = @re_base.Cset::cany()
  assert_eq(any.intervals, [(0, 255)])
  assert_eq(@re_base.Cset::mem(0, any), true)
  assert_eq(@re_base.Cset::mem(255, any), true)
  assert_eq(@re_base.Cset::mem(-1, any), false)
}

///|
test "cset union disjoint" {
  let a = @re_base.Cset::seq(0, 10)
  let b = @re_base.Cset::seq(20, 30)
  let u = @re_base.Cset::union(a, b)
  assert_eq(u.intervals, [(0, 10), (20, 30)])
}

///|
test "cset union overlapping" {
  let a = @re_base.Cset::seq(0, 10)
  let b = @re_base.Cset::seq(5, 15)
  let u = @re_base.Cset::union(a, b)
  assert_eq(u.intervals, [(0, 15)])
}

///|
test "cset union adjacent" {
  let a = @re_base.Cset::seq(0, 5)
  let b = @re_base.Cset::seq(6, 10)
  let u = @re_base.Cset::union(a, b)
  assert_eq(u.intervals, [(0, 10)])
}

///|
test "cset inter" {
  let a = @re_base.Cset::seq(0, 10)
  let b = @re_base.Cset::seq(5, 15)
  let i = @re_base.Cset::inter(a, b)
  assert_eq(i.intervals, [(5, 10)])
}

///|
test "cset diff" {
  let a = @re_base.Cset::seq(0, 10)
  let b = @re_base.Cset::seq(3, 5)
  let d = @re_base.Cset::diff(a, b)
  assert_eq(d.intervals, [(0, 2), (6, 10)])
}

///|
test "cset cdigit" {
  let d = @re_base.Cset::cdigit()
  assert_eq(d.intervals, [(48, 57)])
  assert_eq(@re_base.Cset::mem(48, d), true)
  assert_eq(@re_base.Cset::mem(57, d), true)
  assert_eq(@re_base.Cset::mem(47, d), false)
}

///|
test "cset set from bytes" {
  let s = @re_base.Cset::set(b"abc")
  assert_eq(s.intervals, [(97, 99)])
}

///|
test "cset one_char" {
  assert_eq(@re_base.Cset::one_char(@re_base.Cset::single(65)), Some(65))
  assert_eq(@re_base.Cset::one_char(@re_base.Cset::seq(65, 66)), None)
  assert_eq(@re_base.Cset::one_char(@re_base.Cset::empty()), None)
}

///|
test "pmark gen unique" {
  let a = @re_base.Pmark::gen()
  let b = @re_base.Pmark::gen()
  assert_eq(a.id < b.id, true)
  assert_eq(@re_base.Pmark::equal(a, a), true)
  assert_eq(@re_base.Pmark::equal(a, b), false)
}

///|
test "pmarkset mem/add" {
  let a = @re_base.Pmark::gen()
  let b = @re_base.Pmark::gen()
  let s = @re_base.PmarkSet::empty().add(a).add(b)
  assert_eq(s.mem(a), true)
  assert_eq(s.mem(b), true)
  assert_eq(s.mem(@re_base.Pmark::gen()), false)
  assert_eq(s.length(), 2)
}

///|
test "pmarkset dedup" {
  let a = @re_base.Pmark::gen()
  let s = @re_base.PmarkSet::empty().add(a).add(a)
  assert_eq(s.length(), 1)
}

///|
test "category from_char" {
  assert_eq(@re_base.Category::from_char('a').to_int(), 2)
  assert_eq(@re_base.Category::from_char('Z').to_int(), 2)
  assert_eq(@re_base.Category::from_char('5').to_int(), 2)
  assert_eq(@re_base.Category::from_char('_').to_int(), 2)
  assert_eq(@re_base.Category::from_char(' ').to_int(), 4)
  assert_eq(@re_base.Category::from_char('\n').to_int(), 12)
}

///|
test "category intersect" {
  let l = @re_base.Category::letter()
  let nl = @re_base.Category::newline()
  assert_eq(@re_base.Category::intersect(l, nl), false)
  assert_eq(
    @re_base.Category::intersect(@re_base.Category::from_char('\n'), nl),
    true,
  )
}

///|
test "bitvector basic" {
  let bv = @re_base.BitVector::create_zero(16)
  assert_eq(bv.length(), 16)
  assert_eq(bv.unsafe_get(5), false)
  bv.unsafe_set(5, true)
  assert_eq(bv.unsafe_get(5), true)
  assert_eq(bv.unsafe_get(4), false)
  bv.unsafe_set(0, true)
  bv.unsafe_set(15, true)
  assert_eq(bv.unsafe_get(0), true)
  assert_eq(bv.unsafe_get(15), true)
  bv.reset_zero()
  assert_eq(bv.unsafe_get(5), false)
}

///|
test "hashset basic" {
  let s = @re_base.HashSet::create()
  assert_eq(s.is_empty(), true)
  s.add(1)
  s.add(2)
  s.add(100)
  assert_eq(s.mem(1), true)
  assert_eq(s.mem(2), true)
  assert_eq(s.mem(100), true)
  assert_eq(s.mem(3), false)
  assert_eq(s.is_empty(), false)
}

///|
test "hashset dedup" {
  let s = @re_base.HashSet::create()
  s.add(42)
  s.add(42)
  assert_eq(s.mem(42), true)
}

///|
test "cset empty operations boundary" {
  assert_eq(
    @re_base.Cset::union(@re_base.Cset::empty(), @re_base.Cset::empty()).intervals,
    [],
  )
  assert_eq(
    @re_base.Cset::inter(@re_base.Cset::empty(), @re_base.Cset::seq(0, 255)).intervals,
    [],
  )
  assert_eq(
    @re_base.Cset::diff(@re_base.Cset::seq(0, 255), @re_base.Cset::empty()).intervals,
    [(0, 255)],
  )
  assert_eq(
    @re_base.Cset::diff(@re_base.Cset::empty(), @re_base.Cset::seq(0, 255)).intervals,
    [],
  )
}

///|
test "cset cany combinations" {
  assert_eq(
    @re_base.Cset::union(@re_base.Cset::cany(), @re_base.Cset::single(65)).intervals,
    [(0, 255)],
  )
  assert_eq(
    @re_base.Cset::inter(@re_base.Cset::cany(), @re_base.Cset::single(65)).intervals,
    [(65, 65)],
  )
  assert_eq(
    @re_base.Cset::diff(@re_base.Cset::cany(), @re_base.Cset::cany()).intervals,
    [],
  )
}

///|
test "cset single boundary 0 and 255" {
  let s0 = @re_base.Cset::single(0)
  assert_eq(s0.intervals, [(0, 0)])
  assert_eq(@re_base.Cset::mem(0, s0), true)
  assert_eq(@re_base.Cset::mem(-1, s0), false)
  let s255 = @re_base.Cset::single(255)
  assert_eq(s255.intervals, [(255, 255)])
  assert_eq(@re_base.Cset::mem(255, s255), true)
  assert_eq(@re_base.Cset::mem(256, s255), false)
}

///|
test "cset complement via diff cany" {
  let x = @re_base.Cset::seq(65, 90)
  let compl = @re_base.Cset::diff(@re_base.Cset::cany(), x)
  assert_eq(@re_base.Cset::mem(64, compl), true)
  assert_eq(@re_base.Cset::mem(65, compl), false)
  assert_eq(@re_base.Cset::mem(90, compl), false)
  assert_eq(@re_base.Cset::mem(91, compl), true)
  assert_eq(@re_base.Cset::mem(0, compl), true)
  assert_eq(@re_base.Cset::mem(255, compl), true)
}

///|
test "cset full 256 traversal mem" {
  let any = @re_base.Cset::cany()
  let emp = @re_base.Cset::empty()
  let s65 = @re_base.Cset::single(65)
  let digits = @re_base.Cset::seq(48, 57)
  for c in 0..<256 {
    assert_eq(@re_base.Cset::mem(c, any), true)
    assert_eq(@re_base.Cset::mem(c, emp), false)
    assert_eq(@re_base.Cset::mem(c, s65), c == 65)
    assert_eq(@re_base.Cset::mem(c, digits), c >= 48 && c <= 57)
  }
}

///|
test "cset union_singles non-decreasing input" {
  let result = @re_base.Cset::union_singles_in_strictly_decreasing_order([
    5, 3, 3, 1,
  ])
  assert_true(result.intervals.length() >= 1)
}

///|
test "cset case_insens latin1 and predefined" {
  let ci = @re_base.Cset::case_insens(@re_base.Cset::single(192))
  assert_eq(@re_base.Cset::mem(192, ci), true)
  assert_eq(@re_base.Cset::mem(224, ci), true)
  let alnum = @re_base.Cset::calnum()
  assert_eq(@re_base.Cset::mem(65, alnum), true)
  assert_eq(@re_base.Cset::mem(97, alnum), true)
  assert_eq(@re_base.Cset::mem(48, alnum), true)
  assert_eq(@re_base.Cset::mem(170, alnum), true)
  assert_eq(@re_base.Cset::mem(181, alnum), true)
  assert_eq(@re_base.Cset::mem(223, alnum), true)
  assert_eq(@re_base.Cset::mem(255, alnum), true)
  let alpha = @re_base.Cset::calpha()
  assert_eq(@re_base.Cset::mem(65, alpha), true)
  assert_eq(@re_base.Cset::mem(97, alpha), true)
  assert_eq(@re_base.Cset::mem(170, alpha), true)
  assert_eq(@re_base.Cset::mem(48, alpha), false)
  let lower = @re_base.Cset::clower()
  assert_eq(@re_base.Cset::mem(97, lower), true)
  assert_eq(@re_base.Cset::mem(224, lower), true)
  assert_eq(@re_base.Cset::mem(65, lower), false)
  let word = @re_base.Cset::cword()
  assert_eq(@re_base.Cset::mem(95, word), true)
  assert_eq(@re_base.Cset::mem(65, word), true)
  assert_eq(@re_base.Cset::mem(97, word), true)
  assert_eq(@re_base.Cset::mem(48, word), true)
  assert_eq(@re_base.Cset::mem(32, word), false)
}
