# 任务指令（v19）

## 动作
NEW

## 任务描述
执行 coverage_gap_analysis.md §4 优先级 P12（阶段二方法第 3 步"补充缺失测试"），向 `re/frontend_test.mbt` 末尾追加 4 个 test 块，覆盖 `PcreFlag` 各 flag（Caseless/MultilineP/AnchoredP/DotallP）对匹配行为的影响。具体：

(1) **块 1 `pcre caseless flag`**——验证 Caseless flag 使匹配大小写不敏感：`Pcre::regexp(sb("hello"), flags=[PcreFlag::Caseless()])` 对 "HELLO" → pmatch=true（caseless 下忽略大小写）；对照 `Pcre::regexp(sb("hello"))`（无 flag）对 "HELLO" → pmatch=false（默认大小写敏感）。

(2) **块 2 `pcre multiline flag`**——验证 MultilineP flag 使 `^`/`$` 匹配行首行尾：`Pcre::regexp(sb("^abc$"), flags=[PcreFlag::MultilineP()])` 对 "x\nabc\ny" → pmatch=true（multiline 下 ^ 匹配行首、$ 匹配行尾，abc 在第二行）；对照 `Pcre::regexp(sb("^abc$"))`（无 flag）对 "x\nabc\ny" → pmatch=false（默认 ^ = bos 字符串首、$ = eos 字符串尾）、对 "abc" → pmatch=true（字符串首尾匹配）。

(3) **块 3 `pcre anchored flag`**——验证 AnchoredP flag 使模式仅从字符串起始位置匹配：`Pcre::regexp(sb("hello"), flags=[PcreFlag::AnchoredP()])` 对 "hello world" → pmatch=true（pos=0 匹配 "hello"）、对 "say hello" → pmatch=false（anchored 禁止从 pos=4 开始匹配）；对照 `Pcre::regexp(sb("hello"))`（无 flag）对 "say hello" → pmatch=true（非 anchored 允许搜索）。

(4) **块 4 `pcre dotall flag`**——验证 DotallP flag 使 `.` 匹配任意字符包括换行：`Pcre::regexp(sb("a.b"), flags=[PcreFlag::DotallP()])` 对 "a\nb" → pmatch=true（dotall 下 . 匹配 \n）；对照 `Pcre::regexp(sb("a.b"))`（无 flag）对 "a\nb" → pmatch=false（默认 . 不匹配 \n）、对 "axb" → pmatch=true（. 匹配普通字符）。

每块用 `Pcre::pmatch(re, sb(...))` 返回 Bool + assert_eq 直接断言。完成后运行 `moon test` 确认 307/307（303+4）全绿，运行 `moon check` 确认无新 warning。产出测试补充报告 do_v19.md（含新增 test 块清单、每个块覆盖的 API/分支、moon test 结果、moon check 结果、与 coverage_gap_analysis.md P12 的对应关系）。

## 选择理由
T18（P11）已 PASSED，coverage_gap_analysis.md §4 下一优先级为 P12（中风险 × 低难度 × 高价值：PcreFlag 各 flag 对匹配行为影响未测，影响 Pcre 兼容性）。当前 frontend_test.mbt 中 Pcre 测试仅 `pcre basic`（:141-145 无 flag 基础匹配）+ `pcre extract`（:148-155 无 flag group 提取）+ T10 错误路径 2 块（:290/:308），4 个 PcreFlag（Caseless/MultilineP/AnchoredP/DotallP）完全未测。P12 共 4 个 test 块，每块 4-8 行，难度低（Pcre::regexp flags 参数简单，pmatch 已有调用示例），风险中（Pcre 兼容性契约），价值高（各 flag 影响匹配语义核心行为）。PcreFlag 通过 `pcre_flags_to_opts`（pcre.mbt:23-34）映射到 PerlOpt（Caseless→Caseless/MultilineP→Multiline/AnchoredP→Anchored/DotallP→Dotall），行为与对应 PerlOpt 相同，测试模式可参考 T18（P11）PerlOpt 测试但通过 Pcre::regexp flags 参数传入。符合 task.md 阶段二重点覆盖方向 (c) 各前端解析器边缘 case。

## 任务上下文
`pub enum PcreFlag { Caseless; MultilineP; AnchoredP; DotallP }`（pcre.mbt:7-12），构造函数 `PcreFlag::caseless()/multiline_p()/anchored_p()/dotall_p()`。`fn pcre_flags_to_opts(flags : Array[PcreFlag]) -> Array[PerlOpt]`（pcre.mbt:23-34）逐 flag 映射：Caseless→Caseless、MultilineP→Multiline、AnchoredP→Anchored、DotallP→Dotall。`pub fn Pcre::regexp(pat : Bytes, flags? : Array[PcreFlag] = []) -> Re raise`（pcre.mbt:42-44）调用 `Pcre::re(pat, flags~)`（:37-39）→ `Perl::re(pat, opts=pcre_flags_to_opts(flags))` → `compile`。`Pcre::pmatch`（pub fn 自 core.mbt）返回 Bool 表示是否存在匹配。frontend_test.mbt 已有辅助函数 sb（包内共享自 compile_test.mbt:4）、Pcre::regexp/pmatch 调用示例（:141-145 `pcre basic`）。T18 后 303/303 为基线，预期 307/307。约束：纯 MoonBit 无 C FFI，snake_case 命名，不修改 pkg.generated.mbti，不修改源码（仅追加测试），保持与 OCaml 上游行为一致性，保持 latin1 大小写处理，不运行 benchmark。

## 已有产出上下文
- coverage_gap_analysis.md：§4 优先级排序 P1-P15，本轮执行 P12（P1-P11 已完成）
- frontend_test.mbt：当前含 T18 后 5 个 PerlOpt test 块（:319-366）+ T10 错误路径 2 块 + 原有正向测试，Pcre 相关测试在 :141-155（basic/extract）+ :290/:308（错误路径）
- do_v18.md / check_v18.md：T18 执行 + 检查报告，moon test 303/303 全绿，moon check 26 warnings baseline
- baseline.md：251/251 测试基线（性能优化前），当前累计 303 个测试
