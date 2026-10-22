# re — 正则表达式核心包

> OCaml-re 的 MoonBit 移植核心包，提供线性时间正则匹配。

## 包职责

`re` 包是 re-mbt 项目的核心实现，包含：

- **AST**：正则表达式抽象语法树（`Ast`、`AstCset`、`AstGen`）
- **字符集**：`Cset` — 排序区间列表表示的字符集
- **编译**：`compile` — 将 AST 编译为自动机
- **执行**：`exec`、`execp`、`match_str` — 匹配与搜索
- **6 个前端**：`Perl`、`Pcre`、`Posix`、`Emacs`、`Glob`、`Str`
- **分组**：`GroupT` — 匹配结果与分组提取
- **视图**：`View`、`CsetView` — 字符集可视化

## API 概览

### 前端

| 前端 | 编译方法 | 匹配方法 | 说明 |
|------|----------|----------|------|
| Perl | `Perl::compile_pat` | `execp` / `exec_opt` | Perl 兼容语法 |
| PCRE | `Pcre::regexp` | `Pcre::pmatch` | PCRE 语法 + flags |
| POSIX | `Posix::regexp` | `Posix::pmatch` | POSIX BRE/ERE |
| Emacs | `Emacs::regexp` | `Emacs::pmatch` | Emacs 正则 |
| Glob | `Glob::regexp` | `Glob::pmatch` | Shell glob 模式 |
| Str | `Str::regexp` | `Str::pmatch` | OCaml Str 兼容 |

### 核心函数

```moonbit
// 编译正则表达式
let re = @re.Perl::compile_pat(@re.sb("(\\d+)-(\\d+)"))

// 执行匹配
let result = @re.exec_opt(re, @re.sb("2024-12"))

// 布尔匹配
let matched = @re.execp(re, @re.sb("2024-12"))
```

## 使用示例

```moonbit
test "basic match" {
  let re = @re.Perl::compile_pat(@re.sb("hello"))
  assert_eq(@re.execp(re, @re.sb("hello world")), true)
}
```

## 技术细节

- **算法**：Brzozowski/Antimirov 导数 + 惰性 DFA，线性时间匹配
- **字符集**：排序、不重叠、不邻接区间列表
- **自动机**：Expr → Desc → State，带颜色标记的 DFA
- **移植来源**：[ocaml-re](https://github.com/ocaml/ocaml-re)

## 许可证

LGPL-2.1-or-later WITH OCaml-LGPL-linking-exception