# 计划审查报告（v7 r1）

## 审查结果
APPROVED

## 发现
- **[轻微]** A3"递归改迭代 + 索引区间表示子数组"对 `Alternative` 分支不完全可行：该分支构建 `combined = l2 + l[start+1..]`，其中 `l2` 来自 AST 内部节点而非 `l` 的子段，无法用原数组索引区间表示；`Sequence(xs.length() > 0)` 分支的递归调用非尾递归（需 `merged_rest` 结果决定构建方向），不能直接转为简单循环。task_v7.md 的"仅在最终结果时按需构建 Array"限定语已给出灵活空间，Doer 可在实现时按需构建 combined 并对可尾调用分支做迭代化，M5（capacity 预分配）独立可行，回退分支覆盖负改进情形。建议 Doer 实现时优先做 M5（低风险确定收益），A3 按可行范围部分实施。

- **[轻微]** M5 capacity 上界公式"y/y2 上界 = |xs| - 1"对 y2 不精确：y2 来自 xs2（= merged_rest[0] as Sequence），其上界应为 |xs2| - 1 而非 |xs| - 1。Array::new(capacity) 不足时自动扩容，不影响正确性，仅可能错过预分配收益。Doer 实现时按实际来源分别计算即可。

- **[轻微]** "result 上界 = |merged_rest| + 1"仅适用于 `Sequence(xs.length() > 0)` 分支内的 result 数组（该分支先计算 merged_rest 再构建 result）；`Sequence(xs.length() == 0)` 和 `_` 分支的 result 在递归调用前构建，capacity 无法预知。Doer 需按各分支分别处理。

- **[轻微]** task_v7.md"working tree clean"指 re/ 代码目录干净（git status 确认无 re/ 改动），但 pdc/ 规划文件有改动（plan.md modified、task_v7.md untracked）。不影响同环境 benchmark 方法（Doer 仅 stash re/ast.mbt 代码改动），与 T5/T6 已建立方法一致。
