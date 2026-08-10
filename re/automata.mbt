// Automata — Sem/RepKind/Mark/Idx/Ids (port of lib/automata.ml)
// Expr, Desc, State, delta/advance are in separate files.

///|
pub enum Sem {
  Longest
  Shortest
  First
} derive(Debug, Eq, Compare)

///|
pub enum RepKind {
  Greedy
  NonGreedy
} derive(Debug, Eq, Compare)

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
pub struct Mark {}

///|
pub fn Mark::start() -> Int {
  0
}

///|
pub fn Mark::prev(x : Int) -> Int {
  x - 1
}

///|
pub fn Mark::next(x : Int) -> Int {
  x + 1
}

///|
pub fn Mark::next2(x : Int) -> Int {
  x + 2
}

///|
pub fn Mark::group_count(x : Int) -> Int {
  x / 2
}

///|
pub fn Mark::outside_range(
  t : Int,
  start_inclusive~ : Int,
  stop_inclusive~ : Int,
) -> Bool {
  t < start_inclusive || t > stop_inclusive
}

///|
pub fn Mark::to_dyn(m : Int) -> Dyn {
  Dyn::int(m)
}

///|
pub fn Mark::compare(x : Int, y : Int) -> Int {
  x.compare(y)
}

// --- Idx: state index ---

///|
pub struct Idx {}

///|
pub fn Idx::unknown() -> Int {
  -1
}

///|
pub fn Idx::initial() -> Int {
  0
}

///|
pub fn Idx::used(t : Int) -> Bool {
  t >= 0
}

///|
pub fn Idx::to_int(t : Int) -> Int {
  t
}

///|
pub fn Idx::to_dyn(t : Int) -> Dyn {
  Dyn::int(t)
}

// --- Ids: ID generator for expressions ---

///|
pub struct Ids {
  mut counter : Int
}

///|
pub fn Ids::create() -> Ids {
  { counter: 0 }
}

///|
pub fn Ids::next(self : Ids) -> Int {
  self.counter += 1
  self.counter
}

// --- hash_combine ---

///|
fn hash_combine(h : Int, accu : Int) -> Int {
  accu * 65599 + h
}
