# 任务指令（v13）

## 动作
NEW

## 任务描述
执行 coverage_gap_analysis.md §4 优先级 P6（阶段二方法第 3 步"补充缺失测试"），新增 `re/parse_buffer_test.mbt` 测试文件，写入 6 个 test 块覆盖 `ParseBuffer::integer` 全分支 + `ParseBuffer::eos` 边界 + `ParseBuffer::create` 基本行为。

### 文件结构
- 新增 `re/parse_buffer_test.mbt`
- 文件头注释：`// parse_buffer_test.mbt — tests for ParseBuffer pub APIs`
- 辅助函数 `fn sb(s : String) -> Bytes`（与 compile_test.mbt:4 / coverage_test.mbt:4 sb_cov 风格一致，String→Bytes 转换）

### 6 个 test 块

**块 1 `parse_buffer create and eos boundary`**
- `ParseBuffer::create(sb(""))` → `eos` == true
- `ParseBuffer::create(sb("abc"))` → `eos` == false
- 对 `"abc"` 的 buffer 调用 `junk` 3 次后 `eos` == true（pos 从 0→3==length）
- 覆盖：create（parse_buffer.mbt:12-14）、eos（:27-29）、junk（:22-24）

**块 2 `parse_buffer integer normal digits`**
- `ParseBuffer::create(sb("123"))` 调用 `integer` → `Some(123)`
- 覆盖：integer 数字分支（:101-103）→ integer_aux 累积（:83-88）

**块 3 `parse_buffer integer empty returns None`**
- `ParseBuffer::create(sb(""))` 调用 `integer` → `None`
- 覆盖：integer eos 分支（:98-99）

**块 4 `parse_buffer integer non-digit first returns None`**
- `ParseBuffer::create(sb("abc"))` 调用 `integer` → `None`
- 断言 pos 经 unget 恢复为 0（非数字首字符 unget 回退）
- 覆盖：integer 非数字首字符分支（:104-106，unget + None）

**块 5 `parse_buffer integer digits then non-digit stops`**
- `ParseBuffer::create(sb("123abc"))` 调用 `integer` → `Some(123)`
- 覆盖：integer_aux 非数字停止分支（:89-92，unget + Some）

**块 6 `parse_buffer integer overflow raise`**
- `ParseBuffer::create(sb("99999999999999999999"))`（20 位 9，远超 Int32 最大 2147483647）调用 `integer` 触发 `fail("Parse_buffer.Parse_error: integer overflow")`
- 用 `try { ParseBuffer::integer(buf); false } catch { _ => true }` + `assert_eq(result, true)` 断言 raise
- 覆盖：integer_aux 溢出分支（:85-86）

### 偏差说明（与 coverage_gap_analysis.md P6 描述的差异）

1. **`ParseBuffer::get` at eos 无法直接测试**：`get`（parse_buffer.mbt:53-57）在 eos 时访问 `t.str[t.pos]`（pos == length）触发数组越界 RuntimeError。MoonBit try-catch 不捕获 RuntimeError（参考 T9/do_v9.md 偏差 1 教训：pos<0 和 pos+len>slen 时 match_str_no_bounds 产生不可捕获 RuntimeError）。改为通过块 1 `eos` 边界测试间接保护（确保调用 get 前可检查 eos），不在块中直接调用 get at eos。

2. **P6 描述"非数字 raise"与源码不符**：源码 parse_buffer.mbt:104-106 显示非数字首字符时 `unget` + 返回 `None`（不 raise）。仅溢出（integer_aux:85-86）才 `fail`。按 source-of-truth 源码修正：块 4 测试非数字返回 None（不 raise），块 6 测试溢出 raise。

### 预期产出
- 新增 `re/parse_buffer_test.mbt`（约 50-60 行）
- `moon test` 278/278 全绿（272+6）
- `moon check` 26 warnings（baseline 一致，无新 warning）
- 产出 `do_v13.md`（含新增 test 块清单、每个块覆盖的 API/分支、moon test 结果、moon check 结果、与 coverage_gap_analysis.md P6 的对应关系、偏差说明）

## 选择理由
T12（P5）已 PASSED，coverage_gap_analysis.md §4 下一优先级为 P6（高风险 × 低难度 × 中价值：ParseBuffer 解析基础设施错误路径全缺，影响所有前端解析器鲁棒性）。当前 ParseBuffer 10 个 pub API 全未直接测试（coverage_gap_analysis.md §1 ParseBuffer 0% 覆盖，§2.6 明细 10 项未覆盖，§3.1/§3.2 错误路径缺口含 integer 非数字 + get at eos）。P6 共 6 个 test 块，每块 4-8 行，难度低（API 签名简单，integer 分支明确），风险高（解析基础设施鲁棒性契约），价值中（影响所有前端解析器）。新增 parse_buffer_test.mbt 符合现有测试文件组织风格（basics_test/ast_test/automata_test/color_map_test/compile_test/core_test/coverage_test/frontend_test/view_test 均按模块组织），MoonBit 测试文件以 `_test.mbt` 结尾自动识别无需修改 moon.pkg。符合 task.md 阶段二重点覆盖方向 (b) 错误路径和异常处理 + (a) 核心模块边界条件。

## 任务上下文
- `parse_buffer.mbt:12` `pub fn ParseBuffer::create(str : Bytes) -> ParseBuffer`（pos=0）
- `:17` `unget`（pos-=1，pos=0 时变 -1 不 raise）
- `:22` `junk`（pos+=1）
- `:27` `eos`（pos==length）
- `:32` `peek`（!eos && str[pos]==c）
- `:37` `peek2`（pos+1<length && str[pos]==c && str[pos+1]==c2）
- `:44` `accept`（peek 成功则 pos+=1 返回 true）
- `:53` `get`（r=str[pos], pos+=1, unsafe_to_char，eos 时越界 RuntimeError）
- `:60` `accept_s`（匹配 s 则 pos+=len 返回 true）
- `:78` `integer_aux`（:85-86 `if i2 < i { fail("Parse_buffer.Parse_error: integer overflow") }`）
- `:97` `pub fn ParseBuffer::integer(t : ParseBuffer) -> Int? raise`
  - `:98-99` eos → None
  - `:101-103` 首字符数字 → integer_aux 累积
  - `:104-106` 首字符非数字 → unget + None
- MoonBit Int 为 32 位有符号，最大 2147483647，"99999999999999999999"（20 位 9）必触发 i2 < i 溢出检测
- T12 后 272/272 为基线（check_v12.md 确认）
- 约束：纯 MoonBit 无 C FFI，snake_case 命名，不修改 pkg.generated.mbti，不修改源码（仅新增测试文件），保持与 OCaml 上游行为一致性，保持 latin1 大小写处理，不运行 benchmark

## 已有产出上下文
- **baseline.md**：251/251 测试基线 + 10 section benchmark 基线（Section 1=951ms）
- **hotspot_analysis.md**：compile 路径 12 个热点函数 + 优化方向建议
- **coverage_gap_analysis.md**：413 pub API，219 已覆盖，194 未覆盖，53.0%；§4 优先级 P1-P15
- **opt_v3.md**：T3 ColorMap::flatten 哈希去重 + ids 复用，Section 1 -39.95%
- **opt_v5.md**：T5 union_all/intersect_all 分治归并 + capacity 预分配，Section 1 -3.02%（T3+T5 累计 -46.9%）
- **opt_v4.md / opt_v6.md / opt_v7.md**：T4/T6/T7 负改进回退记录
- **do_v9.md / do_v10.md / do_v11.md / do_v12.md**：P1-P5 测试补充报告
- **当前测试状态**：272/272 全绿（251 baseline + 7 P1-P2 + 7 P3 + 3 P4 + 4 P5），moon check 26 warnings
- **当前代码状态**：T3 后版本（color_map.mbt）+ T5 后版本（cset.mbt），working tree clean（T4/T6/T7 已回退）
- **已完成优先级**：P1（match_str 四象限）、P2（match_str_no_bounds 越界）、P3（前端解析错误路径）、P4（Pcre 高级 API raise）、P5（Str OCaml 风格 API 错误路径）
- **下一优先级**：P6（ParseBuffer::integer 错误路径 + eos 边界）
