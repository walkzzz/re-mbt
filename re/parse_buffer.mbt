// ParseBuffer — cursor over a Bytes for pattern parsing (port of lib/parse_buffer.ml)
// OCaml string (byte sequence) → MoonBit Bytes. Char API uses MoonBit Char;
// internally we compare via .to_int() against the byte at the cursor.

///|
pub struct ParseBuffer {
  str : Bytes
  mut pos : Int
}

///|
pub fn ParseBuffer::create(str : Bytes) -> ParseBuffer {
  { str, pos: 0 }
}

///|
pub fn ParseBuffer::unget(t : ParseBuffer) -> Unit {
  t.pos -= 1
}

///|
pub fn ParseBuffer::junk(t : ParseBuffer) -> Unit {
  t.pos += 1
}

///|
pub fn ParseBuffer::eos(t : ParseBuffer) -> Bool {
  t.pos == t.str.length()
}

///|
pub fn ParseBuffer::peek(t : ParseBuffer, c : Char) -> Bool {
  !ParseBuffer::eos(t) && t.str[t.pos].to_int() == c.to_int()
}

///|
pub fn ParseBuffer::peek2(t : ParseBuffer, c : Char, c2 : Char) -> Bool {
  t.pos + 1 < t.str.length() &&
  t.str[t.pos].to_int() == c.to_int() &&
  t.str[t.pos + 1].to_int() == c2.to_int()
}

///|
pub fn ParseBuffer::accept(t : ParseBuffer, c : Char) -> Bool {
  let r = ParseBuffer::peek(t, c)
  if r {
    t.pos += 1
  }
  r
}

///|
pub fn ParseBuffer::get(t : ParseBuffer) -> Char {
  let r = t.str[t.pos].to_int()
  t.pos += 1
  r.unsafe_to_char()
}

///|
pub fn ParseBuffer::accept_s(t : ParseBuffer, s : Bytes) -> Bool {
  let len = s.length()
  let mut ok = true
  for j in 0..<len {
    if t.pos + j >= t.str.length() || s[j].to_int() != t.str[t.pos + j].to_int() {
      ok = false
      break
    }
  }
  if ok {
    t.pos += len
    true
  } else {
    false
  }
}

///|
fn ParseBuffer::integer_aux(t : ParseBuffer, i : Int) -> Int? raise {
  if ParseBuffer::eos(t) {
    Some(i)
  } else {
    let d = ParseBuffer::get(t).to_int()
    if d >= 48 && d <= 57 {
      let i2 = 10 * i + (d - 48)
      if i2 < i {
        fail("Parse_buffer.Parse_error: integer overflow")
      }
      ParseBuffer::integer_aux(t, i2)
    } else {
      ParseBuffer::unget(t)
      Some(i)
    }
  }
}

///|
pub fn ParseBuffer::integer(t : ParseBuffer) -> Int? raise {
  if ParseBuffer::eos(t) {
    None
  } else {
    let d = ParseBuffer::get(t).to_int()
    if d >= 48 && d <= 57 {
      ParseBuffer::integer_aux(t, d - 48)
    } else {
      ParseBuffer::unget(t)
      None
    }
  }
}
