# 执行报告（v4）

## 概述

执行 hotspot_analysis.md 优先级序 2（D1 局部：flatten 内联 Cset 256-bit 位图）优化尝试。在 `re/color_map.mbt` 的 `ColorMap::flatten` 中预构建每个 cset 的 256-bit 位图（`FixedArray[Byte]` of 32 bytes），将 256 循环内 `Cset::mem`（O(Ī) 区间扫描）替换为 O(1) 位测试。

尝试版本 `moon check` 通过（26 warnings, 0 errors）、`moon test` 251/251 全绿（语义正确）。但同环境 benchmark 实测：Section 1（主优化目标）相对 T3 后基线 **+1.08%（回退）**，含 compile 的 section（3/4/5/6/7）**全部回退 4-7%**。位图构建的固定开销（|csets| × 32 bytes 分配 + Σ interval_length 次位设置）超过 mem 查询的边际节省。

按 task_v4.md 要求"若实测无改进或负改进，则回退改动并标注原因"，已回退 `re/color_map.mbt` 到 T3 后版本。产出 `opt_v4.md` 含改动摘要、diff、test 结果、benchmark 三方对比表、负改进归因、回退说明。

## 产出清单

| 操作 | 文件路径 | 说明 |
|------|---------|------|
| 新建 | `pdc/202608102057_perf_coverage/opt_v4.md` | T4 优化报告（尝试性改动 + 实测负改进 + 回退说明） |
| 修改后回退 | `re/color_map.mbt` | 尝试性位图优化（+18 行），实测回退后 `git checkout` 回到 T3 后版本，最终无改动 |

## 执行过程

### 1. 代码改动（尝试性）

在 `re/color_map.mbt:139-157` 新增位图预构建：对 `self.csets` 中每个 cset，用 `Cset::iter` 遍历区间，对区间内每个字符 `c` 置位 `bitmap[c >> 3] |= (1 << (c & 7))`。位图存于 `Array[FixedArray[Byte]]`，长度 = |csets|，每个 32 bytes（256 bits）。

在 `re/color_map.mbt:170-176` 将 `Cset::mem(i, csets[csetid])` 替换为 `((bitmap[i >> 3]).to_int() & (1 << (i & 7))) != 0`。

### 2. 编译验证

首次 `moon check` 报 4 errors：`..<` 与 `+` 优先级歧义、`&` 与 `!=` 优先级歧义。加括号修正（`c1..<(c2 + 1)`、`((bitmap[i >> 3]).to_int() & (1 << (i & 7))) != 0`）后通过：26 warnings, 0 errors（与 T3 后一致）。

### 3. 测试验证

`moon test`：251/251 全绿，位图与 Cset::mem 语义等价（基于相同 intervals 数据）。

### 4. Benchmark 同环境对比

为消除环境漂移，在同一会话内连续运行：
- T3 后版本（`git stash` T4 改动后）：2 次，取最优
- T4 版本（`git stash pop` 恢复后）：2 次，取最优

结果（Section 1）：T3 后最优 528.2ms，T4 最优 533.9ms，**+1.08%（回退）**。含 compile 的 section 全部回退 4-7%，纯 match 的 section 噪声内波动。

### 5. 负改进归因

- 位图构建成本 O(Σ cset_size) + |csets| × 32 bytes 分配，对当前 cset 规模（|csets| ≈ 5-15，Ī ≈ 1-5）显著
- 原 Cset::mem 平均 1-3 次比较即判定，已很快；位测试单次开销更大（FixedArray 索引 + Byte→Int + 位运算）
- 分配增加 GC 压力，位图占用影响 cache 局部性
- 此优化更适合 |csets| 或 Ī 很大的场景

### 6. 回退

`git checkout re/color_map.mbt` 回退到 T3 后版本。`moon test` 251/251 确认回退后无回归。

### 7. 产出 opt_v4.md

含 task_v4.md 要求的 5 项：改动摘要（§1）、diff 关键行（§2）、moon test 结果（§3）、benchmark 三方对比表（§4，含 baseline / T3 后 / T4 三方数据，10 section，标注 Δ%）、收益分析（§5，实际 vs 预期、负改进归因、为何 Section 2 不变）、风险/回归说明（§6，位图构建正确性、语义等价性、warning 情况、纯 MoonBit 约束、回退决策、后续建议）。

## 偏差说明

无偏差。task_v4.md 预见"若实测无改进或负改进，则回退改动并在 opt_v4.md 中标注原因"的分支，已按此分支执行。代码最终状态与 T3 后版本一致（无净改动），opt_v4.md 完整记录了尝试性改动、实测数据、负改进归因和回退决策。
