# 执行审查报告（v5 r1）

## 审查结果
APPROVED

## 发现

### 验证项

1. **代码改动与 task_v5.md 要求一致性** — 已核验
   - `re/cset.mbt:108` union：`Array::new(capacity=li.length() + ri.length())`，符合 task 要求"上界 = l+r" ✓
   - `re/cset.mbt:169-173` inter：`Array::new(capacity=if li.length() < ri.length() { li.length() } else { ri.length() })`，符合 task 要求"上界 = min(l,r)" ✓
   - `re/cset.mbt:198` diff：`Array::new(capacity=li.length() + ri.length())`，符合 task 要求"上界 = l+r" ✓
   - `re/cset.mbt:304-318` union_all：分治归并 `union_all_rec(ts, 0, ts.length())`，base case 空→`Cset::empty()`、单元素→`ts[lo]`、递归 `Cset::union(分治左半, 分治右半)`，符合 task 要求 ✓
   - `re/cset.mbt:321-335` intersect_all：分治归并 `intersect_all_rec(ts, 0, ts.length())`，base case 空→`Cset::cany()`、单元素→`ts[lo]`、递归 `Cset::inter(分治左半, 分治右半)`，符合 task 要求 ✓
   - inter 额外缓存 `li`/`ri` 局部变量减少字段访问（task 未明确要求但合理微优化）

2. **moon test** — 已实跑验证
   - 实测 `Total tests: 251, passed: 251, failed: 0`，与 do_v5.md 声明一致 ✓

3. **moon check** — 已实跑验证
   - 实测 `26 warnings, 0 errors`，与 do_v5.md 声明一致，与 T3 后 baseline 一致，无新 warning ✓

4. **mbti 约束** — 已核验
   - `git diff HEAD -- re/pkg.generated.mbti` 无输出，mbti 未改动 ✓
   - `union_all_rec`/`intersect_all_rec` 为 `fn`（非 `pub fn`），不暴露 mbti ✓
   - Cset pub struct 未改，union/inter/diff/union_all/intersect_all 签名未改 ✓

5. **纯 MoonBit 约束** — 已核验
   - `Array::new(capacity=...)` 为 moonbitlang/core 核心类型，非 C FFI ✓
   - 递归函数为 MoonBit 原生特性，无外部依赖 ✓

6. **snake_case 命名** — 已核验
   - `union_all_rec`/`intersect_all_rec` 符合 snake_case 风格 ✓

7. **语义等价性** — 已核验
   - union_all：并集满足结合律 `A∪(B∪C)=(A∪B)∪C`，分治归并等价于两两累积；base case 空→`empty()`（与原 `acc=empty()` 一致）、单元素→`ts[lo]`（与原 `union(empty,ts[0])=ts[0]` 一致）✓
   - intersect_all：交集满足结合律 `A∩(B∩C)=(A∩B)∩C`；base case 空→`cany()`（与原 `acc=cany()` 一致）、单元素→`ts[lo]`（与原 `inter(cany,ts[0])=ts[0]` 一致，因 `cany=[(0,255)]` 为全集）✓
   - M2 capacity 预分配：`Array::new(capacity=N)` 仅设置初始容量提示，不影响 push 语义和最终数组内容；capacity 为上界（union≤l+r、inter≤min(l,r)、diff≤l+r），不会截断 push ✓

8. **opt_v5.md 产出完整性** — 已核验
   - 含 task_v5.md 要求的 6 项：§1 改动摘要、§2 diff 关键行（5 个 before/after 代码片段）、§3 moon test 结果、§4 benchmark 三方对比表（Baseline/T3后/T5，10 section，标注 Δ vs T3 和 Δ vs Baseline，附原始 4 次运行数据）、§5 收益分析、§6 风险/回归说明 ✓
   - 三方对比基准数据与 baseline.md（Section 1=951.0ms）和 opt_v3.md（Section 1=571.1ms）一致 ✓

9. **benchmark 改进** — 已核验
   - Section 1（主优化目标）同环境对比 -3.02%（520.5ms → 504.8ms），符合 task_v5.md "可测量的改进"验证标准 ✓
   - 所有 10 个 section 均正改进（-1.89% ~ -8.96%），无回退 ✓
   - 同环境对比方法（git stash 切换消除漂移，T5 2 次取最优 vs T3后 2 次取最优）合理 ✓

10. **回退决策** — 已核验
    - task_v5.md 要求"若实测无改进或负改进则 git checkout 回退并标注原因"。实测所有 section 正改进，无需回退，改动保留，决策正确 ✓

11. **偏差说明** — 已核验
    - 偏差 1（cset.mbt 已有未提交修改）：do_v5.md 已说明判断为前序轮次已开始执行但未完成验证和报告，本轮在此基础上继续完成。最终代码改动内容与 task_v5.md 要求完全一致，无功能差异。处理合理 ✓
    - 偏差 2（plan_review_v5_r1.md 3 个轻微建议）：do_v5.md 已说明 3 个轻微建议均属 Doer 决策范围，已在 opt_v5.md §6.7 后续建议中记录权衡。处理合理 ✓

### 轻微观察（不影响正确性，不构成驳回理由）

- **[轻微] diff capacity 上界偏宽**：diff 的 capacity 用 l+r（task_v5.md 也如此要求），但差集是 l 的子集，区间数 ≤ l.intervals.length()，可收紧为 l。do_v5.md 偏差 2 已说明暂不收紧（diff 调用频率低，收益边际），且 task_v5.md 明确要求 l+r，Doer 按 task 执行无误。
- **[轻微] 极小 ts 未加阈值回退两两累积**：plan_review_v5_r1.md 提出 k≤2 时递归调用开销可能抵消算法收益。do_v5.md 偏差 2 已说明实测所有 section 正改进无需微优化，Doer 决策范围。
- **[轻微] inter 局部变量缓存超出 task 明确要求**：task_v5.md M2 仅要求 inter 预分配 capacity，未要求缓存 li/ri。但 inter 原代码 `while i < l.intervals.length()` 每次循环访问字段，缓存为 `li`/`ri` 是合理微优化，且不改变语义，可接受。

## 修改要求（仅 REJECTED 时）
无
