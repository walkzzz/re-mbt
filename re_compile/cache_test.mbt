// cache_test.mbt — blackbox tests for ReCache memoization.

///|
fn ctb(s : String) -> Bytes {
  let arr : Array[Byte] = []
  for c in s {
    arr.push(c.to_int().to_byte())
  }
  Bytes::from_array(arr)
}

// === ReCache::new / length / clear ===

///|
test "recache new is empty" {
  let cache = @re_compile.ReCache::new()
  assert_eq(@re_compile.ReCache::length(cache), 0)
}

///|
test "recache new_with_capacity is empty" {
  let cache = @re_compile.ReCache::new_with_capacity(16)
  assert_eq(@re_compile.ReCache::length(cache), 0)
}

// === ReCache::compile — miss then hit ===

///|
test "recache compile miss then hit" {
  let cache = @re_compile.ReCache::new()
  let ast = @re_compile.Re::digit()
  let key = ctb("k1")
  // first call: miss, compiles and caches
  let re1 = @re_compile.ReCache::compile(cache, key, ast)
  assert_eq(@re_compile.ReCache::length(cache), 1)
  // second call: hit, returns a clone
  let re2 = @re_compile.ReCache::compile(cache, key, ast)
  assert_eq(@re_compile.ReCache::length(cache), 1)
  // both should match the same input
  let s = ctb("5")
  assert_true(@re_compile.execp(re1, s))
  assert_true(@re_compile.execp(re2, s))
}

///|
test "recache compile different keys" {
  let cache = @re_compile.ReCache::new()
  let ast_d = @re_compile.Re::digit()
  let ast_a = @re_compile.Re::alpha()
  let re1 = @re_compile.ReCache::compile(cache, ctb("digit"), ast_d)
  let re2 = @re_compile.ReCache::compile(cache, ctb("alpha"), ast_a)
  assert_eq(@re_compile.ReCache::length(cache), 2)
  // digit matches '5', alpha does not
  assert_true(@re_compile.execp(re1, ctb("5")))
  assert_false(@re_compile.execp(re2, ctb("5")))
  // alpha matches 'x', digit does not
  assert_true(@re_compile.execp(re2, ctb("x")))
  assert_false(@re_compile.execp(re1, ctb("x")))
}

// === ReCache::get — hit returns clone, miss returns None ===

///|
test "recache get miss returns none" {
  let cache = @re_compile.ReCache::new()
  match @re_compile.ReCache::get(cache, ctb("absent")) {
    Some(_) => assert_eq(true, false)
    None => assert_eq(true, true)
  }
}

///|
test "recache get hit returns clone" {
  let cache = @re_compile.ReCache::new()
  let ast = @re_compile.Re::space()
  let key = ctb("sp")
  let _ = @re_compile.ReCache::compile(cache, key, ast)
  match @re_compile.ReCache::get(cache, key) {
    Some(re) => assert_true(@re_compile.execp(re, ctb(" ")))
    None => assert_eq(true, false)
  }
}

// === ReCache::clear ===

///|
test "recache clear empties cache" {
  let cache = @re_compile.ReCache::new()
  let _ = @re_compile.ReCache::compile(cache, ctb("k"), @re_compile.Re::digit())
  assert_eq(@re_compile.ReCache::length(cache), 1)
  @re_compile.ReCache::clear(cache)
  assert_eq(@re_compile.ReCache::length(cache), 0)
}

// === clone independence: cached Re has independent WorkingArea ===

///|
test "recache hit returns independent clone" {
  let cache = @re_compile.ReCache::new()
  let ast = @re_compile.Re::alnum()
  let key = ctb("alnum")
  let re1 = @re_compile.ReCache::compile(cache, key, ast)
  let re2 = @re_compile.ReCache::compile(cache, key, ast)
  // exercising both clones against different inputs must not interfere
  assert_true(@re_compile.execp(re1, ctb("a")))
  assert_true(@re_compile.execp(re2, ctb("9")))
  assert_true(@re_compile.execp(re1, ctb("z")))
  assert_true(@re_compile.execp(re2, ctb("A")))
}
