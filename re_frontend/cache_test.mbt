// cache_test.mbt — blackbox tests for frontend _cached variants.

///|
fn ftb(s : String) -> Bytes {
  let arr : Array[Byte] = []
  for c in s {
    arr.push(c.to_int().to_byte())
  }
  Bytes::from_array(arr)
}

// === Perl::compile_pat_cached ===

///|
test "perl compile_pat_cached basic" {
  let cache = @compile.ReCache::new()
  let pat = ftb("[0-9]+")
  let re1 = @re_frontend.Perl::compile_pat_cached(cache, pat)
  // second call hits cache
  let re2 = @re_frontend.Perl::compile_pat_cached(cache, pat)
  let s = ftb("abc123")
  assert_true(@compile.execp(re1, s))
  assert_true(@compile.execp(re2, s))
  assert_eq(@compile.ReCache::length(cache), 1)
}

///|
test "perl compile_pat_cached opts differ" {
  let cache = @compile.ReCache::new()
  let pat = ftb("ABC")
  let _ = @re_frontend.Perl::compile_pat_cached(cache, pat)
  let _ = @re_frontend.Perl::compile_pat_cached(cache, pat, opts=[
    @re_frontend.PerlOpt::caseless(),
  ])
  // different opts => different key => 2 entries
  assert_eq(@compile.ReCache::length(cache), 2)
}

// === Pcre::regexp_cached ===

///|
test "pcre regexp_cached basic" {
  let cache = @compile.ReCache::new()
  let pat = ftb("\\d+")
  let re1 = @re_frontend.Pcre::regexp_cached(cache, pat)
  let re2 = @re_frontend.Pcre::regexp_cached(cache, pat)
  let s = ftb("x42y")
  assert_true(@compile.execp(re1, s))
  assert_true(@compile.execp(re2, s))
  assert_eq(@compile.ReCache::length(cache), 1)
}

// === Posix::compile_cached / compile_pat_cached ===

///|
test "posix compile_cached basic" {
  let cache = @compile.ReCache::new()
  let pat = ftb("[a-z]+")
  let re1 = @re_frontend.Posix::compile_cached(cache, pat)
  let re2 = @re_frontend.Posix::compile_cached(cache, pat)
  let s = ftb("hello")
  assert_true(@compile.execp(re1, s))
  assert_true(@compile.execp(re2, s))
  assert_eq(@compile.ReCache::length(cache), 1)
}

///|
test "posix compile_pat_cached basic" {
  let cache = @compile.ReCache::new()
  let pat = ftb("ab*c")
  let re1 = @re_frontend.Posix::compile_pat_cached(cache, pat)
  let re2 = @re_frontend.Posix::compile_pat_cached(cache, pat)
  let s = ftb("ac")
  assert_true(@compile.execp(re1, s))
  assert_true(@compile.execp(re2, s))
  assert_eq(@compile.ReCache::length(cache), 1)
}

// === Emacs::compile_pat_cached ===

///|
test "emacs compile_pat_cached basic" {
  let cache = @compile.ReCache::new()
  let pat = ftb("xy")
  let re1 = @re_frontend.Emacs::compile_pat_cached(cache, pat)
  let re2 = @re_frontend.Emacs::compile_pat_cached(cache, pat)
  let s = ftb("xyz")
  assert_true(@compile.execp(re1, s))
  assert_true(@compile.execp(re2, s))
  assert_eq(@compile.ReCache::length(cache), 1)
}

///|
test "emacs compile_pat_cached case differs" {
  let cache = @compile.ReCache::new()
  let pat = ftb("AB")
  let _ = @re_frontend.Emacs::compile_pat_cached(cache, pat, case=true)
  let _ = @re_frontend.Emacs::compile_pat_cached(cache, pat, case=false)
  assert_eq(@compile.ReCache::length(cache), 2)
}

// === Glob::compile_cached ===

///|
test "glob compile_cached basic" {
  let cache = @compile.ReCache::new()
  let pat = ftb("*.txt")
  let re1 = @re_frontend.Glob::compile_cached(cache, pat)
  let re2 = @re_frontend.Glob::compile_cached(cache, pat)
  let s = ftb("foo.txt")
  assert_true(@compile.execp(re1, s))
  assert_true(@compile.execp(re2, s))
  assert_eq(@compile.ReCache::length(cache), 1)
}

// === Str::compile_regexp_cached ===

///|
test "str compile_regexp_cached basic" {
  let cache = @compile.ReCache::new()
  let pat = ftb("a+")
  let r1 = @re_frontend.Str::compile_regexp_cached(cache, pat, false)
  let r2 = @re_frontend.Str::compile_regexp_cached(cache, pat, false)
  // srch compiled once for this key
  assert_eq(@compile.ReCache::length(cache), 1)
  let s = ftb("aaa")
  assert_true(@re_frontend.Str::string_match(r1, s, 0))
  assert_true(@re_frontend.Str::string_match(r2, s, 0))
}
