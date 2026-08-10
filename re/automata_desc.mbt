// AutomataDesc — Marks, Status, ET (derivative expr), Desc operations
// Port of lib/automata.ml Marks, Status, Desc, E modules

// --- Marks ---

///|
pub struct Marks {
  marks : Array[(Int, Int)] // (Mark.t, Idx.t)
  pmarks : PmarkSet
}

///|
pub fn Marks::empty() -> Marks {
  { marks: [], pmarks: PmarkSet::empty() }
}

///|
pub fn Marks::equal(m1 : Marks, m2 : Marks) -> Bool {
  if m1.marks.length() != m2.marks.length() {
    return false
  }
  for i in 0..<m1.marks.length() {
    let (a1, b1) = m1.marks[i]
    let (a2, b2) = m2.marks[i]
    if a1 != a2 || b1 != b2 {
      return false
    }
  }
  PmarkSet::equal(m1.pmarks, m2.pmarks)
}

///|
fn pmark_set_hash(s : PmarkSet) -> Int {
  let mut h = 0
  s.iter(fn(p) { h = hash_combine(p.id, h) })
  h
}

///|
pub fn Marks::hash(m : Marks, accu : Int) -> Int {
  let accu1 = hash_combine(pmark_set_hash(m.pmarks), accu)
  let mut result = accu1
  for p in m.marks {
    let (a, i) = p
    result = hash_combine(a, hash_combine(i, result))
  }
  result
}

///|
fn marks_set_idx_rec(idx : Int, marks : Array[(Int, Int)]) -> Array[(Int, Int)] {
  let result : Array[(Int, Int)] = []
  let mut done = false
  for p in marks {
    let (a, idx2) = p
    if !done && idx2 == Idx::unknown() {
      result.push((a, idx))
    } else {
      done = true
      result.push(p)
    }
  }
  result
}

///|
pub fn Marks::marks_set_idx(m : Marks, idx : Int) -> Marks {
  { marks: marks_set_idx_rec(idx, m.marks), pmarks: m.pmarks }
}

///|
pub fn Marks::filter(m : Marks, b : Int, e : Int) -> Marks {
  let filtered : Array[(Int, Int)] = []
  for p in m.marks {
    let (i, _) = p
    if Mark::outside_range(i, start_inclusive=b, stop_inclusive=e) {
      filtered.push(p)
    }
  }
  { marks: filtered, pmarks: m.pmarks }
}

///|
pub fn Marks::set_mark(m : Marks, i : Int) -> Marks {
  let filtered : Array[(Int, Int)] = [(i, Idx::unknown())]
  for p in m.marks {
    let (mi, _) = p
    if mi != i {
      filtered.push(p)
    }
  }
  { marks: filtered, pmarks: m.pmarks }
}

///|
pub fn Marks::set_pmark(m : Marks, i : Pmark) -> Marks {
  { marks: m.marks, pmarks: m.pmarks.add(i) }
}

// --- Status ---

///|
pub enum Status {
  Failed
  Match(MarkInfos, PmarkSet)
  Running
}

// --- ET (E.t in OCaml) — derivative expression ---

///|
pub enum ET {
  TSeq(Sem, Array[ET], Expr)
  TExp(Marks, Expr)
  TMatch(Marks)
}

// --- Desc operations (Desc.t = Array[ET]) ---

///|
pub struct Desc {}

///|
fn desc_cons(e : ET, rem : Array[ET]) -> Array[ET] {
  rem.insert(0, e)
  rem
}

///|
fn[T] array_tail(arr : Array[T]) -> Array[T] {
  let result : Array[T] = []
  for i in 1..<arr.length() {
    result.push(arr[i])
  }
  result
}

///|
pub fn Desc::empty() -> Array[ET] {
  []
}

///|
pub fn Desc::initial(expr : Expr) -> Array[ET] {
  [TExp(Marks::empty(), expr)]
}

///|
pub fn Desc::tseq(
  kind : Sem,
  x : Array[ET],
  y : Expr,
  rem : Array[ET],
) -> Array[ET] {
  if x.length() == 0 {
    rem
  } else if x.length() == 1 {
    match x[0] {
      TExp(marks, e) =>
        if Expr::is_eps(e) {
          desc_cons(TExp(marks, y), rem)
        } else {
          desc_cons(TSeq(kind, x, y), rem)
        }
      _ => desc_cons(TSeq(kind, x, y), rem)
    }
  } else {
    desc_cons(TSeq(kind, x, y), rem)
  }
}

///|
pub fn Desc::texp(marks : Marks, e : Expr, rem : Array[ET]) -> Array[ET] {
  desc_cons(TExp(marks, e), rem)
}

///|
pub fn Desc::add_match(t : Array[ET], marks : Marks) -> Array[ET] {
  desc_cons(TMatch(marks), t)
}

///|
pub fn Desc::add_eps(t : Array[ET], marks : Marks) -> Array[ET] {
  desc_cons(TExp(marks, Expr::eps_expr()), t)
}

///|
pub fn Desc::add_expr(t : Array[ET], expr : ET) -> Array[ET] {
  desc_cons(expr, t)
}

///|
pub fn Desc::first_match(t : Array[ET]) -> Marks? {
  for i in 0..<t.length() {
    match t[i] {
      TMatch(marks) => return Some(marks)
      _ => ()
    }
  }
  None
}

///|
pub fn Desc::remove_matches(t : Array[ET]) -> Array[ET] {
  let result : Array[ET] = []
  for e in t {
    match e {
      TMatch(_) => ()
      _ => result.push(e)
    }
  }
  result
}

///|
pub fn Desc::split_at_match(t : Array[ET]) -> (Array[ET], Array[ET]) {
  let before : Array[ET] = []
  let mut i = 0
  let mut found = false
  while i < t.length() && !found {
    match t[i] {
      TMatch(_) => found = true
      _ => {
        before.push(t[i])
        i += 1
      }
    }
  }
  let after : Array[ET] = []
  if found {
    i += 1
  }
  while i < t.length() {
    match t[i] {
      TMatch(_) => ()
      _ => after.push(t[i])
    }
    i += 1
  }
  (before, after)
}

///|
pub fn Desc::status(t : Array[ET]) -> Status {
  if t.length() == 0 {
    Failed
  } else {
    match t[0] {
      TMatch(m) => Match(MarkInfos::make(m.marks), m.pmarks)
      _ => Running
    }
  }
}

///|
pub fn Desc::status_is_ambiguous(t : Array[ET], ambiguity_mark : Pmark) -> Bool {
  if t.length() > 0 {
    match t[0] {
      TMatch(m) => m.pmarks.mem(ambiguity_mark)
      _ => false
    }
  } else {
    false
  }
}

///|
fn et_set_idx(idx : Int, e : ET) -> ET {
  match e {
    TMatch(marks) => TMatch(Marks::marks_set_idx(marks, idx))
    TSeq(kind, l, x) => TSeq(kind, Desc::set_idx(idx, l), x)
    TExp(marks, x) => TExp(Marks::marks_set_idx(marks, idx), x)
  }
}

///|
pub fn Desc::set_idx(idx : Int, xs : Array[ET]) -> Array[ET] {
  Array::map(xs, fn(e) { et_set_idx(idx, e) })
}

///|
pub fn[T] Desc::fold_right(t : Array[ET], init~ : T, f~ : (ET, T) -> T) -> T {
  let mut result = init
  for i in 0..<t.length() {
    let idx = t.length() - 1 - i
    result = f(t[idx], result)
  }
  result
}

///|
pub fn Desc::iter_marks(t : Array[ET], f : (Marks) -> Unit) -> Unit {
  for e in t {
    match e {
      TSeq(_, l, _) => Desc::iter_marks(l, f)
      TExp(marks, _) => f(marks)
      TMatch(marks) => f(marks)
    }
  }
}

// --- ET equal and hash ---

///|
pub fn ET::equal(x : ET, y : ET) -> Bool {
  match (x, y) {
    (TSeq(_, l1, e1), TSeq(_, l2, e2)) =>
      Expr::id(e1) == Expr::id(e2) && ET::equal_list(l1, l2)
    (TExp(m1, e1), TExp(m2, e2)) =>
      Expr::id(e1) == Expr::id(e2) && Marks::equal(m1, m2)
    (TMatch(m1), TMatch(m2)) => Marks::equal(m1, m2)
    (_, _) => false
  }
}

///|
pub fn ET::equal_list(l1 : Array[ET], l2 : Array[ET]) -> Bool {
  if l1.length() != l2.length() {
    return false
  }
  for i in 0..<l1.length() {
    if !ET::equal(l1[i], l2[i]) {
      return false
    }
  }
  true
}

///|
pub fn ET::hash(e : ET, accu : Int) -> Int {
  match e {
    TSeq(_, l, expr) =>
      hash_combine(
        0x172a1bce,
        hash_combine(Expr::id(expr), ET::hash_list(l, accu)),
      )
    TExp(marks, expr) =>
      hash_combine(
        0x2b4c0d77,
        hash_combine(Expr::id(expr), Marks::hash(marks, accu)),
      )
    TMatch(marks) => hash_combine(0x1c205ad5, Marks::hash(marks, accu))
  }
}

///|
pub fn ET::hash_list(l : Array[ET], accu : Int) -> Int {
  let mut result = accu
  for e in l {
    result = ET::hash(e, result)
  }
  result
}

// --- Desc equal and hash ---

///|
pub fn Desc::equal(t1 : Array[ET], t2 : Array[ET]) -> Bool {
  ET::equal_list(t1, t2)
}

///|
pub fn Desc::hash(t : Array[ET], accu : Int) -> Int {
  ET::hash_list(t, accu)
}

// --- remove_duplicates ---

///|
fn desc_remove_duplicates_loop(
  seen : HashSet,
  l : Array[ET],
  start : Int,
  y : Expr,
) -> Array[ET] {
  if start >= l.length() {
    return []
  }
  let head = l[start]
  match head {
    TMatch(_) => [head]
    TSeq(kind, l2, x) => {
      let l3 = desc_remove_duplicates_loop(seen, l2, 0, x)
      let r = desc_remove_duplicates_loop(seen, l, start + 1, y)
      Desc::tseq(kind, l3, x, r)
    }
    TExp(marks, e) => {
      let check_id = if Expr::is_eps(e) { Expr::id(y) } else { Expr::id(e) }
      if seen.mem(check_id) {
        desc_remove_duplicates_loop(seen, l, start + 1, y)
      } else {
        seen.add(check_id)
        desc_cons(
          TExp(marks, e),
          desc_remove_duplicates_loop(seen, l, start + 1, y),
        )
      }
    }
  }
}

///|
pub fn Desc::remove_duplicates(
  seen : HashSet,
  l : Array[ET],
  y : Expr,
) -> Array[ET] {
  seen.clear()
  desc_remove_duplicates_loop(seen, l, 0, y)
}
