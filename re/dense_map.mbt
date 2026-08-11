// DenseMap — memoized dense lookup table (port of lib/dense_map.ml)
// OCaml: `make ~size ~f` builds an array cache and returns a lookup fn.
// MoonBit: we return a closure over an Array.

///|
#warnings("-struct_never_constructed")
pub struct DenseMap {}

///|
fn[T] DenseMap::make(size~ : Int, f~ : (Int) -> T) -> (Int) -> T {
  let cache : Array[T] = Array::makei(size, f)
  fn(i) { cache[i] }
}
