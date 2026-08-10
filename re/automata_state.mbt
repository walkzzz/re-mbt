// AutomataState — State, WorkingArea, delta/advance (port of lib/automata.ml lines 602-852)
// Single-threaded: no Mutex/Atomic (OCaml's thread-safety is a later concern).

// --- Ctx: context for derivative computation ---

///|
priv enum Ctx {
  CDelta(Int, Category, Category) // (c, prev_cat, next_cat)
  CAdvance(Category, Pmark) // (prev_cat, ambiguity_mark)
}

// --- State ---

///|
pub struct State {
  idx : Int // Idx.t
  category : Category
  desc : Array[ET] // Desc.t
  mut status : Status?
  hash : Int
}

///|
fn state_compute_hash(idx : Int, cat : Category, desc : Array[ET]) -> Int {
  Desc::hash(desc, hash_combine(idx, hash_combine(Category::to_int(cat), 0))) &
  0x3FFFFFFF
}

///|
pub fn State::mk(idx : Int, cat : Category, desc : Array[ET]) -> State {
  {
    idx,
    category: cat,
    desc,
    status: None,
    hash: state_compute_hash(idx, cat, desc),
  }
}

///|
pub fn State::create(cat : Category, e : Expr) -> State {
  State::mk(Idx::initial(), cat, Desc::initial(e))
}

///|
pub fn State::dummy() -> State {
  {
    idx: Idx::unknown(),
    category: Category::dummy(),
    desc: Desc::empty(),
    status: None,
    hash: -1,
  }
}

///|
pub fn State::idx(s : State) -> Int {
  s.idx
}

///|
pub fn State::equal(s1 : State, s2 : State) -> Bool {
  s1.hash == s2.hash &&
  s1.idx == s2.idx &&
  Category::equal(s1.category, s2.category) &&
  Desc::equal(s1.desc, s2.desc)
}

///|
pub fn State::status_no_mutex(s : State) -> Status {
  match s.status {
    Some(st) => st
    None => {
      let st = Desc::status(s.desc)
      s.status = Some(st)
      st
    }
  }
}

///|
pub fn State::status(s : State) -> Status {
  State::status_no_mutex(s)
}

///|
pub fn State::to_dyn(s : State) -> Dyn {
  Dyn::variant("State", [Dyn::int(s.idx)])
}

// --- WorkingArea ---

///|
pub struct WorkingArea {
  mut ids : BitVector
  seen : HashSet
  mut index_count : Int
}

///|
pub fn WorkingArea::create() -> WorkingArea {
  { ids: BitVector::create_zero(1), seen: HashSet::create(), index_count: 0 }
}

///|
pub fn WorkingArea::index_count(w : WorkingArea) -> Int {
  w.index_count
}

///|
fn mark_used_indices(tbl : BitVector, l : Array[ET]) -> Unit {
  Desc::iter_marks(l, fn(marks) {
    for p in marks.marks {
      let (_, i) = p
      if Idx::used(i) {
        if i < tbl.length() {
          tbl.unsafe_set(i, true)
        }
      }
    }
  })
}

///|
fn find_free(tbl : BitVector, idx : Int, len : Int) -> Int {
  if idx == len || !tbl.unsafe_get(idx) {
    idx
  } else {
    find_free(tbl, idx + 1, len)
  }
}

///|
pub fn WorkingArea::free_index(t : WorkingArea, l : Array[ET]) -> Int {
  t.ids.reset_zero()
  mark_used_indices(t.ids, l)
  let len = t.ids.length()
  let idx = find_free(t.ids, 0, len)
  if idx == len {
    t.ids = BitVector::create_zero(2 * len)
    t.index_count = 2 * len
  }
  idx
}

// --- Delta functions (derivative computation) ---

///|
fn delta_expr(ctx : Ctx, marks : Marks, x : Expr, rem : Array[ET]) -> Array[ET] {
  match x {
    Cst(_, s) =>
      match ctx {
        CDelta(c, _, _) =>
          if Cset::mem(c, s) {
            Desc::add_eps(rem, marks)
          } else {
            rem
          }
        CAdvance(_, _) => Desc::texp(marks, x, rem)
      }
    Alt(_, l) => delta_alt(ctx, marks, l, rem)
    Seq(_, kind, y, z) => {
      let y2 = delta_expr(ctx, marks, y, Desc::empty())
      delta_seq(ctx, kind, y2, z, rem)
    }
    Rep(_, rep_kind, kind, y) =>
      delta_rep(ctx, marks, x, rep_kind, kind, y, rem)
    Eps(_) => Desc::add_match(rem, marks)
    MarkOf(_, i) => Desc::add_match(rem, Marks::set_mark(marks, i))
    PmarkOf(_, i) => Desc::add_match(rem, Marks::set_pmark(marks, i))
    Erase(_, b, e) => Desc::add_match(rem, Marks::filter(marks, b, e))
    Before(_, cat) =>
      match ctx {
        CDelta(_, _, next_cat) =>
          if Category::intersect(next_cat, cat) {
            Desc::add_match(rem, marks)
          } else {
            rem
          }
        CAdvance(_, ambiguity_mark) =>
          Desc::add_match(rem, Marks::set_pmark(marks, ambiguity_mark))
      }
    After(_, cat) => {
      let prev_cat = match ctx {
        CDelta(_, prev_cat, _) => prev_cat
        CAdvance(prev_cat, _) => prev_cat
      }
      if Category::intersect(prev_cat, cat) {
        Desc::add_match(rem, marks)
      } else {
        rem
      }
    }
  }
}

///|
fn delta_rep(
  ctx : Ctx,
  marks : Marks,
  x : Expr,
  rep_kind : RepKind,
  kind : Sem,
  y : Expr,
  rem : Array[ET],
) -> Array[ET] {
  let y0 = delta_expr(ctx, marks, y, Desc::empty())
  let (y1, marks2) = match Desc::first_match(y0) {
    None => (y0, marks)
    Some(m) => (Desc::remove_matches(y0), m)
  }
  match rep_kind {
    Greedy => Desc::tseq(kind, y1, x, Desc::add_match(rem, marks2))
    NonGreedy => Desc::add_match(Desc::tseq(kind, y1, x, rem), marks2)
  }
}

///|
fn delta_alt(
  ctx : Ctx,
  marks : Marks,
  l : Array[Expr],
  rem : Array[ET],
) -> Array[ET] {
  let mut result = rem
  for i in 0..<l.length() {
    let idx = l.length() - 1 - i
    result = delta_expr(ctx, marks, l[idx], result)
  }
  result
}

///|
fn delta_seq(
  ctx : Ctx,
  kind : Sem,
  y : Array[ET],
  z : Expr,
  rem : Array[ET],
) -> Array[ET] {
  match Desc::first_match(y) {
    None => Desc::tseq(kind, y, z, rem)
    Some(marks) =>
      match kind {
        Longest =>
          Desc::tseq(
            kind,
            Desc::remove_matches(y),
            z,
            delta_expr(ctx, marks, z, rem),
          )
        Shortest =>
          delta_expr(
            ctx,
            marks,
            z,
            Desc::tseq(kind, Desc::remove_matches(y), z, rem),
          )
        First => {
          let (y1, y2) = Desc::split_at_match(y)
          Desc::tseq(
            kind,
            y1,
            z,
            delta_expr(ctx, marks, z, Desc::tseq(kind, y2, z, rem)),
          )
        }
      }
  }
}

///|
fn delta_e(ctx : Ctx, x : ET, rem : Array[ET]) -> Array[ET] {
  match x {
    TSeq(kind, y, z) => {
      let y2 = delta_desc(ctx, y, Desc::empty())
      delta_seq(ctx, kind, y2, z, rem)
    }
    TExp(marks, e) => delta_expr(ctx, marks, e, rem)
    TMatch(_) => Desc::add_expr(rem, x)
  }
}

///|
fn delta_desc(ctx : Ctx, l : Array[ET], rem : Array[ET]) -> Array[ET] {
  Desc::fold_right(l, init=rem, f=fn(y, acc) { delta_e(ctx, y, acc) })
}

// --- create_state, delta, advance ---

///|
fn create_state(
  tbl_ref : WorkingArea,
  next_cat : Category,
  expr : Array[ET],
) -> State {
  let idx = WorkingArea::free_index(tbl_ref, expr)
  let expr2 = Desc::set_idx(idx, expr)
  State::mk(idx, next_cat, expr2)
}

///|
pub fn delta(
  tbl_ref : WorkingArea,
  next_cat : Category,
  char : Int,
  st : State,
) -> State {
  let prev_cat = st.category
  let ctx = CDelta(char, prev_cat, next_cat)
  let expr = Desc::remove_duplicates(
    tbl_ref.seen,
    delta_desc(ctx, st.desc, Desc::empty()),
    Expr::eps_expr(),
  )
  create_state(tbl_ref, next_cat, expr)
}

///|
pub fn advance(tbl_ref : WorkingArea, st : State) -> State {
  let ambiguity_mark = Pmark::gen()
  let prev_cat = st.category
  let ctx = CAdvance(prev_cat, ambiguity_mark)
  let desc = Desc::remove_duplicates(
    tbl_ref.seen,
    delta_desc(ctx, st.desc, Desc::empty()),
    Expr::eps_expr(),
  )
  let expr = if Desc::status_is_ambiguous(desc, ambiguity_mark) {
    st.desc
  } else {
    desc
  }
  create_state(tbl_ref, st.category, expr)
}
