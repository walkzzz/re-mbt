# 检查报告（v4）

## 结果
PASSED

## 检查项
| 检查项 | 方法 | 结果 |
|--------|------|------|
| 产出文件存在性 | `ls` 工作目录 | 通过：opt_v4.md（9635 bytes）存在 |
| opt_v4.md 五项产出完整性 | 读取 opt_v4.md 全文 | 通过：§1 改动摘要、§2 diff 关键行、§3 moon test、§4 benchmark 三方对比表、§5 收益分析、§6 风险/回归说明齐全 |
| benchmark 三方对比表完整性 | 检查 §4 表格 | 通过：10 section 全覆盖，含 Baseline / T3 后 / T4 三方数据，标注 Δ vs T3(ms) 与 Δ vs T3(%)，附原始 2 次运行数据 |
| re/color_map.mbt 回退验证 | `git diff re/color_map.mbt` + `grep bitmaps` + 读取 :130-188 | 通过：git diff 无输出，grep 无 bitmaps/FixedArray::make(32) 命中，:154 仍为 `Cset::mem(i, csets[csetid])`（T3 后版本），无净改动 |
| moon test 不回归 | `moon test` | 通过：Total tests: 251, passed: 251, failed: 0 |
| moon check warning 数 | `moon check` | 通过：26 warnings, 0 errors（与 T3 后一致，无新 warning） |
| 回退决策合规性 | 对比 task_v4.md §4 验证要求与 opt_v4.md §6.5 | 通过：task_v4.md 要求"若实测无改进或负改进，则回退改动并标注原因"；Section 1 +1.08%（回退），含 compile section 全部回退 4-7%，符合负改进条件，已 `git checkout` 回退并在 §1/§5.2/§6.5 标注原因 |
| 负改进归因完整性 | 检查 opt_v4.md §5.2 | 通过：6 条归因（位图构建开销、原 mem 已快、位测试常数更大、分配/GC 压力、cache 退化、规模不匹配）逻辑自洽 |
| 纯 MoonBit 约束保持 | 检查 opt_v4.md §6.4 + 回退后代码 | 通过：尝试性改动使用 FixedArray[Byte] + Int 位运算（核心类型，无 C FFI）；回退后无影响 |
| 语义等价性验证 | 检查 opt_v4.md §6.2 + moon test | 通过：位图构建基于 Cset::iter 遍历相同 intervals，moon test 251/251 全绿验证语义等价 |
| diff 关键行可读性 | 检查 opt_v4.md §2 | 通过：§2.1 位图预构建、§2.2 Cset::mem → 位测试，含 before/after 代码片段，标注"已回退" |
| do_v4.md 与 opt_v4.md 一致性 | 对比两文件关键数据 | 通过：Section 1 +1.08%、251/251、26 warnings、回退决策均一致 |

## 总结

Doer 完整执行了 task_v4.md 的"尝试 → 实测 → 负改进则回退并标注"流程：

1. **尝试性改动**：在 re/color_map.mbt:139-157 预构建位图，:170-176 替换 Cset::mem 为位测试，moon check 通过、moon test 251/251 全绿。
2. **同环境 benchmark 实测**：Section 1 +1.08%（回退），含 compile 的 section 全部回退 4-7%，符合 task_v4.md "负改进"条件。
3. **回退**：`git checkout re/color_map.mbt` 回到 T3 后版本，git diff 确认无净改动，moon test 251/251 确认无回归。
4. **产出 opt_v4.md**：完整记录改动摘要、diff、test 结果、benchmark 三方对比表（10 section + 原始数据）、负改进归因（6 条）、回退决策、后续建议。

所有检查项通过，产出满足 task_v4.md 全部要求。
