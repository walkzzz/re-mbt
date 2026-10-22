# 公共 API 参考

> 从 `pkg.generated.mbti` 整理，最后更新：2026-10-22

## 核心类型

### Re

编译后的正则表达式。

```moonbit
pub type Re
```

### GroupT

匹配结果与分组提取。

```moonbit
pub struct GroupT
```

| 方法 | 签名 | 说明 |
|------|------|------|
| `GroupT::get` | `(GroupT, Int) -> Bytes?` | 获取第 N 个匹配组 |
| `GroupT::start` | `(GroupT, Int) -> Int` | 获取第 N 组起始位置 |
| `GroupT::stop` | `(GroupT, Int) -> Int` | 获取第 N 组结束位置 |

### Cset

字符集，排序、不重叠、不邻接的区间列表。

```moonbit
pub struct Cset { intervals : Array[(Int, Int)] }
```

### Category

字符类别（位标志），用于 look-ahead/look-behind。

```moonbit
pub struct Category { bits : Int }
```

### Pmark / RepKind / Sem

- `Pmark` — 模式标记标识符
- `RepKind` — 重复类型（`Greedy` / `NonGreedy`）
- `Sem` — 语义（`Longest` / `Shortest` / `First`）

## 前端

### Perl

```moonbit
pub fn Perl::compile_pat(pattern : Bytes, opts~ : Array[PerlOpt] = []) -> Re raise
```

### Pcre

```moonbit
pub fn Pcre::regexp(pattern : Bytes, flags~ : Array[PcreFlag] = []) -> Re raise
pub fn Pcre::pmatch(re : Re, input : Bytes) -> Bool raise
```

### Posix / Emacs / Glob / Str

各前端提供 `regexp` / `pmatch` 方法，签名类似。

## 核心函数

| 函数 | 签名 | 说明 |
|------|------|------|
| `compile` | `(Ast) -> Re` | 编译 AST 为 Re |
| `exec` | `(Re, Bytes, pos?, len?) -> GroupT raise` | 执行匹配，不匹配时抛异常 |
| `exec_opt` | `(Re, Bytes, pos?, len?) -> GroupT? raise` | 执行匹配，返回 Option |
| `execp` | `(Re, Bytes, pos?, len?) -> Bool raise` | 布尔匹配 |
| `match_str` | `(groups~, partial~, Re, Bytes, pos~, len~) -> MatchInfo raise` | 详细匹配信息 |
| `sb` | `(String) -> Bytes` | String → Bytes |
| `bs` | `(Bytes) -> String` | Bytes → String |

## AST 类型

| 类型 | 说明 |
|------|------|
| `Ast` | `AstGen[AstCset]` — 带字符集类别的 AST |
| `AstNoCase` | `AstGen[Cset]` — 忽略大小写的 AST |
| `AstAlt[T]` | 备选分支 |
| `AstCset` | 字符集表达式 |
| `AstGen[T]` | 通用 AST 节点 |

## 辅助类型

| 类型 | 说明 |
|------|------|
| `View` / `ViewRange` | 字符集可视化 |
| `CsetView` | Cset 视图 |
| `BitVector` | 位向量 |
| `MatchInfo` | 匹配信息 |
| `ExecPartialResult` | 部分匹配结果（`Full`/`Partial`/`Mismatch`） |
| `Replace` | 替换操作 |
| `Search` | 搜索操作 |