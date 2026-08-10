// Pmark — pattern mark identifier (port of lib/pmark.ml)
// OCaml uses an Atomic counter for `gen`. MoonBit: global Ref[Int] counter.
// Thread-safety (OCaml 5 domains) is a later concern; the port is single-threaded
// for now, matching the non-concurrent subset of upstream.

///|
pub struct Pmark {
  id : Int
} derive(Debug, Eq, Compare)

///|
pub fn Pmark::equal(x : Pmark, y : Pmark) -> Bool {
  x.id == y.id
}

///|
pub fn Pmark::compare(x : Pmark, y : Pmark) -> Int {
  x.id.compare(y.id)
}

///|
let pmark_counter : Ref[Int] = Ref::{ val: 1 }

///|
pub fn Pmark::gen() -> Pmark {
  let r = pmark_counter.val
  pmark_counter.val = r + 1
  { id: r }
}

///|
pub fn Pmark::to_int(self : Pmark) -> Int {
  self.id
}

///|
pub fn Pmark::to_dyn(self : Pmark) -> Dyn {
  Dyn::int(self.id)
}

// PmarkSet — set of Pmark.
// OCaml uses Set.Make(Pmark) (balanced tree). MoonBit: a sorted Array[Pmark]
// with dedup. Pmark counts are small (one per `mark` call in a pattern), so a
// sorted array with binary search is adequate and dependency-free.

///|
pub struct PmarkSet {
  elems : Array[Pmark] // sorted ascending by id, no duplicates
}

///|
pub fn PmarkSet::empty() -> PmarkSet {
  { elems: [] }
}

///|
pub fn PmarkSet::single(x : Pmark) -> PmarkSet {
  { elems: [x] }
}

///|
pub fn PmarkSet::mem(self : PmarkSet, x : Pmark) -> Bool {
  let mut lo = 0
  let mut hi = self.elems.length()
  while lo < hi {
    let mid = (lo + hi) / 2
    let c = self.elems[mid].id - x.id
    if c == 0 {
      return true
    } else if c < 0 {
      lo = mid + 1
    } else {
      hi = mid
    }
  }
  false
}

///|
pub fn PmarkSet::add(self : PmarkSet, x : Pmark) -> PmarkSet {
  let n = self.elems.length()
  let mut lo = 0
  let mut hi = n
  while lo < hi {
    let mid = (lo + hi) / 2
    let c = self.elems[mid].id - x.id
    if c == 0 {
      return self
    } else if c < 0 {
      lo = mid + 1
    } else {
      hi = mid
    }
  }
  let xs = self.elems.copy()
  xs.insert(lo, x)
  { elems: xs }
}

///|
pub fn PmarkSet::union(self : PmarkSet, other : PmarkSet) -> PmarkSet {
  let result : Array[Pmark] = []
  let a = self.elems
  let b = other.elems
  let mut i = 0
  let mut j = 0
  while i < a.length() && j < b.length() {
    if a[i].id < b[j].id {
      result.push(a[i])
      i += 1
    } else if a[i].id > b[j].id {
      result.push(b[j])
      j += 1
    } else {
      result.push(a[i])
      i += 1
      j += 1
    }
  }
  while i < a.length() {
    result.push(a[i])
    i += 1
  }
  while j < b.length() {
    result.push(b[j])
    j += 1
  }
  { elems: result }
}

///|
pub fn PmarkSet::iter(self : PmarkSet, f : (Pmark) -> Unit) -> Unit {
  for x in self.elems {
    f(x)
  }
}

///|
pub fn PmarkSet::to_list(self : PmarkSet) -> Array[Pmark] {
  self.elems.copy()
}

///|
pub fn PmarkSet::is_empty(self : PmarkSet) -> Bool {
  self.elems.length() == 0
}

///|
pub fn PmarkSet::length(self : PmarkSet) -> Int {
  self.elems.length()
}

///|
pub fn PmarkSet::equal(self : PmarkSet, other : PmarkSet) -> Bool {
  if self.elems.length() != other.elems.length() {
    return false
  }
  for i in 0..<self.elems.length() {
    if !Pmark::equal(self.elems[i], other.elems[i]) {
      return false
    }
  }
  true
}
