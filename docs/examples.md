# 使用示例与最佳实践 / Examples

## 1. Perl 前端

### 基本匹配

```moonbit
test "perl basic" {
  let re = @re.Perl::compile_pat(@re.sb("(\\d+)-(\\d+)"))
  match @re.exec_opt(re, @re.sb("2024-12-25")) {
    Some(g) => {
      assert_eq(@re.bs(@re.GroupT::get(g, 0).unwrap()), "2024-12")
      assert_eq(@re.bs(@re.GroupT::get(g, 1).unwrap()), "2024")
      assert_eq(@re.bs(@re.GroupT::get(g, 2).unwrap()), "12")
    }
    None => fail("should match")
  }
}
```

### 选项

```moonbit
test "perl caseless" {
  let re = @re.Perl::compile_pat(@re.sb("hello"), opts=[@re.PerlOpt::caseless()])
  assert_eq(@re.execp(re, @re.sb("HELLO")), true)
}
```

## 2. PCRE 前端

```moonbit
test "pcre flags" {
  let re = @re.Pcre::regexp(@re.sb("^abc$"), flags=[@re.PcreFlag::multiline_p()])
  assert_eq(@re.Pcre::pmatch(re, @re.sb("x\nabc\ny")), true)
}
```

## 3. Str 前端（OCaml 兼容）

```moonbit
test "str frontend" {
  let re = @re.Str::regexp(@re.sb("a+"))
  assert_eq(@re.Str::pmatch(re, @re.sb("aaa")), true)
}
```

## 4. Glob 前端

```moonbit
test "glob match" {
  let re = @re.Glob::regexp(@re.sb("*.txt"))
  assert_eq(@re.execp(re, @re.sb("hello.txt")), true)
  assert_eq(@re.execp(re, @re.sb("hello.md")), false)
}
```

## 5. 替换

```moonbit
test "replace" {
  let re = @re.Perl::compile_pat(@re.sb("\\d+"))
  let result = @re.Replace::global(re, @re.sb("a1b2c3"), fn(m) => @re.sb("[@re.bs(m)]"))
  assert_eq(@re.bs(result), "a[1]b[2]c[3]")
}
```

## 6. 搜索

```moonbit
test "search" {
  let re = @re.Perl::compile_pat(@re.sb("\\w+"))
  let results = @re.Search::all(re, @re.sb("hello world"))
  assert_eq(results.length(), 2)
}
```

## 最佳实践

1. **复用编译结果**：`compile_pat` 开销较大，对同一模式多次匹配时应缓存 `Re`
2. **用 `exec_opt` 而非 `exec`**：`exec` 不匹配时抛异常，`exec_opt` 返回 `Option` 更安全
3. **用 `sb` / `bs` 转换**：MoonBit 字符串为 UTF-8，正则操作用 `Bytes`
4. **注意贪婪模式**：默认贪婪，用 `.*?` 等非贪婪语法控制匹配行为