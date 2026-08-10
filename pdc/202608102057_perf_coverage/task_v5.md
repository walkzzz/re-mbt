# 任务指令（v5）

## 动作
NEW

## 任务描述

执行 hotspot_analysis.md 优先级序 5（A2 + M2），修改 `re/cset.mbt`：

### (1) A2：union_all/intersect_all 改分治归并

- `Cset::union_all`（cset.mbt:298-304）：当前 `acc = Cset::empty(); for t in ts { acc = Cset::union(acc, t) }` 两两累积。改为分治归并：递归二分 ts 数组，base case（空数组 → `Cset::empty()`，单元素 → 直接返回），递归 case（`Cset::union(分治左半, 分治右半)`）。减少中间结果规模和总合并工作量。
- `Cset::intersect_all`（cset.mbt:307-313）：当前 `acc = Cset::cany(); for t in ts { acc = Cset::inter(acc, t) }` 两两累积。改为分治归并：base case（空数组 → `Cset::cany()`，单元素 → 直接返回），递归 case（`Cset::inter(分治左半, 分治右半)`）。

### (2) M2：union/inter/diff result 预分配 capacity

- `Cset::union`（cset.mbt:105-163）：`let result : Array[(Int, Int)] = []` 改为 `let result = Array::new(capacity=l.intervals.length() + r.intervals.length())`（上界 = 两输入区间数之和）。
- `Cset::inter`（cset.mbt:166-186）：`let result : Array[(Int, Int)] = []` 改为 `let result = Array::new(capacity=if l.intervals.length() < r.intervals.length() { l.intervals.length() } else { r.intervals.length() })`（上界 = min(两输入区间数)）。
- `Cset::diff`（cset.mbt:189-）：`let result : Array[(Int, Int)] = []` 改为 `let result = Array::new(capacity=l.intervals.length() + r.intervals.length())`（上界 = l 区间数 + r 区间数，差集最坏情况）。

### 验证

1. `moon test` 全部通过（251/251），不回归
2. `moon check` 无新 warning（baseline 26 warnings）
3. `bench/run_bench.ps1` 对比 baseline.md + opt_v3.md 验证改进
4. 若实测无改进或负改进则 `git checkout re/cset.mbt` 回退改动并在 opt_v5.md 中标注原因（参考 T4 流程）

### 预期产出

`pdc/202608102057_perf_coverage/opt_v5.md`，含：
- §1 改动摘要
- §2 diff 关键行（before/after 代码片段）
- §3 moon test 结果
- §4 benchmark before/after 对比表（含 baseline / T3 后 / 本轮三方，10 section，标注 Δ%）
- §5 收益分析（实际 vs 预期、各 section 改进幅度、若负改进则归因）
- §6 风险/回归说明（语义等价性、warning 情况、纯 MoonBit 约束、回退决策若需、后续建议）

## 选择理由

- T4（序 2）已 PASSED（尝试性改动实测负改进已回退，代码 = T3 后版本）
- 序 3（D2+M3 CSetMap 哈希化 + Cset::hash 缓存）因 mbti 约束 BLOCKED：CSetMap.entries 和 Cset.intervals 均暴露于 pkg.generated.mbti，加字段或改结构会修改 mbti，违反任务约束
- 序 4（A4 translate_colors 位图去重）有 T4 负改进教训（位图构建固定开销对当前 cset 规模 |csets|≈5-15、Ī≈1-5 可能超边际节省），风险类似暂缓
- 序 5（A2+M2）可行：union_all/intersect_all/union/inter/diff 均为 cset.mbt 内部实现优化，不改 Cset pub struct（`{ intervals }` derive(Compare, Eq, Debug)）或 mbti；MoonBit Array 支持 `Array::new(capacity?)` 和 `reserve_capacity`（已确认），M2 技术可行
- 序 5 收益中、难度中、风险低，关联 H3（handle_case_cset 调用 union_all/intersect_all/case_insens）+ H6（Cset 运算频繁分配），是 T3 后剩余 compile 路径热点
- 符合任务方法第 3 步"针对热点逐模块优化"和第 4 步"每次优化后重新运行 benchmark 验证改进"

## 任务上下文

摘录自 hotspot_analysis.md 和 task.md：

- **H3 ★★ `Ast::handle_case` + `handle_case_cset`**（ast.mbt:173/:147）：将 Ast 转为 AstNoCase，对每个 CsetOf/Alternative/Complement/Intersection/Difference 调用 Cset 集合运算。`Cset::union_all`/`intersect_all` 累积式调用 `Cset::union`/`inter`，每次创建新 Cset + 新 Array，O(n) 次分配 + O(n × 总区间数) 拷贝。`Cset::case_insens` 固定调用 union_all 3 路。优化方向：算法层（union_all 改 k 路合并）+ 内存层（result 预分配）。
- **H6 ★ `Cset::union`/`inter`/`diff`**（cset.mbt:105/:166/:189）：每次调用新建 result Array + 新建 Cset 结构，频繁分配。被 union_all/intersect_all/handle_case_cset/cset_or_compl 大量调用。优化方向：内存层（result Array 预分配 capacity = n+m）+ 算法层（union_all k 路归并）。
- **序 5 优先级**：收益中、难度中、风险低，备注"union_all k 路合并 + result 预分配；handle_case_cset 受益"。
- **约束**：保持纯 MoonBit，无 C FFI；保持与 OCaml 上游行为一致；保持 latin1 大小写处理；不修改 pkg.generated.mbti；snake_case 命名；每轮优化后必须运行 moon test 确保不回归。

## 已有产出上下文

工作目录 `pdc/202608102057_perf_coverage/` 已有产出：

- `baseline.md`：原始 benchmark 基线（Section 1 Perl compile=951ms 最高，10 section 完整数据），moon test 251/251 通过基线
- `hotspot_analysis.md`：compile 路径热点分析（12 个热点 H1-H12，3 类优化方向 A1-A5/M1-M5/D1-D5，10 项优先级排序）。H1 ★★★ ColorMap::flatten 为单次 compile 最重函数
- `opt_v3.md`：T3 优化报告（序 1 A1+D3+M1，ColorMap::flatten 哈希去重 + ids 复用）。Section 1 951ms → 571.1ms（-39.95%），所有含 compile section 改进 32-46%。**当前代码状态 = T3 后版本**
- `opt_v4.md`：T4 优化报告（序 2 D1 局部，flatten 内联 Cset 256-bit 位图）。尝试性改动实测 Section 1 +1.08%（回退），已 `git checkout` 回退到 T3 后版本。代码无净改动
- `do_v4.md` / `check_v4.md`：T4 执行/检查报告，T4 PASSED（流程合规，负改进已回退）

**当前代码状态**：`re/color_map.mbt` = T3 后版本（flatten 哈希去重 + ids 复用），`re/cset.mbt` = 原始版本（union_all/intersect_all 两两累积，union/inter/diff result 无预分配）。本轮在此基础上优化 cset.mbt。

**对比基准**：baseline.md Section 1=951ms（原始）；opt_v3.md After=571.1ms（do_v3）/540.8ms（check_v3）（T3 后）。本轮 opt_v5.md 需对比三方。
