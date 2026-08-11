// Cset — character sets as sorted lists of intervals (port of lib/cset.ml)
// OCaml: `type c = int` (null_char = -1), `type t = (c * c) list`.
// MoonBit: `c` is `Int`; `Cset` wraps `Array[(Int, Int)]` (sorted,
// non-overlapping, non-adjacent intervals). All ops return fresh Csets.

// --- c (character code, with null_char sentinel) ---

///|
#warnings("-struct_never_constructed")
pub struct CsetC {}

///|
pub fn CsetC::null_char() -> Int {
  -1
}

///|
pub fn CsetC::equal_c(x : Int, y : Int) -> Bool {
  x == y
}

///|
pub fn CsetC::to_int(x : Int) -> Int {
  x
}

///|
pub fn CsetC::of_int(x : Int) -> Int {
  x
}

///|
pub fn CsetC::to_char(t : Int) -> Char {
  t.unsafe_to_char()
}

///|
pub fn CsetC::of_char(c : Char) -> Int {
  c.to_int()
}

// --- Cset ---

///|
pub struct Cset {
  intervals : Array[(Int, Int)]
} derive(Debug, Eq, Compare)

///|
pub fn Cset::empty() -> Cset {
  { intervals: [] }
}

///|
pub fn Cset::is_empty(t : Cset) -> Bool {
  t.intervals.length() == 0
}

///|
pub fn Cset::cany() -> Cset {
  { intervals: [(0, 255)] }
}

///|
pub fn Cset::equal(t1 : Cset, t2 : Cset) -> Bool {
  if t1.intervals.length() != t2.intervals.length() {
    return false
  }
  for i in 0..<t1.intervals.length() {
    if t1.intervals[i].0 != t2.intervals[i].0 ||
      t1.intervals[i].1 != t2.intervals[i].1 {
      return false
    }
  }
  true
}

///|
fn compare_pair(p1 : (Int, Int), p2 : (Int, Int)) -> Int {
  let c = p1.0.compare(p2.0)
  if c != 0 {
    c
  } else {
    p1.1.compare(p2.1)
  }
}

///|
pub fn Cset::compare(t1 : Cset, t2 : Cset) -> Int {
  let n1 = t1.intervals.length()
  let n2 = t2.intervals.length()
  let mut i = 0
  while i < n1 && i < n2 {
    let c = compare_pair(t1.intervals[i], t2.intervals[i])
    if c != 0 {
      return c
    }
    i += 1
  }
  n1.compare(n2)
}

// union of two sorted interval lists

///|
pub fn Cset::union(l : Cset, r : Cset) -> Cset {
  let li = l.intervals
  let ri = r.intervals
  let result = Array::new(capacity=li.length() + ri.length())
  let mut i = 0
  let mut j = 0
  let mut li_over : (Int, Int)? = None
  let mut ri_over : (Int, Int)? = None
  while i < li.length() && j < ri.length() {
    let (c1, c2) = match li_over {
      Some(p) => p
      None => li[i]
    }
    let (c1p, c2p) = match ri_over {
      Some(p) => p
      None => ri[j]
    }
    if c2 + 1 < c1p {
      result.push((c1, c2))
      i += 1
      li_over = None
    } else if c2p + 1 < c1 {
      result.push((c1p, c2p))
      j += 1
      ri_over = None
    } else if c2 < c2p {
      ri_over = Some((if c1 < c1p { c1 } else { c1p }, c2p))
      i += 1
      li_over = None
    } else {
      li_over = Some((if c1 < c1p { c1 } else { c1p }, c2))
      j += 1
      ri_over = None
    }
  }
  match li_over {
    Some(p) => {
      result.push(p)
      i += 1
    }
    None => ()
  }
  while i < li.length() {
    result.push(li[i])
    i += 1
  }
  match ri_over {
    Some(p) => {
      result.push(p)
      j += 1
    }
    None => ()
  }
  while j < ri.length() {
    result.push(ri[j])
    j += 1
  }
  { intervals: result }
}

///|
pub fn Cset::inter(l : Cset, r : Cset) -> Cset {
  let li = l.intervals
  let ri = r.intervals
  let result = Array::new(
    capacity=if li.length() < ri.length() { li.length() } else { ri.length() },
  )
  let mut i = 0
  let mut j = 0
  while i < li.length() && j < ri.length() {
    let (c1, c2) = li[i]
    let (c1p, c2p) = ri[j]
    if c2 < c1p {
      i += 1
    } else if c2p < c1 {
      j += 1
    } else if c2 < c2p {
      result.push((if c1 > c1p { c1 } else { c1p }, c2))
      i += 1
    } else {
      result.push((if c1 > c1p { c1 } else { c1p }, c2p))
      j += 1
    }
  }
  { intervals: result }
}

///|
pub fn Cset::diff(l : Cset, r : Cset) -> Cset {
  let li = l.intervals
  let ri = r.intervals
  let result = Array::new(capacity=li.length() + ri.length())
  let mut i = 0
  let mut j = 0
  let mut li_over : (Int, Int)? = None
  while i < li.length() && j < ri.length() {
    let (c1, c2) = match li_over {
      Some(p) => p
      None => li[i]
    }
    let (c1p, c2p) = ri[j]
    if c2 < c1p {
      result.push((c1, c2))
      i += 1
      li_over = None
    } else if c2p < c1 {
      j += 1
    } else {
      let leftover = c2p < c2
      if leftover {
        li_over = Some((c2p + 1, c2))
      }
      if c1 < c1p {
        result.push((c1, c1p - 1))
      }
      if !leftover {
        i += 1
        li_over = None
      }
      j += 1
    }
  }
  match li_over {
    Some(p) => {
      result.push(p)
      i += 1
    }
    None => ()
  }
  while i < li.length() {
    result.push(li[i])
    i += 1
  }
  { intervals: result }
}

// single character set. OCaml caches 257 entries via Dense_map.

///|
let cset_single_cache : ReadOnlyArray[Cset] = [
  for i in 0..<257 => { intervals: [(i, i)] }
]

///|
pub fn Cset::single(c : Int) -> Cset {
  cset_single_cache[c]
}

///|
pub fn Cset::csingle(c : Char) -> Cset {
  Cset::single(c.to_int())
}

///|
pub fn Cset::add(c : Int, l : Cset) -> Cset {
  Cset::union(Cset::single(c), l)
}

///|
pub fn Cset::cadd(c : Char, s : Cset) -> Cset {
  Cset::add(c.to_int(), s)
}

///|
pub fn Cset::seq(c : Int, cp : Int) -> Cset {
  if c <= cp {
    { intervals: [(c, cp)] }
  } else {
    { intervals: [(cp, c)] }
  }
}

///|
pub fn Cset::cseq(c : Char, cp : Char) -> Cset {
  Cset::seq(c.to_int(), cp.to_int())
}

///|
pub fn Cset::rg(c : Char, cp : Char) -> Cset {
  Cset::cseq(c, cp)
}

///|
pub fn Cset::char(c : Char) -> Cset {
  Cset::csingle(c)
}

///|
pub fn Cset::offset(o : Int, l : Cset) -> Cset {
  let result : Array[(Int, Int)] = []
  for p in l.intervals {
    result.push((p.0 + o, p.1 + o))
  }
  { intervals: result }
}

///|
fn union_all_rec(ts : Array[Cset], lo : Int, hi : Int) -> Cset {
  if lo >= hi {
    return Cset::empty()
  }
  if lo + 1 == hi {
    return ts[lo]
  }
  let mid = (lo + hi) / 2
  Cset::union(union_all_rec(ts, lo, mid), union_all_rec(ts, mid, hi))
}

///|
pub fn Cset::union_all(ts : Array[Cset]) -> Cset {
  union_all_rec(ts, 0, ts.length())
}

///|
fn intersect_all_rec(ts : Array[Cset], lo : Int, hi : Int) -> Cset {
  if lo >= hi {
    return Cset::cany()
  }
  if lo + 1 == hi {
    return ts[lo]
  }
  let mid = (lo + hi) / 2
  Cset::inter(intersect_all_rec(ts, lo, mid), intersect_all_rec(ts, mid, hi))
}

///|
pub fn Cset::intersect_all(ts : Array[Cset]) -> Cset {
  intersect_all_rec(ts, 0, ts.length())
}

///|
pub fn Cset::mem(c : Int, s : Cset) -> Bool {
  for i in 0..<s.intervals.length() {
    let (c1, c2) = s.intervals[i]
    if c >= c1 && c <= c2 {
      return true
    }
  }
  false
}

///|
pub fn Cset::hash(l : Cset) -> Int {
  let mut h = 0
  let n = l.intervals.length()
  for k in 0..<n {
    let p = l.intervals[n - 1 - k]
    h = p.0 + 13 * p.1 + 257 * h
  }
  h & 0x3FFFFFFF
}

///|
pub fn Cset::iter(t : Cset, f~ : (Int, Int) -> Unit) -> Unit {
  for p in t.intervals {
    f(p.0, p.1)
  }
}

///|
pub fn Cset::one_char(t : Cset) -> Int? {
  if t.intervals.length() == 1 && t.intervals[0].0 == t.intervals[0].1 {
    Some(t.intervals[0].0)
  } else {
    None
  }
}

///|
pub fn Cset::pick(t : Cset) -> Int raise {
  if t.intervals.length() == 0 {
    fail("Re_cset.pick")
  }
  t.intervals[0].0
}

///|
pub fn Cset::union_singles_in_strictly_decreasing_order(
  cs : Array[Int],
) -> Cset {
  if cs.length() == 0 {
    return Cset::empty()
  }
  let result : Array[(Int, Int)] = []
  let c1 = cs[0]
  let mut next = c1
  let mut end_ = c1
  for k in 1..<cs.length() {
    let c = cs[k]
    if next - 1 == c {
      next = c
    } else {
      result.push((next, end_))
      next = c
      end_ = c
    }
  }
  result.push((next, end_))
  { intervals: result }
}

// --- predefined character sets ---
// Helpers for latin1 chars by code point (avoids non-ASCII char literals).

///|
fn ch(n : Int) -> Char {
  n.unsafe_to_char()
}

///|
fn iseq(a : Int, b : Int) -> Cset {
  Cset::seq(a, b)
}

///|
// Cached predefined character sets (computed once at init)
let cset_upper : Cset = Cset::union_all([
  iseq(65, 90),
  iseq(192, 214),
  iseq(216, 222),
])

///|
let cset_clower : Cset = Cset::offset(32, cset_upper)

///|
let cset_cdigit : Cset = iseq(48, 57)

///|
let cset_ascii : Cset = iseq(0, 127)

///|
let cset_space : Cset = Cset::add(32, iseq(9, 13))

///|
let cset_xdigit : Cset = Cset::union_all([
  cset_cdigit,
  iseq(97, 102),
  iseq(65, 70),
])

///|
let cset_calpha : Cset = {
  let base = Cset::union(cset_clower, cset_upper)
  Cset::cadd(
    ch(170),
    Cset::cadd(
      ch(181),
      Cset::cadd(ch(186), Cset::cadd(ch(223), Cset::cadd(ch(255), base))),
    ),
  )
}

///|
let cset_calnum : Cset = Cset::union(cset_calpha, cset_cdigit)

///|
let cset_cword : Cset = Cset::cadd('_', cset_calnum)

///|
let cset_notnl : Cset = Cset::diff(Cset::cany(), Cset::csingle('\n'))

///|
let cset_nl : Cset = Cset::csingle('\n')

///|
let cset_lower : Cset = Cset::union_all([
  Cset::rg('a', 'z'),
  Cset::char(ch(181)),
  Cset::rg(ch(223), ch(246)),
  Cset::rg(ch(248), ch(255)),
])

///|
let cset_alpha : Cset = Cset::union_all([
  cset_lower,
  cset_upper,
  Cset::char(ch(170)),
  Cset::char(ch(186)),
])

///|
let cset_alnum : Cset = Cset::union_all([cset_alpha, cset_cdigit])

///|
let cset_wordc : Cset = Cset::union_all([cset_alnum, Cset::char('_')])

///|
let cset_cntrl : Cset = Cset::union_all([
  Cset::rg(ch(0), ch(31)),
  Cset::rg(ch(127), ch(159)),
])

///|
let cset_graph : Cset = Cset::union_all([
  Cset::rg(ch(33), ch(126)),
  Cset::rg(ch(160), ch(255)),
])

///|
let cset_print : Cset = Cset::union_all([
  Cset::rg(ch(32), ch(126)),
  Cset::rg(ch(160), ch(255)),
])

///|
let cset_punct : Cset = Cset::union_all([
  Cset::rg(ch(33), ch(47)),
  Cset::rg(ch(58), ch(64)),
  Cset::rg(ch(91), ch(96)),
  Cset::rg(ch(123), ch(126)),
  Cset::rg(ch(160), ch(169)),
  Cset::rg(ch(171), ch(180)),
  Cset::rg(ch(182), ch(185)),
  Cset::rg(ch(187), ch(191)),
  Cset::char(ch(215)),
  Cset::char(ch(247)),
])

///|
pub fn Cset::upper() -> Cset {
  cset_upper
}

///|
pub fn Cset::clower() -> Cset {
  cset_clower
}

///|
pub fn Cset::cdigit() -> Cset {
  cset_cdigit
}

///|
pub fn Cset::ascii() -> Cset {
  cset_ascii
}

///|
pub fn Cset::space() -> Cset {
  cset_space
}

///|
pub fn Cset::xdigit() -> Cset {
  cset_xdigit
}

///|
pub fn Cset::calpha() -> Cset {
  cset_calpha
}

///|
pub fn Cset::calnum() -> Cset {
  cset_calnum
}

///|
pub fn Cset::case_insens(s : Cset) -> Cset {
  Cset::union_all([
    s,
    Cset::offset(32, Cset::inter(s, cset_upper)),
    Cset::offset(-32, Cset::inter(s, cset_clower)),
  ])
}

///|
pub fn Cset::cword() -> Cset {
  cset_cword
}

///|
pub fn Cset::notnl() -> Cset {
  cset_notnl
}

///|
pub fn Cset::nl() -> Cset {
  cset_nl
}

///|
pub fn Cset::blank() -> Cset {
  Cset::set(b"\t ")
}

// Note: upstream's [lower] differs from [clower] (CR-someday rgrinberg).

///|
pub fn Cset::lower() -> Cset {
  cset_lower
}

///|
pub fn Cset::alpha() -> Cset {
  cset_alpha
}

///|
pub fn Cset::alnum() -> Cset {
  cset_alnum
}

///|
pub fn Cset::wordc() -> Cset {
  cset_wordc
}

///|
pub fn Cset::cntrl() -> Cset {
  cset_cntrl
}

///|
pub fn Cset::graph() -> Cset {
  cset_graph
}

///|
pub fn Cset::print() -> Cset {
  cset_print
}

///|
pub fn Cset::punct() -> Cset {
  cset_punct
}

// set: union of all bytes in a Bytes

///|
pub fn Cset::set(str : Bytes) -> Cset {
  let n = str.length()
  if n == 0 {
    return Cset::empty()
  }
  let bytes : Array[Int] = Array::make(n, 0)
  for i in 0..<n {
    bytes[i] = str[i].to_int()
  }
  bytes.sort()
  let result : Array[(Int, Int)] = []
  let mut start = bytes[0]
  let mut end_ = bytes[0]
  for i in 1..<n {
    let b = bytes[i]
    if b <= end_ + 1 {
      end_ = b
    } else {
      result.push((start, end_))
      start = b
      end_ = b
    }
  }
  result.push((start, end_))
  { intervals: result }
}

///|
pub fn Cset::to_dyn(self : Cset) -> Dyn {
  let arr = Array::map(self.intervals, fn(p) {
    Dyn::pair(Dyn::int(p.0), Dyn::int(p.1))
  })
  Dyn::variant("Cset", [Dyn::list(arr)])
}

// --- CSetMap: map from (Int, Cset) to Cset ---
// Simple association list (cache is small in practice).

///|
pub struct CSetMap {
  entries : Array[(Int, Cset, Cset)] // (hash, key_cset, value)
}

///|
pub fn CSetMap::empty() -> CSetMap {
  { entries: [] }
}

///|
pub fn CSetMap::find(m : CSetMap, key : (Int, Cset)) -> Cset? {
  let (h, k) = key
  for e in m.entries {
    let (eh, ek, ev) = e
    if eh == h && Cset::equal(ek, k) {
      return Some(ev)
    }
  }
  None
}

///|
pub fn CSetMap::add(m : CSetMap, key : (Int, Cset), value : Cset) -> CSetMap {
  let (h, k) = key
  m.entries.push((h, k, value))
  m
}
