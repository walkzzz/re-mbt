// Automata — Sem/RepKind/Mark/Idx/Ids (port of lib/automata.ml)
// Expr, Desc, State, delta/advance are in separate files.

///|
pub(all) enum Sem {
  Longest
  Shortest
  First
} derive(Debug, Eq, Compare)

///|
pub extend Sem with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Sem with Eq::{equal, not_equal}

///|
pub extend Sem with Compare::{compare, op_lt, op_le, op_gt, op_ge}

///|
pub(all) enum RepKind {
  Greedy
  NonGreedy
} derive(Debug, Eq, Compare)

///|
pub extend RepKind with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend RepKind with Eq::{equal, not_equal}

///|
pub extend RepKind with Compare::{compare, op_lt, op_le, op_gt, op_ge}

///|
pub fn Sem::to_dyn(s : Sem) -> Dyn {
  match s {
    Longest => Dyn::enum_("Longest")
    Shortest => Dyn::enum_("Shortest")
    First => Dyn::enum_("First")
  }
}

///|
pub fn RepKind::to_dyn(r : RepKind) -> Dyn {
  match r {
    Greedy => Dyn::enum_("Greedy")
    NonGreedy => Dyn::enum_("NonGreedy")
  }
}

///|
pub fn Sem::longest() -> Sem {
  Longest
}

///|
pub fn Sem::shortest() -> Sem {
  Shortest
}

///|
pub fn Sem::first() -> Sem {
  First
}

///|
pub fn RepKind::greedy() -> RepKind {
  Greedy
}

///|
pub fn RepKind::non_greedy() -> RepKind {
  NonGreedy
}

///|
pub fn Sem::to_string(s : Sem) -> String {
  match s {
    Longest => "Longest"
    Shortest => "Shortest"
    First => "First"
  }
}

///|
pub fn RepKind::to_string(r : RepKind) -> String {
  match r {
    Greedy => "Greedy"
    NonGreedy => "NonGreedy"
  }
}

///|
pub fn Sem::to_string_short(s : Sem) -> String {
  match s {
    Longest => "L"
    Shortest => "S"
    First => "F"
  }
}

///|
pub fn RepKind::to_string_short(r : RepKind) -> String {
  match r {
    Greedy => "G"
    NonGreedy => "N"
  }
}

// --- Mark: int-based position marks for groups ---

///|
#warnings("-struct_never_constructed")
pub struct Mark {}

///|
pub fn Mark::start() -> Int32 {
  0
}

///|
pub fn Mark::prev(x : Int32) -> Int32 {
  x - 1
}

///|
pub fn Mark::next(x : Int32) -> Int32 {
  x + 1
}

///|
pub fn Mark::next2(x : Int32) -> Int32 {
  x + 2
}

///|
pub fn Mark::group_count(x : Int32) -> Int32 {
  x / 2
}

///|
pub fn Mark::outside_range(
  t : Int32,
  start_inclusive~ : Int32,
  stop_inclusive~ : Int32,
) -> Bool {
  t < start_inclusive || t > stop_inclusive
}

///|
pub fn Mark::to_dyn(m : Int32) -> Dyn {
  Dyn::int(m)
}

///|
pub fn Mark::compare(x : Int32, y : Int32) -> Int32 {
  x.compare(y)
}

// --- Idx: state index ---

///|
#warnings("-struct_never_constructed")
pub struct Idx {}

///|
pub fn Idx::unknown() -> Int32 {
  -1
}

///|
pub fn Idx::initial() -> Int32 {
  0
}

///|
pub fn Idx::used(t : Int32) -> Bool {
  t >= 0
}

///|
pub fn Idx::to_int(t : Int32) -> Int32 {
  t
}

///|
pub fn Idx::to_dyn(t : Int32) -> Dyn {
  Dyn::int(t)
}

// --- Ids: ID generator for expressions ---

///|
pub struct Ids {
  mut counter : Int32
}

///|
pub fn Ids::create() -> Ids {
  { counter: 0, }
}

///|
pub fn Ids::next(self : Ids) -> Int32 {
  self.counter += 1
  self.counter
}

// --- hash_combine ---

///|
pub fn hash_combine(h : Int32, accu : Int32) -> Int32 {
  accu * 65599 + h
}
