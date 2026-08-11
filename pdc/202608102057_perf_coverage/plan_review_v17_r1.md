# 计划审查报告（v17 r1）

## 审查结果
APPROVED

## 发现
- **[轻微]** 任务上下文中多个 Cset API 行号与实际源码不符：`Cset::empty()` 声称 cset.mbt:228 实际 :49、`Cset::single` 声称 :240 实际 :251、`Cset::cany()` 声称 :234 实际 :59、`Cset::diff` 声称 :189 实际 :195。偏差最大 179 行。但 7 个块规格均以 API 名称（如 `Cset::empty()`、`Cset::single(65)`）和断言值表述，不依赖行号；Doer 可通过函数名定位正确实现。不影响执行正确性。
- **[轻微]** 任务上下文中 basics_test.mbt 块分类计数表述不精确："cset 11 块 + Pmark 2 块 + Category 2 块 + BitVector 1 块 + HashSet 2 块 + cset set/one_char 1 块"。实际 Pmark 为 3 块（gen unique / pmarkset mem-add / pmarkset dedup），且 set/one_char 已包含在 cset 11 块中（:74/:80），不应单列。总数 19 正确，分类有误但不影响任务执行。
- **[轻微]** 块 6 对 `union_singles_in_strictly_decreasing_order` 传入非递减输入 `[5, 3, 3, 1]` 仅断言 `result.intervals.length() >= 1`，断言强度弱（任何非空输入均满足）。但 task_v17.md 明确说明这是对 UB 场景的保守策略（"记录实际行为而非断言特定结果——先调用确认不 raise"），设计意图明确。经核实源码（cset.mbt:384-406），该输入实际产生 `[(5,5),(3,3),(3,3),(1,1)]`，length=4，断言通过。

## 已核实事实
- basics_test.mbt 167 行 19 个 test 块（cset 11 + Pmark 3 + Category 2 + BitVector 1 + HashSet 2）✓
- Cset API 行号：empty :49 / cany :59 / union :105 / inter :166 / diff :195 / single :251 / seq :271 / mem :338 / union_singles :384 / clower :532 / calpha :557 / calnum :562 / case_insens :567 / cword :576（seq/mem/union_singles/clower/calpha/calnum/case_insens/cword 行号正确，empty/cany/single/diff 偏差）
- 预定义集定义与 task_v17.md 一致：cset_upper=union_all[iseq(65,90),iseq(192,214),iseq(216,222)]、cset_clower=offset(32,cset_upper)、cset_calpha=union(clower,upper)+{170,181,186,223,255}、cset_calnum=union(calpha,cdigit)、cset_cword=cadd('_',calnum) ✓
- case_insens(single(192)) 经推算 = {192, 224}，块 7 断言 mem(192)==true && mem(224)==true ✓
- calnum 含 65/97/48/170/181/223/255、calpha 含 65/97/170 不含 48、clower 含 97/224 不含 65、cword 含 95/65/97/48 不含 32 — 全部与源码一致 ✓
- Cset::mem（:338-346）线性扫描 `c >= c1 && c <= c2`，对 -1 和 256 无特殊处理，返回 false ✓
- 7 块数量与验证标准 298/298（291+7）一致 ✓
- T16 后 291/291 基线（do_v16.md 确认）✓
- 约束遵守：纯 MoonBit、snake_case、不修改 mbti、不修改源码仅追加测试、不运行 benchmark ✓
