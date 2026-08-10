// HashSet — specialized open-addressing hash set of ints (port of lib/hash_set.ml)
// OCaml stores int64 in Bytes to avoid GC scanning. MoonBit FixedArray[Int]
// is an unboxed int array, so we use that directly. absent = -1 (ids are >= 0).

///|
pub struct HashSet {
  mut table : FixedArray[Int] // sized to powers of two, absent slots = -1
  mut size : Int
}

///|
pub fn HashSet::absent() -> Int {
  -1
}

///|
pub fn HashSet::create() -> HashSet {
  { table: FixedArray::make(0, -1), size: 0 }
}

///|
pub fn HashSet::is_empty(self : HashSet) -> Bool {
  self.size == 0
}

///|
pub fn HashSet::should_grow(self : HashSet) -> Bool {
  self.table.length() <= self.size * 2
}

///|
pub fn HashSet::index_of_offset(slots : Int, index : Int, i : Int) -> Int {
  (index + i) & (slots - 1)
}

///|
pub fn HashSet::clear(self : HashSet) -> Unit {
  self.size = 0
  for i in 0..<self.table.length() {
    self.table[i] = -1
  }
}

// raw add without resize

///|
pub fn HashSet::add_no_resize(self : HashSet, x : Int) -> Unit {
  let slots = self.table.length()
  let index = x.reinterpret_as_uint().reinterpret_as_int() & (slots - 1)
  let mut i = 0
  while true {
    let idx = HashSet::index_of_offset(slots, index, i)
    let elem = self.table[idx]
    if elem == -1 {
      self.table[idx] = x
      return
    }
    i += 1
  }
}

///|
pub fn HashSet::resize(self : HashSet) -> Unit {
  let old_table = self.table
  let slots = old_table.length()
  let new_slots = if slots == 0 { 1 } else { slots << 1 }
  self.table = FixedArray::make(new_slots, -1)
  self.size = 0
  for i in 0..<slots {
    let elem = old_table[i]
    if elem != -1 {
      self.add_no_resize(elem)
      self.size += 1
    }
  }
}

///|
pub fn HashSet::add(self : HashSet, x : Int) -> Unit {
  if self.should_grow() {
    self.resize()
  }
  self.add_no_resize(x)
  self.size += 1
}

///|
pub fn HashSet::mem(self : HashSet, x : Int) -> Bool {
  if self.is_empty() {
    return false
  }
  let slots = self.table.length()
  let index = x.reinterpret_as_uint().reinterpret_as_int() & (slots - 1)
  let mut i = 0
  while i < slots {
    let idx = HashSet::index_of_offset(slots, index, i)
    let elem = self.table[idx]
    if elem == x {
      return true
    } else if elem == -1 {
      return false
    }
    i += 1
  }
  false
}
