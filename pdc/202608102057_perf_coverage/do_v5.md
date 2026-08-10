# 执行报告（v5）

## 概述

执行 hotspot_analysis.md 优先级序 5（A2 + M2），优化 `re/cset.mbt`：

- **A2**：`Cset::union_all`/`intersect_all` 由两两累积改为分治归并（递归二分，base case 空 → `empty()`/`cany()`、单元素 → 直接返回，递归 case `union`/`inter(分治左半, 分治右半)`），新增内部辅助函数 `union_all_rec`/`intersect_all_rec`。
- **M2**：`Cset::union`/`inter`/`diff` 的 `result` Array 由 `[]` 改为 `Array::new(capacity=...)` 预分配上界容量（union/diff = l+r，inter = min(l,r)），消除扩容重分配。inter 同时缓存 `li`/`ri` 局部变量减少字段访问。

验证：`moon test` 251/251 全绿，`moon check` 26 warnings 0 errors（与 T3 后一致，无新 warning）。同环境 benchmark（T5 2 次取最优 vs T3 后 2 次取最优，git stash 切换消除漂移）：Section 1（主优化目标）520.5ms → 504.8ms（-3.02%），所有 10 个 section 均正改进（-1.89% ~ -8.96%），无回退。改动保留，产出 `opt_v5.md`。

## 产出清单

| 操作 | 文件路径 | 说明 |
|------|---------|------|
| 修改 | `re/cset.mbt` | union/inter/diff result 预分配 capacity + union_all/intersect_all 分治归并（+30 行，不改 pub struct/签名/mbti） |
| 新建 | `pdc/202608102057_perf_coverage/opt_v5.md` | T5 优化报告（改动摘要、diff、test、benchmark 三方对比表、收益分析、风险/回归说明） |

## 执行过程

### 1. 代码状态确认

启动时发现 `re/cset.mbt` 工作区已有未提交修改（A2+M2 优化版本），与 task_v5.md 描述"re/cset.mbt = 原始版本"不符。`git diff HEAD -- re/cset.mbt` 确认改动内容正是 task_v5.md 要求的 A2+M2 优化（union/inter/diff 预分配 + union_all/intersect_all 分治归并）。判断为前序轮次已开始执行但未完成验证和报告，本轮在此基础上继续完成验证和产出。

### 2. 编译与测试验证

- `moon test`：251/251 全绿，无回归。
- `moon check`：26 warnings, 0 errors（与 T3 后一致，无新 warning）。

### 3. Benchmark 同环境对比

为消除环境漂移，在同一会话内连续运行（git stash 切换版本）：

| 版本 | 运行次数 | 取最优方式 |
|------|---------|-----------|
| T5（当前 cset.mbt 已修改） | 2 次 | 每 section 2 次取最小 |
| T3 后（git stash 后） | 2 次 | 每 section 2 次取最小 |

**T5 最优**：504.8 / 39.1 / 152.2 / 160.1 / 214.4 / 131.0 / 178.8 / 67.6 / 39.0 / 24.4
**T3 后最优**：520.5 / 41.5 / 159.4 / 165.2 / 234.8 / 135.9 / 186.3 / 68.9 / 41.3 / 26.8

对比 T3 后同环境：Section 1 -3.02%，所有 10 section 均正改进（-1.89% ~ -8.96%），无回退。

### 4. 回退决策

task_v5.md 要求"若实测无改进或负改进则 git checkout re/cset.mbt 回退并标注原因"。实测所有 section 正改进，无需回退，改动保留。

### 5. 产出 opt_v5.md

含 task_v5.md 要求的 6 项：§1 改动摘要、§2 diff 关键行（5 个 before/after 代码片段）、§3 moon test 结果、§4 benchmark 三方对比表（Baseline / T3 后 / T5 三方，10 section，标注 Δ vs T3 和 Δ vs Baseline，附原始 4 次运行数据）、§5 收益分析（实际 vs 预期、收益归因 3 条、Section 2 改进归因、Section 5/10 改进最大归因）、§6 风险/回归说明（测试回归、语义等价性、warning 情况、纯 MoonBit 约束、mbti 约束、回退决策、后续建议）。

## 偏差说明

**偏差 1（已处理）**：task_v5.md 描述"re/cset.mbt = 原始版本（union_all/intersect_all 两两累积，union/inter/diff result 无预分配）"，但实际工作区 cset.mbt 已是 A2+M2 优化版本（未提交修改）。判断为前序轮次已开始执行但未完成验证和报告。本轮未从头重做代码改动，而是在已有改动基础上继续完成验证（moon test/check/benchmark）和产出（opt_v5.md/do_v5.md），符合 doer.md "若任务文件动作为 RETRY，重点关注 RETRY 说明中的修正方向，评估已有产出中需要修改的部分，在已有产出基础上进行针对性修改，而非从头开始"的精神（虽 task_v5 动作为 NEW，但已有改动符合 task 描述，重做无意义）。最终代码改动内容与 task_v5.md 要求完全一致，无功能差异。

**偏差 2（已处理）**：plan_review_v5_r1.md 提出 3 个轻微建议（diff capacity 上界偏宽可收紧、分治递归实现方式为 Doer 决策范围、极小 ts 可加阈值回退两两累积）。本轮处理：diff capacity 用 l+r 宽松上界（正确但多分配 r 份，diff 调用频率低，收益边际，暂不收紧）；分治用递归辅助函数实现（`union_all_rec`/`intersect_all_rec`，签名 `(ts, lo, hi) -> Cset`，内部 `fn` 不暴露 mbti）；极小 ts 阈值未加（实测所有 section 正改进，无需微优化）。3 个轻微建议均属 Doer 决策范围，已在 opt_v5.md §6.7 后续建议中记录权衡。
