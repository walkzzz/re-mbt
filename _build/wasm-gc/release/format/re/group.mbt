// Group — operations on GroupT (port of lib/group.ml)
// GroupT is defined in compile.mbt

///|
pub fn GroupT::get_opt(g : GroupT, i : Int) -> Bytes? {
  if GroupT::matched(g, i) {
    GroupT::get(g, i)
  } else {
    None
  }
}

///|
pub fn GroupT::offset_opt(g : GroupT, i : Int) -> (Int, Int)? {
  match MarkInfos::offset(g.marks, i) {
    None => None
    Some((start, stop)) => Some((g.gpos[start], g.gpos[stop]))
  }
}

///|
pub fn GroupT::offset(g : GroupT, i : Int) -> (Int, Int) raise {
  match GroupT::offset_opt(g, i) {
    Some(p) => p
    None => fail("Group.offset: not found")
  }
}

///|
pub fn GroupT::start_opt(g : GroupT, i : Int) -> Int? {
  match GroupT::offset_opt(g, i) {
    Some((p1, _)) => Some(p1)
    None => None
  }
}

///|
pub fn GroupT::start(g : GroupT, i : Int) -> Int raise {
  match GroupT::start_opt(g, i) {
    Some(p) => p
    None => fail("Group.start: not found")
  }
}

///|
pub fn GroupT::stop_opt(g : GroupT, i : Int) -> Int? {
  match GroupT::offset_opt(g, i) {
    Some((_, p2)) => Some(p2)
    None => None
  }
}

///|
pub fn GroupT::stop(g : GroupT, i : Int) -> Int raise {
  match GroupT::stop_opt(g, i) {
    Some(p) => p
    None => fail("Group.stop: not found")
  }
}

///|
pub fn GroupT::matched(g : GroupT, i : Int) -> Bool {
  MarkInfos::has(g.marks, i)
}

///|
pub fn GroupT::nb_groups(g : GroupT) -> Int {
  g.gcount
}

///|
pub fn GroupT::start_offset(g : GroupT, i : Int) -> Int {
  let off = MarkInfos::start_offset(g.marks, i)
  if MarkOffset::is_present(off) {
    g.gpos[MarkOffset::get_no_check(off)]
  } else {
    -1
  }
}

///|
pub fn GroupT::stop_offset(g : GroupT, i : Int) -> Int {
  let off = MarkInfos::stop_offset(g.marks, i)
  if MarkOffset::is_present(off) {
    g.gpos[MarkOffset::get_no_check(off)]
  } else {
    -1
  }
}

///|
pub fn GroupT::pmarks(g : GroupT) -> PmarkSet {
  g.pmarks
}

///|
pub fn GroupT::all_offset(g : GroupT) -> Array[(Int, Int)] {
  let res = Array::make(g.gcount, (-1, -1))
  MarkInfos::iteri(g.marks, fn(i, start, stop) {
    res[i] = (g.gpos[start], g.gpos[stop])
  })
  res
}

///|
pub fn GroupT::all(g : GroupT) -> Array[Bytes] {
  let empty = Bytes::from_array([])
  let res = Array::make(g.gcount, empty)
  MarkInfos::iteri(g.marks, fn(i, start, stop) {
    let p1 = g.gpos[start]
    let p2 = g.gpos[stop]
    let len = p2 - p1
    let buf : Array[Byte] = []
    for k in 0..<len {
      buf.push(g.s[p1 + k])
    }
    res[i] = Bytes::from_array(buf)
  })
  res
}
