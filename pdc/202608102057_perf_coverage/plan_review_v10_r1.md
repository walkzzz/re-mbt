# 计划审查报告（v10 r1）

## 审查结果
APPROVED

## 发现

- **[轻微]** task_v10.md 多处声称 "当前 frontend_test.mbt 26 个 test 块"（line 8、99、127），但实测 frontend_test.mbt 仅 25 个 test 块。分类 "perl 12 + emacs 2 + posix 2 + glob 3 + pcre 2 + str 3 + perl opts 2 = 26" 有误：实际 perl 相关 13 块（basic match / alternation / groups / star / plus / char class / char class range / escaped chars / digit class / word boundary / non-greedy / {n,m} / caseless），其中仅 caseless 使用 opts，"perl opts 2" 应为 1，合计 25。此偏差不影响目标（265/265 = 258 + 7，由总测试数推算，与 frontend_test.mbt 块数无关），但 "追加 7 块后为 33 块" 实际应为 32 块。Doer 读取文件时即可发现实际数量，不影响执行。

- **[轻微]** task_v10.md line 34 引用 "emacs.mbt:177 `fail("Emacs parse error")`" 作为末尾反斜杠 fail 位置，但实际主解析器中末尾反斜杠的 fail 位于 emacs.mbt:114（`\\` accept 后 else 分支内 eos 检查）。emacs.mbt:177 的 fail 位于 `emacs_char` 函数（用于 bracket 解析），非主解析器路径。行为描述正确（Emacs 确实对末尾反斜杠 fail "Emacs parse error"），仅行号引用偏差。

- **[轻微]** task_v10.md line 41 引用 "pcre.mbt:39" 为 `Perl::re` 调用位置，实际 `Perl::re(pat, opts=...)` 位于 pcre.mbt:38（line 39 是函数闭合 `}`）。off-by-one，不影响理解。

## 验证摘要

- **任务对齐**：T10 对应 coverage_gap_analysis.md §4 P3（前端解析器错误路径），承接 T9（P1-P2 已 PASSED 258/258），符合 task.md 阶段二方法第 3 步"补充缺失测试"及重点覆盖方向 (b) 错误路径 + (c) 前端边缘 case。✓
- **目标算术**：258 + 7 = 265，与验证标准一致。✓
- **技术可行性**：`sb` 辅助函数位于 compile_test.mbt:4（同包共享），frontend_test.mbt 已有 17 处 `sb(...)` 调用先例。try-catch 模式 `try { ...; false } catch { _ => true }` 捕获 `fail` 异常，所有引用的错误路径均使用 `fail(...)`（perl.mbt:180/189/198/224/274/481、emacs.mbt:91/114、pcre 经 Perl 传播），可捕获。✓
- **错误路径行号核验**：perl.mbt:175-200 未闭合 `(` fail ✓、perl.mbt:223-224 末尾反斜杠 fail ✓、perl.mbt:274 `\8`/`\9` fail ✓、perl.mbt:480-481 `perl_char_elem` eos fail（未闭合 `[` 经此路径）✓、emacs.mbt:91 未闭合 `\(` fail ✓、pcre.mbt:37-43 Pcre→Perl 传播 ✓。
- **约束遵守**：纯 MoonBit 无 C FFI ✓、snake_case 命名 ✓、不修改 mbti ✓、不修改源码（仅追加测试）✓、不运行 benchmark ✓。
- **T9 衔接**：do_v9.md / check_v9.md 确认 258/258 全绿、26 warnings，T10 以此为基线。✓
