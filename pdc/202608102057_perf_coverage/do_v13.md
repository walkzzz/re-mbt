# 执行报告（v13）

## 概述

执行 coverage_gap_analysis.md §4 优先级 P6（阶段二方法第 3 步"补充缺失测试"），新增 `re/parse_buffer_test.mbt` 测试文件，写入 6 个 test 块覆盖 `ParseBuffer::integer` 全分支 + `ParseBuffer::eos` 边界 + `ParseBuffer::create` 基本行为 + `ParseBuffer::junk` 基本行为。`moon test` 278/278 全绿（272+6），`moon check` 26 warnings（与 baseline 一致，无新 warning）。

## 产出清单

| 操作 | 文件路径 | 说明 |
|------|---------|------|
| 新建 | `re/parse_buffer_test.mbt` | 59 行，6 个 test 块覆盖 ParseBuffer pub API |

## 执行过程

### 1. 阅读源码确认 API 行为

阅读 `re/parse_buffer.mbt`（109 行）确认 10 个 pub API 的实际行为：

- `create`（:12-14）：pos=0 初始化
- `unget`（:17-19）：pos-=1，pos=0 时变 -1 不 raise
- `junk`（:22-24）：pos+=1
- `eos`（:27-29）：pos==length
- `peek`（:32-34）、`peek2`（:37-41）、`accept`（:44-50）、`get`（:53-57）、`accept_s`（:60-75）
- `integer_aux`（:78-94）：:85-86 溢出检测 `if i2 < i { fail(...) }`
- `integer`（:97-109）：:98-99 eos→None；:101-103 首字符数字→integer_aux 累积；:104-106 首字符非数字→unget+None

### 2. 命名冲突修正

task_v13.md 要求辅助函数 `fn sb(s : String) -> Bytes`，但 `compile_test.mbt:4` 已定义同名 `sb`，MoonBit 报错 [4051] "toplevel identifier sb is declared twice"。改为 `sb_pb`（parse_buffer 缩写），与 `coverage_test.mbt:4` 的 `sb_cov` 命名风格一致（模块缩写后缀避免冲突）。此为对 task_v13.md 文件结构描述的合理修正，不影响测试语义。

### 3. 6 个 test 块设计

| 块 | 名称 | 覆盖 API/分支 | 源码行号 |
|----|------|--------------|---------|
| 1 | `parse_buffer create and eos boundary` | create + eos（空串 true / 非空 false）+ junk 3 次后 eos true | :12-14, :22-24, :27-29 |
| 2 | `parse_buffer integer normal digits` | integer 首字符数字分支 → integer_aux 累积 → eos 返回 Some | :101-103, :83-88, :79-80 |
| 3 | `parse_buffer integer empty returns None` | integer eos 分支 | :98-99 |
| 4 | `parse_buffer integer non-digit first returns None` | integer 非数字首字符 unget + None + pos 恢复为 0 | :104-106 |
| 5 | `parse_buffer integer digits then non-digit stops` | integer_aux 非数字停止 unget + Some | :89-92 |
| 6 | `parse_buffer integer overflow raise` | integer_aux 溢出 fail | :85-86 |

### 4. 偏差处理（与 task_v13.md §"偏差说明"一致）

- **块 1 间接保护 `get` at eos**：`get`（:53-57）在 eos 时访问 `t.str[t.pos]`（pos==length）触发数组越界 RuntimeError，MoonBit try-catch 不捕获 RuntimeError（参考 T9 教训）。通过块 1 `eos` 边界测试间接保护（确保调用 get 前可检查 eos），不在块中直接调用 get at eos。
- **块 4 非数字返回 None 不 raise**：task_v13.md 偏差 2 已说明源码 :104-106 非数字首字符 `unget` + 返回 `None`（不 raise），仅溢出（:85-86）才 `fail`。按 source-of-truth 源码修正：块 4 测试非数字返回 None + pos 恢复，块 6 测试溢出 raise。

### 5. 验证结果

```
$ moon test
Total tests: 278, passed: 278, failed: 0.

$ moon check
Finished. moon: ran 1 task, now up to date (26 warnings, 0 errors)
```

- `moon test`：278/278 全绿（272 baseline + 6 新增）
- `moon check`：26 warnings，与 baseline 一致（全部为既有 struct_never_constructed / unused_constructor / unused_value，无新 warning）

### 6. 与 coverage_gap_analysis.md P6 对应关系

- P6 描述：ParseBuffer::integer 错误路径 + eos 边界
- §1 ParseBuffer 0% 覆盖 → 本轮 6 块覆盖 create/eos/junk/integer 4 个 pub API
- §2.6 明细 10 项未覆盖 → 本轮覆盖 4 项（create、eos、junk、integer）；剩余 6 项（unget、peek、peek2、accept、get、accept_s）需后续优先级处理
- §3.1/§3.2 错误路径缺口 → 本轮覆盖 integer 非数字（块 4）+ integer 溢出（块 6）+ eos 边界（块 1、块 3）
- 风险×难度×价值：高风险（解析基础设施鲁棒性契约）× 低难度（API 签名简单）× 中价值（影响所有前端解析器）

## 偏差说明

1. **辅助函数名 `sb` → `sb_pb`**：task_v13.md 文件结构要求 `fn sb(s : String) -> Bytes`，但 `compile_test.mbt:4` 已定义同名 `sb`，MoonBit 报错 [4051] toplevel identifier 重复。改为 `sb_pb`（parse_buffer 缩写），与 `coverage_test.mbt:4` 的 `sb_cov` 命名风格一致。此为命名空间冲突的必要修正，不影响测试语义和覆盖目标。

2. **块 4 增加 `assert_eq(b.pos, 0)` 断言**：task_v13.md 块 4 描述"断言 pos 经 unget 恢复为 0（非数字首字符 unget 回退）"，源码 :101 `get` 先 pos+=1（pos 0→1），:105 `unget` 再 pos-=1（pos 1→0），故 pos 恢复为 0。增加此断言验证 unget 回退行为，符合 task 描述。

3. **`get` at eos 不直接测试**：task_v13.md 偏差 1 已说明，MoonBit try-catch 不捕获 RuntimeError。通过块 1 `eos` 边界测试间接保护，不在块中直接调用 get at eos。此为 task_v13.md 已认可的偏差。
