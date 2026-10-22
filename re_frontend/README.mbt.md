# re-mbt

[ocaml-re](https://github.com/ocaml/ocaml-re) —— 纯 OCaml 正则表达式库 —— 向地道 MoonBit 的移植。

## 快速上手

> `@base.sb(s)` 将 `String → Bytes`，`@base.bs(b)` 将 `Bytes → String`。

### Perl 前端

```mbt check
///|
test "perl basic match" {
  let re = @re_frontend.Perl::compile_pat(@base.sb("(\\d+)-(\\d+)"))
  match @compile.exec_opt(re, @base.sb("2024-12-25")) {
    Some(g) => {
      assert_eq(@base.bs(@compile.GroupT::get(g, 0).unwrap()), "2024-12")
      assert_eq(@base.bs(@compile.GroupT::get(g, 1).unwrap()), "2024")
      assert_eq(@base.bs(@compile.GroupT::get(g, 2).unwrap()), "12")
    }
    None => fail("should match")
  }
}
```

```mbt check
///|
test "perl caseless" {
  let re = @re_frontend.Perl::compile_pat(@base.sb("hello"), opts=[
    @re_frontend.PerlOpt::caseless(),
  ])
  assert_eq(@compile.execp(re, @base.sb("HELLO")), true)
}
```

```mbt check
///|
test "perl non-greedy" {
  let re = @re_frontend.Perl::compile_pat(@base.sb("a.*?b"))
  match @compile.exec_opt(re, @base.sb("axxbxxb")) {
    Some(g) => assert_eq(@base.bs(@compile.GroupT::get(g, 0).unwrap()), "axxb")
    None => fail("should match")
  }
}
```

### PCRE 前端

```mbt check
///|
test "pcre caseless" {
  let re = @re_frontend.Pcre::regexp(@base.sb("hello"), flags=[
    @re_frontend.PcreFlag::caseless(),
  ])
  assert_eq(@re_frontend.Pcre::pmatch(re, @base.sb("HELLO")), true)
}
```

```mbt check
///|
test "pcre multiline" {
  let re = @re_frontend.Pcre::regexp(@base.sb("^abc$"), flags=[
    @re_frontend.PcreFlag::multiline_p(),
  ])
  assert_eq(@re_frontend.Pcre::pmatch(re, @base.sb("x\nabc\ny")), true)
}
```

### Str 前端（OCaml 兼容）

```mbt check
///|
test "str match" {
  let re = @re_frontend.Str::regexp(@base.sb("[a-z]+"))
  assert_eq(@re_frontend.Str::string_match(re, @base.sb("abc"), 0), true)
}
```

```mbt check
///|
test "str search" {
  let re = @re_frontend.Str::regexp(@base.sb("world"))
  assert_eq(@re_frontend.Str::search_forward(re, @base.sb("hello world"), 0), 6)
}
```

```mbt check
///|
test "str split" {
  let re = @re_frontend.Str::regexp(@base.sb(","))
  let parts = @re_frontend.Str::split(re, @base.sb("a,b,c"))
  assert_eq(parts.length(), 3)
  assert_eq(@base.bs(parts[0]), "a")
  assert_eq(@base.bs(parts[1]), "b")
  assert_eq(@base.bs(parts[2]), "c")
}
```

```mbt check
///|
test "str global_replace" {
  let re = @re_frontend.Str::regexp(@base.sb("o"))
  let result = @re_frontend.Str::global_replace(
    re,
    @base.sb("0"),
    @base.sb("foo"),
  )
  assert_eq(@base.bs(result), "f00")
}
```

```mbt check
///|
test "str replace_first" {
  let re = @re_frontend.Str::regexp(@base.sb("o"))
  let result = @re_frontend.Str::replace_first(
    re,
    @base.sb("0"),
    @base.sb("foo"),
  )
  assert_eq(@base.bs(result), "f0o")
}
```

```mbt check
///|
test "str case_fold" {
  let re = @re_frontend.Str::regexp_case_fold(@base.sb("hello"))
  assert_eq(@re_frontend.Str::string_match(re, @base.sb("HELLO"), 0), true)
}
```

### Core API

```mbt check
///|
test "core Search::all" {
  let re = @compile.compile(@ast.Ast::str(@base.sb("ab")))
  let results = @exec.Search::all(re, @base.sb("ab_ab_ab"))
  assert_eq(results.length(), 3)
}
```

```mbt check
///|
test "core Search::matches" {
  let re = @compile.compile(@ast.Ast::rep1(@compile.Re::digit()))
  let results = @exec.Search::matches(re, @base.sb("a12b34c"))
  assert_eq(results.length(), 2)
  assert_eq(@base.bs(results[0]), "12")
  assert_eq(@base.bs(results[1]), "34")
}
```

```mbt check
///|
test "core Re::pp" {
  let ast = @ast.Ast::str(@base.sb("hello"))
  let s = @compile.Re::pp(ast)
  assert_eq(s.length() > 0, true)
}
```

## 构建与测试

```bash
moon check           # 类型检查（0 警告，0 错误）
moon test            # 运行全部 437 个测试
moon build           # 构建
moon fmt             # 格式化代码
moon info            # 重新生成 pkg.generated.mbti
```

## 许可证

LGPL-2.1-or-later WITH OCaml-LGPL-linking-exception（与上游 ocaml-re 一致）。
