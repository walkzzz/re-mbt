# re_frontend — 正则前端包

> 6 个正则语法前端，共享统一编译核心。

## 公共 API

| 前端 | 类型 | 说明 |
|------|------|------|
| Perl | `Perl` / `PerlOpt` | Perl 兼容语法 |
| PCRE | `Pcre` / `PcreFlag` / `PcreSplitResult` | PCRE 语法 + flags |
| POSIX | `Posix` / `PosixOpt` | POSIX BRE/ERE |
| Emacs | `Emacs` | Emacs 正则 |
| Glob | `Glob` | Shell glob 模式 |
| Str | `Str` / `StrSplitResult` | OCaml Str 兼容 |

## 使用示例

```moonbit
let re = @frontend.Perl::compile_pat(@base.sb("(\\d+)"))
let matched = @compile.execp(re, @base.sb("123"))
```

## 依赖

`re_base`, `re_ast`, `re_compile`, `re_exec`