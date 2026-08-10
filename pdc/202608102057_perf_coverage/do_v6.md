# 执行报告（v6）

## 概述

执行 hotspot_analysis.md 优先级序 6（D4 ColorMap::split 去重），按 task_v6.md 要求改为在 `ColorMap::flatten` 入口一次性去重（避免改 ColorMap pub struct 违反 mbti 约束）。在 `re/color_map.mbt` 的 `flatten` 入口插入 hash 分桶 + 桶内 `Cset::equal` 线性比较的去重逻辑，用 `dedup_csets` 替代 `self.csets` 传入后续 `BoundaryTable::create` 和 256 循环 `Cset::mem`。

验证：`moon test` 251/251 全绿，`moon check` 26 warnings 0 errors（初版 `not(found)` 触发 1 个 deprecated warning，改为 `!found` 后消除，与 T5 后一致）。同环境 benchmark（T6 2 次取最优 vs T5 后 2 次取最优，git stash 切换消除漂移）：**Section 1（主优化目标）509.1ms → 558.8ms（+9.76%）严重负改进，9/10 section 负改进（+1.62% ~ +11.94%），仅 Section 8 小幅正改进（-1.80%）。** 实测重复率低于静态推测，去重开销（Cset::hash + 桶内 Cset::equal + HashMap 开销）远超收益（256 循环 Cset::mem 减少调用），符合 task_v6.md "若实测无改进或负改进则回退"条件，`git stash drop` 回退改动。产出 `opt_v6.md`。

## 产出清单

| 操作 | 文件路径 | 说明 |
|------|---------|------|
| 修改并回退 | `re/color_map.mbt` | flatten 入口插入 cset 去重逻辑（+28 行），实测负改进后 `git stash drop` 回退到 T3 后版本 |
| 新建 | `pdc/202608102057_perf_coverage/opt_v6.md` | T6 优化报告（改动摘要、diff、test、benchmark 三方对比表、收益分析、风险/回归说明，含负改进归因和回退决策） |

## 执行过程

### 1. 代码改动

在 `re/color_map.mbt` 的 `ColorMap::flatten` 入口（:139）插入去重逻辑：
- 创建 `dedup_csets : Array[Cset]` 和 `seen : @hashmap.HashMap[Int, Array[Cset]]`（key = `Cset::hash(cset)`，value = 桶内 csets 列表）
- 遍历 `self.csets`，对每个 cset 算 hash，查 `seen.get(h)`：若 `Some(bucket)` 桶内用 `Cset::equal` 线性比较，找到相等则跳过，未找到则 push 到 bucket 和 dedup_csets；若 `None` 创建新桶 `[cset]`，`seen[h] = [cset]`，push 到 dedup_csets
- 用 `dedup_csets` 替代 `self.csets` 传入后续 `BoundaryTable::create` 和 256 循环 `Cset::mem`

不改 ColorMap pub struct、不改 flatten 签名、不改 mbti。

### 2. 编译与测试验证

- `moon test`：251/251 全绿，无回归。
- `moon check`：初版 27 warnings（`not(found)` 触发 1 个 deprecated warning "Use !expr instead"），改为 `!found` 后 26 warnings, 0 errors（与 T5 后一致，无新 warning）。

### 3. Benchmark 同环境对比

为消除环境漂移，在同一会话内连续运行（git stash 切换版本）：

| 版本 | 运行次数 | 取最优方式 |
|------|---------|-----------|
| T6（color_map.mbt 含去重改动） | 2 次 | 每 section 2 次取最小 |
| T5 后（git stash 后，color_map.mbt = T3 后版本） | 2 次 | 每 section 2 次取最小 |

**T6 最优**：558.8 / 37.7 / 153.6 / 168.7 / 228.2 / 139.9 / 190.1 / 65.6 / 40.3 / 25.1
**T5 后最优**：509.1 / 37.1 / 146.0 / 156.3 / 212.2 / 130.6 / 178.4 / 66.8 / 36.0 / 24.1

对比 T5 后同环境：Section 1 +9.76%（严重负改进），9/10 section 负改进（+1.62% ~ +11.94%），仅 Section 8 小幅正改进（-1.80%）。

### 4. 回退决策

task_v6.md 要求"若实测无改进或负改进则 git checkout re/color_map.mbt 回退改动并标注原因"。实测 Section 1 主优化目标 +9.76% 严重负改进，9/10 section 负改进，回退决策明确。`git stash drop` 丢弃 T6 改动，`re/color_map.mbt` 恢复为 T3 后版本（HEAD 6364b65），`re/cset.mbt` 保持 T5 后版本。回退后 moon test 251/251 全绿。

### 5. 负改进归因

- **实际重复率低**：hotspot_analysis.md §6 附注"实际 |csets| 可能因重复翻倍"为静态推测，实测 |dedup| ≈ |csets|，去重后 csets 数量几乎未减少，256 循环 Cset::mem 调用次数未减少，收益未实现。
- **去重开销高**：`Cset::hash`（O(Ī) 遍历 intervals 算 hash，含乘法）+ 桶内 `Cset::equal`（O(Ī) 线性比较）+ HashMap get/set 开销，即便重复率为 0 仍纯增加开销。
- **256 倍放大未生效**：预期"256 倍放大使收益通常超开销"基于 |csets| - |dedup| ≥ 1 的假设，实测重复率低使 |csets| - |dedup| ≈ 0，256 倍放大 × 0 = 0。
- **与 T4 教训一致**：T4（translate_colors 位图去重）同样因实际重复率低于静态推测而负改进回退。去重类优化对实际重复率敏感，静态推测可能高估，实测是唯一可靠依据。

### 6. 产出 opt_v6.md

含 task_v6.md 要求的 6 项：§1 改动摘要、§2 diff 关键行（before/after 代码片段）、§3 moon test 结果、§4 benchmark 三方对比表（Baseline / T5 后 / T6 三方，10 section，标注 Δ vs T5 和 Δ vs Baseline，附原始 4 次运行数据，T5 后/T6 为同环境重测数值，baseline 为历史参考）、§5 收益分析（实际 vs 预期、负改进归因 5 条、与 T4 教训一致）、§6 风险/回归说明（测试回归、语义等价性、warning 情况、纯 MoonBit 约束、mbti 约束、回退决策、后续建议）。

## 偏差说明

**偏差 1（已处理）**：task_v6.md 预期收益"中、负改进风险较低"，实测严重负改进（Section 1 +9.76%）。这是基于 hotspot_analysis.md §6 附注静态推测的预期与实测的差异，非任务指令偏差。task_v6.md 已预设回退分支"若实测无改进或负改进则回退"，本轮按此执行回退，符合任务指令。

**偏差 2（已处理）**：初版去重逻辑用 `not(found)` 触发 1 个 deprecated warning（"Use !expr instead"），使 warning 数从 26 增至 27，违反"无新 warning 引入"验证标准。改为 `!found` 后 warning 数恢复 26，符合标准。此为 MoonBit 语法选择问题，已在改动中修正，不影响最终回退决策。
