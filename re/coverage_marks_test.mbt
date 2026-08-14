// coverage_marks_test.mbt — Category/Pmark/PmarkSet/MarkInfos/BitVector coverage tests

// === Category ===

///|
test "Category::from_int / to_int roundtrip" {
  let c = Category::from_int(5)
  assert_eq(Category::to_int(c), 5)
}

///|
test "Category::equal" {
  let a = Category::from_int(5)
  let b = Category::from_int(5)
  let c = Category::from_int(6)
  assert_eq(Category::equal(a, b), true)
  assert_eq(Category::equal(a, c), false)
}

///|
test "Category::compare" {
  let a = Category::from_int(5)
  let b = Category::from_int(6)
  assert_eq(Category::compare(a, b) < 0, true)
  assert_eq(Category::compare(b, a) > 0, true)
  assert_eq(Category::compare(a, a), 0)
}

///|
test "Category::add" {
  let a = Category::from_int(2)
  let b = Category::from_int(4)
  let c = Category::add(a, b)
  assert_eq(Category::to_int(c), 6)
}

///|
test "Category::dummy" {
  let d = Category::dummy()
  assert_eq(Category::to_int(d), -1)
}

///|
test "Category::inexistant" {
  let i = Category::inexistant()
  assert_eq(Category::to_int(i), 1)
}

///|
test "Category::not_letter" {
  let nl = Category::not_letter()
  assert_eq(Category::to_int(nl), 4)
}

///|
test "Category::lastnewline" {
  let ln = Category::lastnewline()
  assert_eq(Category::to_int(ln), 16)
}

///|
test "Category::search_boundary" {
  let sb = Category::search_boundary()
  assert_eq(Category::to_int(sb), 32)
}

///|
test "Category::from_char newline" {
  let c = Category::from_char('\n')
  assert_eq(Category::intersect(c, Category::newline()), true)
  assert_eq(Category::intersect(c, Category::not_letter()), true)
}

// === Pmark ===

///|
test "Pmark::compare" {
  let a = Pmark::gen()
  let b = Pmark::gen()
  assert_eq(Pmark::compare(a, b) < 0, true)
  assert_eq(Pmark::compare(b, a) > 0, true)
  assert_eq(Pmark::compare(a, a), 0)
}

///|
test "Pmark::to_int" {
  let a = Pmark::gen()
  assert_eq(Pmark::to_int(a), a.id)
}

// === PmarkSet ===

///|
test "PmarkSet::single" {
  let a = Pmark::gen()
  let s = PmarkSet::single(a)
  assert_eq(s.mem(a), true)
  assert_eq(s.length(), 1)
}

///|
test "PmarkSet::union" {
  let a = Pmark::gen()
  let b = Pmark::gen()
  let s1 = PmarkSet::single(a)
  let s2 = PmarkSet::single(b)
  let u = PmarkSet::union(s1, s2)
  assert_eq(u.mem(a), true)
  assert_eq(u.mem(b), true)
  assert_eq(u.length(), 2)
}

///|
test "PmarkSet::union dedup" {
  let a = Pmark::gen()
  let s1 = PmarkSet::single(a)
  let s2 = PmarkSet::single(a)
  let u = PmarkSet::union(s1, s2)
  assert_eq(u.length(), 1)
}

///|
test "PmarkSet::iter" {
  let a = Pmark::gen()
  let b = Pmark::gen()
  let s = PmarkSet::empty().add(a).add(b)
  let count = Ref::{ val: 0 }
  PmarkSet::iter(s, fn(_) { count.val += 1 })
  assert_eq(count.val, 2)
}

///|
test "PmarkSet::to_list" {
  let a = Pmark::gen()
  let b = Pmark::gen()
  let s = PmarkSet::empty().add(a).add(b)
  let lst = PmarkSet::to_list(s)
  assert_eq(lst.length(), 2)
}

///|
test "PmarkSet::is_empty" {
  assert_eq(PmarkSet::empty().is_empty(), true)
  let a = Pmark::gen()
  assert_eq(PmarkSet::single(a).is_empty(), false)
}

///|
test "PmarkSet::equal" {
  let a = Pmark::gen()
  let b = Pmark::gen()
  let s1 = PmarkSet::empty().add(a).add(b)
  let s2 = PmarkSet::empty().add(a).add(b)
  let s3 = PmarkSet::empty().add(a)
  assert_eq(PmarkSet::equal(s1, s2), true)
  assert_eq(PmarkSet::equal(s1, s3), false)
}

// === MarkInfos / MarkOffset ===

///|
test "MarkInfos::make and has" {
  let mi = MarkInfos::make([(0, 5), (1, 10)])
  assert_eq(MarkInfos::has(mi, 0), true)
  let mi2 = MarkInfos::make([])
  assert_eq(MarkInfos::has(mi2, 0), false)
}

///|
test "MarkInfos::offset" {
  let mi = MarkInfos::make([(0, 5), (2, 10)])
  match MarkInfos::offset(mi, 0) {
    Some((s, _)) => assert_eq(s, 5)
    None => assert_eq(true, false)
  }
  assert_eq(MarkInfos::offset(mi, 1), None)
}

///|
test "MarkInfos::start_offset / stop_offset" {
  let mi = MarkInfos::make([(0, 3), (1, 7)])
  let so = MarkInfos::start_offset(mi, 0)
  assert_eq(MarkOffset::is_present(so), true)
  assert_eq(MarkOffset::get_no_check(so), 3)
  let st = MarkInfos::stop_offset(mi, 0)
  assert_eq(MarkOffset::is_present(st), true)
  assert_eq(MarkOffset::get_no_check(st), 7)
}

///|
test "MarkInfos::iteri" {
  let mi = MarkInfos::make([(0, 1), (2, 3)])
  let count = Ref::{ val: 0 }
  MarkInfos::iteri(mi, fn(_i, _s, _st) { count.val += 1 })
  assert_eq(count.val, 1)
}

///|
test "MarkOffset::is_present false" {
  let mi = MarkInfos::make([])
  let mo = MarkInfos::start_offset(mi, 0)
  assert_eq(MarkOffset::is_present(mo), false)
}

// === BitVector safe get/set ===

///|
test "BitVector::set / get safe" {
  let bv = BitVector::create_zero(16)
  BitVector::set(bv, 5, true)
  assert_eq(BitVector::get(bv, 5), true)
  assert_eq(BitVector::get(bv, 4), false)
}

///|
test "BitVector::set out of bounds raises" {
  let bv = BitVector::create_zero(8)
  let raised = try {
    BitVector::set(bv, 10, true)
    false
  } catch {
    _ => true
  }
  assert_eq(raised, true)
}

///|
test "BitVector::get out of bounds raises" {
  let bv = BitVector::create_zero(8)
  let raised = try {
    let _ = BitVector::get(bv, 10)
    false
  } catch {
    _ => true
  }
  assert_eq(raised, true)
}
