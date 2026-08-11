# 执行报告（v18）

## 概述
执行 coverage_gap_analysis.md §4 优先级 P11，向 `re/frontend_test.mbt` 末尾追加 5 个 test 块，覆盖 `PerlOpt` 各 opt（Anchored/Dotall/Multiline/DollarEndonly/Ungreedy）对匹配行为的影响。完成后 moon test 303/303 全绿，moon check 26 warnings（与基线一致，无新 warning）。

## 产出清单
| 操作 | 文件路径 | 说明 |
|------|---------|------|
| 修改 | re/frontend_test.mbt | 末尾追加 5 个 test 块（perl anchored/dotall/multiline/dollar_endonly/ungreedy opt） |

## 执行过程

### 1. 前置确认
- 阅读 perl.mbt:7-44 确认 `PerlOpt` 枚举与构造函数签名（`anchored()/dotall()/multiline()/dollar_endonly()/ungreedy()/caseless()`）
- 阅读 perl.mbt:577-604 确认 `Perl::compile_pat(s : Bytes, opts? : Array[PerlOpt] = [])` 调用 `Perl::re`，各 opt 映射：
  - Anchored → `Ast::seq([Ast::start(), r])`（:589-593）
  - Dotall → perl_atom 中 `.` 返回 `Ast::any()` 而非 `Re::notnl()`（:170-174）
  - Multiline → `^` 返回 `Ast::bol()`、`$` 返回 `Ast::eol()`（:203-210）
  - DollarEndonly → `$` 返回 `Ast::leol()`（:211-212）
  - Ungreedy → perl_greedy_mod 反转贪婪标志（:73-81）
- 阅读 core.mbt:89-121 确认 `exec_opt` 返回 `GroupT?`、`execp` 返回 `Bool`
- 确认辅助函数 `sb`（compile_test.mbt:4 包内共享）、`bs`（core_test.mbt:4 包内共享）、`GroupT::get`（compile.mbt:629 pub fn）可用
- 运行 moon test 确认基线 298/298

### 2. 五个 test 块实现

**块 1 `perl anchored opt`**（frontend_test.mbt:319-324）：
- `Perl::compile_pat(sb("hello"), opts=[PerlOpt::anchored()])` 对 "hello world" → execp=true（pos=0 匹配 "hello"）
- 对 "say hello" → execp=false（anchored 加 bos 锚点，禁止从 pos=4 开始匹配）
- 对照：`Perl::compile_pat(sb("hello"))` 对 "say hello" → execp=true（非 anchored 允许搜索）
- 覆盖：perl.mbt:589-593 Anchored 分支 → Ast::start() 锚点行为

**块 2 `perl dotall opt`**（frontend_test.mbt:326-331）：
- `Perl::compile_pat(sb("a.b"), opts=[PerlOpt::dotall()])` 对 "a\nb" → execp=true（dotall 下 . = Ast::any() 匹配 \n）
- 对照：`Perl::compile_pat(sb("a.b"))` 对 "a\nb" → execp=false（默认 . = Re::notnl() 不匹配 \n）
- 对照：对 "axb" → execp=true（. 匹配普通字符）
- 覆盖：perl.mbt:170-174 Dotall 分支 → Ast::any() vs Re::notnl()

**块 3 `perl multiline opt`**（frontend_test.mbt:333-338）：
- `Perl::compile_pat(sb("^abc$"), opts=[PerlOpt::multiline()])` 对 "x\nabc\ny" → execp=true（multiline 下 ^ = Ast::bol() 匹配行首、$ = Ast::eol() 匹配行尾，abc 在第二行）
- 对照：`Perl::compile_pat(sb("^abc$"))` 对 "x\nabc\ny" → execp=false（默认 ^ = Ast::bos() 字符串首、$ = Ast::eos() 字符串尾）
- 对照：对 "abc" → execp=true（字符串首尾匹配）
- 覆盖：perl.mbt:203-210 Multiline 分支 → Ast::bol()/Ast::eol() vs Ast::bos()/Ast::eos()

**块 4 `perl dollar_endonly opt`**（frontend_test.mbt:340-345）：
- `Perl::compile_pat(sb("abc$"), opts=[PerlOpt::dollar_endonly()])` 对 "abc\n" → execp=true（dollar_endonly 下 $ = Ast::leol() 匹配最后一个换行前或字符串结尾）
- 对 "abc" → execp=true（abc 后是字符串结尾）
- 对照：`Perl::compile_pat(sb("abc$"))` 对 "abc\n" → execp=false（默认 $ = Ast::eos() 仅匹配字符串结尾，abc 后是 \n 不是结尾）
- 覆盖：perl.mbt:211-212 DollarEndonly 分支 → Ast::leol() vs Ast::eos()
- **注意**：测试输入与任务描述不同（用 "abc\n" 而非 "abc\ndef"），详见偏差说明

**块 5 `perl ungreedy opt`**（frontend_test.mbt:347-357）：
- `Perl::compile_pat(sb("(a+)"), opts=[PerlOpt::ungreedy()])` 对 "aaa" → group 1 = "a"（ungreedy 下 + 非贪婪匹配最短）
- 对照：`Perl::compile_pat(sb("(a+)"))` 对 "aaa" → group 1 = "aaa"（默认 + 贪婪匹配最长）
- 用 `exec_opt` + `GroupT::get(g, 1).unwrap()` + `bs()` 获取 group 内容断言
- 覆盖：perl.mbt:73-81 perl_greedy_mod ungreedy 反转逻辑

### 3. 验证
- `moon test`：303/303 全绿（298 基线 + 5 新增）
- `moon check`：26 warnings，0 errors（与基线一致，无新 warning）

### 4. 与 coverage_gap_analysis.md P11 对应关系
P11 要求覆盖 PerlOpt 各 opt 对匹配行为影响。此前仅 `perl caseless`（:200-204）覆盖 Caseless，其余 5 个 opt 完全未测。本轮 5 个 test 块逐一覆盖 Anchored/Dotall/Multiline/DollarEndonly/Ungreedy 对 `^`/`$`/`.`/贪婪模式/匹配位置的行为影响，填补 P11 全部缺口。

## 偏差说明
**块 4 测试输入与任务描述不同**。任务描述指定用 "abc\ndef" 作为测试输入，期望默认 `$`（eos）对 "abc\ndef" → execp=true（认为 eos 匹配换行前或字符串结尾）、dollar_endonly `$`（leol）对 "abc\ndef" → execp=false（认为 leol 仅匹配字符串结尾）。

经查阅代码实现（compile_translate.mbt:173-178），实际语义与任务描述相反：
- `EndOfStr`（eos）= `Expr::before(ctx.ids, Category::inexistant())` → **仅匹配字符串结尾**
- `LastEndOfLine`（leol）= `Expr::before(ctx.ids, Category::add(Category::inexistant(), Category::lastnewline()))` → **匹配字符串结尾或最后一个换行前**

且根据 compile.mbt:450-465 `get_color`，`re.lnl`（lastnewline 颜色）仅在字符串最后一个字符为 `\n` 时生效。因此对 "abc\ndef"（最后一个字符是 'f'），leol 退化为 eos，两者行为相同（都 false），无法区分。

为使测试具有区分度且符合代码实际行为，将块 4 测试输入改为 "abc\n"（最后一个字符是 \n）：
- dollar_endonly（leol）对 "abc\n" → true（leol 匹配最后一个换行前）
- 默认（eos）对 "abc\n" → false（eos 仅匹配字符串结尾）

此调整符合 OCaml re 上游语义（eos = end of string 仅字符串结尾，leol = last end of line 字符串结尾或最后换行前），且与本移植的代码实现一致。依据 doer.md "独立判断，不盲从审查" 原则，以代码实际行为为准。
