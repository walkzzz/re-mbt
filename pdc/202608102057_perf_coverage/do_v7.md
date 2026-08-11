# 执行报告（v7）

## 概述

执行 hotspot_analysis.md 优先级序 7（A3 + M5），优化 `re/ast.mbt` 的 `merge_sequences_no_case_from`（:343-420）和 `merge_sequences_from`（:252-324）：

- **A3 算法层**：将递归改迭代 + 索引区间表示子数组。引入 `prefix : Array[Ast]` 累积递归点 3/4（简单前缀 `[head] + 递归`）的 head，`mut work : Array[Ast]`/`mut pos : Int` 表示当前工作数组（递归点 1 Alternative 重组 work/pos，不递归调用）。递归点 2（Sequence 非空，需窥探下一结果首元素以决定合并）保留递归 `merge_sequences_from(work, pos+1)`，结果与 prefix 一次性合并构建。
- **M5 内存层**：中间 Array（combined/y/y2/result）全部预分配 capacity 上界（combined = l2.length()+work.length()-pos-1，y/y2 = xs.length()-1，result = prefix.length()+merged_rest.length() 或 +1），消除动态扩容。

验证：`moon test` 251/251 全绿，`moon check` 26 warnings 0 errors（与 T5 后一致，无新 warning）。同环境 benchmark（T7 2 次取最优 vs T5 后 2 次取最优，git stash 切换消除漂移）：**Section 1（主优化目标）522.2ms → 526.4ms（+0.80%）负改进，4/10 section 正改进（-0.76% ~ -3.01%），6/10 section 负改进（+0.77% ~ +7.50%）。** 迭代化引入的 prefix 累积+合并开销超过减少的递归分配开销，符合 task_v7.md "若实测无改进或负改进则 git checkout re/ast.mbt 回退改动"条件，`git stash drop` 回退改动。产出 `opt_v7.md`。

## 产出清单

| 操作 | 文件路径 | 说明 |
|------|---------|------|
| 修改并回退 | `re/ast.mbt` | merge_sequences_from/merge_sequences_no_case_from 迭代化 + 预分配 capacity（+60 行），实测负改进后 `git stash drop` 回退到原始版本 |
| 新建 | `pdc/202608102057_perf_coverage/opt_v7.md` | T7 优化报告（改动摘要、diff、test、benchmark 三方对比表、收益分析、风险/回归说明，含负改进归因和回退决策） |

## 执行过程

### 1. 代码改动

在 `re/ast.mbt` 的 `merge_sequences_from`（:252-324）和 `merge_sequences_no_case_from`（:343-420）中实施 A3+M5：

**A3 迭代化**：
- 递归点 3/4（`_ =>` 和 `Sequence([]) =>`）：原 `[head] + merge_sequences_from(l, start+1)` 改为 `prefix.push(head); pos += 1; continue`，prefix 累积后前进。
- 递归点 1（`Alternative(l2) =>`）：原 `merge_sequences_from(combined, 0)` 改为 `work = combined; pos = 0; continue`，重组工作数组后继续迭代，prefix 不变。
- 递归点 2（`Sequence(xs) if xs 非空 =>`）：保留递归 `merge_sequences_from(work, pos+1)`，结果与 prefix 一次性合并构建 result（`prefix + [new_seq] + merged_rest[1..]` 或 `prefix + [head] + merged_rest`）。

**M5 预分配 capacity**：
- combined：`Array::new(capacity=l2.length() + work.length() - pos - 1)`
- y/y2：`Array::new(capacity=xs.length() - 1)` / `Array::new(capacity=xs2.length() - 1)`
- result：`Array::new(capacity=prefix.length() + merged_rest.length())` 或 `+1`

不改 `merge_sequences`/`merge_sequences_no_case` pub fn 签名、不改 mbti。

### 2. 编译与测试验证

- `moon check`：26 warnings, 0 errors（与 T5 后一致，无新 warning）。
- `moon test`：251/251 全绿，无回归。

### 3. Benchmark 同环境对比

为消除环境漂移，在同一会话内连续运行（git stash 切换版本）：

| 版本 | 运行次数 | 取最优方式 |
|------|---------|-----------|
| T7（ast.mbt 含迭代化+预分配改动） | 2 次 | 每 section 2 次取最小 |
| T5 后（git stash 后，ast.mbt = 原始版本） | 2 次 | 每 section 2 次取最小 |

**T7 最优**：526.4 / 38.1 / 150.0 / 161.5 / 212.2 / 137.7 / 182.4 / 67.9 / 39.2 / 25.4
**T5 后最优**：522.2 / 37.8 / 152.4 / 163.5 / 218.8 / 128.1 / 181.0 / 66.6 / 39.5 / 24.7

对比 T5 后同环境：Section 1 +0.80%（负改进），4/10 section 正改进（-0.76% ~ -3.01%），6/10 section 负改进（+0.77% ~ +7.50%）。

### 4. 回退决策

task_v7.md 要求"若实测无改进或负改进则 git checkout re/ast.mbt 回退改动并标注原因"。实测 Section 1 主优化目标 +0.80% 负改进，6/10 section 负改进，回退决策明确。`git stash drop` 丢弃 T7 改动，`re/ast.mbt` 恢复为原始版本（HEAD e64ec54 v6 done，working tree clean）。回退后 moon test 251/251 全绿。

### 5. 负改进归因

- **prefix 累积开销**：迭代化将递归点 3/4 改为 prefix 累积，但递归点 2 结果与 prefix 一次性合并时需遍历 prefix 构建 result，开销与原递归每层新建 result 相当（甚至更高）。
- **递归点 2 仍递归**：迭代化未消除递归点 2 的递归调用，而递归点 2 是 Sequence 非空分支，含 y/y2/result 的主要分配。迭代化只优化了递归点 3/4，对核心分配无影响。
- **work/pos 重置开销**：递归点 1 迭代化为 `work = combined; pos = 0`，但 combined 仍需新建（跨两个数组，无法用索引区间引用）。
- **Section 6 负改进最大（+7.50%）**：Pcre 模式含较多 Alternative 和 Sequence，merge_sequences_no_case 调用频繁，prefix 累积+合并开销在频繁调用场景下放大。
- **迭代化方案根本限制**：递归点 2 需"窥探下一结果首元素"以决定合并，无法简单迭代化。本次只迭代化递归点 3/4 和递归点 1，保留递归点 2 递归，收益有限。

### 6. 产出 opt_v7.md

含 task_v7.md 要求的 6 项：§1 改动摘要、§2 diff 关键行（before/after 代码片段）、§3 moon test 结果、§4 benchmark 三方对比表（Baseline / T5 后 / T7 三方，10 section，标注 Δ vs T5 和 Δ vs Baseline，附原始 4 次运行数据，T5 后/T7 为同环境重测数值，baseline 为历史参考）、§5 收益分析（实际 vs 预期、负改进归因 6 条、与 T4/T6 教训关系、迭代化方案根本限制）、§6 风险/回归说明（测试回归、语义等价性、warning 情况、纯 MoonBit 约束、mbti 约束、回退决策、后续建议）。

## 偏差说明

**偏差 1（已处理）**：task_v7.md 预期收益"中"，实测负改进（Section 1 +0.80%）。这是基于 hotspot_analysis.md H4 静态推测的预期与实测的差异，非任务指令偏差。task_v7.md 已预设回退分支"若实测无改进或负改进则 git checkout re/ast.mbt 回退改动"，本轮按此执行回退，符合任务指令。

**偏差 2（设计决策）**：task_v7.md 要求"A3 将递归改迭代 + 索引区间表示子数组，避免每层新建 Array"。本轮迭代化方案只迭代化了递归点 3/4（简单前缀累积）和递归点 1（Alternative 重组工作数组），保留了递归点 2（Sequence 非空，需合并）的递归。原因：递归点 2 需"窥探下一结果首元素"以决定是否合并（`merged_rest[0] == x`），当前层贡献依赖下一层完整结果，无法简单迭代化。完全迭代化需引入"前向窥探"辅助函数，复杂性和回归风险高，且 T7 实测负改进表明完全迭代化收益预期也不明朗。此为 Doer 设计决策，已在 opt_v7.md §5.4 迭代化方案根本限制中记录权衡。
