// Dyn — dynamic value for debugging/inspection (port of lib/dyn.ml)
// OCaml Dyn is used only for to_dyn / pp; in MoonBit we keep a small dynamic
// type so that downstream modules can satisfy their .mli contracts.

///|
pub enum Dyn {
  Int(Int)
  Tuple(Array[Dyn])
  Enum(String)
  String(String)
  List(Array[Dyn])
  Variant(String, Array[Dyn])
  Record(Array[(String, Dyn)])
} derive(Debug, Eq)

///|
fn Dyn::variant(name : String, args : Array[Dyn]) -> Dyn {
  Variant(name, args)
}

///|
fn Dyn::list(xs : Array[Dyn]) -> Dyn {
  List(xs)
}

///|
fn Dyn::int(x : Int) -> Dyn {
  Int(x)
}

///|
fn Dyn::pair(x : Dyn, y : Dyn) -> Dyn {
  Tuple([x, y])
}

///|
fn Dyn::enum_(name : String) -> Dyn {
  Enum(name)
}

///|
fn Dyn::string(s : String) -> Dyn {
  String(s)
}
