# 检查审查报告（v7 r1）

## 审查结果
APPROVED

## 发现

### 独立验证项（实跑复核）

- **[验证通过]** `git diff HEAD --stat -- re/ast.mbt` 无输出，re/ast.mbt 与 HEAD 完全一致（0 diff），证实回退到位。
- **[验证通过]** `git stash list` 无输出，无 stash 残留。
- **[验证通过]** `moon test` 实跑：Total tests: 251, passed: 251, failed: 0，与 check_v7.md/opt_v7.md §3 声称一致。
- **[验证通过]** `moon check` 实跑：26 warnings, 0 errors，与 do_v7.md/opt_v7.md §6.3 声称一致。
- **[验证通过]** `git log -1`：HEAD = e64ec542 "v6 done"，与 do_v7.md/opt_v7.md §6.6 声称的 HEAD e64ec54 一致。

### benchmark 数据复核

- **[验证通过]** T7 原始 2 次数据逐 section 取最小 = T7 最优，计算正确（如 Section 1: min(544.0, 526.4)=526.4，Section 10: min(28.3, 25.4)=25.4，全 10 section 复核无误）。
- **[验证通过]** T5 后原始 2 次数据逐 section 取最小 = T5 后最优，计算正确（如 Section 2: min(41.3, 37.8)=37.8，Section 7: min(183.0, 181.0)=181.0，全 10 section 复核无误）。
- **[验证通过]** Δ vs T5(ms) 计算正确（如 Section 1: 526.4-522.2=+4.2，Section 5: 212.2-218.8=-6.6）。
- **[验证通过]** Δ vs T5(%) 计算正确（如 Section 1: 4.2/522.2*100=+0.80%，Section 6: 9.6/128.1*100=+7.50%）。
- **[验证通过]** Δ vs Baseline(%) 计算正确（如 Section 1: (526.4-951.0)/951.0*100=-44.67%，Section 5: (212.2-347.4)/347.4*100=-38.92%）。
- **[验证通过]** 正改进 section 4 个（3/4/5/9），范围 -0.76% ~ -3.01% 正确；负改进 section 6 个（1/2/6/7/8/10），范围 +0.77% ~ +7.50% 正确。与 do_v7.md §3/opt_v7.md §4 声称一致。

### 检查覆盖度评估

- **[覆盖充分]** task_v7.md 要求的 6 项产出（§1-§6）均已检查。
- **[覆盖充分]** task_v7.md 要求的回退分支（"若实测无改进或负改进则 git checkout re/ast.mbt 回退改动并标注原因"）已检查：Section 1 +0.80% 负改进触发回退，re/ast.mbt 0 diff 证实回退到位，opt_v7.md §5.1/§6.6 标注原因。
- **[覆盖充分]** task_v7.md 要求的同环境 benchmark 方法（T7 vs T5 后，各 2 次取最优，git stash 切换）已检查：opt_v7.md §4 附原始 4 次运行数据，do_v7.md §3 描述 git stash 切换方法，git stash list 无残留。
- **[覆盖充分]** task_v7.md 要求的约束（纯 MoonBit、不改 mbti、snake_case、pub fn 签名不改、保持语义、latin1）已检查：opt_v7.md §6.4/§6.5 说明，moon test 251/251 实证语义等价。
- **[覆盖充分]** 负改进归因完整：opt_v7.md §5.2 含 6 条归因 + §5.4 迭代化方案根本限制分析，do_v7.md 偏差 2 记录递归点 2 保留递归的设计决策权衡。

### 轻微问题（不影响结论）

- **[轻微]** opt_v7.md §4 表述歧义：先说"每 section 3 次取最优"，又说"T7 版本 2 次取最优 vs T5 后版本 2 次取最优"。实际是 bench 脚本内部每 section 3 次取最优、外层 T7/T5 后各 2 次取最优，表述不清晰。原始 4 次运行数据证实外层 2 次取最优，数据正确。
- **[轻微]** do_v7.md §4 "working tree clean" 表述不严谨：实际 working tree 有 _build 构建产物修改和 pdc 工作文件新增，但 re/ast.mbt 0 diff 实质回退到位。构建产物和 PDC 文件不影响回退结论。
- **[轻微]** Checker 未实跑 `git diff HEAD -- re/pkg.generated.mbti` 验证 mbti 不变。但 re/ast.mbt 已回退到 HEAD，mbti 自然不变，且 opt_v7.md §6.5 说明改的是内部 fn 不暴露 mbti，遗漏影响小。

## 修改要求（仅 REJECTED 时）
无
