// Slice — a view into a Bytes (port of lib/slice.ml)
// OCaml `type t = { s : string; pos : int; len : int }` where string is a byte
// sequence. Per the migration guide, OCaml string → MoonBit Bytes here, because
// slices carry matched input bytes (binary payload semantics).

///|
#warnings("-unused_type_declaration")
priv struct Slice {
  s : Bytes
  pos : Int
  len : Int
}

// SliceL — list of slices (port of Slice.L)
// OCaml list; MoonBit Array[Slice]. Used by Group to assemble captured substrings
// that may span multiple input chunks (streaming). For non-streaming matches a
// single slice suffices.

///|
#warnings("-unused_type_declaration")
priv struct SliceL {}
