# 任务指令（v15）

## 动作
RETRY

## 任务描述
执行 coverage_gap_analysis.md §4 优先级 P8（阶段二方法第 3 步"补充缺失测试"），向 `re/automata_test.mbt` 末尾追加 4 个 test 块，直接覆盖 `Expr::rename`（automata_expr.mbt:158-174）的递归重命名行为。`Expr::rename(ids, x)` 递归遍历 Expr 树，对每个节点调用 `ids.next()` 分配新 id，保持 Expr 结构（variant + 非 id 字段）不变。具体：

(1) **块 1 `expr rename Cst preserves cset with new id`** — 构造 `ids1 = Ids::create()` + `e = Expr::cst(ids1, Cset::single(97))`（原 id=1），再用 `ids2 = Ids::create()` 调用 `Expr::rename(ids2, e)` 得 `e2`，断言：(a) `e2` match `Cst(new_id, s)` 且 `s` 与原 Cset::single(97) 相等（Cset derive(Eq) 可用 `Cset::equal` 或直接 `==` 比较）；(b) `Expr::id(e2) == 1`（ids2 第一个 next() 返回 1）。覆盖 rename Cst 分支（automata_expr.mbt:160）。

(2) **块 2 `expr rename Seq recursively renames children`** — 构造 `ids1` + `a = Expr::cst(ids1, Cset::single(97))` + `b = Expr::cst(ids1, Cset::single(98))` + `seq = Expr::seq(ids1, Sem::Longest, a, b)`（原 id=3），再用 `ids2 = Ids::create()` 调用 `Expr::rename(ids2, seq)` 得 `seq2`，断言：(a) `seq2` match `Seq(new_id, Sem::Longest, y, z)`；(b) `Expr::id(seq2) == 1`（Seq 分支 `Seq(ids.next(), k, rename(y), rename(z))` 根节点先分配 id=1，然后 y rename 得 id=2，z rename 得 id=3）；(c) `y` match `Cst(_, s1)` 且 `s1 == Cset::single(97)`；(d) `z` match `Cst(_, s2)` 且 `s2 == Cset::single(98)`。覆盖 rename Seq 分支（automata_expr.mbt:171-172）+ 递归子节点。

(3) **块 3 `expr rename Alt recursively renames all children`** — 构造 `ids1` + `a = Expr::cst(ids1, Cset::single(97))` + `b = Expr::cst(ids1, Cset::single(98))` + `c = Expr::cst(ids1, Cset::single(99))` + `alt = Expr::alt(ids1, [a, b, c])`（原 id=4），再用 `ids2 = Ids::create()` 调用 `Expr::rename(ids2, alt)` 得 `alt2`，断言：(a) `alt2` match `Alt(new_id, l)` 且 `l.length() == 3`；(b) `l[0]` / `l[1]` / `l[2]` 均为 Cst 且 Cset 分别等于 single(97)/single(98)/single(99)；(c) `Expr::id(alt2) == 4`（Alt 分支 `let l2 = Array::map(l, ...); Alt(ids.next(), l2)` 先递归 rename 子节点消耗 id 1/2/3，根节点后分配 id 得 4）。覆盖 rename Alt 分支（automata_expr.mbt:167-170）+ Array::map 递归所有子节点。

(4) **块 4 `expr rename Rep recursively renames child`** — 构造 `ids1` + `a = Expr::cst(ids1, Cset::single(97))` + `rep = Expr::rep(ids1, RepKind::Greedy, Sem::Longest, a)`（原 id=2），再用 `ids2 = Ids::create()` 调用 `Expr::rename(ids2, rep)` 得 `rep2`，断言：(a) `rep2` match `Rep(new_id, RepKind::Greedy, Sem::Longest, y)`；(b) `y` match `Cst(_, s)` 且 `s == Cset::single(97)`；(c) `Expr::id(rep2) == 1`（Rep 分支 `Rep(ids.next(), g, k, rename(y))` 根节点先分配 id=1，然后 y rename 得 id=2）。覆盖 rename Rep 分支（automata_expr.mbt:173）+ 递归子节点。

完成后运行 `moon test` 确认 288/288（284+4）全绿，运行 `moon check` 确认无新 warning。产出测试补充报告 do_v15.md（含新增 test 块清单、每个块覆盖的 API/分支、moon test 结果、moon check 结果、与 coverage_gap_analysis.md P8 的对应关系）。

## 选择理由
T14（P7）已 PASSED，coverage_gap_analysis.md §4 下一优先级为 P8（高风险 × 高难度 × 高价值：`Expr::rename` 导数正确性关键，需与 OCaml 上游对照）。当前 automata_test.mbt 13 个 test 块全部覆盖 State::create/delta/advance/WorkingArea 等 API，`Expr::rename` pub fn（mbti:364）完全未直接测试（coverage_gap_analysis.md §1 Expr 模块覆盖率低，§2 未覆盖明细含 rename，§3.3 分支缺口含 rename 各 Expr variant 分支）。P8 共 4 个 test 块，每块 8-15 行，难度高（需构造嵌套 Expr 树 + match 断言 variant + 递归验证子节点），风险高（导数正确性是 Brzozowski/Antimirov 算法核心，rename 错误会导致状态管理混乱），价值高（影响 delta/advance 的状态定位正确性）。符合 task.md 阶段二重点覆盖方向 (a) 核心模块边界条件 + (d) automata 内部操作直接测试。

## 任务上下文
- `Expr::rename`（automata_expr.mbt:158-174）签名 `pub fn Expr::rename(ids : Ids, x : Expr) -> Expr`，递归遍历 Expr 树，每个节点 match 分支调用 `ids.next()` 分配新 id，非 id 字段（Cset/Sem/RepKind/Int mark/Pmark/Category 等）保持不变，Seq/Alt/Rep 递归 rename 子节点。
- **id 分配顺序差异**：Seq 分支（:171-172）`Seq(ids.next(), k, rename(y), rename(z))` 根节点先分配 id，再递归子节点；Rep 分支（:173）同理根节点先分配；Alt 分支（:167-170）`let l2 = Array::map(l, ...); Alt(ids.next(), l2)` 先递归 rename 所有子节点，根节点后分配 id。
- `pub enum Expr`（automata_expr.mbt:5-16）10 个 variant：Cst/Alt/Seq/Eps/Rep/MarkOf/Erase/Before/After/PmarkOf，derive(Debug)。
- `pub fn Expr::id(e : Expr) -> Int`（automata_expr.mbt:19）返回节点 id。
- `Ids`（automata.mbt:175-188）`{ mut counter : Int }`，`Ids::create()` counter=0，`Ids::next()` counter+=1 返回新值（首次 next() 返回 1）。
- `pub fn Expr::cst(ids, s)` / `Expr::seq(ids, kind, x, y)` / `Expr::alt(ids, l)` / `Expr::rep(ids, kind, sem, x)` 等构造函数均调用 `ids.next()` 分配 id。
- `Cset::single(c)` 构造单字符集，Cset derive(Eq) 可用 `==` 比较。
- `Sem` enum（automata.mbt:5-9）变体为 `Longest`/`Shortest`/`First`，`RepKind` enum（automata.mbt:12-15）变体为 `Greedy`/`NonGreedy`，均为 Expr 构造参数。
- automata_test.mbt 已有辅助函数 `status_is_running`/`status_is_failed`/`status_is_match`（:4-25），已有 13 个 test 块（State::create/delta/advance/WorkingArea），风格参考 :28-38 `State::create and dummy`。
- T14 后 284/284 为基线。约束：纯 MoonBit 无 C FFI，snake_case 命名，不修改 pkg.generated.mbti，不修改源码（仅追加测试），保持与 OCaml 上游行为一致性，保持 latin1 大小写处理，不运行 benchmark。

## 已有产出上下文
- baseline.md：性能基线（251/251 测试通过，10 section benchmark）。
- hotspot_analysis.md：compile 路径热点分析（12 个热点函数 + 3 类优化方向）。
- opt_v3.md / opt_v5.md：性能优化报告（T3 ColorMap::flatten 哈希去重 -39.95%，T5 Cset 分治归并 -3.02%，累计 Section 1 -46.9%）。
- opt_v4.md / opt_v6.md / opt_v7.md：负改进回退记录（T4 位图/T6 去重/T7 迭代化均回退）。
- coverage_gap_analysis.md：覆盖率差距报告（413 API，219 已覆盖，194 未覆盖，53.0%；§4 优先级 P1-P15）。
- do_v9.md - do_v14.md：测试补充报告（P1-P7 共 +33 test 块，251→284）。
- 当前测试状态：284/284 全绿，moon check 26 warnings baseline。

## RETRY 说明
plan_review_v15_r1.md REJECTED，3 个严重发现，已全部修正：

1. **[严重] `Sem::Plain` 不存在**：`Sem` enum（automata.mbt:5-9）实际变体为 `Longest`/`Shortest`/`First`，无 `Plain`。原 task_v15.md 块 2 构造 `Expr::seq(ids1, Sem::Plain, a, b)` 和块 4 构造 `Expr::rep(ids1, RepKind::Star, Sem::Plain, a)` 及对应断言均使用了不存在的 `Sem::Plain`，编译会失败（`[4036] Unresolved constructor Sem::Plain`）。修正：所有 `Sem::Plain` 替换为 `Sem::Longest`（块 2 构造 + 断言 (a)、块 4 构造 + 断言 (a)），任务上下文 `Sem` enum 描述同步修正为实际变体。

2. **[严重] `RepKind::Star` 不存在**：`RepKind` enum（automata.mbt:12-15）实际变体为 `Greedy`/`NonGreedy`，无 `Star`。原 task_v15.md 块 4 构造 `Expr::rep(ids1, RepKind::Star, Sem::Plain, a)` 及断言 (a) 使用了不存在的 `RepKind::Star`，编译会失败。修正：`RepKind::Star` 替换为 `RepKind::Greedy`（块 4 构造 + 断言 (a)），任务上下文 `RepKind` enum 描述同步修正为实际变体。

3. **[严重] 块 3 断言 (c) `Expr::id(alt2) == 1` 与 Alt 分支执行顺序不符**：Alt 分支实现（automata_expr.mbt:167-170）为 `let l2 = Array::map(l, fn(e) { Expr::rename(ids, e) }); Alt(ids.next(), l2)`——`let l2 = Array::map(...)` 先执行，对 3 个子节点依次调用 rename 消耗 id 1/2/3，随后 `Alt(ids.next(), l2)` 分配根节点 id 得 4。故 `Expr::id(alt2)` 实际为 4，非 1。原断言隐含假设"根节点先 rename"对 Alt 分支不成立（对比 Seq/Rep 分支确实是根节点先 rename，但 Alt 分支因 `let l2 = ...` 在前导致子节点先 rename）。修正：断言 (c) 改为 `Expr::id(alt2) == 4`，并在块 3 描述中注明"Alt 分支先递归 rename 子节点消耗 id 1-3，根节点后分配 id 得 4"。同时补充任务上下文"id 分配顺序差异"段落，明确 Seq/Rep 根节点先分配 vs Alt 子节点先分配的差异，避免后续误解。

修正后覆写 task_v15.md（动作 NEW → RETRY，添加本 RETRY 说明），保持 ID T15 不变以追踪同一任务的多次尝试。
