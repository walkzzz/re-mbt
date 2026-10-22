// r17_test.mbt — R17 五类多手段测试 for ReCache memoization (Sprint 17).
// 覆盖：形式化证明 / AI 测试 / FAKE 测试 / MOCK 测试

///|
fn r17tb(s : String) -> Bytes {
  let arr : Array[Byte] = []
  for c in s {
    arr.push(c.to_int().to_byte())
  }
  Bytes::from_array(arr)
}

// ============================================================
// 1. 形式化证明 — ReCache key 唯一性不变量
//    不变量 A：相同 (pattern, opts) → 相同 key → 命中缓存（length 不增）
//    不变量 B：不同 key → 不同缓存条目（length +1）
//    不变量 C：命中缓存返回的 Re 与首次编译的 Re 语义等价（execp 一致）
// ============================================================

///|
test "R17-formal: same key hits cache, length stable" {
  let cache = @re_compile.ReCache::new()
  let ast = @re_compile.Re::digit()
  let key = r17tb("formal-key-1")
  let _ = @re_compile.ReCache::compile(cache, key, ast)
  let len1 = @re_compile.ReCache::length(cache)
  let _ = @re_compile.ReCache::compile(cache, key, ast)
  let len2 = @re_compile.ReCache::length(cache)
  assert_eq(len1, len2)
  assert_eq(len2, 1)
}

///|
test "R17-formal: different keys produce different cache entries" {
  let cache = @re_compile.ReCache::new()
  let _ = @re_compile.ReCache::compile(
    cache,
    r17tb("k-a"),
    @re_compile.Re::digit(),
  )
  let _ = @re_compile.ReCache::compile(
    cache,
    r17tb("k-b"),
    @re_compile.Re::alpha(),
  )
  assert_eq(@re_compile.ReCache::length(cache), 2)
}

///|
test "R17-formal: cache hit returns execp-equivalent Re" {
  let cache = @re_compile.ReCache::new()
  let ast = @re_compile.Re::alnum()
  let key = r17tb("formal-eq")
  let re1 = @re_compile.ReCache::compile(cache, key, ast)
  let re2 = @re_compile.ReCache::compile(cache, key, ast)
  let s = r17tb("Z9")
  assert_eq(@re_compile.execp(re1, s), @re_compile.execp(re2, s))
  assert_true(@re_compile.execp(re1, s))
}

///|
test "R17-formal: get after compile returns Some, miss returns None" {
  let cache = @re_compile.ReCache::new()
  let key = r17tb("formal-get")
  let _ = @re_compile.ReCache::compile(cache, key, @re_compile.Re::digit())
  match @re_compile.ReCache::get(cache, key) {
    Some(_) => assert_eq(true, true)
    None => assert_eq(true, false)
  }
  match @re_compile.ReCache::get(cache, r17tb("formal-absent")) {
    Some(_) => assert_eq(true, false)
    None => assert_eq(true, true)
  }
}

// ============================================================
// 2. AI 测试 — 模拟 ReCache 重复编译场景
// ============================================================

///|
test "R17-ai: compile same pattern N times, only 1 cache entry" {
  let cache = @re_compile.ReCache::new()
  let ast = @re_compile.Re::digit()
  let key = r17tb("ai-repeat")
  for _ in 0..<10 {
    let _ = @re_compile.ReCache::compile(cache, key, ast)
  }
  assert_eq(@re_compile.ReCache::length(cache), 1)
}

///|
test "R17-ai: length grows with distinct patterns" {
  let cache = @re_compile.ReCache::new()
  let pats = [
    @re_compile.Re::digit(),
    @re_compile.Re::alpha(),
    @re_compile.Re::space(),
    @re_compile.Re::alnum(),
  ]
  for i in 0..<pats.length() {
    let key = r17tb("ai-pat-" + i.to_string())
    let _ = @re_compile.ReCache::compile(cache, key, pats[i])
  }
  assert_eq(@re_compile.ReCache::length(cache), 4)
}

///|
test "R17-ai: clear empties cache, recompile misses" {
  let cache = @re_compile.ReCache::new()
  let key = r17tb("ai-clear")
  let _ = @re_compile.ReCache::compile(cache, key, @re_compile.Re::digit())
  assert_eq(@re_compile.ReCache::length(cache), 1)
  @re_compile.ReCache::clear(cache)
  assert_eq(@re_compile.ReCache::length(cache), 0)
  let _ = @re_compile.ReCache::compile(cache, key, @re_compile.Re::digit())
  assert_eq(@re_compile.ReCache::length(cache), 1)
}

///|
test "R17-ai: new_with_capacity behaves like new" {
  let cache = @re_compile.ReCache::new_with_capacity(8)
  assert_eq(@re_compile.ReCache::length(cache), 0)
  let _ = @re_compile.ReCache::compile(
    cache,
    r17tb("ai-cap"),
    @re_compile.Re::digit(),
  )
  assert_eq(@re_compile.ReCache::length(cache), 1)
}

// ============================================================
// 3. FAKE 测试 — 构造假数据验证 ReCache 不崩溃
// ============================================================

///|
test "R17-fake: epsilon pattern compile does not crash" {
  let cache = @re_compile.ReCache::new()
  let eps_ast = @ast.Ast::epsilon()
  let key = r17tb("fake-epsilon")
  let re = @re_compile.ReCache::compile(cache, key, eps_ast)
  assert_true(@re_compile.execp(re, r17tb("")))
  assert_true(@re_compile.execp(re, r17tb("x")))
}

///|
test "R17-fake: empty-set pattern compile does not crash" {
  let cache = @re_compile.ReCache::new()
  let empty_ast = @ast.Ast::empty()
  let key = r17tb("fake-emptyset")
  let re = @re_compile.ReCache::compile(cache, key, empty_ast)
  let _ = @re_compile.execp(re, r17tb(""))
  let _ = @re_compile.execp(re, r17tb("abc"))
  assert_eq(@re_compile.ReCache::length(cache), 1)
}

///|
test "R17-fake: very long pattern (a{500}) compile does not crash" {
  let cache = @re_compile.ReCache::new()
  let long_ast = @ast.Ast::repn(@ast.Ast::char('a'), 500, Some(500))
  let key = r17tb("fake-long")
  let re = @re_compile.ReCache::compile(cache, key, long_ast)
  let buf : Array[Byte] = []
  for _ in 0..<500 {
    buf.push((97).to_byte())
  }
  let s = Bytes::from_array(buf)
  assert_true(@re_compile.execp(re, s))
}

///|
test "R17-fake: get on absent key returns None" {
  let cache = @re_compile.ReCache::new()
  match @re_compile.ReCache::get(cache, r17tb("nonexistent-key-xyz")) {
    Some(_) => assert_eq(true, false)
    None => assert_eq(true, true)
  }
}

///|
test "R17-fake: empty key bytes does not crash" {
  let cache = @re_compile.ReCache::new()
  let empty_key = r17tb("")
  let re = @re_compile.ReCache::compile(
    cache,
    empty_key,
    @re_compile.Re::digit(),
  )
  assert_true(@re_compile.execp(re, r17tb("5")))
  let _ = @re_compile.ReCache::compile(
    cache,
    empty_key,
    @re_compile.Re::digit(),
  )
  assert_eq(@re_compile.ReCache::length(cache), 1)
}

// ============================================================
// 4. MOCK 测试 — 验证缓存跳过编译，返回等价 Re
// ============================================================

///|
test "R17-mock: cached re is execp-equivalent to first compile" {
  let cache = @re_compile.ReCache::new()
  let ast = @re_compile.Re::alpha()
  let key = r17tb("mock-equiv")
  let re_first = @re_compile.ReCache::compile(cache, key, ast)
  let re_cached = @re_compile.ReCache::compile(cache, key, ast)
  let inputs = [r17tb("a"), r17tb("Z"), r17tb("5"), r17tb(""), r17tb("hello")]
  for i in 0..<inputs.length() {
    let r1 = @re_compile.execp(re_first, inputs[i])
    let r2 = @re_compile.execp(re_cached, inputs[i])
    assert_eq(r1, r2)
  }
}

///|
test "R17-mock: different keys do not hit each other" {
  let cache = @re_compile.ReCache::new()
  let _ = @re_compile.ReCache::compile(
    cache,
    r17tb("mock-opt-1"),
    @re_compile.Re::digit(),
  )
  let _ = @re_compile.ReCache::compile(
    cache,
    r17tb("mock-opt-2"),
    @re_compile.Re::digit(),
  )
  assert_eq(@re_compile.ReCache::length(cache), 2)
}

///|
test "R17-mock: cache hit clone has independent WorkingArea" {
  let cache = @re_compile.ReCache::new()
  let ast = @re_compile.Re::alnum()
  let key = r17tb("mock-independent")
  let re1 = @re_compile.ReCache::compile(cache, key, ast)
  let re2 = @re_compile.ReCache::compile(cache, key, ast)
  assert_true(@re_compile.execp(re1, r17tb("a")))
  assert_true(@re_compile.execp(re2, r17tb("9")))
  assert_true(@re_compile.execp(re1, r17tb("A")))
  assert_false(@re_compile.execp(re2, r17tb("!")))
}

///|
test "R17-mock: interleaved compile of two patterns keeps both cached" {
  let cache = @re_compile.ReCache::new()
  let ka = r17tb("mock-interleave-a")
  let kb = r17tb("mock-interleave-b")
  let ra1 = @re_compile.ReCache::compile(cache, ka, @re_compile.Re::digit())
  let rb1 = @re_compile.ReCache::compile(cache, kb, @re_compile.Re::alpha())
  let ra2 = @re_compile.ReCache::compile(cache, ka, @re_compile.Re::digit())
  let rb2 = @re_compile.ReCache::compile(cache, kb, @re_compile.Re::alpha())
  assert_eq(@re_compile.ReCache::length(cache), 2)
  assert_true(@re_compile.execp(ra1, r17tb("7")))
  assert_true(@re_compile.execp(ra2, r17tb("7")))
  assert_true(@re_compile.execp(rb1, r17tb("q")))
  assert_true(@re_compile.execp(rb2, r17tb("q")))
}
