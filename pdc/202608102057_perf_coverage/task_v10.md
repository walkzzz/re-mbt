# 任务指令（v10）

## 动作
NEW

## 任务描述

执行 coverage_gap_analysis.md §4 优先级 P3（阶段二方法第 3 步"补充缺失测试"），向 `re/frontend_test.mbt` 追加 7 个 test 块，覆盖 Perl/Emacs/Pcre 三个前端解析器的错误路径（解析非法模式时 raise 行为）。当前 frontend_test.mbt 26 个 test 块全部是正向测试，0 个错误路径测试。

### Perl 错误路径（3 块）

**块 1 `perl unclosed paren raise`**：验证未闭合括号 raise "Perl parse error"
- `Perl::compile_pat(sb("("))` 应 raise
- `Perl::compile_pat(sb("(abc"))` 应 raise
- 断言模式：`try { Perl::compile_pat(sb("(")); false } catch { _ => true }` → assert_eq(result, true)
- 依据：perl.mbt:175-200 `perl_atom` 中 `(` 后调用 `perl_regexp` 再检查 `)`，未闭合则 `fail("Perl parse error")`（:180, :189, :198）

**块 2 `perl invalid escape raise`**：验证非法转义 raise
- `Perl::compile_pat(sb("\\"))` 应 raise（末尾反斜杠，perl.mbt:223-224 `if ParseBuffer::eos(buf) { fail("Perl parse error") }`）
- `Perl::compile_pat(sb("\\8"))` 应 raise（perl.mbt:274 `fail("Perl not supported: \\8 or \\9")`）

**块 3 `perl unclosed bracket raise`**：验证未闭合字符类 raise "Perl parse error"
- `Perl::compile_pat(sb("["))` 应 raise
- `Perl::compile_pat(sb("[abc"))` 应 raise
- 依据：perl.mbt:216 `perl_atom` 中 `[` 进入 `perl_bracket`（:439），未闭合 `]` 时 fail

### Emacs 错误路径（2 块）

**块 4 `emacs unclosed paren raise`**：验证未闭合分组 raise "Emacs parse error"
- `Emacs::compile_pat(sb("\\("))` 应 raise（Emacs 用 `\(` `\)` 表示分组，emacs.mbt:91 `fail("Emacs parse error")`）
- `Emacs::compile_pat(sb("\\(abc"))` 应 raise

**块 5 `emacs invalid escape raise`**：验证非法转义 raise "Emacs parse error"
- `Emacs::compile_pat(sb("\\"))` 应 raise（末尾反斜杠，emacs.mbt:177 `fail("Emacs parse error")`）

### Pcre 错误路径（2 块）

**块 6 `pcre unclosed paren raise`**：验证未闭合括号 raise（Pcre 底层调用 Perl 解析器）
- `Pcre::regexp(sb("("))` 应 raise
- `Pcre::regexp(sb("(abc"))` 应 raise
- 依据：pcre.mbt:37-42 `Pcre::re` / `Pcre::regexp` 调用 `Perl::re`（pcre.mbt:39），Perl 解析错误向上传播

**块 7 `pcre invalid escape raise`**：验证非法转义 raise
- `Pcre::regexp(sb("\\8"))` 应 raise（Perl 不支持 `\8`/`\9`，perl.mbt:274）

### 断言模式

统一使用 `try { <parse call>; false } catch { _ => true }` 模式断言 raise，`assert_eq(result, true)`。MoonBit try-catch 捕获 `fail` 抛出的异常（不捕获 RuntimeError，但解析错误是 `fail` 异常可捕获）。

### 预期产出

- `re/frontend_test.mbt` 追加 7 个 test 块（Perl 3 块 + Emacs 2 块 + Pcre 2 块）
- `pdc/202608102057_perf_coverage/do_v10.md` 测试补充报告，含：
  - 新增 test 块清单（块名 + 覆盖的 API/分支）
  - 每个 test 块源码摘要
  - `moon test` 结果（预期 265/265 全绿）
  - `moon check` 结果（预期无新 warning，baseline 26 warnings）
  - 与 coverage_gap_analysis.md P3 的对应关系

### 验证标准

- `moon test` 265/265 全绿（258 原有 + 7 新增）
- `moon check` 无新 warning（baseline 26 warnings）
- 新增 test 块确实覆盖 Perl/Emacs/Pcre 三前端的未闭合括号、非法转义、未闭合字符类错误路径
- 不修改 `re/pkg.generated.mbti`
- 不修改任何源码（仅追加测试到 frontend_test.mbt）
- 不运行 benchmark

## 选择理由

T9（P1-P2）已 PASSED（258/258 全绿），coverage_gap_analysis.md §4 下一优先级为 P3（高风险 × 中难度 × 高价值：各前端解析器错误路径全缺，用户输入非法模式时行为未验证）。当前 frontend_test.mbt 26 个 test 块全部是正向测试（合法模式匹配验证），0 个错误路径测试——解析器遇到非法模式时的 raise 行为完全未覆盖。

P3 共 7 个 test 块（Perl 3 + Emacs 2 + Pcre 2），每块 5-10 行，难度中（需识别各前端的非法模式并确认 raise 行为），风险高（解析器鲁棒性契约），价值高（影响用户输入验证）。符合 task.md 阶段二重点覆盖方向 (b) 错误路径和异常处理 + (c) 各前端解析器边缘 case。

## 任务上下文

### 目标 API 签名与实现

- **`Perl::compile_pat`**（perl.mbt:602）：
  ```
  pub fn Perl::compile_pat(s : Bytes, opts? : Array[PerlOpt] = []) -> Re raise
  ```
  通过 `fail("Perl parse error")` / `fail("Perl not supported: ...")` 抛出异常。错误路径：未闭合 `(`（:180, :189, :198）、末尾反斜杠（:223-224）、`\8`/`\9`（:274）、未闭合 `[`（perl_bracket :439）。

- **`Emacs::compile_pat`**（emacs.mbt:211）：
  ```
  pub fn Emacs::compile_pat(s : Bytes, case? : Bool = true) -> Re raise
  ```
  通过 `fail("Emacs parse error")` / `fail("Emacs not supported: ...")` 抛出。Emacs 用 `\(` `\)` 表示分组（非 `(` `)`）。错误路径：未闭合 `\(`（:91）、末尾反斜杠（:177）。

- **`Pcre::regexp`**（pcre.mbt:42）：
  ```
  pub fn Pcre::regexp(pat : Bytes, flags? : Array[PcreFlag] = []) -> Re raise
  ```
  底层调用 `Perl::re`（pcre.mbt:39），Perl 解析错误向上传播。

### 测试文件辅助函数与模式

- `re/frontend_test.mbt` 当前 26 个 test 块（perl 12 + emacs 2 + posix 2 + glob 3 + pcre 2 + str 3 + perl opts 2），全部正向测试
- 辅助函数 `sb`（compile_test.mbt:4 `fn sb(s : String) -> Bytes`）包内共享，frontend_test.mbt 已使用
- 已有调用示例：`Perl::compile_pat(sb("hello"))`（:5）、`Emacs::compile_pat(sb("hello"))`（:89）、`Pcre::regexp(sb("hello"))`（:142）
- 建议插入位置：frontend_test.mbt 末尾（:204 之后）
- 建议新增 test 块命名前缀：`perl`/`emacs`/`pcre` + 错误描述，与现有命名风格一致

### MoonBit try-catch 语义

- `try { <body>; <no_raise_value> } catch { _ => <raise_value> }` 捕获 `fail` 抛出的异常
- 不捕获 RuntimeError（如数组越界），但解析错误是 `fail` 异常可捕获
- 参考 coverage_test.mbt:736-744 `test "exec raises on no match"` 已验证此模式可行

### 约束

- 纯 MoonBit 无 C FFI
- snake_case 命名（test 块名、变量名）
- 不修改 `re/pkg.generated.mbti`
- 不修改任何源码（仅追加测试到 frontend_test.mbt）
- 保持与 OCaml 上游行为一致性
- 保持 latin1 大小写处理
- 不运行 benchmark

## 已有产出上下文

- **baseline.md**：测试基线 251/251 通过（0.21s），10 个 section benchmark 基线（性能优化后 Section 1 = 504.8ms）
- **coverage_gap_analysis.md**（T8 产出，417 行）：§4 优先级排序 P1-P15，本任务对应 P3。P3 = Perl/Emacs/Pcre 解析错误路径（6-8 块），本任务取 7 块（Perl 3 + Emacs 2 + Pcre 2）
- **plan.md**：T1-T9 均已 PASSED，T9 完成 P1-P2（258/258 全绿），本任务 T10 为 P3
- 当前代码状态：T5 后版本（性能优化净改进 Section 1 -46.9%），T9 追加 7 块到 coverage_test.mbt（258/258）
- re/frontend_test.mbt 当前 26 个 test 块（204 行），本任务追加 7 块后为 33 块，总测试数 265
