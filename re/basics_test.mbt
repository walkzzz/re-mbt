///|
test "cset empty" {
  assert_eq(Cset::empty().intervals.length(), 0)
  assert_eq(Cset::is_empty(Cset::empty()), true)
}

///|
test "cset single" {
  let s = Cset::single(65)
  assert_eq(s.intervals, [(65, 65)])
  assert_eq(Cset::mem(65, s), true)
  assert_eq(Cset::mem(66, s), false)
}

///|
test "cset cany" {
  let any = Cset::cany()
  assert_eq(any.intervals, [(0, 255)])
  assert_eq(Cset::mem(0, any), true)
  assert_eq(Cset::mem(255, any), true)
  assert_eq(Cset::mem(-1, any), false)
}

///|
test "cset union disjoint" {
  let a = Cset::seq(0, 10)
  let b = Cset::seq(20, 30)
  let u = Cset::union(a, b)
  assert_eq(u.intervals, [(0, 10), (20, 30)])
}

///|
test "cset union overlapping" {
  let a = Cset::seq(0, 10)
  let b = Cset::seq(5, 15)
  let u = Cset::union(a, b)
  assert_eq(u.intervals, [(0, 15)])
}

///|
test "cset union adjacent" {
  let a = Cset::seq(0, 5)
  let b = Cset::seq(6, 10)
  let u = Cset::union(a, b)
  assert_eq(u.intervals, [(0, 10)])
}

///|
test "cset inter" {
  let a = Cset::seq(0, 10)
  let b = Cset::seq(5, 15)
  let i = Cset::inter(a, b)
  assert_eq(i.intervals, [(5, 10)])
}

///|
test "cset diff" {
  let a = Cset::seq(0, 10)
  let b = Cset::seq(3, 5)
  let d = Cset::diff(a, b)
  assert_eq(d.intervals, [(0, 2), (6, 10)])
}

///|
test "cset cdigit" {
  let d = Cset::cdigit()
  assert_eq(d.intervals, [(48, 57)])
  assert_eq(Cset::mem(48, d), true)
  assert_eq(Cset::mem(57, d), true)
  assert_eq(Cset::mem(47, d), false)
}

///|
test "cset set from bytes" {
  let s = Cset::set(b"abc")
  assert_eq(s.intervals, [(97, 99)])
}

///|
test "cset one_char" {
  assert_eq(Cset::one_char(Cset::single(65)), Some(65))
  assert_eq(Cset::one_char(Cset::seq(65, 66)), None)
  assert_eq(Cset::one_char(Cset::empty()), None)
}

///|
test "pmark gen unique" {
  let a = Pmark::gen()
  let b = Pmark::gen()
  assert_eq(a.id < b.id, true)
  assert_eq(Pmark::equal(a, a), true)
  assert_eq(Pmark::equal(a, b), false)
}

///|
test "pmarkset mem/add" {
  let a = Pmark::gen()
  let b = Pmark::gen()
  let s = PmarkSet::empty().add(a).add(b)
  assert_eq(s.mem(a), true)
  assert_eq(s.mem(b), true)
  assert_eq(s.mem(Pmark::gen()), false)
  assert_eq(s.length(), 2)
}

///|
test "pmarkset dedup" {
  let a = Pmark::gen()
  let s = PmarkSet::empty().add(a).add(a)
  assert_eq(s.length(), 1)
}

///|
test "category from_char" {
  assert_eq(Category::from_char('a').to_int(), 2)
  assert_eq(Category::from_char('Z').to_int(), 2)
  assert_eq(Category::from_char('5').to_int(), 2)
  assert_eq(Category::from_char('_').to_int(), 2)
  assert_eq(Category::from_char(' ').to_int(), 4)
  assert_eq(Category::from_char('\n').to_int(), 12)
}

///|
test "category intersect" {
  let l = Category::letter()
  let nl = Category::newline()
  assert_eq(Category::intersect(l, nl), false)
  assert_eq(Category::intersect(Category::from_char('\n'), nl), true)
}

///|
test "bitvector basic" {
  let bv = BitVector::create_zero(16)
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
  let s = HashSet::create()
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
  let s = HashSet::create()
  s.add(42)
  s.add(42)
  assert_eq(s.mem(42), true)
}
