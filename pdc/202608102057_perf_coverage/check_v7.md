# 检查报告（v7）

## 结果
PASSED

## 检查项
| 检查项 | 方法 | 结果 |
|--------|------|------|
| opt_v7.md 存在且含 6 项 | 读取文件并核对章节 | 通过：§1 改动摘要 / §2 diff 关键行 / §3 moon test 结果 / §4 benchmark 三方对比表 / §5 收益分析 / §6 风险/回归说明 齐全 |
| §2 diff 含 before/after 代码片段 | 读取 opt_v7.md §2 | 通过：2.1 merge_sequences_from 和 2.2 merge_sequences_no_case_from 均含 before（递归每层新建 Array）和 after（迭代化 + 预分配 capacity）代码片段 |
| §4 benchmark 三方对比表完整 | 读取 opt_v7.md §4 | 通过：含 Baseline / T5 后 / T7 三方，10 section 齐全，标注 Δ vs T5(ms/%）和 Δ vs Baseline(%)，附原始 4 次运行数据（T7 第1/2次、T5后 第1/2次），明确标注"同环境重测/baseline 历史参考" |
| benchmark 数值与 do_v7.md 一致 | 对比 do_v7.md §3 与 opt_v7.md §4 | 通过：T7 最优 526.4/38.1/150.0/161.5/212.2/137.7/182.4/67.9/39.2/25.4，T5 后最优 522.2/37.8/152.4/163.5/218.8/128.1/181.0/66.6/39.5/24.7，两份数据一致 |
| 回退条件触发正确 | 核对 task_v7.md 回退分支与 opt_v7.md §5/§6.6 | 通过：Section 1 同环境 +0.80% 负改进，6/10 section 负改进，符合 task_v7.md "若实测无改进或负改进则 git checkout re/ast.mbt 回退改动并标注原因"条件，opt_v7.md §5.1 结论、§6.6 回退决策已标注原因 |
| re/ast.mbt 已回退到 HEAD | `git diff HEAD --stat -- re/ast.mbt` | 通过：0 行 diff，re/ast.mbt 与 HEAD e64ec54 完全一致 |
| git stash 已清理 | `git stash list` | 通过：无 stash 残留 |
| moon test 无回归 | `moon test` 实跑 | 通过：Total tests: 251, passed: 251, failed: 0，与 opt_v7.md §3 一致 |
| 约束遵守 | 核对 opt_v7.md §6.4/§6.5 | 通过：纯 MoonBit 无 C FFI（§6.4）、不修改 mbti（§6.5，仅改内部 fn）、snake_case 命名、pub fn 签名不改 |
| 负改进归因完整 | 读取 opt_v7.md §5.2/§5.4 | 通过：6 条归因（prefix 累积开销、递归点 2 仍递归、work/pos 重置开销、prefix 内存开销、Section 6 负改进最大、Section 5 正改进最大）+ 迭代化方案根本限制分析 |
| 偏差说明 | 读取 do_v7.md 偏差说明 | 通过：偏差 1（预期收益与实测差异，已按回退分支处理）、偏差 2（递归点 2 保留递归的设计决策，已记录权衡）均说明 |

## 总结

Doer 按 task_v7.md 要求执行了 A3（递归改迭代 + 索引区间）+ M5（Array 预分配 capacity）优化，实测 Section 1 同环境 +0.80% 负改进后按任务预设回退分支正确回退。opt_v7.md 6 项产出齐全，benchmark 三方对比表数据与 do_v7.md 一致，负改进归因充分（6 条 + 根本限制分析）。re/ast.mbt 已回退到 HEAD e64ec54（0 diff），git stash 已清理，moon test 251/251 全绿无回归。所有约束（纯 MoonBit、不改 mbti、snake_case、pub fn 签名不改、保持语义）均遵守。执行符合 task_v7.md 全部要求。
