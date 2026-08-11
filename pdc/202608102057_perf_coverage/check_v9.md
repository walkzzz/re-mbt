# 检查报告（v9）

## 结果
PASSED

## 检查项

| 检查项 | 方法 | 结果 |
|--------|------|------|
| moon test 258/258 全绿 | 运行 `moon test` | 通过 — `Total tests: 258, passed: 258, failed: 0.`（251 原有 + 7 新增） |
| moon check 无新 warning | 运行 `moon check` 对比 baseline 26 | 通过 — `Finished. moon: ran 1 task, now up to date (26 warnings, 0 errors)`，与 baseline 一致 |
| 追加 7 个 test 块 | 读取 `re/coverage_test.mbt` 末尾（:956-1078）并计数 | 通过 — 7 个 test 块：P1 4 块（match_str 四象限）+ P2 3 块（越界对照） |
| P1 四象限覆盖完整 | 检查 (groups × partial) 四种组合均存在 | 通过 — 块 1 (true,false) 命中/不命中；块 2 (false,false) 命中/不命中；块 3 (true,true) 部分/完整；块 4 (false,true) 部分/完整 |
| P1 断言区分 MatchInfo/FailedInfo/RunningInfo variant | 读取块 1-4 源码 | 通过 — 每块用 match 三分支断言预期 variant 类型，不断言 GroupT 内部 marks（符合 task_v9.md 差异说明） |
| P2 越界对照断言合并入块内 | 读取块 5-7 源码 | 通过 — 块 5/7 内含 match_str raise 对照断言；块 6 内含 match_str_no_bounds 直接调用 + match_str raise 对照断言；无独立第 8 块 |
| 不修改 pkg.generated.mbti | `git status` 检查 | 通过 — `re/pkg.generated.mbti` 未出现在 modified 列表 |
| 不修改任何源码 | `git diff --stat` 检查 re/ 目录 | 通过 — re/ 下仅 `coverage_test.mbt` 被修改（+123 行），其余源码未动 |
| 不运行 benchmark | 检查 do_v9.md 执行过程 | 通过 — 执行过程仅 moon test / moon check，无 bench 调用 |
| snake_case 命名 | 检查 test 块名与变量名 | 通过 — 块名如 `match_str groups=true partial=false`、变量 `bounds_raise` 等均 snake_case |
| 偏差 1 事实性验证 | 读取 compile.mbt:317-323 next_state + :652-687 make_match_str | 通过 — next_state 访问 `s[pos]`（:323），pos<0 或 pos>=slen 时 RuntimeError；make_match_str 中 `last=pos+len`（:662），len<-1 时 last<pos 循环不执行（不 raise），pos<0 或 pos+len>slen 时循环越界（RuntimeError 不可 try-catch 捕获）。Doer 偏差说明与源码行为一致 |
| 偏差 2 事实性验证 | 确认 match_str_no_bounds 签名 `-> MatchInfo`（不 raise） | 通过 — compile.mbt:699 签名无 `raise`，try-catch 包裹会触发 unused_try warning，Doer 改用直接调用避免 warning，语义等效 |

## 总结

所有硬性验证标准均满足：moon test 258/258 全绿、moon check 26 warnings（baseline 一致）、7 个 test 块追加到 coverage_test.mbt 末尾、pkg.generated.mbti 未修改、源码未修改、未运行 benchmark。

P1（match_str 四象限）完全按 task_v9.md 要求实现，4 块覆盖 (groups × partial) 四种组合，断言区分 MatchInfo/FailedInfo/RunningInfo variant 类型。

P2（match_str_no_bounds 越界）存在 2 处偏差，均经事实性验证确认合理：
1. **偏差 1**：块 5/7 仅验证 match_str raise，未验证 match_str_no_bounds 不 raise。源码分析确认 match_str_no_bounds 对 pos<0 和 pos+len>slen 会产生不可捕获的 RuntimeError（next_state 访问 `s[pos]` 越界），task_v9.md 前提"不 raise"与实际行为不符。Doer 遵循"禁止凭假设产出"原则以源码行为为准，在报告中如实说明。
2. **偏差 2**：块 6 用直接调用替代 try-catch 验证不 raise。因 match_str_no_bounds 声明 `-> MatchInfo`（不 raise），try-catch 包裹触发 unused_try warning（27 warnings，违反"无新 warning"标准）。直接调用成功即证明不产生错误，语义等效。

两处偏差均基于源码事实约束，非任意选择，且为满足硬性标准（258/258、26 warnings）的必要调整。do_v9.md 偏差说明充分披露依据与理由。r1 修订已纠正块 5/7 命名（原含 `match_str_no_bounds` 误导，现命名准确反映"仅验证 match_str raise"语义）。
