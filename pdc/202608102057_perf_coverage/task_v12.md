# 任务指令（v12）

## 动作
NEW

## 任务描述
执行 coverage_gap_analysis.md §4 优先级 P5（阶段二方法第 3 步"补充缺失测试"），向 `re/coverage_test.mbt` 末尾追加 4 个 test 块，覆盖 `Str::match_beginning` / `Str::match_end` / `Str::matched_string` / `Str::group_beginning` 四个 Str OCaml 风格 API 的错误路径。具体：

**(1) 块 1 `str match_beginning no match raise`**——先构造 `Str::regexp(sb_cov("abc"))`，调用 `Str::string_match(re, sb_cov("xyz"), 0)`（不匹配，返回 false，并将全局 `str_state.val` 置为 None），再调用 `Str::match_beginning()`，断言 raise（str.mbt:83-88 `fail("Str: no match")`）。

**(2) 块 2 `str match_end no match raise`**——同上先清空 str_state，再调用 `Str::match_end()`，断言 raise（str.mbt:91-96 `fail("Str: no match")`）。

**(3) 块 3 `str matched_string no match raise`**——同上先清空 str_state，再调用 `Str::matched_string(sb_cov("xyz"))`，断言 raise（str.mbt:99-104 `fail("Str: no match")`）。

**(4) 块 4 `str group_beginning out of bounds raise`**——先构造 `Str::regexp(sb_cov("abc"))`，调用 `Str::string_match(re, sb_cov("abc"), 0)`（匹配成功，返回 true，str_state = Some(GroupT)），再用越界 group idx `5` 调用 `Str::group_beginning(5)`，断言 raise（str.mbt:107-112 → `GroupT::start(m, 5)` → group.mbt:38-43 `fail("Group.start: not found")`，正则 `abc` 无捕获组，仅 group 0 存在，n=5 越界）。

块 1-4 均用 `try { <call>; false } catch { _ => true }` + `assert_eq(result, true)` 模式断言 raise。

完成后运行 `moon test` 确认 272/272（268+4）全绿，运行 `moon check` 确认无新 warning（baseline 26 warnings）。产出测试补充报告 do_v12.md（含新增 test 块清单、每个块覆盖的 API/分支、moon test 结果、moon check 结果、与 coverage_gap_analysis.md P5 的对应关系）。

## 选择理由
T11（P4）已 PASSED，coverage_gap_analysis.md §4 下一优先级为 P5（高风险 × 低难度 × 中价值：Str OCaml 风格 API 错误路径全缺）。当前 coverage_test.mbt 仅有 2 个 Str 测试块（:881 `str string_match with pos` 正向、:888 `str search_forward not found` raise），`Str::match_beginning` / `Str::match_end` / `Str::matched_string` / `Str::group_beginning` 四个 API 的 `str_state = None` raise 路径和 `group_beginning` 越界 raise 路径完全未覆盖（coverage_gap_analysis.md §3.5 core API None/异常返回路径 + §2 Str 模块未覆盖明细）。P5 共 4 个 test 块，每块 6-10 行，难度低（API 签名简单，raise 路径明确，str_state 全局状态可通过先调用不匹配的 string_match 清空），风险高（Str 前端 OCaml 兼容性契约），价值中（Str 前端错误处理）。符合 task.md 阶段二重点覆盖方向 (b) 错误路径和异常处理。

## 任务上下文
- `str_state : Ref[GroupT?]`（str.mbt:13）为全局可变状态，初始 None，由 `Str::string_match` / `Str::search_forward` 设置。
- `Str::string_match(re, s, p)`（str.mbt:58-69）：匹配成功 str_state = Some(res) 返回 true；不匹配 str_state = None 返回 false。re.mtch 带 `^` 锚点（str.mbt:18 `compile(Ast::seq([Ast::start(), re]))`），故 `Str::regexp("abc")` 对 `"xyz"` 在 pos=0 不匹配。
- `Str::match_beginning()`（str.mbt:83-88）：str_state = None 时 `fail("Str: no match")`，Some 时 `GroupT::start(m, 0)`。
- `Str::match_end()`（str.mbt:91-96）：str_state = None 时 `fail("Str: no match")`，Some 时 `GroupT::stop(m, 0)`。
- `Str::matched_string(_txt)`（str.mbt:99-104）：str_state = None 时 `fail("Str: no match")`，Some 时 `GroupT::get(m, 0).unwrap()`。
- `Str::group_beginning(n)`（str.mbt:107-112）：str_state = None 时 `fail("Str: no match")`，Some 时 `GroupT::start(m, n)`；n 越界时 `GroupT::start` → `GroupT::start_opt` → `GroupT::offset_opt` → `MarkInfos::offset(g.marks, n)` 返回 None → `fail("Group.start: not found")`（group.mbt:38-43）。
- coverage_test.mbt 辅助函数 `sb_cov`（:4 String→Bytes）。已有 Str 测试：:881 `str string_match with pos`（正向）、:888 `str search_forward not found`（search_forward raise）。T11 后 268/268 为基线。
- 约束：纯 MoonBit 无 C FFI，snake_case 命名，不修改 pkg.generated.mbti，不修改源码（仅追加测试），保持与 OCaml 上游行为一致性，保持 latin1 大小写处理，不运行 benchmark。

## 已有产出上下文
- 阶段一性能优化已完成（T1-T7），Section 1 951ms → 504.8ms（-46.9%，T3+T5 累计），T4/T6/T7 负改进回退，T5-skip mbti BLOCKED。
- 阶段二覆盖率提升进行中：T8 产出 coverage_gap_analysis.md（413 API，194 未覆盖，P1-P15 优先级）；T9 完成 P1-P2（match_str 四象限 + match_str_no_bounds 越界，7 块，258/258）；T10 完成 P3（Perl/Emacs/Pcre 解析错误路径，7 块，265/265）；T11 完成 P4（Pcre 高级 API raise 路径，3 块，268/268）。
- 当前测试基线：268/268 全绿，moon check 26 warnings（baseline 一致）。
- coverage_test.mbt 当前 1119 行（T11 后）。
