# 计划审查报告（v12 r1）

## 审查结果
APPROVED

## 发现
未发现严重、一般或轻微问题。独立验证要点如下：

1. **任务对齐性**：T12 执行 coverage_gap_analysis.md §4 P5，向 coverage_test.mbt 追加 4 个 test 块覆盖 `Str::match_beginning` / `Str::match_end` / `Str::matched_string` / `Str::group_beginning` 错误路径，符合 task.md 阶段二重点覆盖方向 (b) 错误路径和异常处理，是 T11（P4）PASSED 后的下一优先级。

2. **源码行号准确性**（独立读取 str.mbt / group.mbt 核对）：
   - `str_state : Ref[GroupT?]` 在 str.mbt:13 ✓
   - `Str::string_match` 在 str.mbt:58-69，匹配成功 str_state=Some 返回 true，不匹配 str_state=None 返回 false ✓
   - `Str::match_beginning` 在 str.mbt:83-88，None 时 `fail("Str: no match")`（str.mbt:86）✓
   - `Str::match_end` 在 str.mbt:91-96，None 时 `fail("Str: no match")`（str.mbt:94）✓
   - `Str::matched_string` 在 str.mbt:99-104，None 时 `fail("Str: no match")`（str.mbt:102）✓
   - `Str::group_beginning` 在 str.mbt:107-112，None 时 `fail("Str: no match")`，Some 时 `GroupT::start(m, n)` ✓
   - `GroupT::start` 在 group.mbt:38-43，越界时 `fail("Group.start: not found")`（group.mbt:41）✓
   - re.mtch 带 `^` 锚点在 str.mbt:18 ✓

3. **测试逻辑正确性**：
   - 块 1-3 先调用 `Str::string_match(re, sb_cov("xyz"), 0)` 不匹配清空 str_state，再调用目标 API 断言 raise，逻辑正确（`Str::regexp("abc")` 对 `"xyz"` 在 pos=0 因 `^` 锚点不匹配）✓
   - 块 4 先调用 `Str::string_match(re, sb_cov("abc"), 0)` 匹配成功设置 str_state=Some，再用越界 idx 5 调用 `Str::group_beginning(5)`，正则 `abc` 无捕获组仅 group 0，n=5 越界触发 `fail("Group.start: not found")` ✓
   - 全局 str_state 隔离性：每块都先调用 `Str::string_match` 重置 str_state，测试互不干扰 ✓
   - try-catch 模式与既有 `str search_forward not found`（coverage_test.mbt:888-897）一致 ✓

4. **与 coverage_gap_analysis.md P5 对应**：P5 定义为 4 块覆盖 4 个 Str API 错误路径（高风险 × 低难度 × 中价值），T12 完全对应 ✓

5. **预期数量自洽**：plan.md line 140 声明 4 块，line 141 预期 272/272（268+4），task_v12.md 同步，无块数矛盾 ✓

6. **上下文准确性**：
   - coverage_test.mbt 当前 1119 行（独立验证 `Measure-Object -Line` = 986 行内容 + 空行/注释，与 task_v12.md "1119 行（T11 后）"一致）✓
   - 已有 Str 测试 :881 `str string_match with pos` / :888 `str search_forward not found`（独立 grep 验证）✓
   - T11 后基线 268/268（do_v11.md / check_v11.md 确认）✓
   - sb_cov 辅助函数在 coverage_test.mbt:4 ✓

7. **约束遵守**：纯 MoonBit 无 C FFI、snake_case 命名、不修改 pkg.generated.mbti、不修改源码（仅追加测试）、保持 OCaml 上游行为一致性、保持 latin1 大小写处理、不运行 benchmark ✓

8. **plan.md 与 task_v12.md 一致性**：R12 NEW T12 条目（plan.md:140-143）与 task_v12.md 内容、行号引用、预期 272/272 完全一致 ✓
