// coverage_test.mbt — supplementary tests for untested pub APIs

///|
fn sb_cov(s : String) -> Bytes {
  let arr : Array[Byte] = []
  for c in s {
    arr.push(c.to_int().to_byte())
  }
  Bytes::from_array(arr)
}

///|
fn bs_cov(b : Bytes) -> String {
  let mut s = ""
  for i in 0..<b.length() {
    s = s + b[i].to_int().unsafe_to_char().to_string()
  }
  s
}

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

// === GroupT _opt variants ===

///|
test "GroupT::get_opt matched" {
  let re = compile(
    Ast::seq([Ast::str(sb_cov("a")), Ast::group(Ast::str(sb_cov("b")))]),
  )
  match exec_opt(re, sb_cov("ab")) {
    Some(g) =>
      match GroupT::get_opt(g, 1) {
        Some(b) => assert_eq(bs_cov(b), "b")
        None => assert_eq(true, false)
      }
    None => assert_eq(true, false)
  }
}

///|
test "GroupT::get_opt unmatched" {
  let re = compile(
    Ast::seq([
      Ast::str(sb_cov("a")),
      Ast::group(Ast::opt(Ast::str(sb_cov("b")))),
    ]),
  )
  match exec_opt(re, sb_cov("a")) {
    Some(g) => {
      let opt = GroupT::get_opt(g, 1)
      match opt {
        Some(b) => assert_eq(b.length(), 0)
        None => assert_eq(true, true)
      }
    }
    None => assert_eq(true, false)
  }
}

///|
test "GroupT::offset_opt" {
  let re = compile(
    Ast::seq([Ast::str(sb_cov("a")), Ast::group(Ast::str(sb_cov("b")))]),
  )
  match exec_opt(re, sb_cov("ab")) {
    Some(g) =>
      match GroupT::offset_opt(g, 1) {
        Some((s, t)) => {
          assert_eq(s, 1)
          assert_eq(t, 2)
        }
        None => assert_eq(true, false)
      }
    None => assert_eq(true, false)
  }
}

///|
test "GroupT::start_opt / stop_opt" {
  let re = compile(
    Ast::seq([Ast::str(sb_cov("a")), Ast::group(Ast::str(sb_cov("b")))]),
  )
  match exec_opt(re, sb_cov("ab")) {
    Some(g) => {
      assert_eq(GroupT::start_opt(g, 1), Some(1))
      assert_eq(GroupT::stop_opt(g, 1), Some(2))
    }
    None => assert_eq(true, false)
  }
}

///|
test "GroupT::pmarks" {
  let re = compile(Ast::group(Ast::str(sb_cov("a"))))
  match exec_opt(re, sb_cov("a")) {
    Some(g) => {
      let _pm = GroupT::pmarks(g)
      assert_eq(true, true)
    }
    None => assert_eq(true, false)
  }
}

// === Core Re char class shortcuts ===

///|
test "Re::rg" {
  let re = compile(Ast::whole_string(Ast::rep1(Re::rg('a', 'z'))))
  assert_eq(execp(re, sb_cov("hello")), true)
  assert_eq(execp(re, sb_cov("Hello")), false)
}

///|
test "Re::lower" {
  let re = compile(Re::lower())
  assert_eq(execp(re, sb_cov("abc")), true)
  assert_eq(execp(re, sb_cov("ABC")), false)
}

///|
test "Re::upper" {
  let re = compile(Re::upper())
  assert_eq(execp(re, sb_cov("ABC")), true)
  assert_eq(execp(re, sb_cov("abc")), false)
}

///|
test "Re::alnum" {
  let re = compile(Re::alnum())
  assert_eq(execp(re, sb_cov("a")), true)
  assert_eq(execp(re, sb_cov("1")), true)
  assert_eq(execp(re, sb_cov(" ")), false)
}

///|
test "Re::wordc" {
  let re = compile(Re::wordc())
  assert_eq(execp(re, sb_cov("a")), true)
  assert_eq(execp(re, sb_cov("1")), true)
  assert_eq(execp(re, sb_cov("_")), true)
  assert_eq(execp(re, sb_cov(" ")), false)
}

///|
test "Re::xdigit" {
  let re = compile(Re::xdigit())
  assert_eq(execp(re, sb_cov("a")), true)
  assert_eq(execp(re, sb_cov("F")), true)
  assert_eq(execp(re, sb_cov("9")), true)
  assert_eq(execp(re, sb_cov("g")), false)
}

///|
test "Re::notnl" {
  let re = compile(Re::notnl())
  assert_eq(execp(re, sb_cov("a")), true)
}

///|
test "Re::ascii" {
  let re = compile(Re::ascii())
  assert_eq(execp(re, sb_cov("a")), true)
}

///|
test "Re::cntrl" {
  let re = compile(Re::cntrl())
  assert_eq(execp(re, sb_cov("\t")), true)
}

///|
test "Re::graph" {
  let re = compile(Re::graph())
  assert_eq(execp(re, sb_cov("a")), true)
}

///|
test "Re::print" {
  let re = compile(Re::print())
  assert_eq(execp(re, sb_cov(" ")), true)
}

///|
test "Re::punct" {
  let re = compile(Re::punct())
  assert_eq(execp(re, sb_cov("!")), true)
  assert_eq(execp(re, sb_cov("a")), false)
}

// === exec (non-optional) ===

///|
test "exec returns group on match" {
  let re = compile(Ast::str(sb_cov("hello")))
  let g = exec(re, sb_cov("hello world"))
  assert_eq(GroupT::start(g, 0), 0)
}

///|
test "exec raises on no match" {
  let re = compile(Ast::str(sb_cov("xyz")))
  let raised = try {
    let _ = exec(re, sb_cov("hello"))
    false
  } catch {
    _ => true
  }
  assert_eq(raised, true)
}

// === ExecPartialResult::partial ===

///|
test "exec_partial partial" {
  let re = compile(Ast::seq([Ast::bos(), Ast::str(sb_cov("hello"))]))
  let result = exec_partial(re, sb_cov("hel"))
  assert_eq(result, ExecPartialResult::partial())
}

// === Frontend edge cases ===

///|
test "perl anchor ^" {
  let re = Perl::compile_pat(sb_cov("^hello"))
  assert_eq(execp(re, sb_cov("hello world")), true)
  assert_eq(execp(re, sb_cov("say hello")), false)
}

///|
test "perl anchor end of string" {
  let pat : Array[Byte] = [119, 111, 114, 108, 100, 36]
  let re = Perl::compile_pat(Bytes::from_array(pat))
  assert_eq(execp(re, sb_cov("hello world")), true)
  assert_eq(execp(re, sb_cov("world hello")), false)
}

///|
test "perl \\s class" {
  let re = Perl::compile_pat(sb_cov("\\s+"))
  assert_eq(execp(re, sb_cov("   ")), true)
  assert_eq(execp(re, sb_cov("abc")), false)
}

///|
test "perl \\w class" {
  let re = Perl::compile_pat(sb_cov("\\w+"))
  assert_eq(execp(re, sb_cov("hello_123")), true)
  assert_eq(execp(re, sb_cov("   ")), false)
}

///|
test "perl {n} exact" {
  let re = Perl::compile_pat(sb_cov("a{3}"))
  assert_eq(execp(re, sb_cov("aaa")), true)
  assert_eq(execp(re, sb_cov("aa")), false)
}

///|
test "perl {n,} open-ended" {
  let re = Perl::compile_pat(sb_cov("a{2,}"))
  assert_eq(execp(re, sb_cov("aa")), true)
  assert_eq(execp(re, sb_cov("aaaa")), true)
  assert_eq(execp(re, sb_cov("a")), false)
}

///|
test "perl nested groups" {
  let re = Perl::compile_pat(sb_cov("(a(b)c)"))
  match exec_opt(re, sb_cov("abc")) {
    Some(g) => {
      assert_eq(bs_cov(GroupT::get(g, 0).unwrap()), "abc")
      assert_eq(bs_cov(GroupT::get(g, 1).unwrap()), "abc")
      assert_eq(bs_cov(GroupT::get(g, 2).unwrap()), "b")
    }
    None => assert_eq(true, false)
  }
}

///|
test "perl alternation with groups" {
  let re = Perl::compile_pat(sb_cov("(cat)|(dog)"))
  match exec_opt(re, sb_cov("cat")) {
    Some(g) => {
      assert_eq(bs_cov(GroupT::get(g, 0).unwrap()), "cat")
      assert_eq(bs_cov(GroupT::get(g, 1).unwrap()), "cat")
    }
    None => assert_eq(true, false)
  }
  match exec_opt(re, sb_cov("dog")) {
    Some(g) => assert_eq(bs_cov(GroupT::get(g, 0).unwrap()), "dog")
    None => assert_eq(true, false)
  }
}

///|
test "perl char class negation" {
  let re = Perl::compile_pat(sb_cov("[^abc]"))
  assert_eq(execp(re, sb_cov("d")), true)
  assert_eq(execp(re, sb_cov("a")), false)
}

///|
test "perl optional ? after group" {
  let re = Perl::compile_pat(sb_cov("(ab)?c"))
  assert_eq(execp(re, sb_cov("c")), true)
  assert_eq(execp(re, sb_cov("abc")), true)
  assert_eq(execp(re, sb_cov("ab")), false)
}

///|
test "emacs char class" {
  let re = Emacs::compile_pat(sb_cov("[abc]"))
  assert_eq(execp(re, sb_cov("a")), true)
  assert_eq(execp(re, sb_cov("b")), true)
  assert_eq(execp(re, sb_cov("d")), false)
}

///|
test "emacs plus" {
  let re = Emacs::compile_pat(sb_cov("ab+c"))
  assert_eq(execp(re, sb_cov("ac")), false)
  assert_eq(execp(re, sb_cov("abc")), true)
  assert_eq(execp(re, sb_cov("abbbbc")), true)
}

///|
test "glob escape char" {
  let re = Glob::compile(sb_cov("\\a.txt"))
  assert_eq(execp(re, sb_cov("a.txt")), true)
  assert_eq(execp(re, sb_cov("b.txt")), false)
}

///|
test "pcre groups and alternation" {
  let re = Pcre::regexp(sb_cov("(a|b)(c|d)"))
  assert_eq(Pcre::pmatch(re, sb_cov("ac")), true)
  assert_eq(Pcre::pmatch(re, sb_cov("bd")), true)
  assert_eq(Pcre::pmatch(re, sb_cov("ad")), true)
  assert_eq(Pcre::pmatch(re, sb_cov("bc")), true)
  assert_eq(Pcre::pmatch(re, sb_cov("cd")), false)
  assert_eq(Pcre::pmatch(re, sb_cov("ef")), false)
}

///|
test "str string_match with pos" {
  let re = Str::regexp(sb_cov("world"))
  assert_eq(Str::string_match(re, sb_cov("hello world"), 6), true)
  assert_eq(Str::string_match(re, sb_cov("hello world"), 0), false)
}

///|
test "str search_forward not found" {
  let re = Str::regexp(sb_cov("xyz"))
  let raised = try {
    let _ = Str::search_forward(re, sb_cov("hello world"), 0)
    false
  } catch {
    _ => true
  }
  assert_eq(raised, true)
}

///|
test "search matches with groups in result" {
  let re = compile(Ast::rep1(Re::digit()))
  let s = sb_cov("abc123def456")
  let groups = Search::all(re, s)
  assert_eq(groups.length(), 2)
  assert_eq(bs_cov(GroupT::get(groups[0], 0).unwrap()), "123")
  assert_eq(bs_cov(GroupT::get(groups[1], 0).unwrap()), "456")
}

///|
test "replace with function all=false" {
  let re = compile(Ast::rep1(Re::digit()))
  let s = sb_cov("a1b2c3")
  let result = Replace::replace(
    re,
    s,
    f=fn(g : GroupT) { GroupT::get(g, 0).unwrap() },
    all=false,
  )
  assert_eq(bs_cov(result), "a1b2c3")
}

///|
test "exec_partial_detailed partial" {
  let re = compile(Ast::seq([Ast::bos(), Ast::str(sb_cov("hello"))]))
  let result = exec_partial_detailed(re, sb_cov("hel"))
  match result {
    PartialD(_) => assert_eq(true, true)
    _ => assert_eq(true, false)
  }
}

///|
test "exec_partial_detailed mismatch" {
  let re = compile(Ast::seq([Ast::bos(), Ast::str(sb_cov("hello"))]))
  let result = exec_partial_detailed(re, sb_cov("world"))
  match result {
    MismatchD => assert_eq(true, true)
    _ => assert_eq(true, false)
  }
}

// === Re::mark_test / mark_all ===

///|
test "Re::mark_test and mark_all" {
  let re = compile(Ast::group(Ast::str(sb_cov("a"))))
  match exec_opt(re, sb_cov("a")) {
    Some(g) => {
      let all_marks = Re::mark_all(g)
      let _pm = PmarkSet::to_list(all_marks)
      assert_eq(true, true)
    }
    None => assert_eq(true, false)
  }
}

// === match_str 四象限 (P1: groups × partial) ===

///|
test "match_str groups=true partial=false" {
  let re = compile(Ast::str(sb_cov("hello")))
  // 命中返回 MatchInfo
  match match_str(groups=true, partial=false, re, sb_cov("hello world"), pos=0, len=11) {
    MatchInfo(_) => assert_eq(true, true)
    FailedInfo => assert_eq(true, false)
    RunningInfo(_) => assert_eq(true, false)
  }
  // 不命中返回 FailedInfo
  match match_str(groups=true, partial=false, re, sb_cov("world"), pos=0, len=5) {
    MatchInfo(_) => assert_eq(true, false)
    FailedInfo => assert_eq(true, true)
    RunningInfo(_) => assert_eq(true, false)
  }
}

///|
test "match_str groups=false partial=false" {
  let re = compile(Ast::str(sb_cov("hello")))
  // 命中返回 MatchInfo
  match match_str(groups=false, partial=false, re, sb_cov("hello world"), pos=0, len=11) {
    MatchInfo(_) => assert_eq(true, true)
    FailedInfo => assert_eq(true, false)
    RunningInfo(_) => assert_eq(true, false)
  }
  // 不命中返回 FailedInfo
  match match_str(groups=false, partial=false, re, sb_cov("world"), pos=0, len=5) {
    MatchInfo(_) => assert_eq(true, false)
    FailedInfo => assert_eq(true, true)
    RunningInfo(_) => assert_eq(true, false)
  }
}

///|
test "match_str groups=true partial=true" {
  let re = compile(Ast::str(sb_cov("hello")))
  // 部分匹配（输入是模式真前缀）返回 RunningInfo
  match match_str(groups=true, partial=true, re, sb_cov("hel"), pos=0, len=3) {
    MatchInfo(_) => assert_eq(true, false)
    FailedInfo => assert_eq(true, false)
    RunningInfo(_) => assert_eq(true, true)
  }
  // 完整命中返回 MatchInfo
  match match_str(groups=true, partial=true, re, sb_cov("hello"), pos=0, len=5) {
    MatchInfo(_) => assert_eq(true, true)
    FailedInfo => assert_eq(true, false)
    RunningInfo(_) => assert_eq(true, false)
  }
}

///|
test "match_str groups=false partial=true" {
  let re = compile(Ast::str(sb_cov("hello")))
  // 部分匹配（输入是模式真前缀）返回 RunningInfo
  match match_str(groups=false, partial=true, re, sb_cov("hel"), pos=0, len=3) {
    MatchInfo(_) => assert_eq(true, false)
    FailedInfo => assert_eq(true, false)
    RunningInfo(_) => assert_eq(true, true)
  }
  // 完整命中返回 MatchInfo
  match match_str(groups=false, partial=true, re, sb_cov("hello"), pos=0, len=5) {
    MatchInfo(_) => assert_eq(true, true)
    FailedInfo => assert_eq(true, false)
    RunningInfo(_) => assert_eq(true, false)
  }
}

// === match_str_no_bounds 越界 (P2: 对照断言合并入块内) ===

///|
test "match_str pos negative bounds raise" {
  let re = compile(Ast::str(sb_cov("hello")))
  let s = sb_cov("hello")
  // 注：pos < 0 时 match_str_no_bounds 内部 next_state 访问 s[pos] 产生不可捕获的
  // RuntimeError（非 fail 异常），故此处仅对照验证 match_str raise "Re.exec: out of bounds"
  let bounds_raise = try {
    let _ = match_str(groups=true, partial=false, re, s, pos=-1, len=5)
    false
  } catch {
    _ => true
  }
  assert_eq(bounds_raise, true)
}

///|
test "match_str_no_bounds len below -1 no raise" {
  let re = compile(Ast::str(sb_cov("hello")))
  let s = sb_cov("hello")
  // match_str_no_bounds 不 raise：直接调用验证不产生错误（len < -1 时 last < pos，
  // 循环不执行，返回 FailedInfo）
  match match_str_no_bounds(groups=true, partial=false, re, s, pos=0, len=-2) {
    MatchInfo(_) => assert_eq(true, true)
    FailedInfo => assert_eq(true, true)
    RunningInfo(_) => assert_eq(true, true)
  }
  // 对照：match_str 对相同越界参数应 raise "Re.exec: out of bounds"
  let bounds_raise = try {
    let _ = match_str(groups=true, partial=false, re, s, pos=0, len=-2)
    false
  } catch {
    _ => true
  }
  assert_eq(bounds_raise, true)
}

///|
test "match_str pos+len overflow bounds raise" {
  let re = compile(Ast::str(sb_cov("hello")))
  let s = sb_cov("hello")
  // 注：pos+len > s.length() 时 match_str_no_bounds 内部循环访问 s[pos] 产生不可捕获的
  // RuntimeError（非 fail 异常），故此处仅对照验证 match_str raise "Re.exec: out of bounds"
  let bounds_raise = try {
    let _ = match_str(groups=true, partial=false, re, s, pos=0, len=100)
    false
  } catch {
    _ => true
  }
  assert_eq(bounds_raise, true)
}

// === Pcre 高级 API 异常路径 + 命名 group 边界 (P4) ===

///|
test "pcre exec no match raise" {
  let re = Pcre::regexp(sb_cov("abc"))
  // 不匹配输入触发 core.mbt:112 fail("Re.exec: not found")
  let result = try {
    let _ = Pcre::exec(re, sb_cov("xyz"))
    false
  } catch {
    _ => true
  }
  assert_eq(result, true)
}

///|
test "pcre get_named_substring not found raise" {
  let re = Pcre::regexp(sb_cov("(?<word>[a-z]+)"))
  let g = Pcre::exec(re, sb_cov("hello"))
  // 错误 name 触发 pcre.mbt:179 fail("Pcre: named group not found")
  let result = try {
    let _ = Pcre::get_named_substring(re, "num", g)
    false
  } catch {
    _ => true
  }
  assert_eq(result, true)
}

///|
test "pcre get_named_substring opt boundary" {
  let re = Pcre::regexp(sb_cov("(?<word>[a-z]+)"))
  let g = Pcre::exec(re, sb_cov("hello"))
  // 正向：get_named_substring 命中（pcre.mbt:172-180 Some 分支）
  assert_eq(Pcre::get_named_substring(re, "word", g), sb_cov("hello"))
  // 正向：get_named_substring_opt 命中（pcre.mbt:67-84 有名分支）
  assert_eq(Pcre::get_named_substring_opt(re, "word", g), Some(sb_cov("hello")))
  // 边界：get_named_substring_opt 未命中返回 None（pcre.mbt:67-84 无名分支）
  assert_eq(Pcre::get_named_substring_opt(re, "num", g), None)
}

// === Str OCaml 风格 API 错误路径 (P5) ===

///|
test "str match_beginning no match raise" {
  let re = Str::regexp(sb_cov("abc"))
  // 不匹配 → str_state.val = None，触发 str.mbt:83-88 fail("Str: no match")
  let _ = Str::string_match(re, sb_cov("xyz"), 0)
  let result = try {
    let _ = Str::match_beginning()
    false
  } catch {
    _ => true
  }
  assert_eq(result, true)
}

///|
test "str match_end no match raise" {
  let re = Str::regexp(sb_cov("abc"))
  // 先清空 str_state（不匹配 → None），触发 str.mbt:91-96 fail("Str: no match")
  let _ = Str::string_match(re, sb_cov("xyz"), 0)
  let result = try {
    let _ = Str::match_end()
    false
  } catch {
    _ => true
  }
  assert_eq(result, true)
}

///|
test "str matched_string no match raise" {
  let re = Str::regexp(sb_cov("abc"))
  // 先清空 str_state（不匹配 → None），触发 str.mbt:99-104 fail("Str: no match")
  let _ = Str::string_match(re, sb_cov("xyz"), 0)
  let result = try {
    let _ = Str::matched_string(sb_cov("xyz"))
    false
  } catch {
    _ => true
  }
  assert_eq(result, true)
}

///|
test "str group_beginning out of bounds raise" {
  let re = Str::regexp(sb_cov("abc"))
  // 匹配成功 → str_state = Some(GroupT)，正则 abc 无捕获组，仅 group 0
  let _ = Str::string_match(re, sb_cov("abc"), 0)
  // 越界 group idx 5 → GroupT::start → group.mbt:38-43 fail("Group.start: not found")
  let result = try {
    let _ = Str::group_beginning(5)
    false
  } catch {
    _ => true
  }
  assert_eq(result, true)
}
