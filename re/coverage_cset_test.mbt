// coverage_cset_test.mbt — CsetC/Cset/CSetMap coverage tests

// === CsetC ===

///|
test "CsetC::null_char is -1" {
  assert_eq(CsetC::null_char(), -1)
}

///|
test "CsetC::equal_c" {
  assert_eq(CsetC::equal_c(65, 65), true)
  assert_eq(CsetC::equal_c(65, 66), false)
}

///|
test "CsetC::to_int / of_int" {
  assert_eq(CsetC::to_int(65), 65)
  assert_eq(CsetC::of_int(65), 65)
  assert_eq(CsetC::to_int(CsetC::of_int(42)), 42)
}

///|
test "CsetC::to_char / of_char" {
  assert_eq(CsetC::to_char(65), 'A')
  assert_eq(CsetC::of_char('A'), 65)
  assert_eq(CsetC::to_int(CsetC::of_char('z')), 122)
}

// === Cset advanced ===

///|
test "Cset::equal" {
  let a = Cset::seq(0, 10)
  let b = Cset::seq(0, 10)
  let c = Cset::seq(0, 11)
  assert_eq(Cset::equal(a, b), true)
  assert_eq(Cset::equal(a, c), false)
  assert_eq(Cset::equal(Cset::empty(), Cset::empty()), true)
}

///|
test "Cset::compare" {
  let a = Cset::seq(0, 10)
  let b = Cset::seq(0, 10)
  let c = Cset::seq(0, 11)
  assert_eq(Cset::compare(a, b), 0)
  assert_eq(Cset::compare(a, c) < 0, true)
  assert_eq(Cset::compare(c, a) > 0, true)
}

///|
test "Cset::csingle / cadd / cseq" {
  let s = Cset::csingle('a')
  assert_eq(s.intervals, [(97, 97)])
  let s2 = Cset::cadd('b', s)
  assert_eq(Cset::mem(97, s2), true)
  assert_eq(Cset::mem(98, s2), true)
  let r = Cset::cseq('a', 'z')
  assert_eq(Cset::mem(97, r), true)
  assert_eq(Cset::mem(122, r), true)
  assert_eq(Cset::mem(123, r), false)
}

///|
test "Cset::add" {
  let s = Cset::add(65, Cset::add(66, Cset::empty()))
  assert_eq(Cset::mem(65, s), true)
  assert_eq(Cset::mem(66, s), true)
  assert_eq(Cset::mem(67, s), false)
}

///|
test "Cset::offset" {
  let s = Cset::seq(0, 10)
  let o = Cset::offset(5, s)
  assert_eq(o.intervals, [(5, 15)])
}

///|
test "Cset::union_all" {
  let u = Cset::union_all([Cset::single(65), Cset::single(66), Cset::single(67)])
  assert_eq(Cset::mem(65, u), true)
  assert_eq(Cset::mem(66, u), true)
  assert_eq(Cset::mem(67, u), true)
  assert_eq(Cset::mem(68, u), false)
}

///|
test "Cset::intersect_all" {
  let i = Cset::intersect_all([Cset::seq(0, 20), Cset::seq(10, 30)])
  assert_eq(i.intervals, [(10, 20)])
}

///|
test "Cset::hash consistency" {
  let a = Cset::seq(0, 10)
  let b = Cset::seq(0, 10)
  assert_eq(Cset::hash(a), Cset::hash(b))
}

///|
test "Cset::hash differs for different sets" {
  let a = Cset::seq(0, 10)
  let b = Cset::seq(0, 11)
  assert_eq(Cset::hash(a) == Cset::hash(b), false)
}

///|
test "Cset::iter" {
  let s = Cset::union(Cset::seq(0, 5), Cset::seq(10, 15))
  let pairs : Array[(Int, Int)] = []
  Cset::iter(s, f=fn(c1, c2) { pairs.push((c1, c2)) })
  assert_eq(pairs.length(), 2)
  assert_eq(pairs[0], (0, 5))
  assert_eq(pairs[1], (10, 15))
}

///|
test "Cset::pick" {
  let s = Cset::seq(65, 90)
  assert_eq(Cset::pick(s), 65)
}

///|
test "Cset::pick empty raises" {
  let s = Cset::empty()
  let raised = try {
    let _ = Cset::pick(s)
    false
  } catch {
    _ => true
  }
  assert_eq(raised, true)
}

///|
test "Cset::union_singles_in_strictly_decreasing_order" {
  let s = Cset::union_singles_in_strictly_decreasing_order([10, 9, 8, 5, 3])
  assert_eq(Cset::mem(8, s), true)
  assert_eq(Cset::mem(9, s), true)
  assert_eq(Cset::mem(10, s), true)
  assert_eq(Cset::mem(5, s), true)
  assert_eq(Cset::mem(3, s), true)
  assert_eq(Cset::mem(7, s), false)
}

///|
test "Cset::union_singles empty" {
  let s = Cset::union_singles_in_strictly_decreasing_order([])
  assert_eq(Cset::is_empty(s), true)
}

// === Cset predefined sets ===

///|
test "Cset::upper" {
  let u = Cset::upper()
  assert_eq(Cset::mem(65, u), true)
  assert_eq(Cset::mem(90, u), true)
  assert_eq(Cset::mem(97, u), false)
}

///|
test "Cset::lower" {
  let l = Cset::lower()
  assert_eq(Cset::mem(97, l), true)
  assert_eq(Cset::mem(122, l), true)
  assert_eq(Cset::mem(65, l), false)
}

///|
test "Cset::alpha" {
  let a = Cset::alpha()
  assert_eq(Cset::mem(97, a), true)
  assert_eq(Cset::mem(65, a), true)
  assert_eq(Cset::mem(48, a), false)
}

///|
test "Cset::alnum" {
  let a = Cset::alnum()
  assert_eq(Cset::mem(97, a), true)
  assert_eq(Cset::mem(65, a), true)
  assert_eq(Cset::mem(48, a), true)
  assert_eq(Cset::mem(32, a), false)
}

///|
test "Cset::wordc" {
  let w = Cset::wordc()
  assert_eq(Cset::mem(97, w), true)
  assert_eq(Cset::mem(48, w), true)
  assert_eq(Cset::mem(95, w), true)
  assert_eq(Cset::mem(32, w), false)
}

///|
test "Cset::xdigit" {
  let x = Cset::xdigit()
  assert_eq(Cset::mem(48, x), true)
  assert_eq(Cset::mem(57, x), true)
  assert_eq(Cset::mem(97, x), true)
  assert_eq(Cset::mem(102, x), true)
  assert_eq(Cset::mem(65, x), true)
  assert_eq(Cset::mem(70, x), true)
  assert_eq(Cset::mem(103, x), false)
}

///|
test "Cset::space" {
  let s = Cset::space()
  assert_eq(Cset::mem(32, s), true)
  assert_eq(Cset::mem(9, s), true)
  assert_eq(Cset::mem(13, s), true)
  assert_eq(Cset::mem(65, s), false)
}

///|
test "Cset::blank" {
  let b = Cset::blank()
  assert_eq(Cset::mem(32, b), true)
  assert_eq(Cset::mem(9, b), true)
  assert_eq(Cset::mem(10, b), false)
}

///|
test "Cset::notnl" {
  let n = Cset::notnl()
  assert_eq(Cset::mem(65, n), true)
  assert_eq(Cset::mem(10, n), false)
}

///|
test "Cset::nl" {
  let n = Cset::nl()
  assert_eq(Cset::mem(10, n), true)
  assert_eq(Cset::mem(65, n), false)
}

///|
test "Cset::ascii" {
  let a = Cset::ascii()
  assert_eq(Cset::mem(0, a), true)
  assert_eq(Cset::mem(127, a), true)
  assert_eq(Cset::mem(128, a), false)
}

///|
test "Cset::cntrl" {
  let c = Cset::cntrl()
  assert_eq(Cset::mem(0, c), true)
  assert_eq(Cset::mem(31, c), true)
  assert_eq(Cset::mem(65, c), false)
}

///|
test "Cset::graph" {
  let g = Cset::graph()
  assert_eq(Cset::mem(33, g), true)
  assert_eq(Cset::mem(126, g), true)
  assert_eq(Cset::mem(32, g), false)
}

///|
test "Cset::print" {
  let p = Cset::print()
  assert_eq(Cset::mem(32, p), true)
  assert_eq(Cset::mem(126, p), true)
  assert_eq(Cset::mem(31, p), false)
}

///|
test "Cset::punct" {
  let p = Cset::punct()
  assert_eq(Cset::mem(33, p), true)
  assert_eq(Cset::mem(47, p), true)
  assert_eq(Cset::mem(48, p), false)
}

///|
test "Cset::case_insens" {
  let s = Cset::single(65)
  let ci = Cset::case_insens(s)
  assert_eq(Cset::mem(65, ci), true)
  assert_eq(Cset::mem(97, ci), true)
}

// === CSetMap ===

///|
test "CSetMap::empty / find / add" {
  let m = CSetMap::empty()
  let key = Cset::single(65)
  let h = Cset::hash(key)
  assert_eq(CSetMap::find(m, (h, key)), None)
  let m2 = CSetMap::add(m, (h, key), Cset::single(97))
  let found = CSetMap::find(m2, (h, key))
  match found {
    Some(v) => assert_eq(Cset::mem(97, v), true)
    None => assert_eq(true, false)
  }
}
