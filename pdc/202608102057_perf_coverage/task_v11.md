# 任务指令（v11）

## 动作
NEW

## 任务描述
执行 coverage_gap_analysis.md §4 优先级 P4（阶段二方法第 3 步"补充缺失测试"），向 `re/coverage_test.mbt` 末尾追加 3 个 test 块，覆盖 `Pcre::exec` 和 `Pcre::get_named_substring` 两个 Pcre 高级 API 的 raise 路径 + `Pcre::get_named_substring_opt` 边界条件。

### 块 1 `pcre exec no match raise`
- 构造 `let re = Pcre::regexp(sb_cov("abc"))`
- 对不匹配输入调用 `Pcre::exec(re, sb_cov("xyz"))`，断言 raise
- 覆盖 pcre.mbt:53 → core.mbt:112 `fail("Re.exec: not found")`
- 模式：`try { let _ = Pcre::exec(re, sb_cov("xyz")); false } catch { _ => true }` + `assert_eq(result, true)`

### 块 2 `pcre get_named_substring not found raise`
- 构造带命名 group 的正则 `let re = Pcre::regexp(sb_cov("(?<word>[a-z]+)"))`（Perl 命名 group 语法 `(?<name>...)`，perl.mbt:185-191）
- 匹配 `let g = Pcre::exec(re, sb_cov("hello"))` 得到 GroupT
- 用错误 name 调用 `Pcre::get_named_substring(re, "num", g)`，断言 raise
- 覆盖 pcre.mbt:179 `fail("Pcre: named group not found")`
- 模式：`try { let _ = Pcre::get_named_substring(re, "num", g); false } catch { _ => true }` + `assert_eq(result, true)`

### 块 3 `pcre get_named_substring opt boundary`
- 同块 2 正则同匹配：`let re = Pcre::regexp(sb_cov("(?<word>[a-z]+)"))` + `let g = Pcre::exec(re, sb_cov("hello"))`
- 正向断言 1：`assert_eq(Pcre::get_named_substring(re, "word", g), sb_cov("hello"))`（覆盖 pcre.mbt:172-180 Some 分支）
- 正向断言 2：`assert_eq(Pcre::get_named_substring_opt(re, "word", g), Some(sb_cov("hello")))`（覆盖 pcre.mbt:67-84 有名分支）
- 边界断言 3：`assert_eq(Pcre::get_named_substring_opt(re, "num", g), None)`（覆盖 pcre.mbt:67-84 无名分支，result 保持 None）

### 验证
- 运行 `moon test` 确认 268/268（265+3）全绿
- 运行 `moon check` 确认无新 warning（baseline 26 warnings）

### 预期产出
- `re/coverage_test.mbt` 末尾追加 3 个 test 块（行数 1078 → 约 1115）
- `do_v11.md` 测试补充报告，含：(1) 新增 test 块清单（块号/名称/覆盖 API/覆盖分支/断言数）；(2) 每个 test 块源码摘要；(3) moon test 结果；(4) moon check 结果；(5) 与 coverage_gap_analysis.md P4 的对应关系表

## 选择理由
T10（P3）已 PASSED，coverage_gap_analysis.md §4 下一优先级为 P4（高风险 × 低难度 × 高价值：Pcre 高级 API 异常路径未测，命名 group 错误处理缺失）。当前 coverage_test.mbt 仅 1 个 Pcre 测试块（:870 `pcre groups and alternation`，仅覆盖 `Pcre::pmatch` 正向），`Pcre::exec` / `Pcre::get_named_substring` / `Pcre::get_named_substring_opt` 三个 API 完全未覆盖（coverage_gap_analysis.md §2.7 pcre 模块未覆盖明细，line 257/259/260）。P4 共 3 个 test 块，每块 5-12 行，难度低（API 签名简单，raise 路径明确），风险高（Pcre 高级 API 契约），价值高（影响命名 group 提取和异常处理）。符合 task.md 阶段二重点覆盖方向 (b) 错误路径和异常处理。

## 任务上下文
- `Pcre::exec(rex : Re, s : Bytes, pos? : Int = 0) -> GroupT raise`（pcre.mbt:53-55）调用 `exec(rex, s, pos~)`（core.mbt:104-114），无匹配时 `fail("Re.exec: not found")`（core.mbt:112）
- `Pcre::get_named_substring(rex, name, s) -> Bytes raise`（pcre.mbt:172-180）调用 `get_named_substring_opt`，None 时 `fail("Pcre: named group not found")`（pcre.mbt:179）
- `Pcre::get_named_substring_opt(rex, name, s) -> Bytes?`（pcre.mbt:67-84）遍历 `rex.group_names` 匹配 name，不 raise，找到返回 `Some(Bytes)` 未找到返回 `None`
- Perl 命名 group 语法 `(?<name>...)`（perl.mbt:185-191 `ParseBuffer::accept(buf, '<')` → `perl_name` → `Ast::group(name=Some(name), r)`）
- coverage_test.mbt 辅助函数 `sb_cov`（:4 `fn sb_cov(s : String) -> Bytes`）、`bs_cov`（:13 `fn bs_cov(b : Bytes) -> String`）
- 已有 Pcre 测试 `:870 test "pcre groups and alternation"`（仅 pmatch 正向，不涉及 exec/get_named_substring）
- MoonBit try-catch 捕获 `fail` 抛出的异常（不捕获 RuntimeError）
- T10 后 265/265 全绿、moon check 26 warnings 为基线
- 约束：纯 MoonBit 无 C FFI，snake_case 命名，不修改 pkg.generated.mbti，不修改源码（仅追加测试），保持与 OCaml 上游行为一致性，保持 latin1 大小写处理，不运行 benchmark

## 已有产出上下文
- **阶段一（性能优化）已完成**：T1 基线、T2 热点分析、T3 ColorMap::flatten 哈希去重（-39.95%）、T4 位图回退、T5 cset 分治归并（-3.02%）、T6 flatten 入口去重回退、T7 merge_sequences 迭代化回退。净改进 Section 1 951ms → 504.8ms（-46.9%）
- **阶段二（测试覆盖率）进行中**：
  - T8 已 PASSED：coverage_gap_analysis.md（413 API，219 已覆盖，194 未覆盖，53.0%，§4 P1-P15 优先级排序）
  - T9 已 PASSED：P1-P2 core API 测试（match_str 四象限 + match_str_no_bounds 越界），7 块，258/258
  - T10 已 PASSED：P3 前端解析错误路径测试（Perl/Emacs/Pcre），7 块，265/265
- 当前代码状态：阶段一 T3+T5 改动保留（cset.mbt + color_map.mbt），T4/T6/T7 均已回退；阶段二 T9+T10 测试已追加（coverage_test.mbt 7 块 + frontend_test.mbt 7 块）
- 本任务延续阶段二，按 P4 追加 3 块到 coverage_test.mbt
