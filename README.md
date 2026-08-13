# re-mbt

[ocaml-re](https://github.com/ocaml/ocaml-re) —— 纯 OCaml 正则表达式库 —— 向地道 MoonBit 的移植。

## 状态

**已完成。** 所有模块均从 ocaml-re 移植，经过充分测试与优化。

- [x] 项目骨架（`moon.mod`、`re/` 包）
- [x] 基础数据结构：`Pmark`、`Category`、`BitVector`、`DenseMap`、`HashSet`、`Slice`、`Dyn`、`Fmt`、`Cset`
- [x] AST 及辅助模块：`Ast`、`ColorMap`、`MarkInfos`、`PosixClass`、`ParseBuffer`
- [x] `Automata`（Brzozowski/Antimirov 导数）
- [x] `Compile`（惰性 DFA 驱动器）
- [x] `Core` / `Group` / `Replace` / `Search`
- [x] 前端：`Perl`、`Pcre`、`Posix`、`Emacs`、`Glob`、`Str`
- [x] `View`

## 特性

- **线性时间匹配** —— 惰性 DFA + Brzozowski/Antimirov 导数，无灾难性回溯
- **6 种前端语法** —— Perl、PCRE、POSIX、Emacs、Glob、Str（OCaml 兼容）
- **面向字节** —— 输入文本、模式、捕获子串均使用 MoonBit `Bytes`
- **纯 MoonBit** —— 无 C FFI，目标：native、wasm、js
- **latin1 大小写处理** —— 与上游 ocaml-re 行为一致
- **423 个测试** —— 全部通过，覆盖核心 API、前端、错误路径和边界条件
- **零警告** —— `moon check` 干净通过

## 构建与测试

```bash
moon check           # 类型检查（0 警告，0 错误）
moon test            # 运行全部 423 个测试
moon build           # 构建
moon fmt             # 格式化代码
moon info            # 重新生成 pkg.generated.mbti
```

## 快速上手

> **说明：** `sb(s)` 将 `String → Bytes`，`bs(b)` 将 `Bytes → String`。两者均为 `re` 包提供的公开辅助函数。

### Perl 前端

```moonbit
// 编译并匹配，提取捕获组
let re = Perl::compile_pat(sb("(\\d+)-(\\d+)"))
match exec_opt(re, sb("2024-12-25")) {
  Some(g) => {
    assert_eq(bs(GroupT::get(g, 0).unwrap()), "2024-12")  // 完整匹配
    assert_eq(bs(GroupT::get(g, 1).unwrap()), "2024")     // 捕获组 1
    assert_eq(bs(GroupT::get(g, 2).unwrap()), "12")       // 捕获组 2
  }
  None => ()
}

// 谓词匹配
let re2 = Perl::compile_pat(sb("hello"))
assert_eq(execp(re2, sb("hello world")), true)

// 大小写不敏感
let re3 = Perl::compile_pat(sb("hello"), opts=[PerlOpt::caseless()])
assert_eq(execp(re3, sb("HELLO")), true)

// 非贪婪量词
let re4 = Perl::compile_pat(sb("a.*?b"))
match exec_opt(re4, sb("axxbxxb")) {
  Some(g) => assert_eq(bs(GroupT::get(g, 0).unwrap()), "axxb")
  None => ()
}
```

### PCRE 前端

```moonbit
// 带标志的 PCRE
let re = Pcre::regexp(sb("hello"), flags=[PcreFlag::Caseless()])
assert_eq(Pcre::pmatch(re, sb("HELLO")), true)

let re2 = Pcre::regexp(sb("^abc$"), flags=[PcreFlag::MultilineP()])
assert_eq(Pcre::pmatch(re2, sb("x\nabc\ny")), true)
```

### Str 前端（OCaml 兼容）

```moonbit
// 匹配
let re = Str::regexp(sb("[a-z]+"))
assert_eq(Str::string_match(re, sb("abc"), 0), true)

// 搜索
let re2 = Str::regexp(sb("world"))
assert_eq(Str::search_forward(re2, sb("hello world"), 0), 6)

// 分割
let re3 = Str::regexp(sb(","))
let parts = Str::split(re3, sb("a,b,c"))
// parts = ["a", "b", "c"]

// 大小写折叠
let re4 = Str::regexp_case_fold(sb("hello"))
assert_eq(Str::string_match(re4, sb("HELLO"), 0), true)
```

## API 概览

### 核心匹配

| 函数 | 说明 |
|------|------|
| `exec(re, s, pos?, len?) -> GroupT raise` | 匹配，无匹配时 raise |
| `exec_opt(re, s, pos?, len?) -> GroupT? raise` | 匹配，无匹配时返回 `None` |
| `execp(re, s, pos?, len?) -> Bool raise` | 谓词：是否匹配 |
| `exec_partial(re, s, ...) -> ExecPartialResult raise` | 部分匹配（流式） |
| `exec_partial_detailed(re, s, ...) -> ExecPartialDetailedResult raise` | 部分匹配（含捕获组信息） |
| `Re::pp(ast) -> String` | 格式化 AST 为字符串 |
| `Re::pp_re(re) -> String` | 格式化已编译正则为字符串 |

### 高层搜索与分割

| 函数 | 说明 |
|------|------|
| `Search::all(re, s, pos?, len?) -> Array[GroupT]` | 查找全部匹配 |
| `Search::matches(re, s, ...) -> Array[Bytes]` | 提取全部匹配子串 |
| `Search::split(re, s, ...) -> Array[Bytes]` | 按模式分割（丢弃分隔符） |
| `Search::split_delim(re, s, ...) -> Array[Bytes]` | 按模式分割（保留空段） |
| `Search::split_full(re, s, ...) -> Array[SplitToken]` | 分割并返回 `SplitText`/`SplitDelim` 标记 |

### 前端编译器

| 前端 | 编译函数 | 选项 |
|------|---------|------|
| Perl | `Perl::compile_pat(pat, opts?)` | `Anchored`、`Dotall`、`Multiline`、`DollarEndonly`、`Ungreedy`、`Caseless` |
| PCRE | `Pcre::regexp(pat, flags?)` | `Caseless`、`MultilineP`、`AnchoredP`、`DotallP` |
| Emacs | `Emacs::compile_pat(pat, case?)` | 大小写敏感开关 |
| POSIX | `Posix::compile_pat(pat)` | — |
| Glob | `Glob::compile_pat(pat)` | — |
| Str | `Str::regexp(pat)` / `Str::regexp_case_fold(pat)` | 大小写折叠 |

### 捕获组提取

| 函数 | 说明 |
|------|------|
| `GroupT::get(g, n) -> Bytes?` | 获取第 `n` 个捕获组的子串 |
| `GroupT::start(g, n) -> Int` | 第 `n` 个捕获组的起始位置 |
| `GroupT::stop(g, n) -> Int` | 第 `n` 个捕获组的结束位置 |
| `GroupT::nb_groups(g) -> Int` | 捕获组数量 |

### Str 高级 API

| 函数 | 说明 |
|------|------|
| `Str::string_match(re, s, pos) -> Bool` | 在指定位置匹配 |
| `Str::search_forward(re, s, pos) -> Int` | 从指定位置向前搜索 |
| `Str::split(re, text) -> Array[Bytes]` | 按模式分割 |
| `Str::bounded_split(re, text, n) -> Array[Bytes]` | 限制段数的分割 |
| `Str::full_split(re, text) -> Array[StrSplitResult]` | 含分隔符的分割 |
| `Str::global_replace(re, repl, text) -> Bytes` | 全局替换 |
| `Str::replace_first(re, repl, text) -> Bytes` | 替换首个 |
| `Str::quote(s) -> Bytes` | 转义特殊字符 |

## 设计

- **单一 `re` 包**，内部模块与 OCaml 1:1 对应（`cset.mbt`、`ast.mbt`、`automata.mbt`、...）。
- **匹配引擎**：忠实移植惰性 DFA + Brzozowski/Antimirov 导数（线性时间匹配，无灾难性回溯）。
- **面向字节**：OCaml `string` 为字节序列；移植使用 MoonBit `Bytes` 表示输入文本、模式和捕获子串。
- **纯 MoonBit**，无 C FFI。目标：native、wasm、js。
- **latin1** 大小写处理，与上游一致。

## 性能

通过 PDC（Plan-Do-Check）工作流进行 benchmark 驱动的优化验证：

- **ColorMap::flatten** 重写：哈希去重 + 缓冲复用 → **Section 1（Perl 编译）951ms → 505ms（−46.9%）**
- **Cset union/inter/diff** 容量预分配 + 分治归并 → 全 section 均有改进
- 全部 10 个 benchmark section 均为正改进，无回归

## 测试

```
moon test    # 423 个测试，全部通过
moon check   # 0 警告，0 错误
```

测试覆盖范围：
- 核心 API 边界条件与错误路径
- 全部 6 个前端解析器（正向 + 错误路径）
- Cset 边界条件（空集、全集、补集、256 全遍历、latin1）
- 自动机内部（Expr::rename、Desc 操作、StateHashTable）
- 编译内部（CompileIdx 三态判定）
- GroupT 构造与越界 raise 路径
- ParseBuffer 整数解析与溢出
- PerlOpt / PcreFlag 行为验证

## 项目结构

```
re-mbt/
├── moon.mod              # 模块元数据
├── re/                   # 单包 —— 全部源文件
│   ├── cset.mbt          # 字符集操作
│   ├── ast.mbt           # AST 构造与着色
│   ├── automata.mbt      # 自动机核心
│   ├── automata_desc.mbt # Desc（导数表达式）
│   ├── automata_expr.mbt # Expr 树与重命名
│   ├── automata_state.mbt# 状态管理
│   ├── compile.mbt       # 惰性 DFA 驱动器
│   ├── compile_translate.mbt # AST → 自动机翻译
│   ├── color_map.mbt     # 颜色划分
│   ├── core.mbt          # 高层 Re API
│   ├── group.mbt         # Group（捕获）操作
│   ├── search.mbt        # 搜索
│   ├── replace.mbt       # 替换
│   ├── view.mbt          # View
│   ├── perl.mbt          # Perl 前端
│   ├── pcre.mbt          # PCRE 前端
│   ├── emacs.mbt         # Emacs 前端
│   ├── posix.mbt         # POSIX 前端
│   ├── posix_class.mbt   # POSIX 字符类
│   ├── glob.mbt          # Glob 前端
│   ├── str.mbt           # Str（OCaml 兼容）前端
│   ├── parse_buffer.mbt  # 解析缓冲区
│   ├── bit_vector.mbt    # 位向量
│   ├── dense_map.mbt     # 稠密映射
│   ├── hash_set.mbt      # Int 哈希集
│   ├── mark_infos.mbt    # 标记信息
│   ├── pmark.mbt         # 位置标记
│   ├── category.mbt      # Category
│   ├── slice.mbt         # Slice
│   ├── dyn.mbt           # Dyn
│   ├── fmt.mbt           # Fmt
│   ├── util.mbt          # 工具函数
│   ├── *_test.mbt        # 测试文件（423 个测试）
│   └── pkg.generated.mbti # 公开 API 接口（812 行）
├── bench/                # 基准测试套件（10 个 section）
│   ├── main.mbt          # 基准测试主程序
│   └── run_bench.ps1     # 基准测试运行器
└── README.md
```

## 许可证

上游为 LGPL-2.1-or-later WITH OCaml-LGPL-linking-exception；本移植保持相同许可证。

## 移植说明

### 原项目信息

| 项 | 说明 |
|----|------|
| 原项目名称 | ocaml-re |
| 原项目链接 | https://github.com/ocaml/ocaml-re |
| 原项目许可证 | LGPL-2.1-or-later WITH OCaml-LGPL-linking-exception |
| 原作者 | Xavier Leroy (INRIA Rocquencourt), Jerome Vouillon |

### 移植范围

全部核心模块已移植，内部模块与 OCaml 1:1 对应：

- 字符集操作（`cset`）、AST 构造与着色（`ast`、`color_map`）
- 自动机核心（`automata`、`automata_desc`、`automata_expr`、`automata_state`）
- 惰性 DFA 驱动器（`compile`、`compile_translate`）
- 高层 API（`core`、`group`、`search`、`replace`、`view`）
- 6 个前端（`perl`、`pcre`、`posix`、`emacs`、`glob`、`str`）
- 辅助模块（`bit_vector`、`dense_map`、`hash_set`、`pmark`、`category`、`mark_infos`、`parse_buffer`、`slice`、`dyn`、`fmt`）

### 修改与适配

| OCaml | MoonBit | 说明 |
|-------|---------|------|
| `string` | `Bytes` | 面向字节，latin1 兼容 |
| `ref` | `Ref[T]` | 可变引用 |
| `module` | 空结构体命名空间 | 如 `struct Perl {}` + `Perl::compile_pat` |
| `Format.formatter` | `String` | `Re::pp`/`pp_re` 返回字符串 |
| `Domain.DLS` | 全局 `Ref` | 单线程，无 domain 隔离 |
| `lazy` | 直接求值 | MoonBit 无惰性求值 |
| `Not_found` 异常 | `raise` + `fail` | MoonBit checked error |

### 尚未移植

| 功能 | 原因 |
|------|------|
| `Re.Seq.*`（迭代器版本） | MoonBit 无原生 `Seq.t`，已有 `Search::all` 等返回 `Array` 的版本 |
| `Re.Stream`（流式匹配） | 需重构匹配引擎，实验性 API |
| `Re.witness`（生成匹配字符串） | 实验性 API，需反向遍历自动机 |
| `import.ml` | OCaml 特有模块导入 |

### 与上游 API 覆盖率

- Re 核心 API：~95%（缺 `Seq.*`/`Stream`/`witness` 实验性 API）
- Str 前端 API：100%（全部 30+ 个函数已实现）
- 6 个前端语法：100%（Perl/PCRE/POSIX/Emacs/Glob/Str 全部实现）
