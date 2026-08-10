// MarkInfos — store mark (group capture) offsets in a flat int array (port of lib/mark_infos.ml)
// OCaml: `type t = int array`. Pairs of (start, stop) at indices (2*i, 2*i+1).
// -1 = absent. MoonBit: Array[Int].

///|
pub struct MarkInfos {
  table : Array[Int]
}

///|
pub fn MarkInfos::make(marks : Array[(Int, Int)]) -> MarkInfos {
  let mut len = 0
  for p in marks {
    if p.0 > len {
      len = p.0
    }
  }
  len += 1
  let t = Array::make(len, -1)
  for p in marks {
    t[p.0] = p.1
  }
  { table: t }
}

///|
pub fn MarkInfos::has(t : MarkInfos, i : Int) -> Bool {
  if 2 * i >= t.table.length() {
    false
  } else {
    t.table[2 * i] != -1
  }
}

///|
pub struct MarkOffset {
  val : Int
}

///|
pub fn MarkOffset::is_present(t : MarkOffset) -> Bool {
  t.val >= 0
}

///|
pub fn MarkOffset::get_no_check(t : MarkOffset) -> Int {
  t.val
}

///|
pub fn MarkInfos::start_offset(t : MarkInfos, i : Int) -> MarkOffset {
  let start_i = 2 * i
  if start_i + 1 >= t.table.length() {
    { val: -1 }
  } else {
    { val: t.table[start_i] }
  }
}

///|
pub fn MarkInfos::stop_offset(t : MarkInfos, i : Int) -> MarkOffset {
  let stop_i = 2 * i + 1
  if stop_i >= t.table.length() {
    { val: -1 }
  } else {
    { val: t.table[stop_i] }
  }
}

///|
pub fn MarkInfos::offset(t : MarkInfos, i : Int) -> (Int, Int)? {
  let start_i = 2 * i
  let stop_i = start_i + 1
  if stop_i >= t.table.length() {
    None
  } else {
    let start = t.table[start_i]
    if start == -1 {
      None
    } else {
      let stop = t.table[stop_i]
      Some((start, stop))
    }
  }
}

///|
pub fn MarkInfos::iteri(t : MarkInfos, f : (Int, Int, Int) -> Unit) -> Unit {
  let n = t.table.length() / 2
  for i in 0..<n {
    let idx = 2 * i
    let start = t.table[idx]
    if start != -1 {
      let stop = t.table[idx + 1]
      f(i, start, stop)
    }
  }
}
