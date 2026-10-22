# 核心设计文档 / Design

> re-mbt 的核心设计：类型系统、算法、数据结构不变量。

## 1. 类型层次

```
前端语法 ──parse──> Ast ──compile──> Re ──exec──> GroupT / Bool
  Perl              AstGen[AstCset]     Re          GroupT
  PCRE              AstNoCase
  POSIX             (= AstGen[Cset])
  Emacs
  Glob
  Str
```

### Ast 设计

OCaml 用 GADT `('a, 'case) gen` 带幻影类型区分 Cased/Uncased。MoonBit 无 GADT，改用：

- `AstGen[T]` — 通用 AST，`T` 为字符集类型
- `Ast = AstGen[AstCset]` — 带字符集类别（Cased）
- `AstNoCase = AstGen[Cset]` — 忽略大小写（Uncased）

### AstCset vs Cset

- `Cset` — 原始字符集（排序区间列表）
- `AstCset` — AST 中的字符集表达式（支持交集、补集、差集、Cast）

## 2. 字符集算法

### 不变量

`Cset.intervals` 满足：
1. **排序**：`intervals[i].1 < intervals[i+1].0`
2. **不重叠**：`intervals[i].1 < intervals[i+1].0`
3. **不邻接**：`intervals[i].1 + 1 < intervals[i+1].0`
4. **非空区间**：`intervals[i].0 <= intervals[i].1`

### 运算

| 运算 | 复杂度 | 实现 |
|------|--------|------|
| `union` | O(n+m) | 双指针归并 |
| `inter` | O(n+m) | 双指针交集 |
| `diff` | O(n+m) | 双指针差集 |
| `complement` | O(n) | 区间反转 |
| `mem` | O(log n) | 二分查找 |

## 3. 编译流水线

```
Ast ──compile_translate──> Expr ──compile──> Desc ──> State (DFA)
```

### Expr

自动机表达式，单 enum，每个变体携带 ID：
- `Cst(id, Cset)` — 字符集转移
- `Alt(id, Array[Expr])` — 备选
- `Seq(id, Sem, Expr, Expr)` — 串联
- `Eps(id)` — 空串
- `Rep(id, RepKind, Sem, Expr)` — 重复
- `MarkOf(id, Int)` — 标记引用
- `Before/After(id, Category)` — look-around

### Desc / State

- `Desc` — 自动机描述（颜色标记 + 转移表）
- `State` — DFA 状态（运行时展开）
- `WorkingArea` — 执行时工作区（状态哈希表 + 位置信息）

## 4. 匹配执行

### exec 流程

1. 从 `Re` 获取初始 `State`
2. 逐字符调用 `delta(WorkingArea, Category, char, State) -> State`
3. 检查 `State` 是否为接受状态
4. 提取 `GroupT` 分组信息

### 线性时间保证

- DFA 状态数有限，惰性展开
- 每个字符 O(1) 状态转移（均摊）
- 无回溯，无 catastrophic backtracking

## 5. 颜色标记

`ColorTable` + `ColorRepr` 用于 look-around（look-ahead/look-behind）：
- 每个字符分配颜色（类别）
- `Category` 用位标志表示字符类别
- `delta` 根据颜色而非具体字符转移（压缩 DFA）