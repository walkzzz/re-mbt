# 执行报告（v10）

## 概述

执行 coverage_gap_analysis.md §4 优先级 P3（阶段二方法第 3 步"补充缺失测试"），向 `re/frontend_test.mbt` 末尾追加 7 个 test 块，覆盖 Perl/Emacs/Pcre 三个前端解析器的错误路径（解析非法模式时 raise 行为）。此前 frontend_test.mbt 26 个 test 块全部为正向测试，0 个错误路径测试；追加后为 33 块，总测试数 265。

## 产出清单

| 操作 | 文件路径 | 说明 |
|------|---------|------|
| 修改 | `re/frontend_test.mbt` | 末尾追加 7 个 test 块（Perl 3 + Emacs 2 + Pcre 2），行数 204 → 322 |

## 执行过程

### 1. 基线确认

- `moon test`：258/258 全绿（T9 后状态）
- `moon check`：26 warnings, 0 errors（baseline）

### 2. 源码错误路径核实

逐条查阅任务指令引用的源码行号，确认 raise 行为真实存在：

| 前端 | 错误模式 | 源码位置 | raise 信息 | 核实结果 |
|------|---------|---------|-----------|---------|
| Perl | 未闭合 `(` | perl.mbt:180,189,198 | `fail("Perl parse error")` | `perl_atom` 中 `(` 后调用 `perl_regexp` 再检查 `)`，未闭合则 fail |
| Perl | 末尾反斜杠 | perl.mbt:223-224 | `fail("Perl parse error")` | `\\` 后 `ParseBuffer::eos(buf)` 为真则 fail |
| Perl | `\8`/`\9` | perl.mbt:274 | `fail("Perl not supported: \\8 or \\9")` | `c == '8' \|\| c == '9'` 分支 |
| Perl | 未闭合 `[` | perl.mbt:439 + perl_char_elem:480-481 | `fail("Perl parse error")` | `perl_bracket` 递归调用 `perl_char_elem`，eos 时 fail |
| Emacs | 未闭合 `\(` | emacs.mbt:91 | `fail("Emacs parse error")` | `\(` 后 `emacs_regexp` 再检查 `emacs_close_group`，未闭合则 fail |
| Emacs | 末尾反斜杠 | emacs.mbt:113-114,177 | `fail("Emacs parse error")` | `\\` 后进入 else 分支，`eos` 时 fail；或 `emacs_char` eos 时 fail |
| Pcre | 未闭合 `(` | pcre.mbt:37-42 → perl.mbt | Perl 解析错误向上传播 | `Pcre::regexp` → `Pcre::re` → `Perl::re`，Perl fail 向上抛 |
| Pcre | `\8` | pcre.mbt:39 → perl.mbt:274 | `fail("Perl not supported: \\8 or \\9")` | 同 Perl 路径 |

### 3. try-catch 断言模式确认

参考 coverage_test.mbt:736-744 `test "exec raises on no match"` 已验证的模式：
```moonbit
let raised = try {
  let _ = <call>
  false
} catch {
  _ => true
}
assert_eq(raised, true)
```
MoonBit try-catch 捕获 `fail` 抛出的异常（解析错误均为 `fail`，可捕获）。

### 4. 新增 test 块清单

| 块号 | test 块名 | 覆盖 API | 覆盖错误路径 | 测试调用数 |
|------|----------|---------|-------------|-----------|
| 1 | `perl unclosed paren raise` | `Perl::compile_pat` | 未闭合 `(`（perl.mbt:180,189,198） | 2 |
| 2 | `perl invalid escape raise` | `Perl::compile_pat` | 末尾反斜杠（:223-224）+ `\8`（:274） | 2 |
| 3 | `perl unclosed bracket raise` | `Perl::compile_pat` | 未闭合 `[`（perl_char_elem:480-481） | 2 |
| 4 | `emacs unclosed paren raise` | `Emacs::compile_pat` | 未闭合 `\(`（emacs.mbt:91） | 2 |
| 5 | `emacs invalid escape raise` | `Emacs::compile_pat` | 末尾反斜杠（:113-114,177） | 1 |
| 6 | `pcre unclosed paren raise` | `Pcre::regexp` | 未闭合 `(`（Perl 错误传播） | 2 |
| 7 | `pcre invalid escape raise` | `Pcre::regexp` | `\8`（Perl 错误传播） | 1 |

合计 7 块，12 个 try-catch 断言。

### 5. 新增 test 块源码摘要

```moonbit
test "perl unclosed paren raise" {
  // Perl::compile_pat(sb("("))  → raise (perl.mbt:198)
  // Perl::compile_pat(sb("(abc")) → raise (perl.mbt:198)
  let r1 = try { let _ = Perl::compile_pat(sb("(")); false } catch { _ => true }
  assert_eq(r1, true)
  let r2 = try { let _ = Perl::compile_pat(sb("(abc")); false } catch { _ => true }
  assert_eq(r2, true)
}

test "perl invalid escape raise" {
  // Perl::compile_pat(sb("\\"))  → raise (perl.mbt:224, 末尾反斜杠)
  // Perl::compile_pat(sb("\\8")) → raise (perl.mbt:274, \8 不支持)
  let r1 = try { let _ = Perl::compile_pat(sb("\\")); false } catch { _ => true }
  assert_eq(r1, true)
  let r2 = try { let _ = Perl::compile_pat(sb("\\8")); false } catch { _ => true }
  assert_eq(r2, true)
}

test "perl unclosed bracket raise" {
  // Perl::compile_pat(sb("["))    → raise (perl_char_elem:481, eos)
  // Perl::compile_pat(sb("[abc")) → raise (perl_char_elem:481, eos)
  let r1 = try { let _ = Perl::compile_pat(sb("[")); false } catch { _ => true }
  assert_eq(r1, true)
  let r2 = try { let _ = Perl::compile_pat(sb("[abc")); false } catch { _ => true }
  assert_eq(r2, true)
}

test "emacs unclosed paren raise" {
  // Emacs::compile_pat(sb("\\("))   → raise (emacs.mbt:91, 未闭合 \()
  // Emacs::compile_pat(sb("\\(abc")) → raise (emacs.mbt:91)
  let r1 = try { let _ = Emacs::compile_pat(sb("\\(")); false } catch { _ => true }
  assert_eq(r1, true)
  let r2 = try { let _ = Emacs::compile_pat(sb("\\(abc")); false } catch { _ => true }
  assert_eq(r2, true)
}

test "emacs invalid escape raise" {
  // Emacs::compile_pat(sb("\\")) → raise (emacs.mbt:114/177, 末尾反斜杠)
  let r1 = try { let _ = Emacs::compile_pat(sb("\\")); false } catch { _ => true }
  assert_eq(r1, true)
}

test "pcre unclosed paren raise" {
  // Pcre::regexp(sb("("))   → raise (Perl 错误传播, pcre.mbt:39 → perl.mbt:198)
  // Pcre::regexp(sb("(abc")) → raise (同上)
  let r1 = try { let _ = Pcre::regexp(sb("(")); false } catch { _ => true }
  assert_eq(r1, true)
  let r2 = try { let _ = Pcre::regexp(sb("(abc")); false } catch { _ => true }
  assert_eq(r2, true)
}

test "pcre invalid escape raise" {
  // Pcre::regexp(sb("\\8")) → raise (Perl 错误传播, pcre.mbt:39 → perl.mbt:274)
  let r1 = try { let _ = Pcre::regexp(sb("\\8")); false } catch { _ => true }
  assert_eq(r1, true)
}
```

### 6. 验证结果

| 验证项 | 预期 | 实际 | 结果 |
|--------|------|------|------|
| `moon test` | 265/265 全绿 | 265/265 全绿 | ✅ |
| `moon check` warnings | 26（baseline） | 26 | ✅ 无新 warning |
| `moon check` errors | 0 | 0 | ✅ |
| `re/pkg.generated.mbti` | 未修改 | 未修改（git status 仅 frontend_test.mbt） | ✅ |
| 源码修改 | 仅追加测试 | 仅 frontend_test.mbt 追加 | ✅ |
| benchmark | 未运行 | 未运行 | ✅ |

### 7. 与 coverage_gap_analysis.md P3 对应关系

coverage_gap_analysis.md §4 P3 描述：
> Perl/Emacs/Pcre 解析错误路径（未闭合括号、非法转义、非法字符类），frontend_test.mbt 追加，6-8 块，高风险 × 中难度 × 高价值

本任务取 7 块（Perl 3 + Emacs 2 + Pcre 2），落在 P3 建议的 6-8 块范围内：

| P3 描述的错误路径 | 本任务覆盖 |
|------------------|-----------|
| Perl 未闭合括号 | 块 1 `perl unclosed paren raise` |
| Perl 非法转义 | 块 2 `perl invalid escape raise`（末尾反斜杠 + `\8`） |
| Perl 非法字符类 | 块 3 `perl unclosed bracket raise`（未闭合 `[`） |
| Emacs 未闭合括号 | 块 4 `emacs unclosed paren raise`（未闭合 `\(`） |
| Emacs 非法转义 | 块 5 `emacs invalid escape raise`（末尾反斜杠） |
| Pcre 未闭合括号 | 块 6 `pcre unclosed paren raise` |
| Pcre 非法转义 | 块 7 `pcre invalid escape raise`（`\8`） |

对应 §3.2 分支覆盖缺口表（perl.mbt/emacs.mbt/pcre.mbt "非法语法"行）和 §2.9 Emacs/Perl `re` 函数"错误路径"行。

## 偏差说明

无。严格按任务指令执行：7 个 test 块（Perl 3 + Emacs 2 + Pcre 2），统一 try-catch 断言模式，仅追加到 frontend_test.mbt 末尾，未修改源码、未修改 mbti、未运行 benchmark。
