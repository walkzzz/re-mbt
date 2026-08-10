// Tests for Compile module

///|
fn sb(s : String) -> Bytes {
  let arr : Array[Byte] = []
  for c in s {
    arr.push(c.to_int().to_byte())
  }
  Bytes::from_array(arr)
}

///|
test "compile and match: single char 'a'" {
  let re = compile(Ast::char('a'))
  let s = sb("a")
  assert_eq(match_str_p(re, s, pos=0, len=1), true)
}

///|
test "compile and match: single char 'a' no match 'b'" {
  let re = compile(Ast::char('a'))
  let s = sb("b")
  assert_eq(match_str_p(re, s, pos=0, len=1), false)
}

///|
test "compile and match: 'a' in 'abc'" {
  let re = compile(Ast::char('a'))
  let s = sb("abc")
  assert_eq(match_str_p(re, s, pos=0, len=3), true)
}

///|
test "compile and match: 'b' in 'abc' at pos 1" {
  let re = compile(Ast::char('b'))
  let s = sb("abc")
  assert_eq(match_str_p(re, s, pos=0, len=3), true)
}

///|
test "compile and match: 'abc' matches 'abc'" {
  let re = compile(Ast::str(sb("abc")))
  let s = sb("abc")
  assert_eq(match_str_p(re, s, pos=0, len=3), true)
}

///|
test "compile and match: 'abc' no match 'abd'" {
  let re = compile(Ast::str(sb("abc")))
  let s = sb("abd")
  assert_eq(match_str_p(re, s, pos=0, len=3), false)
}

///|
test "compile and match: 'a*' matches 'aaa'" {
  let re = compile(Ast::rep(Ast::char('a')))
  let s = sb("aaa")
  assert_eq(match_str_p(re, s, pos=0, len=3), true)
}

///|
test "compile and match: 'a*' matches empty" {
  let re = compile(Ast::rep(Ast::char('a')))
  let s = sb("")
  assert_eq(match_str_p(re, s, pos=0, len=0), true)
}

///|
test "compile and match: 'a|b' matches 'a'" {
  let re = compile(Ast::alt([Ast::char('a'), Ast::char('b')]))
  let s = sb("a")
  assert_eq(match_str_p(re, s, pos=0, len=1), true)
}

///|
test "compile and match: 'a|b' matches 'b'" {
  let re = compile(Ast::alt([Ast::char('a'), Ast::char('b')]))
  let s = sb("b")
  assert_eq(match_str_p(re, s, pos=0, len=1), true)
}

///|
test "compile and match: 'a|b' no match 'c'" {
  let re = compile(Ast::alt([Ast::char('a'), Ast::char('b')]))
  let s = sb("c")
  assert_eq(match_str_p(re, s, pos=0, len=1), false)
}

///|
test "compile and match: 'a+' matches 'aaa'" {
  let re = compile(Ast::rep1(Ast::char('a')))
  let s = sb("aaa")
  assert_eq(match_str_p(re, s, pos=0, len=3), true)
}

///|
test "compile and match: 'a+' no match empty" {
  let re = compile(Ast::rep1(Ast::char('a')))
  let s = sb("")
  assert_eq(match_str_p(re, s, pos=0, len=0), false)
}

///|
test "compile and match: 'a?' matches 'a'" {
  let re = compile(Ast::opt(Ast::char('a')))
  let s = sb("a")
  assert_eq(match_str_p(re, s, pos=0, len=1), true)
}

///|
test "compile and match: 'a?' matches empty" {
  let re = compile(Ast::opt(Ast::char('a')))
  let s = sb("")
  assert_eq(match_str_p(re, s, pos=0, len=0), true)
}

///|
test "compile and match: any matches 'x'" {
  let re = compile(Ast::any())
  let s = sb("x")
  assert_eq(match_str_p(re, s, pos=0, len=1), true)
}

///|
test "compile and match: 'a*b' matches 'aaab'" {
  let re = compile(Ast::seq([Ast::rep(Ast::char('a')), Ast::char('b')]))
  let s = sb("aaab")
  assert_eq(match_str_p(re, s, pos=0, len=4), true)
}

///|
test "compile and match: 'a*b' matches 'b'" {
  let re = compile(Ast::seq([Ast::rep(Ast::char('a')), Ast::char('b')]))
  let s = sb("b")
  assert_eq(match_str_p(re, s, pos=0, len=1), true)
}

///|
test "compile and match: 'a*b' no match 'aaa'" {
  let re = compile(Ast::seq([Ast::rep(Ast::char('a')), Ast::char('b')]))
  let s = sb("aaa")
  assert_eq(match_str_p(re, s, pos=0, len=3), false)
}

///|
test "compile and match: whole_string 'abc' matches 'abc'" {
  let re = compile(Ast::whole_string(Ast::str(sb("abc"))))
  let s = sb("abc")
  assert_eq(match_str_p(re, s, pos=0, len=3), true)
}

///|
test "compile and match: whole_string 'abc' no match 'abcd'" {
  let re = compile(Ast::whole_string(Ast::str(sb("abc"))))
  let s = sb("abcd")
  assert_eq(match_str_p(re, s, pos=0, len=4), false)
}
