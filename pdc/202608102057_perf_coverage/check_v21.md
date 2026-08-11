# 检查报告（v21）

## 结果
PASSED

## 检查项
| 检查项 | 方法 | 结果 |
|--------|------|------|
| 6 个 test 块已追加到 frontend_test.mbt 末尾 | 读取 frontend_test.mbt:403-476 | 通过：块 1-6 依次位于 :404-409/:411-417/:419-444/:446-460/:462-468/:470-476 |
| 块 1 `str global_replace returns original` 内容 | 对比 task_v21.md §(1) 要求 | 通过：re=regexp("o"), repl="X", text="foo bar boo" → == "foo bar boo"；text="xyz" → == "xyz"（:404-409） |
| 块 2 `str replace_first returns original` 内容 | 对比 task_v21.md §(2) 要求 | 通过：re=regexp("o"), repl="X", text="foo" → == "foo"；text="xyz" → == "xyz"（:411-417） |
| 块 3 `str full_split text and delim` 内容 | 对比 task_v21.md §(3) 要求 | 通过：re=regexp(","), text="a,b,c" → length==5，match pattern 逐元素断言 [StrText("a"),StrDelim(","),StrText("b"),StrDelim(","),StrText("c")]（:419-444） |
| 块 4 `str bounded_split limit` 内容 | 对比 task_v21.md §(4) 要求 | 通过：re=regexp(","), text="a,b,c,d"，bounded_split(,0)==["a","b","c","d"]（4 段），bounded_split(,2)==["a","b,c,d"]（2 段）（:446-460） |
| 块 5 `str quote special chars` 内容 | 对比 task_v21.md §(5) 要求 | 通过：4 条断言 "a.b"→"a\.b"、"[*]"→"\[\*\]"、"normal"→"normal"、"?+$^"→"\?\+\$\^"（:462-468） |
| 块 6 `str regexp_case_fold case insensitive` 内容 | 对比 task_v21.md §(6) 要求 | 通过：re=regexp_case_fold("hello") → string_match("HELLO world",0)==true；re2=regexp("hello") → string_match("HELLO world",0)==false（:470-476） |
| 测试数量 311 → 317 | 运行 `moon test` | 通过：Total tests: 317, passed: 317, failed: 0（311+6=317，全绿） |
| 无新 warning 引入 | 运行 `moon check` | 通过：22 warnings, 0 errors，与基线一致（全部为既有的 struct_never_constructed / unused_value / unused_constructor warning，未涉及 frontend_test.mbt） |
| 未修改源码 | 对比 str.mbt 源码行号 | 通过：do_v21.md 引用的 str.mbt:149-189/:192-217/:270-307/:225-261/:32-50/:27-29 与实际源码一致，源码未动 |
| 纯 MoonBit 无 C FFI / snake_case 命名 | 视察新增测试代码 | 通过：仅使用 Str::regexp / sb / bs / assert_eq / match pattern，命名 snake_case |
| 辅助函数 sb/bs 复用 | 确认 sb/bs 为包内共享 | 通过：与已有 Str 测试 :158/:165/:172 风格一致 |

## 总结
Doer 严格按 task_v21.md 要求向 re/frontend_test.mbt 末尾追加 6 个 test 块，覆盖 P14 的 6 个 Str 高级 API（global_replace / replace_first / full_split / bounded_split / quote / regexp_case_fold）。每块断言内容与任务指令 §(1)-(6) 完全一致，使用 match pattern 断言 StrSplitResult variant（块 3）。`moon test` 317/317 全绿（311+6），`moon check` 22 warnings 0 errors 与基线一致无新 warning。未修改源码、未修改 pkg.generated.mbti，保持纯 MoonBit 无 C FFI 和 snake_case 命名。产出满足任务全部要求。
