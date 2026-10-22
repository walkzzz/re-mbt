// Cache — 前端编译缓存变体。每个前端把 (pattern, opts) 编码为 Bytes key，
// 命中则跳过 parse + compile 直接返回 copy_re 副本；未命中则 parse + compile 并缓存。
// English: Frontend compile-cache variants. Each frontend encodes (pattern, opts) into a
// Bytes key; on hit skip parse+compile and return a copy_re clone; on miss parse+compile+cache.

///|
/// 构造缓存 key：prefix 字节区分前端，opts_byte 编码选项，后接 pattern 字节。
/// English: Build cache key: prefix byte identifies frontend, opts_byte encodes options,
/// followed by pattern bytes.
fn make_cache_key(prefix : Int32, opts_byte : Int32, pat : Bytes) -> Bytes {
  let n = pat.length()
  let buf : Array[Byte] = Array::make(n + 2, (0).to_byte())
  buf[0] = prefix.to_byte()
  buf[1] = opts_byte.to_byte()
  for i in 0..<n {
    buf[i + 2] = pat[i]
  }
  Bytes::from_array(buf)
}

///|
/// 编码 PerlOpt 为单字节位掩码。English: Encode PerlOpt array into a single bitmask byte.
fn perl_opts_byte(opts : Array[PerlOpt]) -> Int32 {
  let mut b = 0
  for opt in opts {
    match opt {
      Ungreedy => b = b | 1
      Dotall => b = b | 2
      DollarEndonly => b = b | 4
      Multiline => b = b | 8
      Anchored => b = b | 16
      Caseless => b = b | 32
    }
  }
  b
}

///|
/// 编码 PcreFlag 为单字节位掩码。English: Encode PcreFlag array into a single bitmask byte.
fn pcre_flags_byte(flags : Array[PcreFlag]) -> Int32 {
  let mut b = 0
  for f in flags {
    match f {
      Caseless => b = b | 1
      MultilineP => b = b | 2
      AnchoredP => b = b | 4
      DotallP => b = b | 8
    }
  }
  b
}

///|
/// 编码 PosixOpt 为单字节位掩码。English: Encode PosixOpt array into a single bitmask byte.
fn posix_opts_byte(opts : Array[PosixOpt]) -> Int32 {
  let mut b = 0
  for opt in opts {
    match opt {
      ICase => b = b | 1
      NoSub => b = b | 2
      Newline => b = b | 4
    }
  }
  b
}

///|
/// 编码 Glob 选项为单字节位掩码。English: Encode Glob options into a single bitmask byte.
fn glob_flags_byte(
  anchored : Bool,
  pathname : Bool,
  match_backslashes : Bool,
  period : Bool,
  double_asterisk : Bool,
) -> Int32 {
  let mut b = 0
  if anchored {
    b = b | 1
  }
  if pathname {
    b = b | 2
  }
  if match_backslashes {
    b = b | 4
  }
  if period {
    b = b | 8
  }
  if double_asterisk {
    b = b | 16
  }
  b
}

// --- Perl ---

///|
/// Perl::compile_pat_cached — 带缓存的 compile_pat。命中跳过 parse+compile。
/// English: Cached compile_pat; on hit skip parse+compile.
pub fn Perl::compile_pat_cached(
  cache : @compile.ReCache,
  s : Bytes,
  opts~ : Array[PerlOpt] = [],
) -> @compile.Re raise {
  let key = make_cache_key(1, perl_opts_byte(opts), s)
  match @compile.ReCache::get(cache, key) {
    Some(re) => re
    None => @compile.ReCache::compile(cache, key, Perl::re(s, opts~))
  }
}

// --- Pcre ---

///|
/// Pcre::regexp_cached — 带缓存的 regexp。命中跳过 parse+compile。
/// English: Cached regexp; on hit skip parse+compile.
pub fn Pcre::regexp_cached(
  cache : @compile.ReCache,
  pat : Bytes,
  flags~ : Array[PcreFlag] = [],
) -> @compile.Re raise {
  let key = make_cache_key(2, pcre_flags_byte(flags), pat)
  match @compile.ReCache::get(cache, key) {
    Some(re) => re
    None => @compile.ReCache::compile(cache, key, Pcre::re(pat, flags~))
  }
}

// --- Posix ---

///|
/// Posix::compile_cached — 带缓存的 compile。命中跳过 parse+compile。
/// English: Cached compile; on hit skip parse+compile.
pub fn Posix::compile_cached(
  cache : @compile.ReCache,
  s : Bytes,
  opts~ : Array[PosixOpt] = [],
) -> @compile.Re raise {
  let key = make_cache_key(3, posix_opts_byte(opts), s)
  match @compile.ReCache::get(cache, key) {
    Some(re) => re
    None =>
      @compile.ReCache::compile(
        cache,
        key,
        @ast.Ast::longest(Posix::re(s, opts~)),
      )
  }
}

///|
/// Posix::compile_pat_cached — 带缓存的 compile_pat。命中跳过 parse+compile。
/// English: Cached compile_pat; on hit skip parse+compile.
pub fn Posix::compile_pat_cached(
  cache : @compile.ReCache,
  s : Bytes,
  opts~ : Array[PosixOpt] = [],
) -> @compile.Re raise {
  Posix::compile_cached(cache, s, opts~)
}

// --- Emacs ---

///|
/// Emacs::compile_pat_cached — 带缓存的 compile_pat。命中跳过 parse+compile。
/// English: Cached compile_pat; on hit skip parse+compile.
pub fn Emacs::compile_pat_cached(
  cache : @compile.ReCache,
  s : Bytes,
  case~ : Bool = true,
) -> @compile.Re raise {
  let opts_byte : Int32 = if case { 1 } else { 0 }
  let key = make_cache_key(4, opts_byte, s)
  match @compile.ReCache::get(cache, key) {
    Some(re) => re
    None => @compile.ReCache::compile(cache, key, Emacs::re(s, case~))
  }
}

// --- Glob ---

///|
/// Glob::compile_cached — 带缓存的 compile。命中跳过 parse+compile。
/// English: Cached compile; on hit skip parse+compile.
pub fn Glob::compile_cached(
  cache : @compile.ReCache,
  s : Bytes,
  anchored~ : Bool = false,
  pathname~ : Bool = true,
  match_backslashes~ : Bool = false,
  period~ : Bool = true,
  double_asterisk~ : Bool = true,
) -> @compile.Re raise {
  let key = make_cache_key(
    5,
    glob_flags_byte(
      anchored, pathname, match_backslashes, period, double_asterisk,
    ),
    s,
  )
  match @compile.ReCache::get(cache, key) {
    Some(re) => re
    None =>
      @compile.ReCache::compile(
        cache,
        key,
        Glob::glob(
          s,
          anchored~,
          pathname~,
          match_backslashes~,
          period~,
          double_asterisk~,
        ),
      )
  }
}

// --- Str ---

///|
/// Str::compile_regexp_cached — 带缓存的 compile_regexp。srch 命中跳过 compile。
/// English: Cached compile_regexp; srch compile is cached.
pub fn Str::compile_regexp_cached(
  cache : @compile.ReCache,
  s : Bytes,
  case_fold : Bool,
) -> StrRegexp raise {
  let opts_byte : Int32 = if case_fold { 1 } else { 0 }
  let key = make_cache_key(6, opts_byte, s)
  let re = Emacs::re_no_emacs(s, case=!case_fold)
  let srch = @compile.ReCache::compile(cache, key, re)
  {
    srch,
    mtch_ast: @ast.Ast::seq([@ast.Ast::start(), re]),
    mtch: Ref::{ val: None, },
  }
}
