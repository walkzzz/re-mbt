# 任务指令（v9）

## 动作
RETRY

## 任务描述

执行 coverage_gap_analysis.md §4 优先级 P1-P2（阶段二方法第 3 步"补充缺失测试"），向 `re/coverage_test.mbt` 追加 7 个 test 块，直接覆盖 `match_str` 和 `match_str_no_bounds` 两个 core API 入口。

### P1 match_str 四象限（groups × partial 四种组合，4 test 块）

构造能产生 Match/Failed/Running 三态的正则（如 `Ast::str(sb_cov("hello"))` 配合完整匹配/前缀部分匹配/不匹配输入），对每组 (groups, partial) 组合调用 `match_str(groups~, partial~, re, s, pos~, len~)`，断言返回的 MatchInfo variant 符合预期：

- `(groups=true, partial=false)` 命中返回 `MatchInfo(GroupT)`，不命中返回 `FailedInfo`
- `(groups=false, partial=false)` 命中返回 `MatchInfo(GroupT)`，不命中返回 `FailedInfo`
- `(groups=true, partial=true)` 部分匹配（输入是模式真前缀）返回 `RunningInfo(Int)`
- `(groups=false, partial=true)` 部分匹配返回 `RunningInfo(Int)`

**groups=true 与 groups=false 的差异**：两者命中时均返回 `MatchInfo(GroupT)` variant，差异在 GroupT 内 group marks 是否填充——由 `Positions::make(groups~, re)` 控制，`groups=true` 时填充捕获组位置标记，`groups=false` 时留空。测试断言只需区分 MatchInfo variant 类型（MatchInfo/FailedInfo/RunningInfo）即可确认四象限返回路径正确，无需断言 GroupT 内部 marks 内容。

### P2 match_str_no_bounds 越界（3 test 块，对照断言合并入块内）

验证 `match_str_no_bounds` 在越界参数下**不 raise**（与 `match_str` 的 raise 行为形成对比）：

- `pos < 0`（如 `pos=-1`）
- `len < -1`（如 `len=-2`）
- `pos + len > s.length()`（如 `pos=0, len=100` 对长度 5 的字符串）

对每组越界参数调用 `match_str_no_bounds(groups=true, partial=false, re, s, pos~, len~)`，用 `try { ...; true } catch { _ => false }` 断言不 raise。**对照断言合并入上述 3 块内**（非独立块）：每块在验证 `match_str_no_bounds` 不 raise 之后，同一块内追加对照断言验证 `match_str` 对相同越界参数应 raise "Re.exec: out of bounds"（用 `try { match_str(...); false } catch { _ => true }` 模式）。因此 P2 = 3 块，P1 + P2 = 4 + 3 = 7 块，预期 258/258（251+7）。

### 预期产出

- `re/coverage_test.mbt` 追加 7 个 test 块（P1 4 块 + P2 3 块，对照断言合并入 P2 的 3 块内）
- `pdc/202608102057_perf_coverage/do_v9.md` 测试补充报告，含：
  - 新增 test 块清单（块名 + 覆盖的 API/分支）
  - 每个 test 块源码摘要
  - `moon test` 结果（预期 258/258 全绿）
  - `moon check` 结果（预期无新 warning，baseline 26 warnings）
  - 与 coverage_gap_analysis.md P1-P2 的对应关系

### 验证标准

- `moon test` 258/258 全绿（251 原有 + 7 新增）
- `moon check` 无新 warning
- 新增 test 块确实覆盖 `match_str` 四象限和 `match_str_no_bounds` 越界行为
- 不修改 `re/pkg.generated.mbti`
- 不修改任何源码（仅追加测试）
- 不运行 benchmark

## 选择理由

T8 已 PASSED，coverage_gap_analysis.md §4 明确 P1-P2 为最高优先级（高风险 × 低难度 × 高价值），是阶段二方法第 3 步"补充缺失测试"的首选目标。当前 `match_str` / `match_str_no_bounds` 仅通过 `exec`/`exec_opt`/`execp`/`exec_partial`/`exec_partial_detailed` 间接覆盖特定参数组合：
- `exec`/`exec_opt` 调用 `match_str(groups=true, partial=false)` → 仅覆盖 1 象限
- `exec_partial` 调用 `match_str(groups=false, partial=true)` → 仅覆盖 1 象限
- `exec_partial_detailed` 调用 `match_str(groups=true, partial=true)` → 仅覆盖 1 象限
- `(groups=false, partial=false)` 象限完全未覆盖
- 越界行为（`match_str` raise vs `match_str_no_bounds` 不 raise 的核心契约）完全未测

P1-P2 共 7 个 test 块，每个 3-10 行，难度极低，风险高（core API 契约），价值高（影响 MatchInfo 返回路径和越界安全性）。符合 task.md 阶段二重点覆盖方向 (a) 核心模块边界条件 + (b) 错误路径和异常处理。

## 任务上下文

### 目标 API 签名与实现

- **`match_str`**（compile.mbt:727-739）：
  ```
  pub fn match_str(groups~ : Bool, partial~ : Bool, Re, Bytes, pos~ : Int, len~ : Int) -> MatchInfo raise
  ```
  实现：先做越界检查（`pos < 0 || len < -1 || pos + len > s.length()` 则 `fail("Re.exec: out of bounds")`），再调用 `match_str_no_bounds`。

- **`match_str_no_bounds`**（compile.mbt:692-722）：
  ```
  pub fn match_str_no_bounds(groups~ : Bool, partial~ : Bool, Re, Bytes, pos~ : Int, len~ : Int) -> MatchInfo
  ```
  实现：不做越界检查，直接调用 `make_match_str`，根据返回值构造 `MatchInfo(GroupT)` / `FailedInfo` / `RunningInfo(no_match_starts_before)`。

- **`pub enum MatchInfo`**（compile.mbt:600-604）：
  ```
  pub enum MatchInfo {
    MatchInfo(GroupT)
    FailedInfo
    RunningInfo(Int) // no_match_starts_before
  }
  ```

### 测试文件辅助函数与模式

- `re/coverage_test.mbt` 已有辅助：
  - `sb_cov(s : String) -> Bytes`（:4）— String 转 Bytes（latin1 编码）
  - `bs_cov(b : Bytes) -> String`（:13）— Bytes 转 String
- 已有 `compile`/`exec`/`exec_opt`/`execp`/`exec_partial`/`exec_partial_detailed` 调用示例：
  - :729-733 `test "exec returns group on match"` — `compile(Ast::str(sb_cov("hello")))` + `exec(re, sb_cov("hello world"))`
  - :736-744 `test "exec raises on no match"` — `try { exec(...) } catch { _ => true }` 模式
  - :750-753 `test "exec_partial partial"` — `exec_partial(re, sb_cov("hel"))` 返回 `Partial`
  - :923-940 `exec_partial_detailed partial/mismatch` 测试
- 建议新增 test 块命名前缀：`match_str_` 和 `match_str_no_bounds_`，便于检索
- 建议插入位置：coverage_test.mbt 末尾（:955 之后），或 `exec raises on no match`（:744）之后集中管理

### RunningInfo 触发方式

`RunningInfo` 在 `partial=true` 且输入是模式的真前缀（即输入匹配到一半但未完成）时返回。例如模式 `Ast::str(sb_cov("hello"))` + 输入 `sb_cov("hel")`，`partial=true` 时应返回 `RunningInfo(_)`。参考 `exec_partial partial` 测试（:750-753）已验证此行为。

### 约束

- 纯 MoonBit 无 C FFI
- snake_case 命名（test 块名、变量名）
- 不修改 `re/pkg.generated.mbti`
- 不修改任何源码（仅追加测试到 coverage_test.mbt）
- 保持与 OCaml 上游行为一致性
- 保持 latin1 大小写处理
- 不运行 benchmark

## 已有产出上下文

- **baseline.md**：测试基线 251/251 通过（0.21s），10 个 section benchmark 基线（性能优化后 Section 1 = 504.8ms）
- **coverage_gap_analysis.md**（T8 产出，417 行）：§4 优先级排序 P1-P15，本任务对应 P1-P2。P1 = match_str 四象限（4 块），P2 = match_str_no_bounds 越界（3 块），预期完成后总体 API 覆盖率从 53.0% 提升（P1-P2 覆盖 2 个 API 的 7 个分支组合）
- **plan.md**：T1-T8 均已 PASSED，T8 为阶段二第 1 步（差距分析），本任务 T9 为阶段二第 2 步（补充测试）的第一个子任务
- 当前代码状态：T5 后版本（HEAD e64ec54，working tree clean），性能优化净改进 Section 1 -46.9%（T3+T5 累计），T4/T6/T7 负改进已回退
- re/coverage_test.mbt 当前 103 个 test 块（coverage_gap_analysis.md §0 声明），本任务追加 7 块后为 110 块，总测试数 258

## RETRY 说明（仅 RETRY 时）

**上一轮审查结果**：plan_review_v9_r1.md REJECTED，2 个发现（1 个一般 + 1 个轻微）。

**失败原因摘要与修正方向**：

1. **[一般] plan.md T9 条目 test 块数量自相矛盾**：plan.md line 108 声明"追加 7 个 test 块"、line 111 预期"258/258（251+7）"，但 line 110 P2 描述写"同时补充 1 个对照块"，自然读法为新增独立第 8 块使总计 8 块（259），与 258 矛盾。
   - **修正**：task_v9.md P2 章节标题改为"3 test 块，对照断言合并入块内"，并明确"对照断言合并入上述 3 块内（非独立块）...因此 P2 = 3 块，P1 + P2 = 4 + 3 = 7 块，预期 258/258（251+7）"。预期产出同步标注"对照断言合并入 P2 的 3 块内"。plan.md 按"仅追加不回改"约束不在 R9 NEW 条目回改，而是在本轮 R10 RETRY 条目中澄清矛盾已消解。

2. **[轻微] P1 四象限描述未说明 groups=true 与 groups=false 的实际差异**：两者均写"命中返回 MatchInfo(GroupT)"，未说明 GroupT 内 group marks 是否填充。
   - **修正**：P1 章节补充"groups=true 与 groups=false 的差异"段落，说明差异在 GroupT 内 group marks 是否填充（由 Positions::make(groups~, re) 控制），测试断言只需区分 variant 类型即可。
