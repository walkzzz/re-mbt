# 执行报告（v9）

## 概述

执行 coverage_gap_analysis.md §4 优先级 P1-P2，向 `re/coverage_test.mbt` 末尾追加 7 个 test 块，直接覆盖 `match_str` 四象限（groups × partial 四种组合）和 `match_str_no_bounds` 越界行为。`moon test` 258/258 全绿（251 原有 + 7 新增），`moon check` 26 warnings（与 baseline 一致，无新 warning）。

## 产出清单

| 操作 | 文件路径 | 说明 |
|------|---------|------|
| 修改 | `re/coverage_test.mbt` | 末尾追加 7 个 test 块（P1 4 块 + P2 3 块），行数 955 → 1078 |

## 新增 test 块清单

| # | 块名 | 覆盖 API/分支 | 对应优先级 |
|---|------|-------------|-----------|
| 1 | `match_str groups=true partial=false` | match_str (groups=true, partial=false) 命中→MatchInfo / 不命中→FailedInfo | P1 象限 1 |
| 2 | `match_str groups=false partial=false` | match_str (groups=false, partial=false) 命中→MatchInfo / 不命中→FailedInfo | P1 象限 2 |
| 3 | `match_str groups=true partial=true` | match_str (groups=true, partial=true) 部分匹配→RunningInfo / 完整命中→MatchInfo | P1 象限 3 |
| 4 | `match_str groups=false partial=true` | match_str (groups=false, partial=true) 部分匹配→RunningInfo / 完整命中→MatchInfo | P1 象限 4 |
| 5 | `match_str pos negative bounds raise` | match_str 越界 pos=-1 raise "Re.exec: out of bounds" | P2 块 1 |
| 6 | `match_str_no_bounds len below -1 no raise` | match_str_no_bounds(len=-2) 不 raise + 对照 match_str raise | P2 块 2 |
| 7 | `match_str pos+len overflow bounds raise` | match_str 越界 pos+len>slen raise "Re.exec: out of bounds" | P2 块 3 |

## 每个 test 块源码摘要

### P1 块 1-4：match_str 四象限

统一模式：`compile(Ast::str(sb_cov("hello")))` 作为正则，对每组 (groups, partial) 组合调用 `match_str(groups~, partial~, re, s, pos=0, len=N)`，match 返回的 MatchInfo variant 断言预期类型。

- **块 1** `(groups=true, partial=false)`：命中 `sb_cov("hello world")` len=11 → MatchInfo；不命中 `sb_cov("world")` len=5 → FailedInfo
- **块 2** `(groups=false, partial=false)`：同块 1 参数，验证 groups=false 路径
- **块 3** `(groups=true, partial=true)`：部分匹配 `sb_cov("hel")` len=3 → RunningInfo；完整命中 `sb_cov("hello")` len=5 → MatchInfo
- **块 4** `(groups=false, partial=true)`：同块 3 参数，验证 groups=false 路径

断言只区分 MatchInfo/FailedInfo/RunningInfo variant 类型，不断言 GroupT 内部 marks（groups=true/false 差异在 GroupT 内 group marks 是否填充，由 Positions::make 控制，variant 类型相同）。

### P2 块 5-7：match_str_no_bounds 越界（对照断言合并入块内）

- **块 5** `pos=-1, len=5`：对照验证 `match_str` raise（try-catch 模式）
- **块 6** `pos=0, len=-2`：直接调用 `match_str_no_bounds` 验证不产生错误 + 对照 `match_str` raise
- **块 7** `pos=0, len=100`（slen=5）：对照验证 `match_str` raise

## 验证结果

- **moon test**：`Total tests: 258, passed: 258, failed: 0.`（251 原有 + 7 新增，全绿）
- **moon check**：`Finished. moon: ran 1 task, now up to date (26 warnings, 0 errors)`（与 baseline 26 warnings 一致，无新 warning）
- **pkg.generated.mbti**：未修改（git status 确认）
- **源码**：未修改任何源码（仅追加测试到 coverage_test.mbt）

## 执行过程

1. 阅读 task_v9.md，理解 P1（match_str 四象限 4 块）+ P2（match_str_no_bounds 越界 3 块，对照断言合并入块内）的要求
2. 阅读 compile.mbt:692-739 确认 match_str/match_str_no_bounds 签名与实现，阅读 core.mbt:89-182 确认 exec/exec_partial/exec_partial_detailed 如何调用 match_str
3. 运行 `moon test` 确认基线 251/251 通过
4. 追加 7 个 test 块到 coverage_test.mbt 末尾（:955 之后）
5. 首次 `moon test` 失败 2 块（pos=-1 和 pos+len=100），错误为 `RuntimeError: array element access out of bounds`（next_state 中 s[pos] 越界，不可捕获）
6. 分析发现：`match_str_no_bounds` 对 `pos < 0` 和 `pos+len > slen` 的越界参数会产生不可捕获的 RuntimeError（MoonBit try-catch 只捕获 fail 异常，不捕获 RuntimeError）；仅 `len < -1`（pos=0）不产生错误（last < pos，循环不执行）
7. 调整 P2 块 5/7：仅对照验证 match_str raise；P2 块 6 保留 match_str_no_bounds 调用
8. 再次 `moon test` 258/258 全绿，但 `moon check` 报 27 warnings（新增 unused_try：match_str_no_bounds 不声明 raise，try-catch 包裹触发警告）
9. 调整 P2 块 6：将 try-catch 包裹改为直接调用 match_str_no_bounds（不声明 raise 的函数无需 try-catch），消除 unused_try warning
10. 最终 `moon test` 258/258 全绿，`moon check` 26 warnings（baseline 一致）

## 与 coverage_gap_analysis.md P1-P2 的对应关系

| 优先级 | 分析描述 | 实现块 | 状态 |
|--------|---------|--------|------|
| P1 | match_str 四象限（groups × partial），4 块 | 块 1-4 | 完全匹配 |
| P2 | match_str_no_bounds 越界 pos/len，3 块，对照断言合并入块内 | 块 5-7 | 部分匹配（见偏差说明） |

## 偏差说明

### 偏差 1：P2 块 5/7 未验证 match_str_no_bounds 不 raise

**任务前提**："`match_str_no_bounds` 在越界参数下不 raise（与 `match_str` 的 raise 行为形成对比）"

**实际行为**（通过阅读源码与运行测试确认）：
- `len < -1`（pos=0, len=-2）：`last = pos + len = -2 < pos`，循环不执行，不产生错误 ✓
- `pos < 0`（pos=-1, len=5）：`match_loop` 调用 `next_state(colors, st, s, pos=-1)`，`next_state` 访问 `s[pos]`（compile.mbt:323）即 `s[-1]` 越界，产生 `RuntimeError: array element access out of bounds`
- `pos+len > slen`（pos=0, len=100, slen=5）：`last = 100`，循环中 pos 从 0 递增，当 pos >= 5 时 `s[pos]` 越界，产生 RuntimeError

MoonBit 的 `try { ... } catch { _ => ... }` 只捕获 `fail` 抛出的异常，不捕获 RuntimeError（array out of bounds 等运行时错误）。因此对 `pos < 0` 和 `pos+len > slen` 的越界参数，无法用 try-catch 验证 `match_str_no_bounds` "不 raise"——调用会直接导致测试块失败。

**处理方式**：P2 块 5/7 仅对照验证 `match_str` raise "Re.exec: out of bounds"（match_str 的越界检查在 compile.mbt:735-736，通过 fail 抛出可捕获异常）。P2 块 6（len < -1）保留 `match_str_no_bounds` 不 raise 验证。7 块总数不变，258/258 全绿。

**理由**：Doer 核心原则"禁止凭假设产出"——任务前提与实际行为不符，以源码行为为准，在报告中如实说明。

### 偏差 2：P2 块 6 用直接调用替代 try-catch 验证不 raise

**任务要求**：用 `try { ...; true } catch { _ => false }` 断言不 raise

**实际问题**：`match_str_no_bounds` 声明 `-> MatchInfo`（不 raise），用 try-catch 包裹会触发 `unused_try` warning（"The body of this try expression never raises any error"），导致 `moon check` 从 26 增至 27 warnings，违反"无新 warning"验证标准。

**处理方式**：P2 块 6 改为直接调用 `match_str_no_bounds` 并 match 返回值（match 三分支均 assert_eq(true, true)）。直接调用成功即证明不产生错误，等效验证"不 raise"语义。

**理由**：Doer 核心原则"独立判断"——任务要求的 try-catch 模式对不声明 raise 的函数会产生 warning，与"无新 warning"标准冲突。选择保留更硬性的验证标准（无新 warning），调整验证方式（直接调用），两者语义等效。

## 修订说明（v9 r1）

| 审查意见 | 处理方式 |
|---------|---------|
| [一般] P2 块 5/7 命名与实际验证内容不符：块名含 `match_str_no_bounds` 和 `no raise` 暗示验证不 raise 行为，但块内仅调用 `match_str` 验证其 raise，未调用 `match_str_no_bounds`，命名误导维护者 | 修改：块 5 重命名为 `match_str pos negative bounds raise`，块 7 重命名为 `match_str pos+len overflow bounds raise`，准确反映"仅验证 match_str raise"语义。块 6 实际调用了 match_str_no_bounds，命名准确无需调整。块内注释保留说明为何未验证 match_str_no_bounds 不 raise |
| [轻微] P2 块 6 未按 task_v9.md 要求使用 try-catch 模式，改为直接调用 match_str_no_bounds 并 match 返回值 | 保留+理由：审查报告已认定此调整合理（直接调用成功即证明不产生错误，语义等效于 try-catch 验证不 raise，且避免 unused_try warning）。维持无新 warning 的硬性验证标准，不改回 try-catch 模式 |

### 修订验证

- `moon test`：`Total tests: 258, passed: 258, failed: 0.`（全绿，命名修改不影响测试逻辑）
- `moon check`：`Finished. moon: ran 1 task, now up to date (26 warnings, 0 errors)`（与 baseline 一致，无新 warning）
- 修改范围：仅 `re/coverage_test.mbt` 块 5/7 的 test 块名（2 处字符串字面量），未改动测试代码体
