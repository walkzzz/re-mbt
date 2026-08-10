// BitVector — mutable bit vector (port of lib/bit_vector.ml)
// OCaml stores bits in a Bytes.t. MoonBit: FixedArray[Byte] (8 bits per byte).

///|
pub struct BitVector {
  len : Int
  bits : FixedArray[Byte] // mutable
}

///|
pub fn BitVector::length(self : BitVector) -> Int {
  self.len
}

///|
pub fn BitVector::create_zero(len : Int) -> BitVector {
  let n = if len == 0 { 0 } else { (len + 7) / 8 }
  { len, bits: FixedArray::make(n, 0b0) }
}

///|
pub fn BitVector::reset_zero(self : BitVector) -> Unit {
  for i in 0..<self.bits.length() {
    self.bits[i] = 0b0
  }
}

///|
pub fn BitVector::unsafe_set(self : BitVector, n : Int, b : Bool) -> Unit {
  let i = n >> 3
  let cur = self.bits[i].to_int()
  let mask = 1 << (n & 7)
  self.bits[i] = if b {
    (cur | mask).to_byte()
  } else {
    (cur & mask.lnot()).to_byte()
  }
}

///|
pub fn BitVector::set(self : BitVector, n : Int, b : Bool) -> Unit raise {
  if n < 0 || n >= self.len {
    fail("Bit_vector.set: index out of bounds")
  }
  self.unsafe_set(n, b)
}

///|
pub fn BitVector::unsafe_get(self : BitVector, n : Int) -> Bool {
  let i = n >> 3
  (self.bits[i].to_int() & (1 << (n & 7))) > 0
}

///|
pub fn BitVector::get(self : BitVector, n : Int) -> Bool raise {
  if n < 0 || n >= self.len {
    fail("Bit_vector.get: index out of bounds")
  }
  self.unsafe_get(n)
}
