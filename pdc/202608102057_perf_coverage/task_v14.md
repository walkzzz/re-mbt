# 任务指令（v14）

## 动作
NEW

## 任务描述
执行 coverage_gap_analysis.md §4 优先级 P7（阶段二方法第 3 步"补充缺失测试"），新增 `re/desc_test.mbt` 测试文件，写入 6 个 test 块直接覆盖 `Desc::initial`、`Desc::status` 三分支（Failed/Match/Running）、`Desc::remove_duplicates` 去重正确性。具体：

**(1) 块 1 `desc initial returns single TExp with empty marks`**
构造 `Ids::create()` + `Expr::cst(ids, Cset::single(97))` 得到 expr，调用 `Desc::initial(expr)`，断言返回数组 `length() == 1`，再调用 `Desc::status(result)` 断言为 `Running`（因首元素是 TExp 非 TMatch）。覆盖 `Desc::initial`（automata_desc.mbt:144-146，返回 `[TExp(Marks::empty(), expr)]`）。

**(2) 块 2 `desc status empty array returns Failed`**
调用 `Desc::status([])`（空数组），断言返回 `Failed`。覆盖 `Desc::status` 空分支（automata_desc.mbt:245-246 `if t.length() == 0 { Failed }`）。

**(3) 块 3 `desc status TMatch head returns Match`**
构造 `let t : Array[ET] = [TMatch(Marks::empty())]`，调用 `Desc::status(t)`，断言返回的 Status 为 `Match(...)` variant（用 match 判断 variant 类型，不检查内部 MarkInfos/PmarkSet 值）。覆盖 `Desc::status` TMatch 分支（automata_desc.mbt:248 `TMatch(m) => Match(...)`）。

**(4) 块 4 `desc status TExp head returns Running`**
构造 `let t : Array[ET] = [TExp(Marks::empty(), expr)]`（expr 同块 1 构造方式），调用 `Desc::status(t)`，断言返回 `Running`。覆盖 `Desc::status` 非 TMatch 分支（automata_desc.mbt:249 `_ => Running`）。

**(5) 块 5 `desc remove_duplicates dedup same expr TExp`**
构造两个相同 expr 的 TExp：`let ids = Ids::create(); let e = Expr::cst(ids, Cset::single(97)); let t : Array[ET] = [TExp(Marks::empty(), e), TExp(Marks::empty(), e)]`，调用 `Desc::remove_duplicates(HashSet::create(), t, e)`，断言返回数组 `length() == 1`（第二个 TExp 因 `seen.mem(Expr::id(e))` 命中而被跳过，automata_desc.mbt:393-397）。覆盖 `Desc::remove_duplicates` 去重分支（TExp 相同 expr id 去重）。

**(6) 块 6 `desc remove_duplicates keeps distinct expr TExp`**
构造两个不同 expr 的 TExp：`let ids = Ids::create(); let e1 = Expr::cst(ids, Cset::single(97)); let e2 = Expr::cst(ids, Cset::single(98)); let t : Array[ET] = [TExp(Marks::empty(), e1), TExp(Marks::empty(), e2)]`，调用 `Desc::remove_duplicates(HashSet::create(), t, e1)`，断言返回数组 `length() == 2`（两个 TExp 的 expr id 不同，均保留）。覆盖 `Desc::remove_duplicates` 保留分支（TExp 不同 expr id 保留）。

**文件结构**：文件头注释 `// desc_test.mbt — tests for Desc pub APIs (initial/status/remove_duplicates)`。无需辅助函数（直接用 `Ids::create`/`Cset::single`/`Marks::empty`/`HashSet::create`/`ET` 枚举构造器）。

**Status variant 断言方式**：块 3 用 `match Desc::status(t) { Match(_, _) => true; _ => false }` 判断是否为 Match variant（不检查内部值），块 1/4 用 `match ... { Running => true; _ => false }`，块 2 用 `match ... { Failed => true; _ => false }`。或定义辅助函数 `fn status_is_failed/running/match`（参考 automata_test.mbt:5-20 风格）。

完成后运行 `moon test` 确认 284/284（278+6）全绿，运行 `moon check` 确认无新 warning。产出测试补充报告 do_v14.md（含新增 test 块清单、每个块覆盖的 API/分支、moon test 结果、moon check 结果、与 coverage_gap_analysis.md P7 的对应关系）。

## 选择理由
T13（P6）已 PASSED，coverage_gap_analysis.md §4 下一优先级为 P7（高风险 × 高难度 × 高价值：`Desc::remove_duplicates`/`Desc::initial`/`Desc::status` 是自动机核心操作，目前仅通过 delta/advance 端到端间接覆盖，无直接断言）。当前 automata_test.mbt 14 个 test 块全部通过 `State::create`/`delta`/`advance` 高层 API 间接测试，`Desc::initial`/`Desc::status`/`Desc::remove_duplicates` 三个 pub fn 从未直接调用（coverage_gap_analysis.md §1 Desc 5.6% 覆盖，§2.4 明细 17 项未覆盖/仅间接，§3.3 分支缺口含 status Failed/Match/Running 三分支 + remove_duplicates 去重）。P7 共 6 个 test 块，每块 5-12 行，难度高（需直接构造 ET 枚举值 TExp/TMatch 和 Marks/HashSet 内部类型，非通过高层 API），风险高（自动机核心操作正确性契约），价值高（影响 delta/advance 回归定位精度）。符合 task.md 阶段二重点覆盖方向 (a) 核心模块边界条件 + (d) cset/automata/compile 的内部操作（通过公开 API 间接测试，此处为直接测试 pub fn）。新增 desc_test.mbt 符合现有测试文件组织风格（basics_test/ast_test/automata_test/color_map_test/compile_test/core_test/coverage_test/frontend_test/parse_buffer_test/view_test 均按模块组织），MoonBit 测试文件以 `_test.mbt` 结尾自动识别无需修改 moon.pkg。

## 任务上下文
**目标 API 签名**（re/pkg.generated.mbti）：
- `pub fn Desc::initial(Expr) -> Array[ET]`（mbti:288，automata_desc.mbt:144-146）
- `pub fn Desc::status(Array[ET]) -> Status`（mbti:294，automata_desc.mbt:244-251）
- `pub fn Desc::remove_duplicates(HashSet, Array[ET], Expr) -> Array[ET]`（mbti:290，automata_desc.mbt:403-408）

**关键类型定义**（automata_desc.mbt）：
- `pub enum Status { Failed, Match(MarkInfos, PmarkSet), Running }`（:103-107）
- `pub enum ET { TSeq(Sem, Array[ET], Expr), TExp(Marks, Expr), TMatch(Marks) }`（:112-116），pub enum 可直接构造
- `pub fn Marks::empty() -> Marks`（:13-15）

**构造方式**：
- `Ids::create()` → `Expr::cst(ids, Cset::single(97))` 构造 Expr（参考 automata_test.mbt:24-25）
- `Marks::empty()` 构造空 Marks
- `HashSet::create()` 构造空 HashSet（mbti:409）
- `TExp(Marks::empty(), expr)` / `TMatch(Marks::empty())` 直接构造 ET 枚举值

**Desc::status 实现逻辑**（automata_desc.mbt:244-251）：
```
pub fn Desc::status(t : Array[ET]) -> Status {
  if t.length() == 0 { Failed }
  else { match t[0] { TMatch(m) => Match(...); _ => Running } }
}
```

**Desc::remove_duplicates 实现逻辑**（automata_desc.mbt:403-408 + 370-400）：
- `seen.clear()` 后调用 `desc_remove_duplicates_loop(seen, l, 0, y)`
- loop 遍历 l，对 TExp(marks, e)：`check_id = if Expr::is_eps(e) { Expr::id(y) } else { Expr::id(e) }`，若 `seen.mem(check_id)` 则跳过，否则 `seen.add(check_id)` 并保留
- 对 TMatch：直接保留 `[head]`
- 对 TSeq：递归处理 l2 和 r

**现有测试参考**：automata_test.mbt:5-20 已有 `status_is_running`/`status_is_failed`/`status_is_match` 辅助函数（match Status variant 返回 Bool），可参考其风格。automata_test.mbt 14 个 test 块全部通过 `State::create`/`delta`/`advance` 间接测试。

**T13 后基线**：moon test 278/278 全绿，moon check 26 warnings。本轮预期 284/284（278+6）。

**约束**：纯 MoonBit 无 C FFI，snake_case 命名，不修改 pkg.generated.mbti，不修改源码（仅新增测试文件），保持与 OCaml 上游行为一致性，保持 latin1 大小写处理，不运行 benchmark。

## 已有产出上下文
- **阶段一（性能优化）**：T1-T7 已完成，性能净改进 Section 1 951ms → 504.8ms（-46.9%，T3+T5 累计），T4/T6/T7 负改进回退，T5-skip mbti BLOCKED。代码最终状态 = T3 后版本（color_map.mbt）+ T5 后版本（cset.mbt），HEAD e64ec54。
- **阶段二（覆盖率提升）**：T8 产出 coverage_gap_analysis.md（413 API，219 已覆盖，194 未覆盖，53.0%）。T9-T13 按 P1-P6 顺序补充测试：
  - T9（P1-P2）：7 块 → coverage_test.mbt，258/258
  - T10（P3）：7 块 → frontend_test.mbt，265/265
  - T11（P4）：3 块 → coverage_test.mbt，268/268
  - T12（P5）：4 块 → coverage_test.mbt，272/272
  - T13（P6）：6 块 → parse_buffer_test.mbt（新增），278/278
- **当前测试文件**：re/ 下 10 个测试文件（basics_test/ast_test/automata_test/color_map_test/compile_test/core_test/coverage_test/frontend_test/parse_buffer_test/view_test + 即将新增 desc_test）。
- **coverage_gap_analysis.md §4 剩余优先级**：P7（本轮）→ P8-P15（后续 8 项）。
