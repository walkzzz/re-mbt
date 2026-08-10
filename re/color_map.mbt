// ColorMap — color mapping for character equivalence classes (port of lib/color_map.ml)
// Each character is assigned a color; characters with the same color are interchangeable.

///|
pub struct ColorMap {
  csets : Array[Cset]
}

///|
pub fn ColorMap::make() -> ColorMap {
  { csets: [] }
}

///|
fn size_cset(cset : Cset) -> Int {
  let mut size = 0
  Cset::iter(cset, f=fn(c1, c2) { size += c2 - c1 + 1 })
  size
}

///|
fn cset_or_compl(cset : Cset) -> Cset {
  if size_cset(cset) > 128 {
    Cset::diff(Cset::cany(), cset)
  } else {
    cset
  }
}

///|
pub fn ColorMap::split(self : ColorMap, set : Cset) -> Unit {
  self.csets.push(cset_or_compl(set))
}

// --- BoundaryTable ---
// Maps each byte to distance to next boundary char. 257 bytes (extra for sentinel).

///|
pub struct BoundaryTable {
  data : FixedArray[Byte]
}

///|
fn BoundaryTable::create(csets : Array[Cset]) -> BoundaryTable {
  let b = FixedArray::make(257, (255).to_byte())
  b[0] = (0).to_byte()
  for cset in csets {
    Cset::iter(cset, f=fn(c1, c2) {
      b[c1] = (0).to_byte()
      b[c2 + 1] = (0).to_byte()
    })
  }
  let mut skip = 0
  for i in 0..<256 {
    let idx = 255 - i
    if b[idx] == (0).to_byte() {
      skip = 0
    } else {
      skip += 1
      b[idx] = skip.to_byte()
    }
  }
  { data: b }
}

///|
pub fn BoundaryTable::unsafe_next_boundary(t : BoundaryTable, i : Int) -> Int {
  i + 1 + t.data[i + 1].to_int()
}

// --- ColorTable (Table.t in OCaml) ---
// 256-byte table mapping char codes to color codes.

///|
pub struct ColorTable {
  data : Bytes
}

///|
pub fn ColorTable::get_char(t : ColorTable, c : Int) -> Byte {
  t.data[c]
}

///|
pub fn ColorTable::get(t : ColorTable, c : Int) -> Int {
  t.data[c].to_int()
}

///|
pub fn ColorTable::translate_colors(
  t : ColorTable,
  boundary_table : BoundaryTable,
  cset : Cset,
) -> Cset {
  let cs : Array[Int] = []
  let mut last_version = -1
  Cset::iter(cset, f=fn(c1, c2) {
    let mut ci = c1
    while ci <= c2 {
      let v = t.data[ci].to_int()
      if v > last_version {
        cs.push(v)
        last_version = v
      }
      ci = BoundaryTable::unsafe_next_boundary(boundary_table, ci)
    }
  })
  let cs_rev : Array[Int] = []
  for k in 0..<cs.length() {
    cs_rev.push(cs[cs.length() - 1 - k])
  }
  Cset::union_singles_in_strictly_decreasing_order(cs_rev)
}

// --- ColorRepr (Repr.t in OCaml) ---
// Representative char for each color.

///|
pub struct ColorRepr {
  data : Bytes
}

///|
pub fn ColorRepr::repr(t : ColorRepr, color : Int) -> Byte {
  t.data[color]
}

///|
pub fn ColorRepr::length(t : ColorRepr) -> Int {
  t.data.length()
}

// --- flatten ---

///|
fn array_int_eq(a : Array[Int], b : Array[Int]) -> Bool {
  if a.length() != b.length() {
    return false
  }
  for i in 0..<a.length() {
    if a[i] != b[i] {
      return false
    }
  }
  true
}

///|
pub fn ColorMap::flatten(
  self : ColorMap,
) -> (ColorTable, BoundaryTable, ColorRepr) {
  let csets = self.csets
  let bt = BoundaryTable::create(csets)
  let table_arr = Array::make(256, (0).to_byte())
  let repr_arr = Array::make(256, (0).to_byte())
  let mut num_colors = 0
  let unique_lists : Array[Array[Int]] = []
  let mut last_version = 0
  let mut prev_ids : Array[Int] = []
  for i in 0..<256 {
    let ids : Array[Int] = []
    if bt.data[i] == (0).to_byte() {
      for csetid in 0..<csets.length() {
        if Cset::mem(i, csets[csetid]) {
          ids.push(csetid + 1)
        }
      }
      prev_ids = ids
      let mut found = -1
      for j in 0..<unique_lists.length() {
        if found < 0 && array_int_eq(ids, unique_lists[j]) {
          found = j
        }
      }
      let v = if found >= 0 {
        found
      } else {
        unique_lists.push(ids)
        num_colors += 1
        num_colors - 1
      }
      table_arr[i] = v.to_byte()
      repr_arr[v] = i.to_byte()
      last_version = v
    } else {
      for x in prev_ids {
        ids.push(x)
      }
      table_arr[i] = last_version.to_byte()
      repr_arr[last_version] = i.to_byte()
    }
  }
  let table_bytes = Bytes::from_array(table_arr)
  let repr_slice = Array::make(num_colors, (0).to_byte())
  for k in 0..<num_colors {
    repr_slice[k] = repr_arr[k]
  }
  let repr_bytes = Bytes::from_array(repr_slice)
  ({ data: table_bytes }, bt, { data: repr_bytes })
}
