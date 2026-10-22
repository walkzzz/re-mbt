// parse_buffer_test.mbt — tests for ParseBuffer pub APIs

///|
fn sb_pb(s : String) -> Bytes {
  let arr : Array[Byte] = []
  for c in s {
    arr.push(c.to_int().to_byte())
  }
  Bytes::from_array(arr)
}

///|
test "parse_buffer create and eos boundary" {
  let b0 = @re.ParseBuffer::create(sb_pb(""))
  assert_eq(@re.ParseBuffer::eos(b0), true)
  let b1 = @re.ParseBuffer::create(sb_pb("abc"))
  assert_eq(@re.ParseBuffer::eos(b1), false)
  @re.ParseBuffer::junk(b1)
  @re.ParseBuffer::junk(b1)
  @re.ParseBuffer::junk(b1)
  assert_eq(@re.ParseBuffer::eos(b1), true)
}

///|
test "parse_buffer integer normal digits" {
  let b = @re.ParseBuffer::create(sb_pb("123"))
  assert_eq(@re.ParseBuffer::integer(b), Some(123))
}

///|
test "parse_buffer integer empty returns None" {
  let b = @re.ParseBuffer::create(sb_pb(""))
  assert_eq(@re.ParseBuffer::integer(b), None)
}

///|
test "parse_buffer integer non-digit first returns None" {
  let b = @re.ParseBuffer::create(sb_pb("abc"))
  assert_eq(@re.ParseBuffer::integer(b), None)
  assert_eq(b.pos, 0)
}

///|
test "parse_buffer integer digits then non-digit stops" {
  let b = @re.ParseBuffer::create(sb_pb("123abc"))
  assert_eq(@re.ParseBuffer::integer(b), Some(123))
}

///|
test "parse_buffer integer overflow raise" {
  let b = @re.ParseBuffer::create(sb_pb("99999999999999999999"))
  let raised = try {
    let _ = @re.ParseBuffer::integer(b)
    false
  } catch {
    _ => true
  }
  assert_eq(raised, true)
}
