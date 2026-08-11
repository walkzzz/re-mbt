# 任务指令（v18）

## 动作
NEW

## 任务描述
执行 coverage_gap_analysis.md §4 优先级 P11（阶段二方法第 3 步"补充缺失测试"），向 `re/frontend_test.mbt` 末尾追加 5 个 test 块，覆盖 `PerlOpt` 各 opt（anchored/dotall/multiline/dollar_endonly/ungreedy）对匹配行为的影响。具体：

(1) **块 1 `perl anchored opt`**——验证 Anchored opt 使模式仅从字符串起始位置匹配：
- `Perl::compile_pat(sb("hello"), opts=[PerlOpt::anchored()])` 对 "hello world" → execp=true（pos=0 匹配 "hello"）
- 对 "say hello" → execp=false（anchored 禁止从 pos=4 开始匹配）
- 对照：`Perl::compile_pat(sb("hello"))`（无 opt）对 "say hello" → execp=true（非 anchored 允许搜索）

(2) **块 2 `perl dotall opt`**——验证 Dotall opt 使 `.` 匹配任意字符包括换行：
- `Perl::compile_pat(sb("a.b"), opts=[PerlOpt::dotall()])` 对 "a\nb" → execp=true（dotall 下 . 匹配 \n）
- 对照：`Perl::compile_pat(sb("a.b"))`（无 opt）对 "a\nb" → execp=false（默认 . 不匹配 \n，= Re::notnl()）
- 对照：`Perl::compile_pat(sb("a.b"))` 对 "axb" → execp=true（. 匹配普通字符）

(3) **块 3 `perl multiline opt`**——验证 Multiline opt 使 `^`/`$` 匹配行首行尾而非字符串首尾：
- `Perl::compile_pat(sb("^abc$"), opts=[PerlOpt::multiline()])` 对 "x\nabc\ny" → execp=true（multiline 下 ^ 匹配行首、$ 匹配行尾，abc 在第二行）
- 对照：`Perl::compile_pat(sb("^abc$"))`（无 opt）对 "x\nabc\ny" → execp=false（默认 ^ = bos 字符串首、$ = eos 字符串尾）
- 对照：`Perl::compile_pat(sb("^abc$"))` 对 "abc" → execp=true（字符串首尾匹配）

(4) **块 4 `perl dollar_endonly opt`**——验证 DollarEndonly opt 使 `$` 仅匹配字符串结尾不匹配换行前：
- `Perl::compile_pat(sb("abc$"), opts=[PerlOpt::dollar_endonly()])` 对 "abc\ndef" → execp=false（dollar_endonly 下 $ = leol 仅匹配字符串结尾，abc 后是 \n 不是结尾）
- 对 "abc" → execp=true（abc 后是字符串结尾）
- 对照：`Perl::compile_pat(sb("abc$"))`（无 opt）对 "abc\ndef" → execp=true（默认 $ = eos 匹配换行前或字符串结尾）

(5) **块 5 `perl ungreedy opt`**——验证 Ungreedy opt 反转贪婪模式（`*`/`+` 变非贪婪）：
- 用 exec_opt 获取 group 验证匹配长度
- `Perl::compile_pat(sb("(a+)"), opts=[PerlOpt::ungreedy()])` 对 "aaa" → group 1 = "a"（ungreedy 下 + 非贪婪匹配最短）
- 对照：`Perl::compile_pat(sb("(a+)"))`（无 opt）对 "aaa" → group 1 = "aaa"（默认 + 贪婪匹配最长）
- 用 `match exec_opt(re, sb("aaa")) { Some(g) => assert_eq(bs(GroupT::get(g, 1).unwrap()), ...) None => assert_eq(true, false) }` 模式断言 group 内容

每块用 assert_eq 直接断言（块 1-4 用 execp 返回 Bool，块 5 用 exec_opt + GroupT::get 获取 group 内容）。

完成后运行 `moon test` 确认 303/303（298+5）全绿，运行 `moon check` 确认无新 warning。

预期产出：测试补充报告 do_v18.md（含新增 test 块清单、每个块覆盖的 API/分支、moon test 结果、moon check 结果、与 coverage_gap_analysis.md P11 的对应关系）。

## 选择理由
T17（P10）已 PASSED，coverage_gap_analysis.md §4 下一优先级为 P11（中风险 × 低难度 × 高价值：PerlOpt 各 opt 对匹配行为影响未测，影响 Perl 兼容性）。当前 frontend_test.mbt 仅 1 个 `perl caseless` 测试（:200-204）覆盖 Caseless opt，其余 5 个 opt（Anchored/Dotall/Multiline/DollarEndonly/Ungreedy）完全未测——各 opt 对 `^`/`$`/`.`/贪婪模式/匹配位置的行为影响全部未验证。P11 共 5 个 test 块，每块 5-12 行，难度低（Perl::compile_pat opts 参数简单，execp/exec_opt 已有调用示例），风险中（Perl 兼容性契约），价值高（各 opt 影响匹配语义核心行为）。符合 task.md 阶段二重点覆盖方向 (c) 各前端解析器边缘 case。

## 任务上下文
- `pub enum PerlOpt { Ungreedy; Dotall; DollarEndonly; Multiline; Anchored; Caseless }`（perl.mbt:7-14），构造函数 `PerlOpt::anchored()/dotall()/multiline()/dollar_endonly()/ungreedy()/caseless()`（:17-44）
- `pub fn Perl::compile_pat(s : Bytes, opts? : Array[PerlOpt] = []) -> Re raise`（perl.mbt:602）调用 `Perl::re`（:577-599）：
  - Anchored → `Ast::seq([Ast::start(), r])`（:589-593）加 bos 锚点
  - Dotall → perl_atom 中 `.` 返回 `Ast::any()` 而非 `Re::notnl()`（:170-174）
  - Multiline → `^` 返回 `Ast::bol()` 而非 `Ast::bos()`（:203-207）、`$` 返回 `Ast::eol()` 而非 `Ast::eos()`/`Ast::leol()`（:209-210）
  - DollarEndonly → `$` 返回 `Ast::leol()` 而非 `Ast::eos()`（:211-212）
  - Ungreedy → perl_greedy_mod 反转贪婪标志（:73-81，`*`/`+`/`?`/`{n,m}` 的 greedy 取反）
  - Caseless → `Ast::no_case(r)`（:594-598）
- execp（core.mbt:119）返回 Bool 表示是否存在匹配，exec_opt（core.mbt:89）返回 GroupT? 含 group 信息
- frontend_test.mbt 已有辅助函数 sb（包内共享自 compile_test.mbt:4）、execp/exec_opt（pub fn 自 core.mbt）、bs（pub fn 自 core_test.mbt:4）
- 已有 `perl caseless` 测试（:200-204）可参考 opts 参数用法
- T17 后 298/298 为基线，预期 303/303
- 约束：纯 MoonBit 无 C FFI，snake_case 命名，不修改 pkg.generated.mbti，不修改源码（仅追加测试），保持与 OCaml 上游行为一致性，保持 latin1 大小写处理，不运行 benchmark

## 已有产出上下文
- 阶段一性能优化已完成：T3（ColorMap::flatten 哈希去重，Section 1 -39.95%）+ T5（Cset 分治归并 + capacity 预分配，-3.02%）保留，T4/T6/T7 负改进回退，T5-skip mbti BLOCKED
- 阶段二测试覆盖率提升进度：
  - T8：coverage_gap_analysis.md（413 API，219 已覆盖，194 未覆盖，53.0%）
  - T9（P1-P2）：match_str 四象限 + match_str_no_bounds 越界（7 块，258/258）
  - T10（P3）：前端解析错误路径（7 块，265/265）
  - T11（P4）：Pcre 高级 API raise 路径（3 块，268/268）
  - T12（P5）：Str OCaml 风格 API 错误路径（4 块，272/272）
  - T13（P6）：ParseBuffer::integer 错误路径（6 块，278/278）
  - T14（P7）：Desc::initial/status/remove_duplicates（6 块，284/284）
  - T15（P8）：Expr::rename 导数正确性（4 块，288/288）
  - T16（P9）：Ast::colorize + ColorMap::split 一致性（3 块，291/291）
  - T17（P10）：cset 边界测试（7 块，298/298）
- 当前基线：moon test 298/298 全绿，moon check 26 warnings
- 剩余优先级：P11（本轮）→ P12（PcreFlag）→ P13（GroupT 越界）→ P14（Str 高级 API）→ P15（CompileIdx 内部状态）
