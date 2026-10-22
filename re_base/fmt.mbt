// Fmt — minimal formatting helpers (port of lib/fmt.ml)
// OCaml Fmt is built on Format.formatter; MoonBit has no equivalent formatter
// abstraction. We expose a small set of to-string helpers that downstream
// modules use for debugging output.

///|
#warnings("-unused_type_declaration")
priv struct Fmt {}
