// coverage_marks_test.mbt — Category/Pmark/PmarkSet/MarkInfos/BitVector coverage tests

// === Category ===

///|
test "Category::from_int / to_int roundtrip" {
  let c = @re.Category::from_int(5)
  assert_eq(@re.Category::to_int(c), 5)
}

///|
test "Category::equal" {
  let a = @re.Category::from_int(5)
  let b = @re.Category::from_int(5)
  let c = @re.Category::from_int(6)
  assert_eq(@re.Category::equal(a, b), true)
  assert_eq(@re.Category::equal(a, c), false)
}

///|
test "Category::compare" {
  let a = @re.Category::from_int(5)
  let b = @re.Category::from_int(6)
  assert_eq(@re.Category::compare(a, b) < 0, true)
  assert_eq(@re.Category::compare(b, a) > 0, true)
  assert_eq(@re.Category::compare(a, a), 0)
}

///|
test "Category::add" {
  let a = @re.Category::from_int(2)
  let b = @re.Category::from_int(4)
  let c = @re.Category::add(a, b)
  assert_eq(@re.Category::to_int(c), 6)
}

///|
test "Category::dummy" {
  let d = @re.Category::dummy()
  assert_eq(@re.Category::to_int(d), -1)
}

///|
test "Category::inexistant" {
  let i = @re.Category::inexistant()
  assert_eq(@re.Category::to_int(i), 1)
}

///|
test "Category::not_letter" {
  let nl = @re.Category::not_letter()
  assert_eq(@re.Category::to_int(nl), 4)
}

///|
test "Category::lastnewline" {
  let ln = @re.Category::lastnewline()
  assert_eq(@re.Category::to_int(ln), 16)
}

///|
test "Category::search_boundary" {
  let sb = @re.Category::search_boundary()
  assert_eq(@re.Category::to_int(sb), 32)
}

///|
test "Category::from_char newline" {
  let c = @re.Category::from_char('\n')
  assert_eq(@re.Category::intersect(c, @re.Category::newline()), true)
  assert_eq(@re.Category::intersect(c, @re.Category::not_letter()), true)
}

// === Pmark ===

///|
test "Pmark::compare" {
  let a = @re.Pmark::gen()
  let b = @re.Pmark::gen()
  assert_eq(@re.Pmark::compare(a, b) < 0, true)
  assert_eq(@re.Pmark::compare(b, a) > 0, true)
  assert_eq(@re.Pmark::compare(a, a), 0)
}

///|
test "Pmark::to_int" {
  let a = @re.Pmark::gen()
  assert_eq(@re.Pmark::to_int(a), a.id)
}

// === PmarkSet ===

///|
test "PmarkSet::single" {
  let a = @re.Pmark::gen()
  let s = @re.PmarkSet::single(a)
  assert_eq(s.mem(a), true)
  assert_eq(s.length(), 1)
}

///|
test "PmarkSet::union" {
  let a = @re.Pmark::gen()
  let b = @re.Pmark::gen()
  let s1 = @re.PmarkSet::single(a)
  let s2 = @re.PmarkSet::single(b)
  let u = @re.PmarkSet::union(s1, s2)
  assert_eq(u.mem(a), true)
  assert_eq(u.mem(b), true)
  assert_eq(u.length(), 2)
}

///|
test "PmarkSet::union dedup" {
  let a = @re.Pmark::gen()
  let s1 = @re.PmarkSet::single(a)
  let s2 = @re.PmarkSet::single(a)
  let u = @re.PmarkSet::union(s1, s2)
  assert_eq(u.length(), 1)
}

///|
test "PmarkSet::iter" {
  let a = @re.Pmark::gen()
  let b = @re.Pmark::gen()
  let s = @re.PmarkSet::empty().add(a).add(b)
  let count = Ref::{ val: 0 }
  @re.PmarkSet::iter(s, fn(_) { count.val += 1 })
  assert_eq(count.val, 2)
}

///|
test "PmarkSet::to_list" {
  let a = @re.Pmark::gen()
  let b = @re.Pmark::gen()
  let s = @re.PmarkSet::empty().add(a).add(b)
  let lst = @re.PmarkSet::to_list(s)
  assert_eq(lst.length(), 2)
}

///|
test "PmarkSet::is_empty" {
  assert_eq(@re.PmarkSet::empty().is_empty(), true)
  let a = @re.Pmark::gen()
  assert_eq(@re.PmarkSet::single(a).is_empty(), false)
}

///|
test "PmarkSet::equal" {
  let a = @re.Pmark::gen()
  let b = @re.Pmark::gen()
  let s1 = @re.PmarkSet::empty().add(a).add(b)
  let s2 = @re.PmarkSet::empty().add(a).add(b)
  let s3 = @re.PmarkSet::empty().add(a)
  assert_eq(@re.PmarkSet::equal(s1, s2), true)
  assert_eq(@re.PmarkSet::equal(s1, s3), false)
}

// === MarkInfos / MarkOffset ===

///|
test "MarkInfos::make and has" {
  let mi = @re.MarkInfos::make([(0, 5), (1, 10)])
  assert_eq(@re.MarkInfos::has(mi, 0), true)
  let mi2 = @re.MarkInfos::make([])
  assert_eq(@re.MarkInfos::has(mi2, 0), false)
}

///|
test "MarkInfos::offset" {
  let mi = @re.MarkInfos::make([(0, 5), (2, 10)])
  match @re.MarkInfos::offset(mi, 0) {
    Some((s, _)) => assert_eq(s, 5)
    None => assert_eq(true, false)
  }
  assert_eq(@re.MarkInfos::offset(mi, 1), None)
}

///|
test "MarkInfos::start_offset / stop_offset" {
  let mi = @re.MarkInfos::make([(0, 3), (1, 7)])
  let so = @re.MarkInfos::start_offset(mi, 0)
  assert_eq(@re.MarkOffset::is_present(so), true)
  assert_eq(@re.MarkOffset::get_no_check(so), 3)
  let st = @re.MarkInfos::stop_offset(mi, 0)
  assert_eq(@re.MarkOffset::is_present(st), true)
  assert_eq(@re.MarkOffset::get_no_check(st), 7)
}

///|
test "MarkInfos::iteri" {
  let mi = @re.MarkInfos::make([(0, 1), (2, 3)])
  let count = Ref::{ val: 0 }
  @re.MarkInfos::iteri(mi, fn(_i, _s, _st) { count.val += 1 })
  assert_eq(count.val, 1)
}

///|
test "MarkOffset::is_present false" {
  let mi = @re.MarkInfos::make([])
  let mo = @re.MarkInfos::start_offset(mi, 0)
  assert_eq(@re.MarkOffset::is_present(mo), false)
}

// === BitVector safe get/set ===

///|
test "BitVector::set / get safe" {
  let bv = @re.BitVector::create_zero(16)
  @re.BitVector::set(bv, 5, true)
  assert_eq(@re.BitVector::get(bv, 5), true)
  assert_eq(@re.BitVector::get(bv, 4), false)
}

///|
test "BitVector::set out of bounds raises" {
  let bv = @re.BitVector::create_zero(8)
  let raised = try {
    @re.BitVector::set(bv, 10, true)
    false
  } catch {
    _ => true
  }
  assert_eq(raised, true)
}

///|
test "BitVector::get out of bounds raises" {
  let bv = @re.BitVector::create_zero(8)
  let raised = try {
    let _ = @re.BitVector::get(bv, 10)
    false
  } catch {
    _ => true
  }
  assert_eq(raised, true)
}
