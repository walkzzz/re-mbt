# 执行报告（v15）

## 概述
执行 coverage_gap_analysis.md §4 优先级 P8（阶段二方法第 3 步"补充缺失测试"），向 `re/automata_test.mbt` 末尾追加 4 个 test 块，直接覆盖 `Expr::rename`（automata_expr.mbt:158-174）的递归重命名行为，涵盖 Cst/Seq/Alt/Rep 四个核心分支及 id 分配顺序差异。moon test 288/288 全绿（284+4），moon check 26 warnings（与基线一致，无新 warning）。

## 产出清单
| 操作 | 文件路径 | 说明 |
|------|---------|------|
| 修改 | re/automata_test.mbt | 末尾追加 4 个 test 块覆盖 Expr::rename 的 Cst/Seq/Alt/Rep 分支 |

## 执行过程

### 1. 基线确认
T14 后基线 284/284 全绿，moon check 26 warnings baseline。

### 2. 源码核实
查阅 `re/automata_expr.mbt:158-174` 确认 `Expr::rename` 实现：
- **Cst 分支**（:160）：`Cst(_, s) => Cst(ids.next(), s)` — 分配新 id，保留 Cset
- **Eps/MarkOf/PmarkOf/Erase/Before/After 分支**（:161-166）：分配新 id，保留非 id 字段
- **Alt 分支**（:167-170）：`let l2 = Array::map(l, fn(e) { Expr::rename(ids, e) }); Alt(ids.next(), l2)` — **先递归 rename 所有子节点，根节点后分配 id**
- **Seq 分支**（:171-172）：`Seq(_, k, y, z) => Seq(ids.next(), k, Expr::rename(ids, y), Expr::rename(ids, z))` — **根节点先分配 id，再递归 rename 子节点**
- **Rep 分支**（:173）：`Rep(_, g, k, y) => Rep(ids.next(), g, k, Expr::rename(ids, y))` — **根节点先分配 id，再递归 rename 子节点**

查阅 `re/automata.mbt:175-188` 确认 `Ids` 结构：`Ids::create()` counter=0，`Ids::next()` counter+=1 返回新值（首次 next() 返回 1）。

查阅 `re/automata.mbt:5-15` 确认 `Sem` 变体为 `Longest`/`Shortest`/`First`（derive Eq），`RepKind` 变体为 `Greedy`/`NonGreedy`（derive Eq），构造函数 `Sem::longest()`/`RepKind::greedy()`。

查阅 `re/cset.mbt:44-46` 确认 `Cset` derive(Debug, Eq, Compare)，`==` 可用。

### 3. id 分配顺序验证
根据 RETRY 说明的修正，确认三种构造的 id 分配顺序差异：
- **Seq**：`Seq(ids.next(), k, rename(y), rename(z))` — MoonBit 求值顺序从左到右，根节点 `ids.next()` 先执行得 id=1，然后 `rename(y)` 得 id=2，`rename(z)` 得 id=3。故 `Expr::id(seq2) == 1`。
- **Alt**：`let l2 = Array::map(l, ...); Alt(ids.next(), l2)` — `let l2 = ...` 先执行，对 3 个子节点依次 rename 消耗 id 1/2/3，随后 `Alt(ids.next(), l2)` 分配根节点 id 得 4。故 `Expr::id(alt2) == 4`。
- **Rep**：`Rep(ids.next(), g, k, rename(y))` — 根节点 `ids.next()` 先执行得 id=1，然后 `rename(y)` 得 id=2。故 `Expr::id(rep2) == 1`。

### 4. test 块清单

| 块 | 名称 | 覆盖分支 | 源码位置 | 关键断言 |
|----|------|---------|---------|---------|
| 1 | `expr rename Cst preserves cset with new id` | rename Cst 分支 | automata_expr.mbt:160 | Cset 保留 + id==1 |
| 2 | `expr rename Seq recursively renames children` | rename Seq 分支 + 递归子节点 | automata_expr.mbt:171-172 | Sem 保留 + id==1（根先分配）+ 子 Cset 保留 |
| 3 | `expr rename Alt recursively renames all children` | rename Alt 分支 + Array::map 递归 | automata_expr.mbt:167-170 | 3 子节点 Cset 保留 + id==4（子先分配）|
| 4 | `expr rename Rep recursively renames child` | rename Rep 分支 + 递归子节点 | automata_expr.mbt:173 | RepKind/Sem 保留 + id==1（根先分配）+ 子 Cset 保留 |

### 5. 构造方式
- 使用 `Ids::create()` 创建独立 id 生成器（ids1 构造原 Expr，ids2 用于 rename）
- 使用 `Expr::cst`/`Expr::seq`/`Expr::alt`/`Expr::rep` 构造函数构造原 Expr 树
- 使用 `Sem::longest()`/`RepKind::greedy()` 构造函数（与现有测试 :91/:127 风格一致）
- match pattern 直接 match Expr variant（`Cst(_, s)`/`Seq(_, k, y, z)`/`Alt(_, l)`/`Rep(_, g, k, y)`）
- `assert_eq` 比较 Cset/Sem/RepKind（均 derive Eq）和 id 值
- `_ => assert_true(false)` 处理非预期 variant 分支

### 6. 验证结果
- `moon test`：Total tests: 288, passed: 288, failed: 0 ✓（284+4）
- `moon check`：26 warnings, 0 errors（与基线一致，无新 warning）✓

### 7. 与 coverage_gap_analysis.md P8 的对应关系
P8 要求覆盖 `Expr::rename` pub fn（mbti:364），§1 Expr 模块覆盖率低，§2 未覆盖明细含 rename，§3.3 分支缺口含 rename 各 Expr variant 分支。本轮 4 个 test 块覆盖 rename 的 4 个核心分支：
- Cst 分支：块 1
- Seq 分支 + 递归：块 2
- Alt 分支 + Array::map 递归：块 3
- Rep 分支 + 递归：块 4

未覆盖的 Eps/MarkOf/PmarkOf/Erase/Before/After 分支为叶子节点（无递归，仅 id 替换），风险低于含递归的 Seq/Alt/Rep 分支，P8 聚焦于含递归的 4 个核心分支。

## 偏差说明
无。task_v15.md RETRY 说明已修正 3 个严重问题（Sem::Plain→Sem::Longest、RepKind::Star→RepKind::Greedy、Alt 断言 id 1→4），本轮严格按照修正后的 task_v15.md 执行，构造使用 `Sem::longest()`/`RepKind::greedy()` 构造函数（与现有测试风格一致，语义等价于变体 `Longest`/`Greedy`），断言 `Expr::id(alt2) == 4` 与 Alt 分支"先递归子节点后分配根 id"的执行顺序一致。
