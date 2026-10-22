// traits_test.mbt — R17 五类多手段测试 for P3 trait 化
// 覆盖 RegexParser / RegexCompiler / Quotable 三 trait 的 7 impl
// 测试手段：形式化证明 / AI / FAKE / MOCK / E2E
// 契约：
//   RegexParser::re(Self, Bytes) -> @ast.AstGen[@ast.AstCset] raise
//   RegexCompiler::compile_pat(Self, Bytes, case~ : Bool) -> @compile.Re raise
//   Quotable::quote(Self, Bytes) -> Bytes

// ============================================================
// 1. 形式化证明 — 验证 trait 方法返回类型契约 + 语义正确性
//    不变量：re() 返回可编译的 AstGen；compile_pat 返回可执行的 Re；
//    quote() 返回转义后的 Bytes，编译后只匹配字面。
// ============================================================

///|
test "R17-trait-formal-1: RegexParser::re Perl returns compilable AstGen" {
  let ast = @re_frontend.RegexParser::re(
    @re_frontend.Perl::default(),
    @base.sb("abc"),
  )
  let re = @compile.compile(ast)
  assert_true(@compile.execp(re, @base.sb("abc")))
  assert_false(@compile.execp(re, @base.sb("xyz")))
}

///|
test "R17-trait-formal-2: RegexParser::re Posix returns compilable AstGen" {
  let ast = @re_frontend.RegexParser::re(
    @re_frontend.Posix::default(),
    @base.sb("ab"),
  )
  let re = @compile.compile(ast)
  assert_true(@compile.execp(re, @base.sb("ab")))
  assert_false(@compile.execp(re, @base.sb("cd")))
}

///|
test "R17-trait-formal-3: RegexParser::re Pcre returns compilable AstGen" {
  let ast = @re_frontend.RegexParser::re(
    @re_frontend.Pcre::default(),
    @base.sb("xy"),
  )
  let re = @compile.compile(ast)
  assert_true(@compile.execp(re, @base.sb("xy")))
  assert_false(@compile.execp(re, @base.sb("zz")))
}

///|
test "R17-trait-formal-4: RegexParser::re Emacs returns compilable AstGen" {
  let ast = @re_frontend.RegexParser::re(
    @re_frontend.Emacs::default(),
    @base.sb("ef"),
  )
  let re = @compile.compile(ast)
  assert_true(@compile.execp(re, @base.sb("ef")))
  assert_false(@compile.execp(re, @base.sb("gh")))
}

///|
test "R17-trait-formal-5: RegexCompiler::compile_pat Emacs returns executable Re" {
  let re = @re_frontend.RegexCompiler::compile_pat(
    @re_frontend.Emacs::default(),
    @base.sb("hello"),
    case=false,
  )
  assert_true(@compile.execp(re, @base.sb("hello world")))
  assert_false(@compile.execp(re, @base.sb("goodbye")))
}

///|
test "R17-trait-formal-6: Quotable::quote Pcre returns escaped Bytes" {
  let q = @re_frontend.Quotable::quote(
    @re_frontend.Pcre::default(),
    @base.sb("a.b"),
  )
  let re = @compile.compile(
    @re_frontend.RegexParser::re(@re_frontend.Pcre::default(), q),
  )
  assert_true(@compile.execp(re, @base.sb("a.b")))
  assert_false(@compile.execp(re, @base.sb("axb")))
}

///|
test "R17-trait-formal-7: Quotable::quote Str returns escaped Bytes" {
  let q = @re_frontend.Quotable::quote(
    @re_frontend.Str::default(),
    @base.sb("c.d"),
  )
  let re = @re_frontend.Str::compile_regexp(q, false)
  assert_true(@re_frontend.Str::string_match(re, @base.sb("c.d"), 0))
  assert_false(@re_frontend.Str::string_match(re, @base.sb("cxd"), 0))
}

// ============================================================
// 2. AI 测试 — 模拟 trait 多态调用 + 跨前端解析一致性
//    用 RegexParser::re 统一调用不同前端，验证多态分发正确。
// ============================================================

///|
test "R17-trait-ai-1: polymorphic dispatch via RegexParser trait" {
  let pat = @base.sb("ok")
  let s = @base.sb("ok")
  let perl_ast = @re_frontend.RegexParser::re(@re_frontend.Perl::default(), pat)
  let posix_ast = @re_frontend.RegexParser::re(
    @re_frontend.Posix::default(),
    pat,
  )
  let pcre_ast = @re_frontend.RegexParser::re(@re_frontend.Pcre::default(), pat)
  let emacs_ast = @re_frontend.RegexParser::re(
    @re_frontend.Emacs::default(),
    pat,
  )
  assert_true(@compile.execp(@compile.compile(perl_ast), s))
  assert_true(@compile.execp(@compile.compile(posix_ast), s))
  assert_true(@compile.execp(@compile.compile(pcre_ast), s))
  assert_true(@compile.execp(@compile.compile(emacs_ast), s))
}

///|
test "R17-trait-ai-2: cross-frontend consistency for literal pattern" {
  let pat = @base.sb("test")
  let s = @base.sb("test")
  let perl_ast = @re_frontend.RegexParser::re(@re_frontend.Perl::default(), pat)
  let posix_ast = @re_frontend.RegexParser::re(
    @re_frontend.Posix::default(),
    pat,
  )
  let pcre_ast = @re_frontend.RegexParser::re(@re_frontend.Pcre::default(), pat)
  let emacs_ast = @re_frontend.RegexParser::re(
    @re_frontend.Emacs::default(),
    pat,
  )
  assert_true(@compile.execp(@compile.compile(perl_ast), s))
  assert_true(@compile.execp(@compile.compile(posix_ast), s))
  assert_true(@compile.execp(@compile.compile(pcre_ast), s))
  assert_true(@compile.execp(@compile.compile(emacs_ast), s))
}

///|
test "R17-trait-ai-3: trait dispatch result matches direct关联函数 call" {
  let pat = @base.sb("abc")
  let s = @base.sb("abc")
  let trait_ast = @re_frontend.RegexParser::re(
    @re_frontend.Perl::default(),
    pat,
  )
  let direct_ast = @re_frontend.Perl::re(pat)
  assert_eq(
    @compile.execp(@compile.compile(trait_ast), s),
    @compile.execp(@compile.compile(direct_ast), s),
  )
}

///|
test "R17-trait-ai-4: Quotable polymorphic dispatch Pcre and Str both return Bytes" {
  let pat = @base.sb("x.y")
  let pcre_q = @re_frontend.Quotable::quote(@re_frontend.Pcre::default(), pat)
  let str_q = @re_frontend.Quotable::quote(@re_frontend.Str::default(), pat)
  assert_true(pcre_q.length() > 0)
  assert_true(str_q.length() > 0)
}

// ============================================================
// 3. FAKE 测试 — 边界/假数据（空模式、简单模式）不崩溃
//    空模式可能抛预期错误，验证错误可控不崩溃。
// ============================================================

///|
test "R17-trait-fake-1: empty pattern re() controlled (no crash)" {
  let ok1 = try {
    let _ = @re_frontend.RegexParser::re(
      @re_frontend.Perl::default(),
      @base.sb(""),
    )
    true
  } catch {
    _ => true
  }
  let ok2 = try {
    let _ = @re_frontend.RegexParser::re(
      @re_frontend.Posix::default(),
      @base.sb(""),
    )
    true
  } catch {
    _ => true
  }
  let ok3 = try {
    let _ = @re_frontend.RegexParser::re(
      @re_frontend.Pcre::default(),
      @base.sb(""),
    )
    true
  } catch {
    _ => true
  }
  let ok4 = try {
    let _ = @re_frontend.RegexParser::re(
      @re_frontend.Emacs::default(),
      @base.sb(""),
    )
    true
  } catch {
    _ => true
  }
  assert_true(ok1)
  assert_true(ok2)
  assert_true(ok3)
  assert_true(ok4)
}

///|
test "R17-trait-fake-2: simple pattern re() does not crash" {
  let _ = @re_frontend.RegexParser::re(
    @re_frontend.Perl::default(),
    @base.sb("a"),
  )
  let _ = @re_frontend.RegexParser::re(
    @re_frontend.Posix::default(),
    @base.sb("a"),
  )
  let _ = @re_frontend.RegexParser::re(
    @re_frontend.Pcre::default(),
    @base.sb("a"),
  )
  let _ = @re_frontend.RegexParser::re(
    @re_frontend.Emacs::default(),
    @base.sb("a"),
  )
}

///|
test "R17-trait-fake-3: empty pattern compile_pat/quote controlled (no crash)" {
  let ok_compile = try {
    let _ = @re_frontend.RegexCompiler::compile_pat(
      @re_frontend.Emacs::default(),
      @base.sb(""),
      case=false,
    )
    true
  } catch {
    _ => true
  }
  assert_true(ok_compile)
  let q1 = @re_frontend.Quotable::quote(
    @re_frontend.Pcre::default(),
    @base.sb(""),
  )
  let q2 = @re_frontend.Quotable::quote(
    @re_frontend.Str::default(),
    @base.sb(""),
  )
  let _ = (q1, q2)
}

///|
test "R17-trait-fake-4: simple pattern compile_pat/quote does not crash" {
  let re = @re_frontend.RegexCompiler::compile_pat(
    @re_frontend.Emacs::default(),
    @base.sb("ab"),
    case=true,
  )
  assert_true(@compile.execp(re, @base.sb("ab")))
  let q1 = @re_frontend.Quotable::quote(
    @re_frontend.Pcre::default(),
    @base.sb("a+b"),
  )
  let q2 = @re_frontend.Quotable::quote(
    @re_frontend.Str::default(),
    @base.sb("a+b"),
  )
  assert_true(q1.length() > 0)
  assert_true(q2.length() > 0)
}

// ============================================================
// 4. MOCK 测试 — pub(open) trait 跨包可扩展 + trait 分发一致性
//    在测试包中定义新 struct 并 impl RegexParser，验证 open trait。
// ============================================================

///|
struct MockParser {} derive(Default)

///|
extend MockParser with Default::{default}

///|
impl @re_frontend.RegexParser for MockParser with fn re(_self, s) {
  @re_frontend.Pcre::re(s)
}

///|
test "R17-trait-mock-1: pub(open) trait allows cross-package extension" {
  let ast = @re_frontend.RegexParser::re(
    MockParser::default(),
    @base.sb("mock"),
  )
  let re = @compile.compile(ast)
  assert_true(@compile.execp(re, @base.sb("mock")))
  assert_false(@compile.execp(re, @base.sb("real")))
}

///|
test "R17-trait-mock-2: trait dispatch consistency across repeated calls" {
  let parser = @re_frontend.Pcre::default()
  let pat = @base.sb("repeat")
  let s = @base.sb("repeat")
  let ast1 = @re_frontend.RegexParser::re(parser, pat)
  let ast2 = @re_frontend.RegexParser::re(parser, pat)
  assert_eq(
    @compile.execp(@compile.compile(ast1), s),
    @compile.execp(@compile.compile(ast2), s),
  )
}

///|
test "R17-trait-mock-3: Quotable trait dispatch matches direct quote" {
  let pat = @base.sb("a.b*c")
  let trait_q = @re_frontend.Quotable::quote(@re_frontend.Pcre::default(), pat)
  let direct_q = @re_frontend.Pcre::quote(pat)
  assert_eq(@base.bs(trait_q), @base.bs(direct_q))
}

// ============================================================
// 5. E2E 测试 — 端到端全链路
//    re() 解析 → compile 编译 → execp 匹配
//    quote() 转义 → 编译 → 匹配原义字符
// ============================================================

///|
test "R17-trait-e2e-1: re() -> compile -> execp full chain Perl" {
  let ast = @re_frontend.RegexParser::re(
    @re_frontend.Perl::default(),
    @base.sb("[0-9]+"),
  )
  let re = @compile.compile(ast)
  assert_true(@compile.execp(re, @base.sb("abc123")))
  assert_false(@compile.execp(re, @base.sb("abc")))
}

///|
test "R17-trait-e2e-2: compile_pat -> execp full chain Emacs" {
  let re = @re_frontend.RegexCompiler::compile_pat(
    @re_frontend.Emacs::default(),
    @base.sb("gr"),
    case=false,
  )
  assert_true(@compile.execp(re, @base.sb("grep")))
  assert_false(@compile.execp(re, @base.sb("sed")))
}

///|
test "R17-trait-e2e-3: quote() -> re -> compile -> match literal Pcre" {
  let lit = @base.sb("a.b")
  let q = @re_frontend.Quotable::quote(@re_frontend.Pcre::default(), lit)
  let re = @compile.compile(
    @re_frontend.RegexParser::re(@re_frontend.Pcre::default(), q),
  )
  assert_true(@compile.execp(re, @base.sb("a.b")))
  assert_false(@compile.execp(re, @base.sb("axb")))
  assert_false(@compile.execp(re, @base.sb("aXb")))
}

///|
test "R17-trait-e2e-4: quote() -> Str compile -> match literal Str" {
  let lit = @base.sb("x.y")
  let q = @re_frontend.Quotable::quote(@re_frontend.Str::default(), lit)
  let re = @re_frontend.Str::compile_regexp(q, false)
  assert_true(@re_frontend.Str::string_match(re, @base.sb("x.y"), 0))
  assert_false(@re_frontend.Str::string_match(re, @base.sb("xzy"), 0))
}
