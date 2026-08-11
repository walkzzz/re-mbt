# 优化报告（v7）：merge_sequences_no_case_from/merge_sequences_from 迭代化 + Array 预分配 capacity（A3 + M5）

> 对应 hotspot_analysis.md 优先级序 7（A3 + M5）
> **结论：实测负改进，已回退改动。**

## 1. 改动摘要

| 文件 | 行号 | 改动点 |
|------|------|--------|
| `re/ast.mbt` | :252-324（merge_sequences_from） | 递归改迭代 + 索引区间：引入 `prefix : Array[Ast]` 累积递归点 3/4 的 head，`mut work : Array[Ast]`/`mut pos : Int` 表示当前工作数组（递归点 1 Alternative 重组 work/pos，不递归调用），递归点 2（Sequence 非空，需窥探下一结果首元素决定合并）保留递归 `merge_sequences_from(work, pos+1)`，结果与 prefix 一次性合并构建。中间 Array 全部预分配 capacity（combined = l2.length()+work.length()-pos-1，y/y2 = xs.length()-1，result = prefix.length()+merged_rest.length() 或 +1）。 |
| `re/ast.mbt` | :343-420（merge_sequences_no_case_from） | 同上结构，类型为 `Array[AstNoCase]`，alt 构造用 `seq_no_case(y)`/`seq_no_case(y2)`。 |

净变化：`re/ast.mbt` +60 行（两个函数各 +30 行：迭代化 while 循环 + prefix/work/pos 状态 + 预分配 capacity）。不改 `merge_sequences`/`merge_sequences_no_case` pub fn 签名、不改 mbti。

## 2. diff 关键行

### 2.1 merge_sequences_from 迭代化 + 预分配（ast.mbt:252-324）

```moonbit
// before：递归，每层新建 combined/y/y2/result Array
fn merge_sequences_from(l : Array[Ast], start : Int) -> Array[Ast] {
  if start >= l.length() {
    return []
  }
  let head = l[start]
  match head {
    AstNode(Alternative(l2)) => {
      let combined : Array[Ast] = []
      for x in l2 { combined.push(x) }
      for i in (start + 1)..<l.length() { combined.push(l[i]) }
      merge_sequences_from(combined, 0)  // 递归点 1
    }
    Sequence(xs) =>
      if xs.length() > 0 {
        let x = xs[0]
        let y : Array[Ast] = []
        for i in 1..<xs.length() { y.push(xs[i]) }
        let merged_rest = merge_sequences_from(l, start + 1)  // 递归点 2
        // ... 每层新建 result Array
      } else {
        let result : Array[Ast] = [head]  // 递归点 3
        for x in merge_sequences_from(l, start + 1) { result.push(x) }
        result
      }
    _ => {
      let result : Array[Ast] = [head]  // 递归点 4
      for x in merge_sequences_from(l, start + 1) { result.push(x) }
      result
    }
  }
}

// after：迭代化递归点 3/4 + 递归点 1，保留递归点 2；中间 Array 预分配 capacity
fn merge_sequences_from(l : Array[Ast], start : Int) -> Array[Ast] {
  let prefix : Array[Ast] = []
  let mut work : Array[Ast] = l
  let mut pos = start
  while true {
    if pos >= work.length() { return prefix }
    let head = work[pos]
    match head {
      AstNode(Alternative(l2)) => {
        // 递归点 1：重组 work，不递归调用
        let combined = Array::new(capacity=l2.length() + work.length() - pos - 1)
        for x in l2 { combined.push(x) }
        for i in (pos + 1)..<work.length() { combined.push(work[i]) }
        work = combined
        pos = 0
        continue
      }
      Sequence(xs) =>
        if xs.length() > 0 {
          // 递归点 2：保留递归，结果与 prefix 一次性合并
          let x = xs[0]
          let y = Array::new(capacity=xs.length() - 1)
          for i in 1..<xs.length() { y.push(xs[i]) }
          let merged_rest = merge_sequences_from(work, pos + 1)
          // ... 预分配 result capacity，一次性构建 prefix + [贡献] + merged_rest[1..]
          // ...（详见代码）
        } else {
          // 递归点 3：prefix 累积后前进
          prefix.push(head)
          pos += 1
          continue
        }
      _ => {
        // 递归点 4：prefix 累积后前进
        prefix.push(head)
        pos += 1
        continue
      }
    }
  }
  prefix
}
```

### 2.2 merge_sequences_no_case_from 迭代化 + 预分配（ast.mbt:343-420）

结构与 2.1 相同，类型为 `Array[AstNoCase]`，alt 构造用 `seq_no_case(y)`/`seq_no_case(y2)`。省略完整 diff，关键变化同 2.1。

## 3. moon test 结果

- **命令**：`moon test`（在 `D:\CodeWorkspace\forMoonbit\re-mbt`）
- **T7 改动后**：`Total tests: 251, passed: 251, failed: 0`，无回归
- **回退后**：`Total tests: 251, passed: 251, failed: 0`，无回归

## 4. benchmark before/after 对比表

> bench/run_bench.ps1，native release，每 section 3 次取最优，5000 iters
> 同环境连续运行：T7 版本 2 次取最优 vs T5 后版本 2 次取最优（git stash 切换），消除环境漂移
> 三方对比：Baseline（baseline.md 原史参考）/ T5 后（同环境 2 次取最优）/ T7（同环境 2 次取最优）
> **T5 后/T7 为同环境重测数值，baseline 为历史参考**

| Section | Name | Baseline(ms) | T5 后(ms) | T7(ms) | Δ vs T5(ms) | Δ vs T5(%) | Δ vs Baseline(%) | 备注 |
|---------|------|--------------|-----------|--------|-------------|-----------|------------------|------|
| **1** | **Perl compile** | **951.0** | **522.2** | **526.4** | **+4.2** | **+0.80%** | **-44.67%** | **★ 主优化目标，负改进** |
| 2 | Perl match | 43.3 | 37.8 | 38.1 | +0.3 | +0.79% | -12.01% | 负改进 |
| 3 | Emacs compile+match | 276.4 | 152.4 | 150.0 | -2.4 | -1.57% | -45.73% | 正改进 |
| 4 | POSIX compile+match | 281.1 | 163.5 | 161.5 | -2.0 | -1.22% | -42.55% | 正改进 |
| 5 | Glob compile+match | 347.4 | 218.8 | 212.2 | -6.6 | -3.01% | -38.92% | 正改进最大 |
| 6 | Pcre compile+match | 208.2 | 128.1 | 137.7 | +9.6 | +7.50% | -33.86% | 负改进最大 |
| 7 | Str compile+match | 348.5 | 181.0 | 182.4 | +1.4 | +0.77% | -47.66% | 负改进 |
| 8 | Search all+matches | 77.6 | 66.6 | 67.9 | +1.3 | +1.95% | -12.50% | 负改进 |
| 9 | Split+Replace | 42.3 | 39.5 | 39.2 | -0.3 | -0.76% | -7.33% | 正改进（小幅） |
| 10 | Large+Caseless | 25.8 | 24.7 | 25.4 | +0.7 | +2.83% | -1.55% | 负改进 |

**Section 1 同环境对比：+0.80%（522.2ms → 526.4ms，+4.2ms）负改进**
**4/10 section 正改进（-0.76% ~ -3.01%），6/10 section 负改进（+0.77% ~ +7.50%）。已回退改动。**

### 原始运行数据

**T7 第 1 次**：544.0 / 38.1 / 150.0 / 161.8 / 212.2 / 140.3 / 183.7 / 67.9 / 39.2 / 28.3
**T7 第 2 次**：526.4 / 40.7 / 151.0 / 161.5 / 222.9 / 137.7 / 182.4 / 68.4 / 40.4 / 25.4
**T7 最优**：526.4 / 38.1 / 150.0 / 161.5 / 212.2 / 137.7 / 182.4 / 67.9 / 39.2 / 25.4

**T5 后 第 1 次**：522.2 / 41.3 / 152.4 / 163.5 / 218.8 / 128.1 / 183.0 / 66.6 / 39.5 / 24.7
**T5 后 第 2 次**：531.5 / 37.8 / 158.7 / 167.7 / 219.7 / 133.0 / 181.0 / 67.9 / 41.6 / 25.9
**T5 后 最优**：522.2 / 37.8 / 152.4 / 163.5 / 218.8 / 128.1 / 181.0 / 66.6 / 39.5 / 24.7

## 5. 收益分析

### 5.1 实际改进 vs 预期

- **预期**：hotspot_analysis.md 序 7 标注收益"中"。task_v7.md 预期 A3 迭代化减少每层新建 Array 的分配+拷贝，M5 预分配 capacity 消除扩容。H4（merge_sequences_no_case 最坏 O(n²)，每层新建 Array 大量分配+拷贝）受益。预期含 Alternative 的模式（`(a|b)*c`、`(?:ab|cd|ef)+`、`[^aeiou][aeiou][^aeiou]`）compile 路径改进。
- **实际**：Section 1 同环境 +0.80% 负改进，4/10 section 正改进，6/10 section 负改进。**与预期"收益中"不符，实测为负改进。**
- **结论**：迭代化引入的额外开销（prefix 累积 + 一次性合并构建 result 时遍历 prefix）超过减少的递归分配开销，负改进。回退改动。

### 5.2 负改进归因

1. **prefix 累积开销**：迭代化将递归点 3/4 的 `[head] + 递归` 改为 `prefix.push(head); pos += 1`，避免了每层新建 result Array。但递归点 2（Sequence 非空，需合并）保留递归，其结果与 prefix 一次性合并时需遍历 prefix 构建 result（`for p in prefix { result.push(p) }`），这次遍历+拷贝的开销与原递归每层新建 result 的开销相当（甚至更高，因为 prefix 可能跨多个递归点 3/4 累积，一次性合并时 prefix 较长）。
2. **递归点 2 仍递归**：迭代化未消除递归点 2 的递归调用 `merge_sequences_from(work, pos+1)`，而递归点 2 是 Sequence 非空分支，含 y/y2/result 的主要分配。迭代化只优化了递归点 3/4（简单前缀累积），对递归点 2 的核心分配无影响。
3. **work/pos 重置开销**：递归点 1（Alternative）迭代化为 `work = combined; pos = 0`，但 combined 仍需新建（跨 l2 和 work[pos+1..] 两个数组，无法用索引区间引用）。迭代化避免了递归调用开销，但 combined 新建+拷贝开销不变。
4. **prefix 内存开销**：prefix 在迭代过程中累积，其内存占用与原递归每层 result 的总内存相当（甚至更高，因为 prefix 在遇到递归点 2 前持续增长，而原递归每层 result 独立分配可被 GC 回收）。
5. **Section 6 负改进最大（+7.50%）**：Pcre 模式含较多 Alternative 和 Sequence，merge_sequences_no_case 调用频繁。迭代化后 prefix 累积+合并的开销在频繁调用场景下放大，负改进最显著。
6. **Section 5 正改进最大（-3.01%）**：Glob 模式 Alternative 节点较少但 Sequence 较多，递归点 3/4 迭代化收益相对突出（prefix 累积避免了多层 result 新建），正改进。但整体不足以抵消其他 section 负改进。

### 5.3 与 T4/T6 教训的关系

T4（translate_colors 位图去重）和 T6（flatten cset 去重）因去重开销超收益而负改进回退。T7 与 T4/T6 不同：T7 非去重类优化，是算法层迭代化 + 内存层预分配。但 T7 同样体现"预期收益可能不实现"的教训——迭代化减少的递归分配开销被 prefix 累积+合并的开销抵消甚至超过。**实测是唯一可靠依据，静态分析的"减少分配"预期可能被动态开销抵消。**

### 5.4 迭代化方案的根本限制

`merge_sequences_from` 的递归点 2（Sequence 非空，需合并）需要"窥探下一结果首元素"以决定是否合并（`merged_rest[0] == x` 则合并，否则不合并）。这使得递归点 2 无法简单迭代化——当前层的贡献依赖于下一层的完整结果。本次迭代化只优化了递归点 3/4（简单前缀累积）和递归点 1（Alternative 重组），保留了递归点 2 的递归。由于递归点 2 是核心分配点，迭代化收益有限。

要完全迭代化递归点 2，需引入"前向窥探"辅助函数（只计算下一结果首元素，不构建完整数组），但这会显著增加代码复杂性和回归风险，且仍无法完全避免 Array 构建（alt 构造需要 y/y2 所有权）。考虑到 T7 实测负改进，完全迭代化的收益预期也不明朗，不值得进一步投入。

## 6. 风险/回归说明

### 6.1 测试回归

无。T7 改动后 251/251 全绿，回退后 251/251 全绿，语义未回归。

### 6.2 语义等价性

- **迭代化语义等价**：递归点 3/4 的 `[head] + merge_sequences_from(l, start+1)` 改为 `prefix.push(head); pos += 1` 后，prefix 累积了递归点 3/4 的 head，遇到递归点 2 时一次性构建 `prefix + [贡献] + merged_rest[1..]`，与原递归展开 `[l[start]] + [l[start+1]] + ... + merge_sequences_from(l, pos)` 等价。
- **递归点 1 迭代化等价**：`merge_sequences_from(combined, 0)` 改为 `work = combined; pos = 0; continue`，循环继续处理新工作数组，prefix 不变，与原递归 `merge_sequences_from(combined, 0)` 的结果作为当前层返回值等价（prefix 在递归点 1 不累积，combined 的处理结果作为后续 prefix 累积的起点）。
- **M5 capacity 预分配**：`Array::new(capacity=N)` 仅设置初始容量提示，不影响 push 语义和最终数组内容。capacity 是上界（combined ≤ l2.length()+work.length()-pos-1，y/y2 ≤ xs.length()-1，result ≤ prefix.length()+merged_rest.length() 或 +1），不会截断 push。
- **moon test 251/251 验证**：所有 merge_sequences/merge_sequences_no_case 语义等价性由测试套件覆盖（含 coverage_test.mbt 103 个 pub API 测试）。

### 6.3 warning 情况

- 改动前（T5 后）：26 warnings, 0 errors
- T7 改动后：26 warnings, 0 errors
- 回退后：26 warnings, 0 errors
- **无新 warning 引入**。

### 6.4 纯 MoonBit 约束

`Array::new(capacity?)`、`Array::push`、`while true`/`break`/`continue`、`let mut` 为 MoonBit 核心语法（moonbitlang/core），非 C FFI。迭代化使用 `prefix : Array[Ast]`/`mut work : Array[Ast]`/`mut pos : Int` 状态变量，无外部依赖。满足"纯 MoonBit 无 C FFI"约束，支持 native/wasm/js 全后端。

### 6.5 mbti 约束

- `merge_sequences_from`/`merge_sequences_no_case_from` 为 `fn`（非 `pub fn`），内部辅助函数，不暴露于 mbti。
- `pub fn Ast::merge_sequences`/`pub fn Ast::merge_sequences_no_case` 签名未改（仅改内部实现）。
- **不违反"不修改 pkg.generated.mbti"约束**。

### 6.6 回退决策

**已回退。** 实测 Section 1 同环境 +0.80% 负改进，6/10 section 负改进（+0.77% ~ +7.50%），仅 4/10 section 正改进（-0.76% ~ -3.01%）。符合 task_v7.md "若实测无改进或负改进则 git checkout re/ast.mbt 回退改动"条件。`git stash drop` 丢弃 T7 改动，`re/ast.mbt` 恢复为原始版本（HEAD e64ec54 v6 done，working tree clean）。回退后 moon test 251/251 全绿。

### 6.7 后续建议

1. **merge_sequences_no_case 优化方向**：T7 迭代化负改进回退，表明递归点 3/4 的简单前缀累积迭代化收益有限（核心分配在递归点 2）。后续可考虑：
   - **完全迭代化 + 前向窥探**：引入 `peek_first` 辅助函数只计算下一结果首元素，但复杂性和风险高，收益预期不明朗。
   - **递归点 2 局部优化**：只优化递归点 2 的 y/y2/result 预分配 capacity（M5 部分），不做迭代化（A3）。但 T7 已包含 M5 预分配且负改进，单独 M5 收益可能也不足。
   - **放弃 H4 优化**：H4 是"最坏 O(n²)"，但实际 benchmark 中 Alternative 节点较少（仅含 `(a|b)*c`、`(?:ab|cd|ef)+`、`[^aeiou][aeiou][^aeiou]` 等模式命中），merge_sequences_no_case 在 compile 路径占比可能低于静态预期。T7 实测表明 H4 优化收益不值得投入。
2. **剩余优先级**：序 4（A4 translate_colors 位图去重）T4 负改进回退暂缓，序 6（D4 split 去重）T6 负改进回退，序 7（A3+M5）T7 负改进回退，序 8-9 高风险放后期。当前性能优化剩余候选较少，可考虑转向阶段二（测试覆盖率提升）或其他热点（H2-H12 未覆盖方向，如 H8 BoundaryTable 复用、H10 Expr::rename 评估）。
3. **去重/迭代化类优化的教训**：T4/T6/T7 三轮负改进回退表明，hotspot_analysis.md 的静态推测收益可能与实测存在偏差。后续优化应优先选择"减少确定开销"的方向（如 T3 ColorMap::flatten 哈希去重 -39.95%、T5 union_all 分治归并 -3.02%），而非"改变控制流"的方向（如 T7 迭代化改变递归结构），后者易引入额外开销抵消收益。
