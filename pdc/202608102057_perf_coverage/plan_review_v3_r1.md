# 计划审查报告（v3 r1）

## 审查结果
REJECTED

## 发现
- **[一般]** plan.md 缺少 `R3 PASSED T2` 状态记录条目。plan.md 的任务状态轨迹为：`R1 NEW T1` → `R2 PASSED T1` + `R2 NEW T2` → `R3 NEW T3`，跳过了 T2 的 PASSED 记录。按 R1→R2 建立的范式（R2 先记录 `PASSED T1` 再 `NEW T2`），R3 应先记录 `PASSED T2` 再 `NEW T3`。do_v2.md 和 check_v2.md 均存在且确认 T2 已 PASSED，task_v3.md 第 42 行也引用了这两份产出，但 plan.md 本身未将 T2 的完成状态固化为计划记录。这导致：① 计划内部逻辑不一致——T3 选择理由以"T2 已定位 ColorMap::flatten（H1 ★★★）"开头，假设 T2 已完成，但计划体中 T2 始终处于 NEW 状态未被标记完成；② 审计链断裂——仅读 plan.md 无法得知 T2 已验证通过，后续轮次或审查者可能误判 T3 的依据（hotspot_analysis.md）未经校验。

- **[轻微]** T3 优化目标 `color_map.mbt` 不在 task.md 第 33-40 行的"核心模块优先级"列表中（该列表为 cset > compile > automata_state > automata_desc > core > hash_set > bit_vector）。plan.md 正确遵循了 T2 数据驱动热点分析的结论（H1 ★★★ 位于 color_map.mbt::flatten），但未显式说明此偏差。选择理由中"T2 已定位"隐含了依据来源，但未点明"color_map.mbt 不在原始静态优先级列表、改为依据 T2 实测分析结果选择"，可追溯性不够清晰。不影响正确性——T2 的分析结论比 task.md 的静态文件大小排序更可靠。

- **[轻微]** T3 验证要求"对比 baseline.md 验证改进"未指定无改进或回退时的处理策略。task.md 第 44 行要求"benchmark 结果有可测量的改进"作为验证标准，plan.md 和 task_v3.md 均要求产出 before/after 对比表和收益分析，但未说明若实测无改进或负改进时 Doer 应如何处置（回退改动？保留并标注？进入下一轮？）。这主要是执行层关注点，Checker 可按对比表判定，但计划层补充一句可减少执行歧义。

- **[轻微]** T3 的 M1（ids 缓冲复用）与 A1+D3（哈希去重需保留 ids 副本作为 key）存在交互细节：task_v3.md 第 10 行已正确指出"命中新 color 时做一次深拷贝存入 map，其余情况复用缓冲"，plan.md 第 27 行的描述也涵盖了此点但较为简略。不影响正确性，执行时 task_v3.md 的详细说明可指导实现。

## 修改要求（仅 REJECTED 时）

### 问题 1：缺少 `R3 PASSED T2` 状态记录
**问题是什么**：plan.md 从 `R2 NEW T2` 直接跳到 `R3 NEW T3`，缺少 `R3 PASSED T2` 条目记录 T2 的完成状态。

**为什么是问题**：① 破坏计划内部逻辑一致性——T3 选择理由假设 T2 已完成（"T2 已定位..."），但计划体中 T2 仍为 NEW 未被标记完成，形成"未完成任务产出被后续任务依赖"的矛盾表述；② 破坏审计链——仅依据 plan.md 无法确认 T2 已验证通过，与 R1→R2 范式（先 PASSED 再 NEW）不一致；③ 若此模式延续，计划将累积未关闭的 NEW 条目，无法区分已完成与进行中任务。

**期望的修正方向**：在 `R3 NEW T3` 条目之前插入 `R3 PASSED T2` 条目，记录 T2 的完成结果摘要（参照 `R2 PASSED T1` 的格式：产出文件、关键结论、Check 结论），例如：`## R3 PASSED 分析 compile 路径代码热点 [ID: T2]` + 结果摘要（产出 hotspot_analysis.md，12 个热点函数 + 10 项优先级排序，Check PASSED）。
