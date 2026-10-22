// coverage_cset_test.mbt — CsetC/Cset/CSetMap coverage tests

// === CsetC ===

///|
test "CsetC::null_char is -1" {
  assert_eq(@base.CsetC::null_char(), -1)
}

///|
test "CsetC::equal_c" {
  assert_eq(@base.CsetC::equal_c(65, 65), true)
  assert_eq(@base.CsetC::equal_c(65, 66), false)
}

///|
test "CsetC::to_int / of_int" {
  assert_eq(@base.CsetC::to_int(65), 65)
  assert_eq(@base.CsetC::of_int(65), 65)
  assert_eq(@base.CsetC::to_int(@base.CsetC::of_int(42)), 42)
}

///|
test "CsetC::to_char / of_char" {
  assert_eq(@base.CsetC::to_char(65), 'A')
  assert_eq(@base.CsetC::of_char('A'), 65)
  assert_eq(@base.CsetC::to_int(@base.CsetC::of_char('z')), 122)
}

// === Cset advanced ===

///|
test "Cset::equal" {
  let a = @base.Cset::seq(0, 10)
  let b = @base.Cset::seq(0, 10)
  let c = @base.Cset::seq(0, 11)
  assert_eq(@base.Cset::equal(a, b), true)
  assert_eq(@base.Cset::equal(a, c), false)
  assert_eq(@base.Cset::equal(@base.Cset::empty(), @base.Cset::empty()), true)
}

///|
test "Cset::compare" {
  let a = @base.Cset::seq(0, 10)
  let b = @base.Cset::seq(0, 10)
  let c = @base.Cset::seq(0, 11)
  assert_eq(@base.Cset::compare(a, b), 0)
  assert_eq(@base.Cset::compare(a, c) < 0, true)
  assert_eq(@base.Cset::compare(c, a) > 0, true)
}

///|
test "Cset::csingle / cadd / cseq" {
  let s = @base.Cset::csingle('a')
  assert_eq(s.intervals, [(97, 97)])
  let s2 = @base.Cset::cadd('b', s)
  assert_eq(@base.Cset::mem(97, s2), true)
  assert_eq(@base.Cset::mem(98, s2), true)
  let r = @base.Cset::cseq('a', 'z')
  assert_eq(@base.Cset::mem(97, r), true)
  assert_eq(@base.Cset::mem(122, r), true)
  assert_eq(@base.Cset::mem(123, r), false)
}

///|
test "Cset::add" {
  let s = @base.Cset::add(65, @base.Cset::add(66, @base.Cset::empty()))
  assert_eq(@base.Cset::mem(65, s), true)
  assert_eq(@base.Cset::mem(66, s), true)
  assert_eq(@base.Cset::mem(67, s), false)
}

///|
test "Cset::offset" {
  let s = @base.Cset::seq(0, 10)
  let o = @base.Cset::offset(5, s)
  assert_eq(o.intervals, [(5, 15)])
}

///|
test "Cset::union_all" {
  let u = @base.Cset::union_all([
    @base.Cset::single(65),
    @base.Cset::single(66),
    @base.Cset::single(67),
  ])
  assert_eq(@base.Cset::mem(65, u), true)
  assert_eq(@base.Cset::mem(66, u), true)
  assert_eq(@base.Cset::mem(67, u), true)
  assert_eq(@base.Cset::mem(68, u), false)
}

///|
test "Cset::intersect_all" {
  let i = @base.Cset::intersect_all([
    @base.Cset::seq(0, 20),
    @base.Cset::seq(10, 30),
  ])
  assert_eq(i.intervals, [(10, 20)])
}

///|
test "Cset::hash consistency" {
  let a = @base.Cset::seq(0, 10)
  let b = @base.Cset::seq(0, 10)
  assert_eq(@base.Cset::hash(a, 0), @base.Cset::hash(b, 0))
}

///|
test "Cset::hash differs for different sets" {
  let a = @base.Cset::seq(0, 10)
  let b = @base.Cset::seq(0, 11)
  assert_eq(@base.Cset::hash(a, 0) == @base.Cset::hash(b, 0), false)
}

///|
test "Cset::iter" {
  let s = @base.Cset::union(@base.Cset::seq(0, 5), @base.Cset::seq(10, 15))
  let pairs : Array[(Int32, Int32)] = []
  @base.Cset::iter(s, f=fn(c1, c2) { pairs.push((c1, c2)) })
  assert_eq(pairs.length(), 2)
  assert_eq(pairs[0], (0, 5))
  assert_eq(pairs[1], (10, 15))
}

///|
test "Cset::pick" {
  let s = @base.Cset::seq(65, 90)
  assert_eq(@base.Cset::pick(s), 65)
}

///|
test "Cset::pick empty raises" {
  let s = @base.Cset::empty()
  let raised = try {
    let _ = @base.Cset::pick(s)
    false
  } catch {
    _ => true
  }
  assert_eq(raised, true)
}

///|
test "Cset::union_singles_in_strictly_decreasing_order" {
  let s = @base.Cset::union_singles_in_strictly_decreasing_order([
    10, 9, 8, 5, 3,
  ])
  assert_eq(@base.Cset::mem(8, s), true)
  assert_eq(@base.Cset::mem(9, s), true)
  assert_eq(@base.Cset::mem(10, s), true)
  assert_eq(@base.Cset::mem(5, s), true)
  assert_eq(@base.Cset::mem(3, s), true)
  assert_eq(@base.Cset::mem(7, s), false)
}

///|
test "Cset::union_singles empty" {
  let s = @base.Cset::union_singles_in_strictly_decreasing_order([])
  assert_eq(@base.Cset::is_empty(s), true)
}

// === Cset predefined sets ===

///|
test "Cset::upper" {
  let u = @base.Cset::upper()
  assert_eq(@base.Cset::mem(65, u), true)
  assert_eq(@base.Cset::mem(90, u), true)
  assert_eq(@base.Cset::mem(97, u), false)
}

///|
test "Cset::lower" {
  let l = @base.Cset::lower()
  assert_eq(@base.Cset::mem(97, l), true)
  assert_eq(@base.Cset::mem(122, l), true)
  assert_eq(@base.Cset::mem(65, l), false)
}

///|
test "Cset::alpha" {
  let a = @base.Cset::alpha()
  assert_eq(@base.Cset::mem(97, a), true)
  assert_eq(@base.Cset::mem(65, a), true)
  assert_eq(@base.Cset::mem(48, a), false)
}

///|
test "Cset::alnum" {
  let a = @base.Cset::alnum()
  assert_eq(@base.Cset::mem(97, a), true)
  assert_eq(@base.Cset::mem(65, a), true)
  assert_eq(@base.Cset::mem(48, a), true)
  assert_eq(@base.Cset::mem(32, a), false)
}

///|
test "Cset::wordc" {
  let w = @base.Cset::wordc()
  assert_eq(@base.Cset::mem(97, w), true)
  assert_eq(@base.Cset::mem(48, w), true)
  assert_eq(@base.Cset::mem(95, w), true)
  assert_eq(@base.Cset::mem(32, w), false)
}

///|
test "Cset::xdigit" {
  let x = @base.Cset::xdigit()
  assert_eq(@base.Cset::mem(48, x), true)
  assert_eq(@base.Cset::mem(57, x), true)
  assert_eq(@base.Cset::mem(97, x), true)
  assert_eq(@base.Cset::mem(102, x), true)
  assert_eq(@base.Cset::mem(65, x), true)
  assert_eq(@base.Cset::mem(70, x), true)
  assert_eq(@base.Cset::mem(103, x), false)
}

///|
test "Cset::space" {
  let s = @base.Cset::space()
  assert_eq(@base.Cset::mem(32, s), true)
  assert_eq(@base.Cset::mem(9, s), true)
  assert_eq(@base.Cset::mem(13, s), true)
  assert_eq(@base.Cset::mem(65, s), false)
}

///|
test "Cset::blank" {
  let b = @base.Cset::blank()
  assert_eq(@base.Cset::mem(32, b), true)
  assert_eq(@base.Cset::mem(9, b), true)
  assert_eq(@base.Cset::mem(10, b), false)
}

///|
test "Cset::notnl" {
  let n = @base.Cset::notnl()
  assert_eq(@base.Cset::mem(65, n), true)
  assert_eq(@base.Cset::mem(10, n), false)
}

///|
test "Cset::nl" {
  let n = @base.Cset::nl()
  assert_eq(@base.Cset::mem(10, n), true)
  assert_eq(@base.Cset::mem(65, n), false)
}

///|
test "Cset::ascii" {
  let a = @base.Cset::ascii()
  assert_eq(@base.Cset::mem(0, a), true)
  assert_eq(@base.Cset::mem(127, a), true)
  assert_eq(@base.Cset::mem(128, a), false)
}

///|
test "Cset::cntrl" {
  let c = @base.Cset::cntrl()
  assert_eq(@base.Cset::mem(0, c), true)
  assert_eq(@base.Cset::mem(31, c), true)
  assert_eq(@base.Cset::mem(65, c), false)
}

///|
test "Cset::graph" {
  let g = @base.Cset::graph()
  assert_eq(@base.Cset::mem(33, g), true)
  assert_eq(@base.Cset::mem(126, g), true)
  assert_eq(@base.Cset::mem(32, g), false)
}

///|
test "Cset::print" {
  let p = @base.Cset::print()
  assert_eq(@base.Cset::mem(32, p), true)
  assert_eq(@base.Cset::mem(126, p), true)
  assert_eq(@base.Cset::mem(31, p), false)
}

///|
test "Cset::punct" {
  let p = @base.Cset::punct()
  assert_eq(@base.Cset::mem(33, p), true)
  assert_eq(@base.Cset::mem(47, p), true)
  assert_eq(@base.Cset::mem(48, p), false)
}

///|
test "Cset::case_insens" {
  let s = @base.Cset::single(65)
  let ci = @base.Cset::case_insens(s)
  assert_eq(@base.Cset::mem(65, ci), true)
  assert_eq(@base.Cset::mem(97, ci), true)
}

// === CSetMap ===

///|
test "CSetMap::empty / find / add" {
  let m = @base.CSetMap::empty()
  let key = @base.Cset::single(65)
  let h = @base.Cset::hash(key, 0)
  assert_eq(@base.CSetMap::find(m, (h, key)), None)
  let m2 = @base.CSetMap::add(m, (h, key), @base.Cset::single(97))
  let found = @base.CSetMap::find(m2, (h, key))
  match found {
    Some(v) => assert_eq(@base.Cset::mem(97, v), true)
    None => assert_eq(true, false)
  }
}
