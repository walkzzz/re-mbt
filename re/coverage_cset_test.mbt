// coverage_cset_test.mbt — CsetC/Cset/CSetMap coverage tests

// === CsetC ===

///|
test "CsetC::null_char is -1" {
  assert_eq(@re.CsetC::null_char(), -1)
}

///|
test "CsetC::equal_c" {
  assert_eq(@re.CsetC::equal_c(65, 65), true)
  assert_eq(@re.CsetC::equal_c(65, 66), false)
}

///|
test "CsetC::to_int / of_int" {
  assert_eq(@re.CsetC::to_int(65), 65)
  assert_eq(@re.CsetC::of_int(65), 65)
  assert_eq(@re.CsetC::to_int(@re.CsetC::of_int(42)), 42)
}

///|
test "CsetC::to_char / of_char" {
  assert_eq(@re.CsetC::to_char(65), 'A')
  assert_eq(@re.CsetC::of_char('A'), 65)
  assert_eq(@re.CsetC::to_int(@re.CsetC::of_char('z')), 122)
}

// === Cset advanced ===

///|
test "Cset::equal" {
  let a = @re.Cset::seq(0, 10)
  let b = @re.Cset::seq(0, 10)
  let c = @re.Cset::seq(0, 11)
  assert_eq(@re.Cset::equal(a, b), true)
  assert_eq(@re.Cset::equal(a, c), false)
  assert_eq(@re.Cset::equal(@re.Cset::empty(), @re.Cset::empty()), true)
}

///|
test "Cset::compare" {
  let a = @re.Cset::seq(0, 10)
  let b = @re.Cset::seq(0, 10)
  let c = @re.Cset::seq(0, 11)
  assert_eq(@re.Cset::compare(a, b), 0)
  assert_eq(@re.Cset::compare(a, c) < 0, true)
  assert_eq(@re.Cset::compare(c, a) > 0, true)
}

///|
test "Cset::csingle / cadd / cseq" {
  let s = @re.Cset::csingle('a')
  assert_eq(s.intervals, [(97, 97)])
  let s2 = @re.Cset::cadd('b', s)
  assert_eq(@re.Cset::mem(97, s2), true)
  assert_eq(@re.Cset::mem(98, s2), true)
  let r = @re.Cset::cseq('a', 'z')
  assert_eq(@re.Cset::mem(97, r), true)
  assert_eq(@re.Cset::mem(122, r), true)
  assert_eq(@re.Cset::mem(123, r), false)
}

///|
test "Cset::add" {
  let s = @re.Cset::add(65, @re.Cset::add(66, @re.Cset::empty()))
  assert_eq(@re.Cset::mem(65, s), true)
  assert_eq(@re.Cset::mem(66, s), true)
  assert_eq(@re.Cset::mem(67, s), false)
}

///|
test "Cset::offset" {
  let s = @re.Cset::seq(0, 10)
  let o = @re.Cset::offset(5, s)
  assert_eq(o.intervals, [(5, 15)])
}

///|
test "Cset::union_all" {
  let u = @re.Cset::union_all([@re.Cset::single(65), @re.Cset::single(66), @re.Cset::single(67)])
  assert_eq(@re.Cset::mem(65, u), true)
  assert_eq(@re.Cset::mem(66, u), true)
  assert_eq(@re.Cset::mem(67, u), true)
  assert_eq(@re.Cset::mem(68, u), false)
}

///|
test "Cset::intersect_all" {
  let i = @re.Cset::intersect_all([@re.Cset::seq(0, 20), @re.Cset::seq(10, 30)])
  assert_eq(i.intervals, [(10, 20)])
}

///|
test "Cset::hash consistency" {
  let a = @re.Cset::seq(0, 10)
  let b = @re.Cset::seq(0, 10)
  assert_eq(@re.Cset::hash(a), @re.Cset::hash(b))
}

///|
test "Cset::hash differs for different sets" {
  let a = @re.Cset::seq(0, 10)
  let b = @re.Cset::seq(0, 11)
  assert_eq(@re.Cset::hash(a) == @re.Cset::hash(b), false)
}

///|
test "Cset::iter" {
  let s = @re.Cset::union(@re.Cset::seq(0, 5), @re.Cset::seq(10, 15))
  let pairs : Array[(Int, Int)] = []
  @re.Cset::iter(s, f=fn(c1, c2) { pairs.push((c1, c2)) })
  assert_eq(pairs.length(), 2)
  assert_eq(pairs[0], (0, 5))
  assert_eq(pairs[1], (10, 15))
}

///|
test "Cset::pick" {
  let s = @re.Cset::seq(65, 90)
  assert_eq(@re.Cset::pick(s), 65)
}

///|
test "Cset::pick empty raises" {
  let s = @re.Cset::empty()
  let raised = try {
    let _ = @re.Cset::pick(s)
    false
  } catch {
    _ => true
  }
  assert_eq(raised, true)
}

///|
test "Cset::union_singles_in_strictly_decreasing_order" {
  let s = @re.Cset::union_singles_in_strictly_decreasing_order([10, 9, 8, 5, 3])
  assert_eq(@re.Cset::mem(8, s), true)
  assert_eq(@re.Cset::mem(9, s), true)
  assert_eq(@re.Cset::mem(10, s), true)
  assert_eq(@re.Cset::mem(5, s), true)
  assert_eq(@re.Cset::mem(3, s), true)
  assert_eq(@re.Cset::mem(7, s), false)
}

///|
test "Cset::union_singles empty" {
  let s = @re.Cset::union_singles_in_strictly_decreasing_order([])
  assert_eq(@re.Cset::is_empty(s), true)
}

// === Cset predefined sets ===

///|
test "Cset::upper" {
  let u = @re.Cset::upper()
  assert_eq(@re.Cset::mem(65, u), true)
  assert_eq(@re.Cset::mem(90, u), true)
  assert_eq(@re.Cset::mem(97, u), false)
}

///|
test "Cset::lower" {
  let l = @re.Cset::lower()
  assert_eq(@re.Cset::mem(97, l), true)
  assert_eq(@re.Cset::mem(122, l), true)
  assert_eq(@re.Cset::mem(65, l), false)
}

///|
test "Cset::alpha" {
  let a = @re.Cset::alpha()
  assert_eq(@re.Cset::mem(97, a), true)
  assert_eq(@re.Cset::mem(65, a), true)
  assert_eq(@re.Cset::mem(48, a), false)
}

///|
test "Cset::alnum" {
  let a = @re.Cset::alnum()
  assert_eq(@re.Cset::mem(97, a), true)
  assert_eq(@re.Cset::mem(65, a), true)
  assert_eq(@re.Cset::mem(48, a), true)
  assert_eq(@re.Cset::mem(32, a), false)
}

///|
test "Cset::wordc" {
  let w = @re.Cset::wordc()
  assert_eq(@re.Cset::mem(97, w), true)
  assert_eq(@re.Cset::mem(48, w), true)
  assert_eq(@re.Cset::mem(95, w), true)
  assert_eq(@re.Cset::mem(32, w), false)
}

///|
test "Cset::xdigit" {
  let x = @re.Cset::xdigit()
  assert_eq(@re.Cset::mem(48, x), true)
  assert_eq(@re.Cset::mem(57, x), true)
  assert_eq(@re.Cset::mem(97, x), true)
  assert_eq(@re.Cset::mem(102, x), true)
  assert_eq(@re.Cset::mem(65, x), true)
  assert_eq(@re.Cset::mem(70, x), true)
  assert_eq(@re.Cset::mem(103, x), false)
}

///|
test "Cset::space" {
  let s = @re.Cset::space()
  assert_eq(@re.Cset::mem(32, s), true)
  assert_eq(@re.Cset::mem(9, s), true)
  assert_eq(@re.Cset::mem(13, s), true)
  assert_eq(@re.Cset::mem(65, s), false)
}

///|
test "Cset::blank" {
  let b = @re.Cset::blank()
  assert_eq(@re.Cset::mem(32, b), true)
  assert_eq(@re.Cset::mem(9, b), true)
  assert_eq(@re.Cset::mem(10, b), false)
}

///|
test "Cset::notnl" {
  let n = @re.Cset::notnl()
  assert_eq(@re.Cset::mem(65, n), true)
  assert_eq(@re.Cset::mem(10, n), false)
}

///|
test "Cset::nl" {
  let n = @re.Cset::nl()
  assert_eq(@re.Cset::mem(10, n), true)
  assert_eq(@re.Cset::mem(65, n), false)
}

///|
test "Cset::ascii" {
  let a = @re.Cset::ascii()
  assert_eq(@re.Cset::mem(0, a), true)
  assert_eq(@re.Cset::mem(127, a), true)
  assert_eq(@re.Cset::mem(128, a), false)
}

///|
test "Cset::cntrl" {
  let c = @re.Cset::cntrl()
  assert_eq(@re.Cset::mem(0, c), true)
  assert_eq(@re.Cset::mem(31, c), true)
  assert_eq(@re.Cset::mem(65, c), false)
}

///|
test "Cset::graph" {
  let g = @re.Cset::graph()
  assert_eq(@re.Cset::mem(33, g), true)
  assert_eq(@re.Cset::mem(126, g), true)
  assert_eq(@re.Cset::mem(32, g), false)
}

///|
test "Cset::print" {
  let p = @re.Cset::print()
  assert_eq(@re.Cset::mem(32, p), true)
  assert_eq(@re.Cset::mem(126, p), true)
  assert_eq(@re.Cset::mem(31, p), false)
}

///|
test "Cset::punct" {
  let p = @re.Cset::punct()
  assert_eq(@re.Cset::mem(33, p), true)
  assert_eq(@re.Cset::mem(47, p), true)
  assert_eq(@re.Cset::mem(48, p), false)
}

///|
test "Cset::case_insens" {
  let s = @re.Cset::single(65)
  let ci = @re.Cset::case_insens(s)
  assert_eq(@re.Cset::mem(65, ci), true)
  assert_eq(@re.Cset::mem(97, ci), true)
}

// === CSetMap ===

///|
test "CSetMap::empty / find / add" {
  let m = @re.CSetMap::empty()
  let key = @re.Cset::single(65)
  let h = @re.Cset::hash(key)
  assert_eq(@re.CSetMap::find(m, (h, key)), None)
  let m2 = @re.CSetMap::add(m, (h, key), @re.Cset::single(97))
  let found = @re.CSetMap::find(m2, (h, key))
  match found {
    Some(v) => assert_eq(@re.Cset::mem(97, v), true)
    None => assert_eq(true, false)
  }
}
