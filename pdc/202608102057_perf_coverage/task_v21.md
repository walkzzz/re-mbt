# 任务指令（v21）

## 动作
NEW

## 任务描述
执行 coverage_gap_analysis.md §4 优先级 P14（阶段二方法第 3 步"补充缺失测试"），向 `re/frontend_test.mbt` 末尾追加 6 个 test 块，覆盖 `Str::global_replace` / `Str::replace_first` / `Str::full_split` / `Str::bounded_split` / `Str::quote` / `Str::regexp_case_fold` 六个 Str 高级 API。

具体要求：

(1) **块 1 `str global_replace returns original`**——验证 `Str::global_replace` 的实际行为：`_repl` 参数未使用（str.mbt:151 下划线前缀），匹配文本原样放回结果（:173-176 push matched），故 global_replace(re, repl, text) == text。测试：re = Str::regexp(sb("o"))，text = sb("foo bar boo")，repl = sb("X")，断言 `bs(Str::global_replace(re, repl, text)) == "foo bar boo"`（原文本不变）；再测不匹配场景 text = sb("xyz")，断言 == "xyz"。

(2) **块 2 `str replace_first returns original`**——验证 `Str::replace_first` 的实际行为：同样 `_repl` 未使用（:194），匹配文本原样放回（:206-209），故 replace_first(re, repl, text) == text。测试：re = Str::regexp(sb("o"))，text = sb("foo")，repl = sb("X")，断言 `bs(Str::replace_first(re, repl, text)) == "foo"`；再测不匹配 text = sb("xyz")，断言 == "xyz"（None 分支返回原 text）。

(3) **块 3 `str full_split text and delim`**——验证 `Str::full_split` 返回 StrText/StrDelim 交替序列。测试：re = Str::regexp(sb(","))，text = sb("a,b,c")，full_split 返回 [StrText("a"), StrDelim(","), StrText("b"), StrDelim(","), StrText("c")]。断言 result.length() == 5，用 match 逐元素断言 variant 类型 + 内容：match result[0] { StrText(t) => assert_eq(bs(t), "a") ... }。

(4) **块 4 `str bounded_split limit`**——验证 `Str::bounded_split` 的 count 限制行为。测试：re = Str::regexp(sb(","))，text = sb("a,b,c,d")。bounded_split(re, text, 0) == split == ["a","b","c","d"]（4 段，0 = 无限制）；bounded_split(re, text, 2) == ["a","b,c,d"]（2 段，首个分隔符前 + 剩余）。断言 length 和各段内容。

(5) **块 5 `str quote special chars`**——验证 `Str::quote` 转义 9 个特殊字符 `[ ] * . \ ? + ^ $`（str.mbt:36-44，ASCII 91/93/42/46/92/63/43/94/36 前加反斜杠 92）。测试：断言 `bs(Str::quote(sb("a.b"))) == "a\\.b"`（. 前加 \）；断言 `bs(Str::quote(sb("[*]"))) == "\\[\\*\\]"`（三个特殊字符均转义）；断言 `bs(Str::quote(sb("normal"))) == "normal"`（无特殊字符不变）；断言 `bs(Str::quote(sb("?+$^"))) == "\\?\\+\\$\\^"`（四个特殊字符均转义）。

(6) **块 6 `str regexp_case_fold case insensitive`**——验证 `Str::regexp_case_fold` 大小写不敏感匹配。测试：re = Str::regexp_case_fold(sb("hello"))，断言 `Str::string_match(re, sb("HELLO world"), 0) == true`（case_fold 下忽略大小写）；对照 re2 = Str::regexp(sb("hello"))，断言 `Str::string_match(re2, sb("HELLO world"), 0) == false`（默认大小写敏感）。

每块用 assert_eq 直接断言（块 3 用 match pattern 断言 StrSplitResult variant）。

完成后运行 `moon test` 确认 317/317（311+6）全绿，运行 `moon check` 确认无新 warning。

预期产出：测试补充报告 do_v21.md（含新增 test 块清单、每个块覆盖的 API/分支、moon test 结果、moon check 结果、与 coverage_gap_analysis.md P14 的对应关系）。

## 选择理由
T20（P13）已 PASSED，coverage_gap_analysis.md §4 下一优先级为 P14（中风险 × 低难度 × 中价值：Str 高级 API 6 个未覆盖，OCaml 兼容性需要）。当前 frontend_test.mbt 中 Str 测试仅 3 块（:158 `str basic match` 正向、:165 `str search` 正向、:172 `str split` 正向），`Str::global_replace` / `replace_first` / `full_split` / `bounded_split` / `quote` / `regexp_case_fold` 六个高级 API 完全未测。P14 共 6 个 test 块，每块 5-12 行，难度低（Str API 签名简单，已有 sb/bs 辅助函数和 Str::regexp/string_match 调用示例），风险中（Str 前端 OCaml 兼容性契约），价值中（Str 高级 API 完整性）。符合 task.md 阶段二重点覆盖方向 (c) 各前端解析器边缘 case。P14 难度（低）低于 P15（中），先做 P14。

## 任务上下文
- `Str::global_replace`（str.mbt:149-189）签名 `pub fn Str::global_replace(re : StrRegexp, _repl : Bytes, text : Bytes) -> Bytes raise`，`_repl` 未使用，循环 exec_opt 匹配，匹配文本原样 push 到 result，最终 == text。
- `Str::replace_first`（:192-217）同理，`_repl` 未使用，匹配文本原样放回 == text，None 分支返回 text。
- `Str::full_split`（:270-307）返回 `Array[StrSplitResult]`，StrText（匹配间文本）/ StrDelim（匹配文本）交替。
- `Str::bounded_split`（:225-261）签名 `pub fn Str::bounded_split(re, text, num : Int) -> Array[Bytes] raise`，num=0 无限制（= split），num>0 最多分 num 段。
- `Str::quote`（:32-50）对 9 个特殊字符（91/93/42/46/92/63/43/94/36）前加反斜杠 92。
- `Str::regexp_case_fold`（:27-29）调用 compile_regexp(e, true) 大小写不敏感。
- `pub enum StrSplitResult { StrText(Bytes); StrDelim(Bytes) }`（:264-267），同包内可 match pattern。
- frontend_test.mbt 已有辅助函数 sb（包内共享自 compile_test.mbt:4）、bs（包内共享自 core_test.mbt:4），已有 Str 测试 :158/:165/:172 可参考。
- T20 后 311/311 为基线，预期 317/317。
- 约束：纯 MoonBit 无 C FFI，snake_case 命名，不修改 pkg.generated.mbti，不修改源码（仅追加测试），保持与 OCaml 上游行为一致性，保持 latin1 大小写处理，不运行 benchmark。

## 已有产出上下文
- 阶段一性能优化已完成：T3（ColorMap::flatten 哈希去重，Section 1 -39.95%）+ T5（Cset 分治归并，-3.02%），T4/T6/T7 负改进回退，T5-skip mbti BLOCKED。净改进 Section 1 951ms → 504.8ms（-46.9%）。
- 阶段二测试覆盖率：T8 产出 coverage_gap_analysis.md（413 API，219 已覆盖，194 未覆盖，53.0%），T9-T20 完成 P1-P13 测试补充（251 → 311 测试，全绿）。
- 当前测试基线：moon test 311/311 全绿，moon check 22 warnings 0 errors。
- coverage_gap_analysis.md §4 优先级排序：P1-P13 已完成，P14（Str 高级 API，本任务）和 P15（CompileIdx 三态 + StateHashTable）待做。
