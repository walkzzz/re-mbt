// Util — shared utility functions

///|
pub fn sb(s : String) -> Bytes {
  let arr : Array[Byte] = []
  for c in s {
    arr.push(c.to_int().to_byte())
  }
  Bytes::from_array(arr)
}

///|
pub fn bs(b : Bytes) -> String {
  let mut s = ""
  for i in 0..<b.length() {
    s = s + b[i].to_int().unsafe_to_char().to_string()
  }
  s
}

///|
fn[T] array_reverse(arr : Array[T]) -> Array[T] {
  let n = arr.length()
  let result : Array[T] = []
  for i in 0..<n {
    result.push(arr[n - 1 - i])
  }
  result
}
