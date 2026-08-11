# 执行报告（v21）

## 概述
执行 coverage_gap_analysis.md §4 优先级 P14，向 `re/frontend_test.mbt` 末尾追加 6 个 test 块，覆盖 `Str::global_replace` / `Str::replace_first` / `Str::full_split` / `Str::bounded_split` / `Str::quote` / `Str::regexp_case_fold` 六个 Str 高级 API。测试从 311 增至 317，全绿，无新 warning。

## 产出清单
| 操作 | 文件路径 | 说明 |
|------|---------|------|
| 修改 | re/frontend_test.mbt | 末尾追加 6 个 test 块（块 1-6），覆盖 Str 高级 API |

## 执行过程

### 基线确认
运行 `moon test` 确认基线 311/311 全绿，与任务上下文一致。

### 源码分析
阅读 `re/str.mbt` 确认 6 个 API 的行为契约：
- `Str::global_replace`（:149-189）：`_repl` 未使用，循环 exec_opt 匹配，匹配文本原样 push 到 result，最终 == text。
- `Str::replace_first`（:192-217）：`_repl` 未使用，匹配文本原样放回 == text；None 分支返回 text。
- `Str::full_split`（:270-307）：返回 `Array[StrSplitResult]`，StrText/StrDelim 交替。
- `Str::bounded_split`（:225-261）：num=0 无限制（n 从 0 递减，n != 1 恒真，等同 split）；num>0 最多分 num 段（n 递减至 1 时退出循环，剩余文本作为最后一段）。
- `Str::quote`（:32-50）：对 9 个特殊字符（ASCII 91/93/42/46/92/63/43/94/36）前加反斜杠 92。
- `Str::regexp_case_fold`（:27-29）：调用 compile_regexp(e, true) 大小写不敏感。

### 测试编写
参考已有 Str 测试（frontend_test.mbt:158 `str basic match` / :165 `str search` / :172 `str split`）的代码风格，使用包内共享辅助函数 `sb`（compile_test.mbt:4）和 `bs`（core_test.mbt:4），追加 6 个 test 块：

**块 1 `str global_replace returns original`**（frontend_test.mbt:404-408）
- 覆盖 API：`Str::global_replace`，分支：匹配分支（循环 push matched）+ 不匹配分支（None push 剩余文本）
- 测试：re=regexp("o"), repl="X", text="foo bar boo" → 断言 == "foo bar boo"（_repl 未用，原文本不变）；text="xyz" → 断言 == "xyz"（不匹配）

**块 2 `str replace_first returns original`**（frontend_test.mbt:411-415）
- 覆盖 API：`Str::replace_first`，分支：Some 分支（push matched）+ None 分支（返回 text）
- 测试：re=regexp("o"), repl="X", text="foo" → 断言 == "foo"；text="xyz" → 断言 == "xyz"

**块 3 `str full_split text and delim`**（frontend_test.mbt:418-439）
- 覆盖 API：`Str::full_split`，分支：pos > cur（push StrText）+ end_pos == pos（空匹配跳过）+ None（push 最后 StrText）
- 测试：re=regexp(","), text="a,b,c" → 断言 length == 5，用 match pattern 逐元素断言 variant 类型 + 内容：[StrText("a"), StrDelim(","), StrText("b"), StrDelim(","), StrText("c")]

**块 4 `str bounded_split limit`**（frontend_test.mbt:442-455）
- 覆盖 API：`Str::bounded_split`，分支：num=0 无限制 + num>0 限制段数 + end_pos > cur（push 段）+ None（break）
- 测试：re=regexp(","), text="a,b,c,d" → bounded_split(re, text, 0) == ["a","b","c","d"]（4 段）；bounded_split(re, text, 2) == ["a","b,c,d"]（2 段，首个分隔符前 + 剩余）

**块 5 `str quote special chars`**（frontend_test.mbt:458-463）
- 覆盖 API：`Str::quote`，分支：9 个特殊字符转义 + 普通字符不变
- 测试：assert "a.b" → "a\.b"（. 转义）；"[*]" → "\[\*\]"（三个特殊字符均转义）；"normal" → "normal"（无特殊字符不变）；"?+$^" → "\?\+\$\^"（四个特殊字符均转义）

**块 6 `str regexp_case_fold case insensitive`**（frontend_test.mbt:466-470）
- 覆盖 API：`Str::regexp_case_fold`，分支：case_fold=true（大小写不敏感）+ 对照 case_fold=false（默认大小写敏感）
- 测试：re=regexp_case_fold("hello") → string_match("HELLO world", 0) == true；re2=regexp("hello") → string_match("HELLO world", 0) == false

### 验证
- `moon test`：Total tests: 317, passed: 317, failed: 0.（311 + 6 = 317，全绿）
- `moon check`：22 warnings, 0 errors（与基线一致，无新 warning 引入）

### 与 coverage_gap_analysis.md P14 的对应关系
P14（中风险 × 低难度 × 中价值：Str 高级 API 6 个未覆盖，OCaml 兼容性需要）的 6 个 API 全部覆盖：
| P14 API | 对应 test 块 | 覆盖分支 |
|---------|-------------|---------|
| Str::global_replace | 块 1 | 匹配 + 不匹配 |
| Str::replace_first | 块 2 | Some + None |
| Str::full_split | 块 3 | StrText/StrDelim 交替序列 |
| Str::bounded_split | 块 4 | num=0 无限制 + num>0 限制 |
| Str::quote | 块 5 | 9 个特殊字符转义 + 普通字符不变 |
| Str::regexp_case_fold | 块 6 | case_fold=true + 对照 false |

## 偏差说明
无。严格按 task_v21.md 要求追加 6 个 test 块，测试命名、断言方式（assert_eq + match pattern）、辅助函数（sb/bs）均与已有 Str 测试风格一致，未修改源码，未修改 pkg.generated.mbti，保持纯 MoonBit 无 C FFI，保持 snake_case 命名。
