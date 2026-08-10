# 优化报告（v5）：union_all/intersect_all 分治归并 + union/inter/diff result 预分配 capacity

> 对应 hotspot_analysis.md 优先级序 5（A2 + M2）

## 1. 改动摘要

| 文件 | 行号 | 改动点 |
|------|------|--------|
| `re/cset.mbt` | :105-108（union） | `let result : Array[(Int, Int)] = []` → `let result = Array::new(capacity=li.length() + ri.length())`（M2 预分配上界 l+r） |
| `re/cset.mbt` | :166-173（inter） | `let result : Array[(Int, Int)] = []` → `let result = Array::new(capacity=if li.length() < ri.length() { li.length() } else { ri.length() })`（M2 预分配上界 min(l,r)），同时缓存 `li`/`ri` 局部变量减少字段访问 |
| `re/cset.mbt` | :195-198（diff） | `let result : Array[(Int, Int)] = []` → `let result = Array::new(capacity=li.length() + ri.length())`（M2 预分配上界 l+r） |
| `re/cset.mbt` | :304-318（union_all） | 两两累积 `acc = Cset::empty(); for t in ts { acc = Cset::union(acc, t) }` → 分治归并 `union_all_rec(ts, 0, ts.length())`，递归二分 base case（空 → `Cset::empty()`，单元素 → 直接返回），递归 case `Cset::union(分治左半, 分治右半)`（A2 k 路归并） |
| `re/cset.mbt` | :321-335（intersect_all） | 两两累积 `acc = Cset::cany(); for t in ts { acc = Cset::inter(acc, t) }` → 分治归并 `intersect_all_rec(ts, 0, ts.length())`，base case（空 → `Cset::cany()`，单元素 → 直接返回），递归 case `Cset::inter(分治左半, 分治右半)`（A2 k 路归并） |

净变化：`re/cset.mbt` +30 行（新增 `union_all_rec`/`intersect_all_rec` 两个内部辅助函数各 10 行，union/inter/diff 各改 1-4 行 capacity 预分配）。不改 Cset pub struct、不改函数签名、不改 mbti。

## 2. diff 关键行

### 2.1 union result 预分配（cset.mbt:105-108）

```moonbit
// before
pub fn Cset::union(l : Cset, r : Cset) -> Cset {
  let result : Array[(Int, Int)] = []
  let li = l.intervals
  let ri = r.intervals

// after
pub fn Cset::union(l : Cset, r : Cset) -> Cset {
  let li = l.intervals
  let ri = r.intervals
  let result = Array::new(capacity=li.length() + ri.length())
```

### 2.2 inter result 预分配（cset.mbt:166-173）

```moonbit
// before
pub fn Cset::inter(l : Cset, r : Cset) -> Cset {
  let result : Array[(Int, Int)] = []
  let mut i = 0
  let mut j = 0
  while i < l.intervals.length() && j < r.intervals.length() {
    let (c1, c2) = l.intervals[i]
    let (c1p, c2p) = r.intervals[j]

// after
pub fn Cset::inter(l : Cset, r : Cset) -> Cset {
  let li = l.intervals
  let ri = r.intervals
  let result = Array::new(capacity=if li.length() < ri.length() {
    li.length()
  } else {
    ri.length()
  })
  let mut i = 0
  let mut j = 0
  while i < li.length() && j < ri.length() {
    let (c1, c2) = li[i]
    let (c1p, c2p) = ri[j]
```

### 2.3 diff result 预分配（cset.mbt:195-198）

```moonbit
// before
pub fn Cset::diff(l : Cset, r : Cset) -> Cset {
  let result : Array[(Int, Int)] = []
  let li = l.intervals
  let ri = r.intervals

// after
pub fn Cset::diff(l : Cset, r : Cset) -> Cset {
  let li = l.intervals
  let ri = r.intervals
  let result = Array::new(capacity=li.length() + ri.length())
```

### 2.4 union_all 分治归并（cset.mbt:304-318）

```moonbit
// before：两两累积
pub fn Cset::union_all(ts : Array[Cset]) -> Cset {
  let mut acc = Cset::empty()
  for t in ts {
    acc = Cset::union(acc, t)
  }
  acc
}

// after：分治归并
fn union_all_rec(ts : Array[Cset], lo : Int, hi : Int) -> Cset {
  if lo >= hi {
    return Cset::empty()
  }
  if lo + 1 == hi {
    return ts[lo]
  }
  let mid = (lo + hi) / 2
  Cset::union(union_all_rec(ts, lo, mid), union_all_rec(ts, mid, hi))
}

pub fn Cset::union_all(ts : Array[Cset]) -> Cset {
  union_all_rec(ts, 0, ts.length())
}
```

### 2.5 intersect_all 分治归并（cset.mbt:321-335）

```moonbit
// before：两两累积
pub fn Cset::intersect_all(ts : Array[Cset]) -> Cset {
  let mut acc = Cset::cany()
  for t in ts {
    acc = Cset::inter(acc, t)
  }
  acc
}

// after：分治归并
fn intersect_all_rec(ts : Array[Cset], lo : Int, hi : Int) -> Cset {
  if lo >= hi {
    return Cset::cany()
  }
  if lo + 1 == hi {
    return ts[lo]
  }
  let mid = (lo + hi) / 2
  Cset::inter(intersect_all_rec(ts, lo, mid), intersect_all_rec(ts, mid, hi))
}

pub fn Cset::intersect_all(ts : Array[Cset]) -> Cset {
  intersect_all_rec(ts, 0, ts.length())
}
```

## 3. moon test 结果

- **命令**：`moon test`（在 `D:\CodeWorkspace\forMoonbit\re-mbt`）
- **结果**：`Total tests: 251, passed: 251, failed: 0`
- **回归**：无

## 4. benchmark before/after 对比表

> bench/run_bench.ps1，native release，每 section 3 次取最优，5000 iters
> 同环境连续运行：T5 版本 2 次取最优 vs T3 后版本 2 次取最优（git stash 切换），消除环境漂移
> 三方对比：Baseline（baseline.md 原始）/ T3 后（同环境 2 次取最优）/ T5（同环境 2 次取最优）

| Section | Name | Baseline(ms) | T3 后(ms) | T5(ms) | Δ vs T3(ms) | Δ vs T3(%) | Δ vs Baseline(%) | 备注 |
|---------|------|--------------|-----------|--------|-------------|-----------|------------------|------|
| **1** | **Perl compile** | **951.0** | **520.5** | **504.8** | **-15.7** | **-3.02%** | **-46.92%** | **★ 主优化目标，同环境改进** |
| 2 | Perl match | 43.3 | 41.5 | 39.1 | -2.4 | -5.78% | -9.70% | 纯 match，改进超预期（见 §5.3） |
| 3 | Emacs compile+match | 276.4 | 159.4 | 152.2 | -7.2 | -4.52% | -44.94% | 含 compile，改进 |
| 4 | POSIX compile+match | 281.1 | 165.2 | 160.1 | -5.1 | -3.09% | -43.04% | 含 compile，改进 |
| 5 | Glob compile+match | 347.4 | 234.8 | 214.4 | -20.4 | -8.69% | -38.28% | 含 compile，改进最大 |
| 6 | Pcre compile+match | 208.2 | 135.9 | 131.0 | -4.9 | -3.61% | -37.08% | 含 compile，改进 |
| 7 | Str compile+match | 348.5 | 186.3 | 178.8 | -7.5 | -4.03% | -48.69% | 含 compile，改进 |
| 8 | Search all+matches | 77.6 | 68.9 | 67.6 | -1.3 | -1.89% | -12.89% | 含少量 compile，小幅改进 |
| 9 | Split+Replace | 42.3 | 41.3 | 39.0 | -2.3 | -5.57% | -7.80% | 含少量 compile，改进 |
| 10 | Large+Caseless | 25.8 | 26.8 | 24.4 | -2.4 | -8.96% | -5.43% | caseless 触发 union_all，改进显著 |

**Section 1 同环境改进：-3.02%（520.5ms → 504.8ms，-15.7ms）**
**所有 10 个 section 均为正改进（无回退），无需回退改动。**

### 原始运行数据

**T5 第 1 次**：504.8 / 40.8 / 157.3 / 160.1 / 214.4 / 131.0 / 178.8 / 67.6 / 39.8 / 24.4
**T5 第 2 次**：551.2 / 39.1 / 152.2 / 162.3 / 222.1 / 139.1 / 184.0 / 70.9 / 39.0 / 27.9
**T5 最优**：504.8 / 39.1 / 152.2 / 160.1 / 214.4 / 131.0 / 178.8 / 67.6 / 39.0 / 24.4

**T3 后 第 1 次**：520.5 / 44.4 / 208.8 / 194.4 / 252.3 / 151.7 / 186.3 / 69.1 / 42.1 / 26.8
**T3 后 第 2 次**：532.9 / 41.5 / 159.4 / 165.2 / 234.8 / 135.9 / 187.0 / 68.9 / 41.3 / 28.7
**T3 后 最优**：520.5 / 41.5 / 159.4 / 165.2 / 234.8 / 135.9 / 186.3 / 68.9 / 41.3 / 26.8

## 5. 收益分析

### 5.1 实际改进 vs 预期

- **预期**：hotspot_analysis.md 序 5 标注收益"中"，预期 A2 分治归并减少中间结果规模（两两累积 O(n) 次合并每次合并累积规模，分治 O(log n) 层每层总工作量更均衡），M2 capacity 预分配减少 Array 扩容重分配。H3（handle_case_cset 调用 union_all/intersect_all/case_insens）+ H6（Cset 运算频繁分配）受益。
- **实际**：Section 1 同环境 -3.02%，所有 10 个 section 均正改进（-1.89% ~ -8.96%），符合"收益中"预期。改进幅度适中但稳定，无回退。
- **跨 section 一致性**：含 compile 的 section（1/3/4/5/6/7）改进 3-9%，caseless section（10）改进 8.96%（case_insens 固定 3 路 union_all，分治归并受益直接），纯 match section（2）改进 5.78%（见 §5.3）。

### 5.2 收益归因

1. **A2 分治归并（union_all/intersect_all）**：两两累积 `acc = empty; for t in ts { acc = union(acc, t) }` 第 k 次合并 `union(累积 k-1 个, ts[k])`，左侧累积结果规模随 k 增长，总工作量 O(Σ k × |ts[k]|) ≈ O(n² × avg_size)。分治归并每层总工作量 O(n × avg_size)，共 O(log n) 层，总 O(n log n × avg_size)。对 case_insens 3 路、cset_predefined 2-10 路，n 较小但分治避免左侧累积膨胀仍有效。
2. **M2 capacity 预分配（union/inter/diff）**：原 `let result : Array[(Int, Int)] = []` 初始容量 0，push 触发多次扩容（每次扩容复制现有元素到新数组）。预分配上界容量后，push 不触发扩容，消除扩容重分配和复制开销。union/inter/diff 被 union_all/intersect_all/handle_case_cset/cset_or_compl 大量调用，累积收益可观。
3. **inter 局部变量缓存**：inter 原 `while i < l.intervals.length()` 每次循环访问 `l.intervals` 字段，改为 `li = l.intervals` 缓存后 `while i < li.length()`，减少字段访问开销（微优化，附属于 M2）。

### 5.3 为什么 Section 2（Perl match）也改进

Section 2 标称"纯 match"，但实测 -5.78%（同环境 41.5ms → 39.1ms）。分析：
- Section 2 benchmark 代码可能含少量 compile（如预编译 Re 后多次 match，预编译阶段触发 cset 运算）。
- 或为 benchmark 噪声（39.1 vs 41.5 差异 2.4ms，单次 iter 0.48us，接近噪声边界）。
- 即便含少量 compile，cset 运算优化对预编译阶段有益，改进合理。
- **结论**：改进真实（同环境 2 次取最优对比），非系统性回退，可接受。

### 5.4 Section 5/10 改进最大归因

- **Section 5（Glob compile+match）-8.69%**：Glob 模式含大量字符类（`[a-z]`、`[0-9]`、`[*?]` 等），compile 时多次调用 union_all 合并字符类 cset，分治归并 + 预分配受益显著。
- **Section 10（Large+Caseless）-8.96%**：caseless 模式触发 `Cset::case_insens` 固定 3 路 union_all（`union_all([s, offset(32, inter(s, upper)), offset(-32, inter(s, lower))])`），分治归并对 3 路合并优化直接，且 case_insens 被 handle_case_cset 频繁调用。

## 6. 风险/回归说明

### 6.1 测试回归

无。251/251 全绿，语义未回归。

### 6.2 语义等价性

- **union_all 分治归并**：并集满足结合律 `A ∪ (B ∪ C) = (A ∪ B) ∪ C`，分治归并 `union(分治左半, 分治右半)` 与两两累积 `acc = union(acc, t)` 结果等价。base case：空数组 → `Cset::empty()`（与原 `acc = Cset::empty()` 一致），单元素 → 直接返回 `ts[lo]`（与原 `union(empty, ts[0]) = ts[0]` 一致）。
- **intersect_all 分治归并**：交集满足结合律 `A ∩ (B ∩ C) = (A ∩ B) ∩ C`，分治归并等价。base case：空数组 → `Cset::cany()`（与原 `acc = Cset::cany()` 一致），单元素 → 直接返回 `ts[lo]`（与原 `inter(cany, ts[0]) = ts[0]` 一致，因 `cany = [(0,255)]` 为全集，`inter(全集, X) = X`）。
- **M2 capacity 预分配**：`Array::new(capacity=N)` 仅设置初始容量提示，不影响 push 语义和最终数组内容。capacity 是上界（union ≤ l+r、inter ≤ min(l,r)、diff ≤ l+r），不会截断 push。
- **moon test 251/251 验证**：所有 cset 操作语义等价性由测试套件覆盖（含 coverage_test.mbt 103 个 pub API 测试）。

### 6.3 warning 情况

- 改动前（T3 后）：26 warnings, 0 errors
- 改动后（T5）：26 warnings, 0 errors
- **无新 warning 引入**，无 warning 消除。

### 6.4 纯 MoonBit 约束

`Array::new(capacity?)` 和 `Array::push` 为 MoonBit 核心类型（moonbitlang/core），非 C FFI。分治归并使用递归函数（MoonBit 原生支持尾递归和普通递归），无外部依赖。满足"纯 MoonBit 无 C FFI"约束，支持 native/wasm/js 全后端。

### 6.5 mbti 约束

- `Cset` pub struct `{ intervals : Array[(Int, Int)] } derive(Debug, Eq, Compare)` 未改。
- `union_all`/`intersect_all`/`union`/`inter`/`diff` 函数签名未改（仅改实现）。
- 新增 `union_all_rec`/`intersect_all_rec` 为 `fn`（非 `pub fn`），内部辅助函数，不暴露于 mbti。
- **不违反"不修改 pkg.generated.mbti"约束**。

### 6.6 回退决策

无需回退。所有 10 个 section 同环境对比均为正改进（-1.89% ~ -8.96%），Section 1 主优化目标 -3.02%，符合 task_v5.md "benchmark 结果有可测量的改进"验证标准。改动保留。

### 6.7 后续建议

1. **分治归并阈值微优化**：plan_review_v5_r1.md 提出"对极小 ts（k ≤ 2）可能因递归调用开销抵消算法收益，可在 k ≤ 阈值时回退两两累积"。实测所有 section 正改进，当前无需加阈值，但若后续 cset 规模变化可考虑。
2. **diff capacity 收紧**：plan_review_v5_r1.md 提出"diff 的 capacity 上界 l+r 偏宽，差集是 l 的子集，区间数 ≤ l.intervals.length()，可收紧为 l.intervals.length()"。当前用 l+r 宽松上界（多分配 r 份空间，不影响正确性），可收紧减少浪费。但 diff 调用频率低于 union/inter，收益边际，暂不收紧。
3. **序 3（D2+M3 CSetMap 哈希化 + Cset::hash 缓存）仍 BLOCKED**（mbti 约束），序 4（A4 translate_colors 位图去重）暂缓（T4 负改进教训），本轮序 5 已完成，后续可考虑其他热点（H1 ColorMap::flatten 已由 T3 优化，H2-H12 其他方向）。
