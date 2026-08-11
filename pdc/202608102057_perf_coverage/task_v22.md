# 任务指令（v22）

## 动作
NEW

## 任务描述
执行 coverage_gap_analysis.md §4 优先级 P15（阶段二方法第 3 步"补充缺失测试"，最后一项），新增 `re/compile_internal_test.mbt` 测试文件，写入 6 个 test 块直接覆盖 `CompileIdx` 9 个 API + `StateHashTable` 3 个 API。具体：

(1) **块 1 `compile_idx constants`**——验证 CompileIdx 两个常量值：`CompileIdx::unknown() == -2`、`CompileIdx::break_value() == -3`。

(2) **块 2 `compile_idx three state predicates`**——验证三态判定函数：
- `CompileIdx::is_idx(0) == true`、`CompileIdx::is_idx(1) == true`、`CompileIdx::is_idx(-1) == false`、`CompileIdx::is_idx(CompileIdx::unknown()) == false`、`CompileIdx::is_idx(CompileIdx::break_value()) == false`
- `CompileIdx::is_break(CompileIdx::break_value()) == true`、`CompileIdx::is_break(CompileIdx::make_break(5)) == true`、`CompileIdx::is_break(0) == false`、`CompileIdx::is_break(CompileIdx::unknown()) == false`
- `CompileIdx::is_unknown(CompileIdx::unknown()) == true`、`CompileIdx::is_unknown(0) == false`、`CompileIdx::is_unknown(CompileIdx::break_value()) == false`

(3) **块 3 `compile idx conversion functions`**——验证转换函数：
- `CompileIdx::of_idx(42) == 42`、`CompileIdx::idx(42) == 42`
- `CompileIdx::make_break(3) == -8`（-5-3=-8）、`CompileIdx::make_break(0) == -5`
- `CompileIdx::break_idx(CompileIdx::make_break(3)) == 3`（round-trip）、`CompileIdx::break_idx(CompileIdx::make_break(10)) == 10`（round-trip）、`CompileIdx::break_idx(-5) == 0`

(4) **块 4 `state hash table create and find empty`**——验证 StateHashTable::create + 空表 find：
- `let tbl = StateHashTable::create(4)`，`StateHashTable::find(tbl, State::dummy())` 返回 None（空表 find 返回 None）
- 再测 `StateHashTable::create(1)`（capacity=1 边界）和 `StateHashTable::create(0)`（capacity=0 边界，应被钳制为 1），均 find 返回 None

(5) **块 5 `state hash table add and find hit`**——验证 StateHashTable::add + find 命中：
- 构造 CompileState cs（`{ info: { idx: 0, final_: [], desc: State::dummy() }, transitions: [] }`）
- `let key = State::dummy()`，`StateHashTable::add(tbl, key, cs)`
- `StateHashTable::find(tbl, key)` 返回 Some（命中）。用 match pattern 断言 `find(tbl, key)` 返回 `Some(cs')` 且 `CompileState::get_info(cs').idx == 0`

(6) **块 6 `state hash table find miss different state`**——验证 StateHashTable::find 未命中（不同 State）：
- 用 `State::mk(1, Category::dummy(), [])` 构造与 dummy 不同的 State other_key（idx 不同）
- `StateHashTable::find(tbl, other_key)` 返回 None（未命中）
- 再验证 add 后对同一 key find 行为不变（add 覆盖同 hash 桶但 State::equal 区分）

完成后运行 `moon test` 确认 323/323（317+6）全绿，运行 `moon check` 确认无新 warning。产出测试补充报告 do_v22.md（含新增 test 块清单、每个块覆盖的 API/分支、moon test 结果、moon check 结果、与 coverage_gap_analysis.md P15 的对应关系）。

## 选择理由
T21（P14）已 PASSED，coverage_gap_analysis.md §4 优先级 P1-P14 全部完成，仅剩 P15（中风险 × 中难度 × 中价值：compile 内部状态管理正确性，CompileIdx 9 API + StateHashTable 3 API 全部 0% 覆盖，目前全靠端到端间接覆盖）。P15 是 coverage_gap_analysis.md §4 最后一项，完成后阶段二（测试覆盖率提升）全部优先级项完成。P15 共 6 个 test 块，CompileIdx 部分（块 1-3）难度低（纯 Int 操作，API 签名简单，返回值确定），StateHashTable 部分（块 4-6）难度中（需构造 State + CompileState，但 State::dummy()/State::mk/Category::dummy() 均为 pub fn 可直接调用，CompileState 可用 struct literal 同包构造）。风险中（compile 内部状态管理影响 lazy DFA 匹配正确性），价值中（CompileIdx 三态判定 + StateHashTable 哈希查找是 compile 核心基础设施）。符合 task.md 阶段二重点覆盖方向 (a) 核心模块边界条件 + (d) cset/automata/compile 内部操作（通过公开 API 直接测试）。

## 任务上下文
- **CompileIdx**（compile.mbt:8-52）9 个 pub fn 全为纯 Int 操作：
  - `unknown() = -2`（:11-13）
  - `break_value() = -3`（:16-18）
  - `of_idx(x) = x`（:21-23）
  - `is_idx(t) = t >= 0`（:26-28）
  - `is_break(x) = x <= break_value()` 即 `x <= -3`（:31-33）
  - `is_unknown(x) = x == unknown()` 即 `x == -2`（:36-38）
  - `idx(t) = t`（:41-43）
  - `make_break(idx) = -5 - idx`（:46-48）
  - `break_idx(t) = (t + 5) * -1`（:51-53）

- **StateHashTable**（compile.mbt:106-144）3 个 pub fn：
  - `create(capacity)`（:112-119）：创建 capacity 个空桶（capacity<1 钳制为 1），返回 `{ buckets, size: 0 }`
  - `find(tbl, key)`（:122-132）：按 `key.hash & (buckets.length()-1)` 定位桶，State::equal 线性查找，返回 `CompileState?`
  - `add(tbl, key, value)`（:135-144）：按 `key.hash & (buckets.length()-1)` 定位桶，push `(key, value)`，`size += 1`

- **State**（automata_state.mbt）pub struct `{ idx; category; desc; mut status; hash }`（mbti:675-681）：
  - `State::dummy()`（:46-54）= `{ idx: Idx::unknown(), category: Category::dummy(), desc: Desc::empty(), status: None, hash: -1 }`
  - `State::mk(idx, cat, desc)`（:30-38）= `{ idx, category: cat, desc, status: None, hash: state_compute_hash(idx, cat, desc) }`
  - `State::equal(s1, s2)`（:62）先比较 hash 再比较 idx/category/desc

- **CompileState**（compile.mbt:67-70）pub struct `{ info : StateInfo; transitions : Array[CompileState] }`，同包测试可用 struct literal 构造
- **StateInfo**（compile.mbt:58-62）pub struct `{ idx : Int; final_ : Array[(Category, (Int, Status))]; desc : State }`
- **Category::dummy()**（category.mbt:40）pub fn 返回 Category

- T21 后 317/317 为基线，预期 323/323（317+6）
- 约束：纯 MoonBit 无 C FFI，snake_case 命名，不修改 pkg.generated.mbti，不修改源码（仅新增测试文件），保持与 OCaml 上游行为一致性，保持 latin1 大小写处理，不运行 benchmark

## 已有产出上下文
- **coverage_gap_analysis.md**：§4 优先级 P15 明确 CompileIdx 9 API + StateHashTable 3 API 全部 0% 覆盖（§1 CompileIdx 0/9、StateHashTable 0/3），§2.5 明细 12 项未覆盖，§3.4 分支缺口含 StateHashTable 命中/未命中 + 容量增长
- **baseline.md**：251/251 测试基线（阶段一前）
- **T9-T21 已完成 P1-P14**：317/317 测试通过，22 warnings，覆盖 core API 错误路径/前端解析错误/Str API/ParseBuffer/Desc/Expr::rename/Ast::colorize/cset 边界/PerlOpt/PcreFlag/GroupT/Str 高级 API
- **已有测试文件组织**：basics_test/ast_test/automata_test/color_map_test/compile_test/core_test/coverage_test/frontend_test/view_test/desc_test/parse_buffer_test，均按模块组织，MoonBit `_test.mbt` 自动识别无需修改 moon.pkg
- **compile_test.mbt**：已有 compile 相关测试（compile/exec/exec_opt/execp/exec_partial/exec_partial_detailed），但不覆盖 CompileIdx/StateHashTable 内部 API
