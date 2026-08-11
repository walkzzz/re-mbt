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
pub fn ColorMap::flatten(
  self : ColorMap,
) -> (ColorTable, BoundaryTable, ColorRepr) {
  let csets = self.csets
  let bt = BoundaryTable::create(csets)
  let table_arr = Array::make(256, (0).to_byte())
  let repr_arr = Array::make(256, (0).to_byte())
  let mut num_colors = 0
  // M1: 预分配 ids 缓冲，循环内 clear 后复用，消除 256 次 Array 分配
  let ids_buf : Array[Int] = []
  // A1 + D3: HashMap 按 ids 内容去重，key = ids 副本，value = color_id
  // 消除 O(256 × |unique| × |ids|) 线性查找 → O(256 × |ids|)
  let color_map : @hashmap.HashMap[Array[Int], Int] = @hashmap.HashMap::HashMap([],
  )
  let mut last_version = 0
  for i in 0..<256 {
    if bt.data[i] == (0).to_byte() {
      ids_buf.clear()
      for csetid in 0..<csets.length() {
        if Cset::mem(i, csets[csetid]) {
          ids_buf.push(csetid + 1)
        }
      }
      // A1: 哈希查找 color_id
      let v = match color_map.get(ids_buf) {
        Some(id) => id
        None => {
          // 未命中：深拷贝 ids_buf 作为 key 存入 map（仅命中新 color 时分配一次）
          let key = Array::make(ids_buf.length(), 0)
          for k in 0..<ids_buf.length() {
            key[k] = ids_buf[k]
          }
          let id = num_colors
          color_map[key] = id
          num_colors += 1
          id
        }
      }
      table_arr[i] = v.to_byte()
      repr_arr[v] = i.to_byte()
      last_version = v
    } else {
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
