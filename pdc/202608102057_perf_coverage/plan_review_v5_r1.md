# 计划审查报告（v5 r1）

## 审查结果
APPROVED

## 发现

- **[轻微]** diff 的 capacity 上界 `l.intervals.length() + r.intervals.length()` 偏宽：差集是 l 的子集，区间数 ≤ l.intervals.length()，用 l+r 会多分配 r 份空间。不影响正确性（capacity 仅是初始容量提示，不会截断 push），但可收紧为 l.intervals.length() 减少浪费。Doer 实现时可自行收紧，无需计划层修正。

- **[轻微]** task_v5.md 描述 A2 为"递归二分 ts"，但未明确递归实现方式（辅助函数签名、是否改 union_all/intersect_all 签名）。当前签名为 `Array[Cset] -> Cset`，分治需引入内部辅助函数或迭代实现。此为实现细节，属 Doer 决策范围，不构成计划缺陷。

- **[轻微]** 分治归并对极小 ts（k ≤ 2）可能因递归调用开销抵消算法收益。hotspot_analysis.md §6 估算 |csets| 典型 2-15，case_insens 固定 3 路。可在 k ≤ 阈值时回退两两累积作为微优化，但计划未明确阈值。不影响正确性，Doer 可据实测决定。

### 验证通过项

1. **行号引用准确性**：独立读取 cset.mbt 验证 union_all(:298-304)、intersect_all(:307-313)、union(:105-163)、inter(:166-186)、diff(:189-235)、case_insens(:545) 全部与 plan.md/task_v5.md 引用一致。
2. **API 可行性**：task_v5.md 声称"Array::new(capacity?) 已确认"，独立创建临时项目实测 `Array::new(capacity=10)` 编译通过、moon test 1/1 通过，API 真实存在。
3. **语义等价性**：并集/交集满足结合律，分治归并与两两累积等价；intersect_all 原实现 acc=cany 首次 inter(cany,ts[0])=ts[0]，分治版单元素 base case 直接返回 ts[0]，一致；M2 capacity 预分配仅影响内存策略不改逻辑。
4. **capacity 上界正确性**：union ≤ l+r ✓、inter ≤ min(l,r) ✓、diff ≤ l+r（宽松但正确）✓。
5. **mbti 约束遵守**：union_all/intersect_all/union/inter/diff 均为内部实现优化，不改函数签名；Cset pub struct `{ intervals }` derive(Compare, Eq, Debug) 不改；不违反"不修改 pkg.generated.mbti"约束。
6. **benchmark 对比基准**：T4 已回退（代码 = T3 后版本，do_v4.md/check_v4.md 确认 git diff 无输出），本轮基于 T3 后优化，对比三方（baseline/T3 后/本轮）合理。
7. **负改进回退预案**：task_v5.md §验证第 4 条明确"若实测无改进或负改进则 git checkout re/cset.mbt 回退并标注原因（参考 T4 流程）"，预案完整。
8. **任务覆盖与推进逻辑**：task.md 要求"先性能后覆盖率"，当前在阶段一；hotspot_analysis.md 序 1(T3)✓→序 2(T4)回退✓→序 3 BLOCKED(mbti)✓→序 4 暂缓(T4 教训)✓→序 5(T5)可行，推进逻辑链清晰，选择理由充分。
9. **plan.md 与 task_v5.md 一致性**：plan.md R5 NEW T5 描述与 task_v5.md 任务描述、选择理由、上下文、验证标准均对齐。
10. **纯 MoonBit 约束**：Array::new + 整数运算为核心类型，无 C FFI。
