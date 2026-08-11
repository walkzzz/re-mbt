# 检查报告（v11）

## 结果
PASSED

## 检查项
| 检查项 | 方法 | 结果 |
|--------|------|------|
| 3 个 test 块已追加到 coverage_test.mbt 末尾 | 读取 re/coverage_test.mbt:1079-1119 | 通过：文件末尾含 `pcre exec no match raise`、`pcre get_named_substring not found raise`、`pcre get_named_substring opt boundary` 三个 test 块 |
| 块 1 `pcre exec no match raise` 符合规格 | 对比 task_v11.md §块1 与 coverage_test.mbt:1083-1093 | 通过：`Pcre::regexp(sb_cov("abc"))` + `Pcre::exec(re, sb_cov("xyz"))` + try-catch + `assert_eq(result, true)` 完全一致 |
| 块 2 `pcre get_named_substring not found raise` 符合规格 | 对比 task_v11.md §块2 与 coverage_test.mbt:1096-1107 | 通过：`Pcre::regexp(sb_cov("(?<word>[a-z]+)"))` + `Pcre::exec(re, sb_cov("hello"))` + `Pcre::get_named_substring(re, "num", g)` + try-catch + `assert_eq(result, true)` 完全一致 |
| 块 3 `pcre get_named_substring opt boundary` 符合规格 | 对比 task_v11.md §块3 与 coverage_test.mbt:1110-1119 | 通过：三条 assert_eq 分别覆盖 `get_named_substring` 命中、`get_named_substring_opt` 命中 Some、`get_named_substring_opt` 未命中 None，与规格一致 |
| moon test 全绿 | 运行 `moon test` | 通过：`Total tests: 268, passed: 268, failed: 0.`（265+3=268，符合预期） |
| moon check 无新 warning | 运行 `moon check` | 通过：`26 warnings, 0 errors`，与 baseline 26 warnings 一致 |
| 仅修改 coverage_test.mbt | `git status --short` + `git diff --stat HEAD re/coverage_test.mbt` | 通过：仅 `re/coverage_test.mbt` 被修改（+41 行），其他源码文件未修改，符合"不修改源码"约束 |
| do_v11.md 报告内容完整 | 阅读 do_v11.md | 通过：含 (1) 新增 test 块清单（块号/名称/覆盖 API/覆盖分支/断言数）；(2) 各 test 块源码摘要；(3) moon test 结果；(4) moon check 结果；(5) 与 coverage_gap_analysis.md P4 对应关系表 |
| 纯 MoonBit 无 C FFI | 检查新增代码 | 通过：仅使用 Pcre 公开 API + sb_cov 辅助函数，无 FFI 引入 |
| snake_case 命名 | 检查新增代码 | 通过：test 块名称使用空格分隔小写单词（与既有约定一致），无新标识符引入 |

## 总结
Doer 严格按 task_v11.md 规格 向 coverage_test.mbt 末尾追加 3 个 test 块，覆盖 `Pcre::exec` raise 路径（core.mbt:112）、`Pcre::get_named_substring` raise 路径（pcre.mbt:179）、`Pcre::get_named_substring_opt` 命中/未命中边界（pcre.mbt:67-84、172-180）。moon test 268/268 全绿，moon check 26 warnings 基线保持，仅修改 coverage_test.mbt 未触及源码。do_v11.md 报告内容完整，与 P4 要求一一对应。行数小偏差（do 报告 1112 行 vs 实际 1119 行）属非功能性记录偏差，不影响任务完成。
