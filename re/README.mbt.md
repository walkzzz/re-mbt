# re-mbt

[ocaml-re](https://github.com/ocaml/ocaml-re) —— 纯 OCaml 正则表达式库 —— 向地道 MoonBit 的移植。

## 快速上手

> `sb(s)` 将 `String → Bytes`，`bs(b)` 将 `Bytes → String`。

### Perl 前端

```mbt check
///|
test "perl basic match" {
  let re = @re.Perl::compile_pat(sb("(\\d+)-(\\d+)"))
  match @re.exec_opt(re, sb("2024-12-25")) {
    Some(g) => {
      assert_eq(bs(@re.GroupT::get(g, 0).unwrap()), "2024-12")
      assert_eq(bs(@re.GroupT::get(g, 1).unwrap()), "2024")
      assert_eq(bs(@re.GroupT::get(g, 2).unwrap()), "12")
    }
    None => fail("should match")
  }
}
```

```mbt check
///|
test "perl caseless" {
  let re = @re.Perl::compile_pat(sb("hello"), opts=[@re.PerlOpt::caseless()])
  assert_eq(@re.execp(re, sb("HELLO")), true)
}
```

```mbt check
///|
test "perl non-greedy" {
  let re = @re.Perl::compile_pat(sb("a.*?b"))
  match @re.exec_opt(re, sb("axxbxxb")) {
    Some(g) => assert_eq(bs(@re.GroupT::get(g, 0).unwrap()), "axxb")
    None => fail("should match")
  }
}
```

### PCRE 前端

```mbt check
///|
test "pcre caseless" {
  let re = @re.Pcre::regexp(sb("hello"), flags=[@re.PcreFlag::caseless()])
  assert_eq(@re.Pcre::pmatch(re, sb("HELLO")), true)
}
```

```mbt check
///|
test "pcre multiline" {
  let re = @re.Pcre::regexp(sb("^abc$"), flags=[@re.PcreFlag::multiline_p()])
  assert_eq(@re.Pcre::pmatch(re, sb("x\nabc\ny")), true)
}
```

### Str 前端（OCaml 兼容）

```mbt check
///|
test "str match" {
  let re = @re.Str::regexp(sb("[a-z]+"))
  assert_eq(@re.Str::string_match(re, sb("abc"), 0), true)
}
```

```mbt check
///|
test "str search" {
  let re = @re.Str::regexp(sb("world"))
  assert_eq(@re.Str::search_forward(re, sb("hello world"), 0), 6)
}
```

```mbt check
///|
test "str split" {
  let re = @re.Str::regexp(sb(","))
  let parts = @re.Str::split(re, sb("a,b,c"))
  assert_eq(parts.length(), 3)
  assert_eq(bs(parts[0]), "a")
  assert_eq(bs(parts[1]), "b")
  assert_eq(bs(parts[2]), "c")
}
```

```mbt check
///|
test "str global_replace" {
  let re = @re.Str::regexp(sb("o"))
  let result = @re.Str::global_replace(re, sb("0"), sb("foo"))
  assert_eq(bs(result), "f00")
}
```

```mbt check
///|
test "str replace_first" {
  let re = @re.Str::regexp(sb("o"))
  let result = @re.Str::replace_first(re, sb("0"), sb("foo"))
  assert_eq(bs(result), "f0o")
}
```

```mbt check
///|
test "str case_fold" {
  let re = @re.Str::regexp_case_fold(sb("hello"))
  assert_eq(@re.Str::string_match(re, sb("HELLO"), 0), true)
}
```

### Core API

```mbt check
///|
test "core Search::all" {
  let re = @re.compile(@re.Ast::str(sb("ab")))
  let results = @re.Search::all(re, sb("ab_ab_ab"))
  assert_eq(results.length(), 3)
}
```

```mbt check
///|
test "core Search::matches" {
  let re = @re.compile(@re.Ast::rep1(@re.Re::digit()))
  let results = @re.Search::matches(re, sb("a12b34c"))
  assert_eq(results.length(), 2)
  assert_eq(bs(results[0]), "12")
  assert_eq(bs(results[1]), "34")
}
```

```mbt check
///|
test "core Re::pp" {
  let ast = @re.Ast::str(sb("hello"))
  let s = @re.Re::pp(ast)
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
