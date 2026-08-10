# 检查审查报告（v6 r1）

## 审查结果
APPROVED

## 发现

### 检查覆盖度

检查报告 11 个检查项覆盖了 task_v6.md 要求的所有关键方面：
- 代码改动与回退状态（检查项 1、2）
- moon test 无回归（检查项 3）
- moon check warning 数（检查项 4）
- opt_v6.md 产出完整性 6 项（检查项 5）
- benchmark 同环境对比与数据一致性（检查项 6、7）
- 回退决策依据（检查项 8）
- 偏差处理（检查项 9）
- mbti 约束（检查项 10）
- 纯 MoonBit 约束（检查项 11）

### 方法可靠性独立验证

1. **git 状态**：独立运行 `git log -1` 确认 HEAD = `6364b65 v5 done`，`git status --short` 确认 `re/color_map.mbt` 和 `re/cset.mbt` 均未 modified（modified 的仅 _build 产物和 pdc 文档）。与检查项 1 结论一致。
2. **去重残留**：独立 `grep dedup_csets|seen : @hashmap` 无匹配，`read color_map.mbt:130-188` 确认 flatten 为 T3 后版本（含 M1 ids_buf + A1+D3 color_map HashMap，:144-148），无 D4 去重逻辑。与检查项 2 结论一致。
3. **git stash list**：独立运行确认 stash 列表为空，回退干净（检查报告未显式验证此项，但 git status 干净已足够确认代码状态）。
4. **对比表数据一致性**：独立全量验算 10 个 section 的 Δ vs T5(%) 和 Δ vs Baseline(%)，全部与 opt_v6.md §4 表格数值一致（检查报告仅抽样验算 Section 1 和 Section 8，抽样方法合理但范围偏窄）。
5. **最优值选取**：独立验算 T6 和 T5 后各 10 个 section 的最优值选取（min of 2 runs），20 个全部正确。与检查项 7 结论一致。

### 结论证据支撑

- PASSED 结论有充分证据支撑：所有 11 个检查项均通过，且经独立验证确认。
- 回退决策依据充分：Section 1 同环境 +9.76% 严重负改进，9/10 section 负改进，符合 task_v6.md "若实测无改进或负改进则回退"条件。
- 负改进归因合理：实际重复率低、去重开销高、256 倍放大未生效、与 T4 教训一致，逻辑自洽。

### 轻微遗漏（不影响结论）

- **[轻微]** 检查报告未显式验证 `git stash list` 清空：do_v6.md 称用 `git stash drop` 回退，检查报告仅用 git status 确认代码状态。独立验证确认 stash list 为空，不影响结论。
- **[轻微]** 检查报告仅抽样验算 Section 1 和 Section 8 的数据一致性，未全量验算 10 个 section：独立全量验算确认全部一致，抽样方法合理，不影响结论。
- **[轻微]** 检查报告未明确验证代码命名 snake_case 风格：代码已回退到 T3 后版本，不影响最终状态，且 opt_v6.md §2 diff 显示新增代码用 `dedup_csets`/`seen`/`found` 等 snake_case 命名。
