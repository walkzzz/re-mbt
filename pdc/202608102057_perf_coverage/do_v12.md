# 执行报告（v12）

## 概述
执行 coverage_gap_analysis.md §4 优先级 P5（阶段二方法第 3 步"补充缺失测试"），向 `re/coverage_test.mbt` 末尾追加 4 个 test 块，覆盖 `Str::match_beginning` / `Str::match_end` / `Str::matched_string` / `Str::group_beginning` 四个 Str OCaml 风格 API 的错误路径（str_state = None raise × 3 + group 越界 raise × 1）。测试基线从 268/268 提升至 272/272，moon check 维持 26 warnings baseline，无回归。

## 产出清单
| 操作 | 文件路径 | 说明 |
|------|---------|------|
| 修改 | re/coverage_test.mbt | 末尾追加 P5 分节注释 + 4 个 Str API 错误路径 test 块（1119 → 1171 行，+52 行） |

## 新增 test 块清单

| # | test 块名 | 覆盖 API | 覆盖分支/raise 路径 | 行号 |
|---|----------|---------|---------------------|------|
| 1 | `str match_beginning no match raise` | `Str::match_beginning` | str.mbt:83-88 `str_state = None → fail("Str: no match")` | 1124-1135 |
| 2 | `str match_end no match raise` | `Str::match_end` | str.mbt:91-96 `str_state = None → fail("Str: no match")` | 1138-1149 |
| 3 | `str matched_string no match raise` | `Str::matched_string` | str.mbt:99-104 `str_state = None → fail("Str: no match")` | 1152-1163 |
| 4 | `str group_beginning out of bounds raise` | `Str::group_beginning` | str.mbt:107-112 → `GroupT::start(m, 5)` → group.mbt:38-43 `fail("Group.start: not found")`（越界 group idx） | 1166-1171 |

## 每个块的构造与覆盖说明

### 块 1 `str match_beginning no match raise`
- **构造**：`Str::regexp(sb_cov("abc"))` → `Str::string_match(re, sb_cov("xyz"), 0)`（不匹配，因 re.mtch 带 `^` 锚点，`abc` 对 `xyz` 在 pos=0 不匹配）→ str_state.val = None → 调用 `Str::match_beginning()`。
- **断言**：`try { Str::match_beginning(); false } catch { _ => true }` + `assert_eq(result, true)`。
- **覆盖**：str.mbt:83-88 的 `None => fail("Str: no match")` 分支。

### 块 2 `str match_end no match raise`
- **构造**：同块 1 先清空 str_state（`Str::string_match(re, sb_cov("xyz"), 0)` 不匹配 → None）→ 调用 `Str::match_end()`。
- **断言**：同 raise 模式。
- **覆盖**：str.mbt:91-96 的 `None => fail("Str: no match")` 分支。

### 块 3 `str matched_string no match raise`
- **构造**：同块 1 先清空 str_state → 调用 `Str::matched_string(sb_cov("xyz"))`（参数 `_txt` 未使用，仅 str_state 决定 raise）。
- **断言**：同 raise 模式。
- **覆盖**：str.mbt:99-104 的 `None => fail("Str: no match")` 分支。

### 块 4 `str group_beginning out of bounds raise`
- **构造**：`Str::regexp(sb_cov("abc"))` → `Str::string_match(re, sb_cov("abc"), 0)`（匹配成功，str_state = Some(GroupT)，正则 `abc` 无捕获组，仅 group 0 存在）→ 调用 `Str::group_beginning(5)`（越界 group idx）。
- **断言**：同 raise 模式。
- **覆盖**：str.mbt:107-112 `Some(m) => GroupT::start(m, n)` → group.mbt:38-43 `GroupT::start_opt` → `GroupT::offset_opt` → `MarkInfos::offset(g.marks, 5)` 返回 None → `fail("Group.start: not found")`。

## 执行过程

### 1. 基线确认
运行 `moon test`：268/268 全绿（T11 后基线），与任务上下文一致。

### 2. 源码核查
阅读 `re/str.mbt` 确认四个 API 的 raise 路径：
- `Str::string_match`（str.mbt:58-69）：不匹配时 `str_state.val = None` 返回 false，匹配时 `str_state.val = Some(res)` 返回 true。re.mtch 带 `^` 锚点（str.mbt:18 `compile(Ast::seq([Ast::start(), re]))`），故 `Str::regexp("abc")` 对 `"xyz"` 在 pos=0 不匹配。
- `Str::match_beginning`（str.mbt:83-88）：`None => fail("Str: no match")`。
- `Str::match_end`（str.mbt:91-96）：`None => fail("Str: no match")`。
- `Str::matched_string`（str.mbt:99-104）：`None => fail("Str: no match")`，参数 `_txt` 未使用。
- `Str::group_beginning`（str.mbt:107-112）：`Some(m) => GroupT::start(m, n)`。

阅读 `re/group.mbt` 确认越界路径：
- `GroupT::start`（group.mbt:38-43）：`None => fail("Group.start: not found")`。
- `GroupT::start_opt` → `GroupT::offset_opt` → `MarkInfos::offset(g.marks, n)`，n=5 越界返回 None。

### 3. 测试块构造
4 个块均采用任务指定的 `try { <call>; false } catch { _ => true }` + `assert_eq(result, true)` 模式，与现有 `str search_forward not found`（:888）及 P4 测试块风格一致。str_state 全局状态通过先调用不匹配的 `Str::string_match` 清空（块 1-3），块 4 先匹配成功再越界。每个块附注释说明覆盖的源码路径，与 T11 P4 测试块注释风格一致。

### 4. 验证
- `moon test`：**272/272 全绿**（268 + 4 = 272），无回归。
- `moon check`：**26 warnings, 0 errors**，与 baseline 一致，无新 warning 引入。

## moon test 结果
```
Total tests: 272, passed: 272, failed: 0.
```

## moon check 结果
```
Finished. moon: ran 1 task, now up to date (26 warnings, 0 errors)
```
26 warnings 与 baseline 一致（均为既有的 struct_never_constructed / unused_constructor / unused_value，与本次追加无关）。

## 与 coverage_gap_analysis.md P5 的对应关系

| P5 要求 | 本次实现 |
|---------|---------|
| `Str::match_beginning` str_state=None raise | 块 1 `str match_beginning no match raise` |
| `Str::match_end` str_state=None raise | 块 2 `str match_end no match raise` |
| `Str::matched_string` str_state=None raise | 块 3 `str matched_string no match raise` |
| `Str::group_beginning` 越界 raise | 块 4 `str group_beginning out of bounds raise` |

P5 属"高风险 × 低难度 × 中价值"：Str 前端 OCaml 兼容性契约（高风险），API 签名简单且 raise 路径明确（低难度），Str 前端错误处理（中价值）。符合 task.md 阶段二重点覆盖方向 (b) 错误路径和异常处理。

## 偏差说明
无。严格按 task_v12.md 执行：4 个 test 块名称、构造、断言模式、覆盖路径均与任务指令一致；仅追加测试未修改源码；未运行 benchmark（任务约束）；snake_case 命名（测试名沿用现有空格分隔描述风格，与 :881/:888 Str 测试及 P4 测试一致）；未修改 pkg.generated.mbti。
