// Dyn — dynamic value for debugging/inspection (port of lib/dyn.ml)
// OCaml Dyn is used only for to_dyn / pp; in MoonBit we keep a small dynamic
// type so that downstream modules can satisfy their .mli contracts.

///|
#warnings("-unused_constructor")
#derive(Debug, Eq)
pub enum Dyn {
  Int(Int32)
  Tuple(Array[Dyn])
  Enum(String)
  String(String)
  List(Array[Dyn])
  Variant(String, Array[Dyn])
  Record(Array[(String, Dyn)])
}

///|
pub extend Dyn with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Dyn with Eq::{equal, not_equal}

///|
pub fn Dyn::variant(name : String, args : Array[Dyn]) -> Dyn {
  Variant(name, args)
}

///|
pub fn Dyn::list(xs : Array[Dyn]) -> Dyn {
  List(xs)
}

///|
pub fn Dyn::int(x : Int32) -> Dyn {
  Int(x)
}

///|
pub fn Dyn::pair(x : Dyn, y : Dyn) -> Dyn {
  Tuple([x, y])
}

///|
pub fn Dyn::enum_(name : String) -> Dyn {
  Enum(name)
}

///|
pub fn Dyn::string(s : String) -> Dyn {
  String(s)
}
