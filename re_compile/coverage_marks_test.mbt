// coverage_marks_test.mbt — Category/Pmark/PmarkSet/MarkInfos/BitVector coverage tests

// === Category ===

///|
test "Category::from_int / to_int roundtrip" {
  let c = @base.Category::from_int(5)
  assert_eq(@base.Category::to_int(c), 5)
}

///|
test "Category::equal" {
  let a = @base.Category::from_int(5)
  let b = @base.Category::from_int(5)
  let c = @base.Category::from_int(6)
  assert_eq(@base.Category::equal(a, b), true)
  assert_eq(@base.Category::equal(a, c), false)
}

///|
test "Category::compare" {
  let a = @base.Category::from_int(5)
  let b = @base.Category::from_int(6)
  assert_eq(@base.Category::compare(a, b) < 0, true)
  assert_eq(@base.Category::compare(b, a) > 0, true)
  assert_eq(@base.Category::compare(a, a), 0)
}

///|
test "Category::add" {
  let a = @base.Category::from_int(2)
  let b = @base.Category::from_int(4)
  let c = @base.Category::add(a, b)
  assert_eq(@base.Category::to_int(c), 6)
}

///|
test "Category::dummy" {
  let d = @base.Category::dummy()
  assert_eq(@base.Category::to_int(d), -1)
}

///|
test "Category::inexistant" {
  let i = @base.Category::inexistant()
  assert_eq(@base.Category::to_int(i), 1)
}

///|
test "Category::not_letter" {
  let nl = @base.Category::not_letter()
  assert_eq(@base.Category::to_int(nl), 4)
}

///|
test "Category::lastnewline" {
  let ln = @base.Category::lastnewline()
  assert_eq(@base.Category::to_int(ln), 16)
}

///|
test "Category::search_boundary" {
  let sb = @base.Category::search_boundary()
  assert_eq(@base.Category::to_int(sb), 32)
}

///|
test "Category::from_char newline" {
  let c = @base.Category::from_char('\n')
  assert_eq(@base.Category::intersect(c, @base.Category::newline()), true)
  assert_eq(@base.Category::intersect(c, @base.Category::not_letter()), true)
}

// === Pmark ===

///|
test "Pmark::compare" {
  let a = @base.Pmark::gen()
  let b = @base.Pmark::gen()
  assert_eq(@base.Pmark::compare(a, b) < 0, true)
  assert_eq(@base.Pmark::compare(b, a) > 0, true)
  assert_eq(@base.Pmark::compare(a, a), 0)
}

///|
test "Pmark::to_int" {
  let a = @base.Pmark::gen()
  assert_eq(@base.Pmark::to_int(a), a.id)
}

// === PmarkSet ===

///|
test "PmarkSet::single" {
  let a = @base.Pmark::gen()
  let s = @base.PmarkSet::single(a)
  assert_eq(s.mem(a), true)
  assert_eq(s.length(), 1)
}

///|
test "PmarkSet::union" {
  let a = @base.Pmark::gen()
  let b = @base.Pmark::gen()
  let s1 = @base.PmarkSet::single(a)
  let s2 = @base.PmarkSet::single(b)
  let u = @base.PmarkSet::union(s1, s2)
  assert_eq(u.mem(a), true)
  assert_eq(u.mem(b), true)
  assert_eq(u.length(), 2)
}

///|
test "PmarkSet::union dedup" {
  let a = @base.Pmark::gen()
  let s1 = @base.PmarkSet::single(a)
  let s2 = @base.PmarkSet::single(a)
  let u = @base.PmarkSet::union(s1, s2)
  assert_eq(u.length(), 1)
}

///|
test "PmarkSet::iter" {
  let a = @base.Pmark::gen()
  let b = @base.Pmark::gen()
  let s = @base.PmarkSet::empty().add(a).add(b)
  let count = Ref::{ val: 0, }
  @base.PmarkSet::iter(s, fn(_) { count.val += 1 })
  assert_eq(count.val, 2)
}

///|
test "PmarkSet::to_list" {
  let a = @base.Pmark::gen()
  let b = @base.Pmark::gen()
  let s = @base.PmarkSet::empty().add(a).add(b)
  let lst = @base.PmarkSet::to_list(s)
  assert_eq(lst.length(), 2)
}

///|
test "PmarkSet::is_empty" {
  assert_eq(@base.PmarkSet::empty().is_empty(), true)
  let a = @base.Pmark::gen()
  assert_eq(@base.PmarkSet::single(a).is_empty(), false)
}

///|
test "PmarkSet::equal" {
  let a = @base.Pmark::gen()
  let b = @base.Pmark::gen()
  let s1 = @base.PmarkSet::empty().add(a).add(b)
  let s2 = @base.PmarkSet::empty().add(a).add(b)
  let s3 = @base.PmarkSet::empty().add(a)
  assert_eq(@base.PmarkSet::equal(s1, s2), true)
  assert_eq(@base.PmarkSet::equal(s1, s3), false)
}

// === MarkInfos / MarkOffset ===

///|
test "MarkInfos::make and has" {
  let mi = @base.MarkInfos::make([(0, 5), (1, 10)])
  assert_eq(@base.MarkInfos::has(mi, 0), true)
  let mi2 = @base.MarkInfos::make([])
  assert_eq(@base.MarkInfos::has(mi2, 0), false)
}

///|
test "MarkInfos::offset" {
  let mi = @base.MarkInfos::make([(0, 5), (2, 10)])
  match @base.MarkInfos::offset(mi, 0) {
    Some((s, _)) => assert_eq(s, 5)
    None => assert_eq(true, false)
  }
  assert_eq(@base.MarkInfos::offset(mi, 1), None)
}

///|
test "MarkInfos::start_offset / stop_offset" {
  let mi = @base.MarkInfos::make([(0, 3), (1, 7)])
  let so = @base.MarkInfos::start_offset(mi, 0)
  assert_eq(@base.MarkOffset::is_present(so), true)
  assert_eq(@base.MarkOffset::get_no_check(so), 3)
  let st = @base.MarkInfos::stop_offset(mi, 0)
  assert_eq(@base.MarkOffset::is_present(st), true)
  assert_eq(@base.MarkOffset::get_no_check(st), 7)
}

///|
test "MarkInfos::iteri" {
  let mi = @base.MarkInfos::make([(0, 1), (2, 3)])
  let count = Ref::{ val: 0, }
  @base.MarkInfos::iteri(mi, fn(_i, _s, _st) { count.val += 1 })
  assert_eq(count.val, 1)
}

///|
test "MarkOffset::is_present false" {
  let mi = @base.MarkInfos::make([])
  let mo = @base.MarkInfos::start_offset(mi, 0)
  assert_eq(@base.MarkOffset::is_present(mo), false)
}

// === BitVector safe get/set ===

///|
test "BitVector::set / get safe" {
  let bv = @base.BitVector::create_zero(16)
  @base.BitVector::set(bv, 5, true)
  assert_eq(@base.BitVector::get(bv, 5), true)
  assert_eq(@base.BitVector::get(bv, 4), false)
}

///|
test "BitVector::set out of bounds raises" {
  let bv = @base.BitVector::create_zero(8)
  let raised = try {
    @base.BitVector::set(bv, 10, true)
    false
  } catch {
    _ => true
  }
  assert_eq(raised, true)
}

///|
test "BitVector::get out of bounds raises" {
  let bv = @base.BitVector::create_zero(8)
  let raised = try {
    let _ = @base.BitVector::get(bv, 10)
    false
  } catch {
    _ => true
  }
  assert_eq(raised, true)
}
