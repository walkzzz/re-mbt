// crap_test.mbt — CRAP coverage tests for re_base
// Covers cset.mbt, util.mbt, pmark.mbt, hash_set.mbt, bit_vector.mbt, mark_infos.mbt

// === Cset coverage ===

///|
test "Cset::equal different length" {
  let c1 = @re_base.Cset::single(97)
  let c2 = @re_base.Cset::seq(97, 98)
  assert_eq(@re_base.Cset::equal(c1, c2), false)
}

///|
test "Cset::compare different first" {
  let c1 = @re_base.Cset::single(97)
  let c2 = @re_base.Cset::single(98)
  let _ = @re_base.Cset::compare(c1, c2)
}

///|
test "Cset::seq reversed" {
  let c = @re_base.Cset::seq(98, 97)
  assert_eq(@re_base.Cset::mem(97, c), true)
  assert_eq(@re_base.Cset::mem(98, c), true)
}

///|
test "Cset::union ri_over Some" {
  let l = @re_base.Cset::union(
    @re_base.Cset::single(97),
    @re_base.Cset::single(100),
  )
  let r = @re_base.Cset::seq(97, 99)
  let _ = @re_base.Cset::union(l, r)
}

///|
test "Cset::diff c2 < c1p" {
  let l = @re_base.Cset::seq(97, 98)
  let r = @re_base.Cset::seq(100, 101)
  let _ = @re_base.Cset::diff(l, r)
}

///|
test "Cset::diff c2p < c1" {
  let l = @re_base.Cset::seq(100, 101)
  let r = @re_base.Cset::seq(97, 98)
  let _ = @re_base.Cset::diff(l, r)
}

///|
test "Cset::union_all empty" {
  let c = @re_base.Cset::union_all([])
  assert_eq(@re_base.Cset::is_empty(c), true)
}

///|
test "Cset::intersect_all empty" {
  let c = @re_base.Cset::intersect_all([])
  assert_eq(@re_base.Cset::is_empty(c), false)
}

///|
test "Cset::set empty bytes" {
  let c = @re_base.Cset::set(b"")
  assert_eq(@re_base.Cset::is_empty(c), true)
}

// === util coverage ===

///|
test "array_reverse basic" {
  let r = @re_base.array_reverse([1, 2, 3])
  assert_eq(r, [3, 2, 1])
  let r2 : Array[Int32] = @re_base.array_reverse([])
  assert_eq(r2, [])
}

// === PmarkSet coverage ===

///|
test "PmarkSet::add hi = mid" {
  let pm1 = @re_base.Pmark::gen()
  let pm2 = @re_base.Pmark::gen()
  let pm3 = @re_base.Pmark::gen()
  let s1 = @re_base.PmarkSet::empty()
  let s2 = @re_base.PmarkSet::add(s1, pm3)
  let s3 = @re_base.PmarkSet::add(s2, pm1)
  let s4 = @re_base.PmarkSet::add(s3, pm2)
  assert_eq(@re_base.PmarkSet::length(s4), 3)
}

///|
test "PmarkSet::union a > b and remaining" {
  let pm1 = @re_base.Pmark::gen()
  let pm2 = @re_base.Pmark::gen()
  let pm3 = @re_base.Pmark::gen()
  let a = @re_base.PmarkSet::add(
    @re_base.PmarkSet::add(@re_base.PmarkSet::empty(), pm1),
    pm3,
  )
  let b = @re_base.PmarkSet::single(pm2)
  let u = @re_base.PmarkSet::union(a, b)
  assert_eq(@re_base.PmarkSet::length(u), 3)
}

///|
test "PmarkSet::equal different elements" {
  let pm1 = @re_base.Pmark::gen()
  let pm2 = @re_base.Pmark::gen()
  let s1 = @re_base.PmarkSet::single(pm1)
  let s2 = @re_base.PmarkSet::single(pm2)
  assert_eq(@re_base.PmarkSet::equal(s1, s2), false)
}

// === HashSet coverage ===

///|
test "HashSet::absent" {
  assert_eq(@re_base.HashSet::absent(), -1)
}

// === BitVector coverage ===

///|
test "BitVector::unsafe_set false" {
  let bv = @re_base.BitVector::create_zero(16)
  @re_base.BitVector::unsafe_set(bv, 0, true)
  @re_base.BitVector::unsafe_set(bv, 0, false)
  assert_eq(@re_base.BitVector::unsafe_get(bv, 0), false)
}

// === MarkInfos coverage ===

///|
test "MarkInfos::offset start == -1" {
  let mi = @re_base.MarkInfos::make([(-1, -1)])
  match @re_base.MarkInfos::offset(mi, 0) {
    None => assert_eq(true, true)
    Some(_) => assert_eq(true, false)
  }
}
