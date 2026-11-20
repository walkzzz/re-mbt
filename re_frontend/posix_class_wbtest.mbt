///|
/// 覆盖率补强 — POSIX 字符类（全名称映射、正/负解析、错误路径）
/// Coverage-gap tests for POSIX character classes.

///|
test "posix_class: all 14 names map to an AST" {
  let names = PosixClass::names()
  assert_eq(names.length(), 14)
  for n in names {
    ignore(PosixClass::of_name(n))
  }
}

///|
test "posix_class: parse positive class" {
  let buf = @base.ParseBuffer::create(@base.sb(":alpha:]"))
  assert_true(PosixClass::parse(buf) is Some(_))
}

///|
test "posix_class: parse negated class" {
  let buf = @base.ParseBuffer::create(@base.sb(":^digit:]"))
  assert_true(PosixClass::parse(buf) is Some(_))
}

///|
test "posix_class: non-class input yields None" {
  let buf = @base.ParseBuffer::create(@base.sb("alpha]"))
  assert_true(PosixClass::parse(buf) is None)
}

///|
test "panic posix_class: unknown name" {
  let buf = @base.ParseBuffer::create(@base.sb(":bogus:]"))
  ignore(PosixClass::parse(buf))
}

///|
test "panic posix_class: missing closing bracket" {
  let buf = @base.ParseBuffer::create(@base.sb(":alpha"))
  ignore(PosixClass::parse(buf))
}
