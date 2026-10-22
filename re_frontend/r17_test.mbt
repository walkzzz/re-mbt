// r17_test.mbt — R17 五类多手段测试 for Str 延迟编译 (Sprint 16) + E2E flow.
// 覆盖：形式化证明（Str 语义等价） / E2E（完整流程含缓存 + 延迟编译）

// ============================================================
// 1. 形式化证明 — Str 延迟编译语义等价性
//    不变量 A：string_match(re, s, p) == true 当且仅当 srch 在 s 中 pos=p 找到匹配且 start==p
//    不变量 B：search_forward 找到的位置 pos 满足 string_match(re, s, pos) == true
//    不变量 C：compile_regexp_cached 的 srch 与 compile_regexp 的 srch 语义等价
// ============================================================

///|
test "R17-formal-str: string_match anchored at 0" {
  let re = @re_frontend.Str::regexp(@base.sb("abc"))
  let s = @base.sb("abcdef")
  assert_true(@re_frontend.Str::string_match(re, s, 0))
  assert_false(@re_frontend.Str::string_match(re, s, 1))
}

///|
test "R17-formal-str: string_match false when match not at pos" {
  let re = @re_frontend.Str::regexp(@base.sb("bc"))
  let s = @base.sb("abc")
  assert_false(@re_frontend.Str::string_match(re, s, 0))
  assert_true(@re_frontend.Str::string_match(re, s, 1))
}

///|
test "R17-formal-str: search_forward pos satisfies string_match" {
  let re = @re_frontend.Str::regexp(@base.sb("world"))
  let s = @base.sb("hello world")
  let pos = @re_frontend.Str::search_forward(re, s, 0)
  assert_eq(pos, 6)
  assert_true(@re_frontend.Str::string_match(re, s, pos))
}

///|
test "R17-formal-str: compile_regexp_cached equivalent to compile_regexp" {
  let cache = @compile.ReCache::new()
  let pat = @base.sb("a+b")
  let r_cached = @re_frontend.Str::compile_regexp_cached(cache, pat, false)
  let r_direct = @re_frontend.Str::compile_regexp(pat, false)
  let s = @base.sb("aaab")
  assert_eq(
    @re_frontend.Str::string_match(r_cached, s, 0),
    @re_frontend.Str::string_match(r_direct, s, 0),
  )
  assert_true(@re_frontend.Str::string_match(r_cached, s, 0))
}

///|
test "R17-formal-str: case_fold cached equivalent to direct" {
  let cache = @compile.ReCache::new()
  let pat = @base.sb("HELLO")
  let r_cached = @re_frontend.Str::compile_regexp_cached(cache, pat, true)
  let r_direct = @re_frontend.Str::compile_regexp(pat, true)
  let s = @base.sb("hello world")
  assert_eq(
    @re_frontend.Str::string_match(r_cached, s, 0),
    @re_frontend.Str::string_match(r_direct, s, 0),
  )
  assert_true(@re_frontend.Str::string_match(r_cached, s, 0))
}

// ============================================================
// 5. E2E 测试 — 端到端完整流程
// ============================================================

///|
test "R17-e2e: ReCache lifecycle: compile→match→hit→match→clear→miss" {
  let cache = @compile.ReCache::new()
  let pat = @base.sb("[0-9]+")
  let re1 = @re_frontend.Perl::compile_pat_cached(cache, pat)
  assert_eq(@compile.ReCache::length(cache), 1)
  let s = @base.sb("abc123")
  assert_true(@compile.execp(re1, s))
  let re2 = @re_frontend.Perl::compile_pat_cached(cache, pat)
  assert_eq(@compile.ReCache::length(cache), 1)
  assert_eq(@compile.execp(re1, s), @compile.execp(re2, s))
  @compile.ReCache::clear(cache)
  assert_eq(@compile.ReCache::length(cache), 0)
  let _ = @re_frontend.Perl::compile_pat_cached(cache, pat)
  assert_eq(@compile.ReCache::length(cache), 1)
}

///|
test "R17-e2e: Str lazy compile: match→forward→backward triggers mtch" {
  let re = @re_frontend.Str::regexp(@base.sb("ab"))
  let s = @base.sb("xyzab123ab")
  assert_true(@re_frontend.Str::string_match(re, s, 3))
  assert_false(@re_frontend.Str::string_match(re, s, 0))
  let fwd = @re_frontend.Str::search_forward(re, s, 0)
  assert_eq(fwd, 3)
  let bwd = @re_frontend.Str::search_backward(re, s, 9)
  assert_eq(bwd, 8)
  let bwd2 = @re_frontend.Str::search_backward(re, s, 9)
  assert_eq(bwd2, 8)
}

///|
test "R17-e2e: Str cached + lazy compile full flow" {
  let cache = @compile.ReCache::new()
  let pat = @base.sb("cd")
  let r1 = @re_frontend.Str::compile_regexp_cached(cache, pat, false)
  assert_eq(@compile.ReCache::length(cache), 1)
  let s = @base.sb("abcde")
  assert_true(@re_frontend.Str::string_match(r1, s, 2))
  let fwd = @re_frontend.Str::search_forward(r1, s, 0)
  assert_eq(fwd, 2)
  let bwd = @re_frontend.Str::search_backward(r1, s, 4)
  assert_eq(bwd, 2)
  let r2 = @re_frontend.Str::compile_regexp_cached(cache, pat, false)
  assert_eq(@compile.ReCache::length(cache), 1)
  assert_true(@re_frontend.Str::string_match(r2, s, 2))
  @compile.ReCache::clear(cache)
  assert_eq(@compile.ReCache::length(cache), 0)
  let _ = @re_frontend.Str::compile_regexp_cached(cache, pat, false)
  assert_eq(@compile.ReCache::length(cache), 1)
}

///|
test "R17-e2e: multi-frontend cache isolation" {
  let cache = @compile.ReCache::new()
  let perl_re = @re_frontend.Perl::compile_pat_cached(cache, @base.sb("a|b"))
  let pcre_re = @re_frontend.Pcre::regexp_cached(cache, @base.sb("a|b"))
  let posix_re = @re_frontend.Posix::compile_cached(cache, @base.sb("a|b"))
  let emacs_re = @re_frontend.Emacs::compile_pat_cached(cache, @base.sb("an"))
  let s = @base.sb("banana")
  assert_true(@compile.execp(perl_re, s))
  assert_true(@compile.execp(pcre_re, s))
  assert_true(@compile.execp(posix_re, s))
  assert_true(@compile.execp(emacs_re, s))
  assert_eq(@compile.ReCache::length(cache), 4)
}

///|
test "R17-e2e: Str split with cached regexp" {
  let cache = @compile.ReCache::new()
  let r = @re_frontend.Str::compile_regexp_cached(cache, @base.sb(","), false)
  let parts = @re_frontend.Str::split(r, @base.sb("a,b,c"))
  assert_eq(parts.length(), 3)
  assert_eq(@base.bs(parts[0]), "a")
  assert_eq(@base.bs(parts[1]), "b")
  assert_eq(@base.bs(parts[2]), "c")
}
