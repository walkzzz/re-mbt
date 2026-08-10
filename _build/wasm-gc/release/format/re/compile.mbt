// Compile — compiled regex and matching engine (port of lib/compile.ml)
// Single-threaded: no Mutex (OCaml's thread-safety is a later concern).

// --- CompileIdx: index with break sentinel ---
// Different from Automata.Idx: uses negative values for break states.

///|
pub struct CompileIdx {}

///|
pub fn CompileIdx::unknown() -> Int {
  -2
}

///|
pub fn CompileIdx::break_value() -> Int {
  -3
}

///|
pub fn CompileIdx::of_idx(x : Int) -> Int {
  x
}

///|
pub fn CompileIdx::is_idx(t : Int) -> Bool {
  t >= 0
}

///|
pub fn CompileIdx::is_break(x : Int) -> Bool {
  x <= CompileIdx::break_value()
}

///|
pub fn CompileIdx::is_unknown(x : Int) -> Bool {
  x == CompileIdx::unknown()
}

///|
pub fn CompileIdx::idx(t : Int) -> Int {
  t
}

///|
pub fn CompileIdx::make_break(idx : Int) -> Int {
  -5 - idx
}

///|
pub fn CompileIdx::break_idx(t : Int) -> Int {
  (t + 5) * -1
}

// --- StateInfo ---

///|
pub struct StateInfo {
  idx : Int // CompileIdx.t
  final_ : Array[(Category, (Int, Status))] // (cat, (idx, status))
  desc : State // Automata.State.t
}

// --- CompileState: state with transition table ---

///|
pub struct CompileState {
  info : StateInfo
  transitions : Array[CompileState] // size ncolor, initially unknown_state
}

///|
pub fn CompileState::get_info(s : CompileState) -> StateInfo {
  s.info
}

///|
pub fn CompileState::follow_transition(
  s : CompileState,
  color : Int,
) -> CompileState {
  s.transitions[color]
}

///|
pub fn CompileState::set_transition(
  s : CompileState,
  color : Int,
  st : CompileState,
) -> Unit {
  s.transitions[color] = st
}

///|
pub fn CompileState::is_unknown_transition(
  s : CompileState,
  color : Int,
) -> Bool {
  let st = s.transitions[color]
  CompileIdx::is_unknown(st.info.idx)
}

// --- StateHashTable: hash table for Automata.State -> CompileState ---

///|
pub struct StateHashTable {
  buckets : Array[Array[(State, CompileState)]]
  mut size : Int
}

///|
pub fn StateHashTable::create(capacity : Int) -> StateHashTable {
  let n = if capacity < 1 { 1 } else { capacity }
  let buckets : Array[Array[(State, CompileState)]] = []
  for _ in 0..<n {
    buckets.push([])
  }
  { buckets, size: 0 }
}

///|
pub fn StateHashTable::find(tbl : StateHashTable, key : State) -> CompileState? {
  let h = key.hash.reinterpret_as_uint().reinterpret_as_int() &
    (tbl.buckets.length() - 1)
  for p in tbl.buckets[h] {
    let (k, v) = p
    if State::equal(k, key) {
      return Some(v)
    }
  }
  None
}

///|
pub fn StateHashTable::add(
  tbl : StateHashTable,
  key : State,
  value : CompileState,
) -> Unit {
  let h = key.hash.reinterpret_as_uint().reinterpret_as_int() &
    (tbl.buckets.length() - 1)
  tbl.buckets[h].push((key, value))
  tbl.size += 1
}

// --- Re: compiled regex ---

///|
pub struct Re {
  initial : Expr
  initial_states : Array[(Category, CompileState)]
  colors : ColorTable
  color_repr : ColorRepr
  ncolor : Int
  lnl : Int // Cset.c (color index)
  tbl : WorkingArea
  states : StateHashTable
  group_names : Array[(String, Int)]
  group_count : Int
}

///|
pub fn Re::group_count(r : Re) -> Int {
  r.group_count
}

///|
pub fn Re::group_names(r : Re) -> Array[(String, Int)] {
  r.group_names
}

// --- Positions ---

///|
pub struct Positions {
  mut positions : Array[Int]
  mut length : Int
}

///|
pub fn Positions::empty() -> Positions {
  { positions: [], length: 0 }
}

///|
pub fn Positions::length(t : Positions) -> Int {
  t.length
}

///|
pub fn Positions::unsafe_set(t : Positions, idx : Int, pos : Int) -> Unit {
  t.positions[idx] = pos
}

///|
fn positions_resize(idx : Int, t : Positions) -> Unit {
  t.length = 2 * t.length
  if idx >= t.length {
    positions_resize(idx, t)
  } else {
    let pos = t.positions
    t.positions = Array::make(t.length, 0)
    for i in 0..<pos.length() {
      t.positions[i] = pos[i]
    }
  }
}

///|
pub fn Positions::set(t : Positions, idx : Int, pos : Int) -> Unit {
  if idx >= Positions::length(t) {
    positions_resize(idx, t)
  }
  Positions::unsafe_set(t, idx, pos)
}

///|
pub fn Positions::all(t : Positions) -> Array[Int] {
  t.positions
}

///|
pub fn Positions::first(t : Positions) -> Int {
  t.positions[0]
}

///|
pub fn Positions::make(groups~ : Bool, re : Re) -> Positions {
  if groups {
    let length = WorkingArea::index_count(re.tbl) + 1
    { positions: Array::make(length, 0), length }
  } else {
    Positions::empty()
  }
}

// --- category ---

///|
let category_lnl : Category = Category::add(
  Category::add(Category::lastnewline(), Category::newline()),
  Category::not_letter(),
)

///|
fn compile_category(re : Re, color : Int) -> Category {
  if CsetC::equal_c(color, CsetC::null_char()) {
    Category::inexistant()
  } else if CsetC::equal_c(color, re.lnl) {
    category_lnl
  } else {
    Category::from_char(re.color_repr.repr(color).to_int().unsafe_to_char())
  }
}

// --- find_state ---

///|
fn find_state(re : Re, desc : State) -> CompileState {
  match StateHashTable::find(re.states, desc) {
    Some(st) => st
    None => {
      let break_state = match State::status_no_mutex(desc) {
        Running => false
        Failed => true
        Match(_, _) => true
      }
      let info_idx = if break_state {
        CompileIdx::make_break(State::idx(desc))
      } else {
        CompileIdx::of_idx(State::idx(desc))
      }
      let st_info = { idx: info_idx, final_: [], desc }
      let st = if break_state {
        { info: st_info, transitions: [] }
      } else {
        {
          info: st_info,
          transitions: Array::make(re.ncolor, compile_unknown_state()),
        }
      }
      StateHashTable::add(re.states, desc, st)
      st
    }
  }
}

///|
fn compile_unknown_state() -> CompileState {
  let unknown_info : StateInfo = {
    idx: CompileIdx::unknown(),
    final_: [],
    desc: State::dummy(),
  }
  { info: unknown_info, transitions: [] }
}

// --- delta and validate ---

///|
fn compile_delta(re : Re, cat : Category, color : Int, st : State) -> State {
  delta(re.tbl, cat, color, st)
}

///|
fn validate(re : Re, s : Bytes, pos : Int, st : CompileState) -> Unit {
  let color = re.colors.get(s[pos].to_int())
  if CompileState::is_unknown_transition(st, color) {
    let cat = compile_category(re, color)
    let desc = compile_delta(re, cat, color, st.info.desc)
    let st2 = find_state(re, desc)
    CompileState::set_transition(st, color, st2)
  }
}

///|
fn next_state(
  colors : ColorTable,
  st : CompileState,
  s : Bytes,
  pos : Int,
) -> CompileState {
  st.transitions[colors.get(s[pos].to_int())]
}

// --- matching loops ---

///|
fn match_loop(
  re : Re,
  colors : ColorTable,
  positions : Positions,
  s : Bytes,
  pos : Int,
  last : Int,
  st0 : CompileState,
  st : CompileState,
) -> CompileState {
  if pos < last {
    let st2 = next_state(colors, st, s, pos)
    let idx = st2.info.idx
    if CompileIdx::is_idx(idx) {
      if CompileIdx::idx(idx) < Positions::length(positions) {
        Positions::unsafe_set(positions, CompileIdx::idx(idx), pos)
        match_loop(re, colors, positions, s, pos + 1, last, st2, st2)
      } else {
        Positions::set(positions, CompileIdx::idx(idx), pos)
        match_loop(re, colors, positions, s, pos + 1, last, st2, st2)
      }
    } else if CompileIdx::is_break(idx) {
      Positions::set(positions, CompileIdx::break_idx(idx), pos)
      st2
    } else {
      validate(re, s, pos, st0)
      match_loop(re, colors, positions, s, pos, last, st0, st0)
    }
  } else {
    st
  }
}

///|
fn match_loop_no_mark(
  re : Re,
  colors : ColorTable,
  s : Bytes,
  pos : Int,
  last : Int,
  st0 : CompileState,
  st : CompileState,
) -> CompileState {
  if pos < last {
    let st2 = next_state(colors, st, s, pos)
    let idx = st2.info.idx
    if CompileIdx::is_idx(idx) {
      match_loop_no_mark(re, colors, s, pos + 1, last, st2, st2)
    } else if CompileIdx::is_break(idx) {
      st2
    } else {
      validate(re, s, pos, st0)
      match_loop_no_mark(re, colors, s, pos, last, st0, st0)
    }
  } else {
    st
  }
}

// --- final and advance ---

///|
fn find_or_add_final(
  re : Re,
  st : StateInfo,
  cat : Category,
  f : (Re, StateInfo, Category) -> (Int, Status),
) -> (Int, Status) {
  for p in st.final_ {
    let (c, res) = p
    if Category::equal(c, cat) {
      return res
    }
  }
  let res = f(re, st, cat)
  st.final_.push((cat, res))
  res
}

///|
fn final_state(re : Re, st : StateInfo, cat : Category) -> (Int, Status) {
  let st2 = compile_delta(re, cat, CsetC::null_char(), st.desc)
  (State::idx(st2), State::status_no_mutex(st2))
}

///|
fn advance_state(re : Re, st : StateInfo, _cat : Category) -> (Int, Status) {
  let st2 = advance(re.tbl, st.desc)
  (State::idx(st2), State::status_no_mutex(st2))
}

///|
fn compile_final(re : Re, st : StateInfo, cat : Category) -> (Int, Status) {
  find_or_add_final(re, st, cat, fn(r, si, c) { final_state(r, si, c) })
}

///|
fn compile_advance(re : Re, st : StateInfo) -> (Int, Status) {
  find_or_add_final(re, st, Category::dummy(), fn(r, si, c) {
    advance_state(r, si, c)
  })
}

// --- find_initial_state ---

///|
fn find_initial_state(re : Re, cat : Category) -> CompileState {
  for p in re.initial_states {
    let (c, st) = p
    if Category::equal(c, cat) {
      return st
    }
  }
  let st = find_state(re, State::create(cat, re.initial))
  re.initial_states.push((cat, st))
  st
}

// --- get_color ---

///|
fn get_color(re : Re, s : Bytes, pos : Int) -> Int {
  if pos < 0 {
    CsetC::null_char()
  } else {
    let slen = s.length()
    if pos >= slen {
      CsetC::null_char()
    } else if pos == slen - 1 &&
      !CsetC::equal_c(re.lnl, CsetC::null_char()) &&
      s[pos].to_int() == 10 {
      re.lnl
    } else {
      re.colors.get(s[pos].to_int())
    }
  }
}

// --- handle_last_newline ---

///|
fn handle_last_newline(
  re : Re,
  positions : Positions,
  pos : Int,
  st : CompileState,
  groups : Bool,
) -> CompileState {
  let st2 = st.transitions[re.lnl]
  let info = st2.info
  if CompileIdx::is_idx(info.idx) {
    if groups {
      Positions::set(positions, CompileIdx::idx(info.idx), pos)
    }
    st2
  } else if CompileIdx::is_break(info.idx) {
    if groups {
      Positions::set(positions, CompileIdx::break_idx(info.idx), pos)
    }
    st2
  } else {
    let color = re.lnl
    if CompileState::is_unknown_transition(st, color) {
      let cat = compile_category(re, color)
      let real_c = re.colors.get(10)
      let desc = compile_delta(re, cat, real_c, st.info.desc)
      let st3 = find_state(re, desc)
      CompileState::set_transition(st, color, st3)
    }
    handle_last_newline(re, positions, pos, st, groups)
  }
}

// --- scan_str ---

///|
fn scan_str(
  re : Re,
  positions : Positions,
  s : Bytes,
  initial_state : CompileState,
  last : Int,
  pos : Int,
  groups : Bool,
) -> CompileState {
  if last == s.length() &&
    !CsetC::equal_c(re.lnl, CsetC::null_char()) &&
    last > pos &&
    s[last - 1].to_int() == 10 {
    let last2 = last - 1
    let st = scan_str(re, positions, s, initial_state, last2, pos, groups)
    if CompileIdx::is_break(st.info.idx) {
      st
    } else {
      handle_last_newline(re, positions, last, st, groups)
    }
  } else if groups {
    match_loop(
      re,
      re.colors,
      positions,
      s,
      pos,
      last,
      initial_state,
      initial_state,
    )
  } else {
    match_loop_no_mark(
      re,
      re.colors,
      s,
      pos,
      last,
      initial_state,
      initial_state,
    )
  }
}

// --- final_boundary_check and final_advance ---

///|
fn final_boundary_check(
  re : Re,
  positions : Positions,
  last : Int,
  slen : Int,
  s : Bytes,
  state_info : StateInfo,
  groups : Bool,
) -> Status {
  let final_cat = Category::add(
    Category::search_boundary(),
    if last == slen {
      Category::inexistant()
    } else {
      compile_category(re, get_color(re, s, last))
    },
  )
  let (idx, res) = compile_final(re, state_info, final_cat)
  if groups {
    match res {
      Match(_, _) => Positions::set(positions, idx, last)
      _ => ()
    }
  }
  res
}

///|
fn final_advance(
  re : Re,
  positions : Positions,
  last : Int,
  state_info : StateInfo,
  groups : Bool,
) -> Status {
  let (idx, res) = compile_advance(re, state_info)
  if groups {
    match res {
      Match(_, _) => Positions::set(positions, idx, last)
      _ => ()
    }
  }
  res
}

// --- MatchInfo ---

///|
pub enum MatchInfo {
  MatchInfo(GroupT)
  FailedInfo
  RunningInfo(Int) // no_match_starts_before
}

// --- Group (simplified for now) ---

///|
pub struct GroupT {
  s : Bytes
  marks : MarkInfos
  pmarks : PmarkSet
  gpos : Array[Int]
  gcount : Int
}

///|
pub fn GroupT::create(
  s : Bytes,
  marks : MarkInfos,
  pmarks : PmarkSet,
  gpos : Array[Int],
  gcount : Int,
) -> GroupT {
  { s, marks, pmarks, gpos, gcount }
}

///|
pub fn GroupT::get(g : GroupT, i : Int) -> Bytes? {
  match MarkInfos::offset(g.marks, i) {
    None => None
    Some((start, stop)) => {
      let s_start = g.gpos[start]
      let s_stop = g.gpos[stop]
      let len = s_stop - s_start
      if len < 0 {
        None
      } else {
        let buf = Array::make(len, (0).to_byte())
        for k in 0..<len {
          buf[k] = g.s[s_start + k]
        }
        Some(Bytes::from_array(buf))
      }
    }
  }
}

// --- make_match_str ---

///|
fn make_match_str(
  re : Re,
  positions : Positions,
  len : Int,
  groups : Bool,
  partial : Bool,
  s : Bytes,
  pos : Int,
) -> Status {
  let slen = s.length()
  let last = if len == -1 { slen } else { pos + len }
  let initial_state = {
    let initial_cat = Category::add(
      Category::search_boundary(),
      if pos == 0 {
        Category::inexistant()
      } else {
        compile_category(re, get_color(re, s, pos - 1))
      },
    )
    find_initial_state(re, initial_cat)
  }
  let st = scan_str(re, positions, s, initial_state, last, pos, groups)
  let state_info = st.info
  if partial {
    match State::status(state_info.desc) {
      Match(_, _) as status => status
      Failed as status => status
      Running => final_advance(re, positions, last, state_info, groups)
    }
  } else if CompileIdx::is_break(state_info.idx) {
    State::status(state_info.desc)
  } else {
    final_boundary_check(re, positions, last, slen, s, state_info, groups)
  }
}

// --- match_str_no_bounds ---

///|
pub fn match_str_no_bounds(
  groups~ : Bool,
  partial~ : Bool,
  re : Re,
  s : Bytes,
  pos~ : Int,
  len~ : Int,
) -> MatchInfo {
  let positions = Positions::make(groups~, re)
  match make_match_str(re, positions, len, groups, partial, s, pos) {
    Match(marks, pmarks) =>
      MatchInfo(
        GroupT::create(
          s,
          marks,
          pmarks,
          Positions::all(positions),
          re.group_count,
        ),
      )
    Failed => FailedInfo
    Running => {
      let no_match_starts_before = if groups {
        Positions::first(positions)
      } else {
        0
      }
      RunningInfo(no_match_starts_before)
    }
  }
}

// --- match_str ---

///|
pub fn match_str(
  groups~ : Bool,
  partial~ : Bool,
  re : Re,
  s : Bytes,
  pos~ : Int,
  len~ : Int,
) -> MatchInfo raise {
  if pos < 0 || len < -1 || pos + len > s.length() {
    fail("Re.exec: out of bounds")
  }
  match_str_no_bounds(groups~, partial~, re, s, pos~, len~)
}

// --- match_str_p ---

///|
pub fn match_str_p(re : Re, s : Bytes, pos~ : Int, len~ : Int) -> Bool raise {
  if pos < 0 || len < -1 || pos + len > s.length() {
    fail("Re.exec: out of bounds")
  }
  match make_match_str(re, Positions::empty(), len, false, false, s, pos) {
    Match(_, _) => true
    _ => false
  }
}

// --- mk_re ---

///|
pub fn mk_re(
  initial~ : Expr,
  colors~ : ColorTable,
  color_repr~ : ColorRepr,
  ncolor~ : Int,
  lnl~ : Int,
  group_names~ : Array[(String, Int)],
  group_count~ : Int,
) -> Re {
  {
    initial,
    initial_states: [],
    colors,
    color_repr,
    ncolor,
    lnl,
    tbl: WorkingArea::create(),
    states: StateHashTable::create(64),
    group_names,
    group_count,
  }
}

///|
pub fn copy_re(re : Re) -> Re {
  mk_re(
    initial=re.initial,
    colors=re.colors,
    color_repr=re.color_repr,
    ncolor=re.ncolor,
    lnl=re.lnl,
    group_names=re.group_names,
    group_count=re.group_count,
  )
}
