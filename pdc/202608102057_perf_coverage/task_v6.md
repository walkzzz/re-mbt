# 任务指令（v6）

## 动作
RETRY

## 任务描述

执行 hotspot_analysis.md 优先级序 6（D4 ColorMap::split 去重），但**改为在 `ColorMap::flatten` 入口一次性去重**而非 split 中去重——避免改 ColorMap pub struct 违反 mbti 约束。

### 具体改动

修改 `re/color_map.mbt` 的 `ColorMap::flatten`（:136-188，T3 后版本）：

1. **在 flatten 入口去重**（`let csets = self.csets` :139 之后、`BoundaryTable::create(csets)` :140 之前）：
   - 创建 `dedup_csets : Array[Cset] = []`（去重后列表）
   - 创建 `seen : @hashmap.HashMap[Int, Array[Cset]] = @hashmap.HashMap::HashMap([])`（key = `Cset::hash(cset)`，value = 桶内 csets 列表）
   - 遍历 `self.csets`，对每个 `cset`：
     - 算 `h = Cset::hash(cset)`
     - 查 `seen.get(h)`：若 `Some(bucket)`，在 bucket 内用 `Cset::equal` 线性比较；若找到相等 cset 则跳过（重复）；若未找到则 push 到 bucket 和 `dedup_csets`
     - 若 `None`，创建新桶 `[cset]`，`seen[h] = [cset]`，push 到 `dedup_csets`
2. **用 `dedup_csets` 替代 `self.csets`**：将后续 `BoundaryTable::create(csets)` 和 256 循环内 `for csetid in 0..<csets.length() { if Cset::mem(i, csets[csetid]) ... }` 中的 `csets` 改为 `dedup_csets`。

### 语义保持

flatten 返回 (ColorTable, BoundaryTable, ColorRepr) 语义不变：去重前后 csets 集合的并集相同，boundary table（由 csets 的边界字符决定）和 color table（由字符等价类决定）均与 csets 顺序/重复无关。

### 验证

1. 运行 `moon test` 确保不回归（251/251 全绿）
2. 运行 `moon check` 确保无新 warning（baseline 26 warnings）
3. **同环境 benchmark 对比**（消除环境漂移，参考 do_v5.md git stash 切换方法）：
   - 在同一会话内用 `git stash` 切换两个版本，分别运行 `bench/run_bench.ps1`（各 2 次取最优）：
     - **T5 后版本**：`re/color_map.mbt` = T3 后版本、`re/cset.mbt` = T5 后版本（即当前 HEAD `6364b65 v5 done` 的 color_map.mbt + cset.mbt）
     - **T6 版本**：`re/color_map.mbt` 含本轮去重改动、`re/cset.mbt` = T5 后版本
   - 对比 T5 后和 T6 的**同环境数值**判定改进/回退（这是回退决策的唯一依据）
   - `baseline.md` 历史数值仅用于三方对比表展示累积改进幅度（Δ vs Baseline），**不用于回退决策**
4. **若实测无改进或负改进**则 `git checkout re/color_map.mbt` 回退改动，并在 opt_v6.md 中标注原因（参考 T4 流程）

### 预期产出

`opt_v6.md`，含：
- §1 改动摘要
- §2 diff 关键行（before/after 代码片段）
- §3 moon test 结果
- §4 benchmark before/after 对比表（含 baseline/T5/本轮三方，10 section，标注 Δ vs T5 和 Δ vs Baseline；**T5 后/本轮为同环境重测数值，baseline 为历史参考**）
- §5 收益分析（实际 vs 预期、收益归因）
- §6 风险/回归说明（测试回归、语义等价性、warning 情况、纯 MoonBit 约束、mbti 约束、回退决策）

## 选择理由

- **与已完成任务的关系**：T5（序 5）已 PASSED，性能优化已完成序 1（T3 大收益 -39.95%）/序 5（T5 中收益 -3.02%），序 2（T4 负改进回退）/序 3（mbti BLOCKED）已处理。本轮继续性能优化序 6。
- **当前优先级**：剩余序 4（A4 translate_colors 位图）有 T4 负改进教训暂缓，序 6（D4 split 去重）是下一候选（收益中、难度低、风险低）。序 7（A3+M5 merge_sequences_no_case）风险中暂后排。序 8-9 高风险放后期。
- **为何改在 flatten 去重而非 split**：原序 6 建议在 split 中去重，但 split 是 `pub fn`（mbti:174）且 ColorMap pub struct（mbti:169-171）只有 `csets` 字段。split 中**高效去重**（跨调用维护 HashSet/HashMap 缓存）需改 struct 加缓存字段 → 违反 mbti 约束（同 T5-skip 教训）；split 中**局部线性查找**（每次 split 遍历 self.csets 用 Cset::equal 检查）虽不改 struct 但低效（每次 split O(|csets| × Ī)，总 O(|AST| × |csets| × Ī)）。改为在 flatten 入口一次性去重：flatten 是 `pub fn`（mbti:172）但内部实现可自由改，去重逻辑在函数体内，不改 struct/签名/mbti，且一次性 O(|csets| × Ī) 比 split 逐个 O(|csets|² × Ī) 更优。
- **预期收益**（基于 hotspot_analysis.md §6 附注的静态推测，非实测确认）：§6 附注"实际 |csets| 可能因重复翻倍"为静态推测（§6 表格标注"大致 cset 数"），实际重复率待实测。若 |dedup| ≈ |csets|（重复率低），去重收益小。但从开销-收益分析看：去重开销 O(|csets| × Ī)（算 hash + 桶内 equal），收益 256 × (|csets| - |dedup|) × Ī（减少 256 循环 Cset::mem 调用），**256 倍放大使收益通常超开销**（只要 |csets| - |dedup| ≥ 1 且 |csets| < 256），负改进风险较低。且保留了回退分支兜底。
- **风险与回退**：去重本身 O(|csets| × Ī) 开销（算 hash + 桶内 equal），若重复率低则可能负改进（类似 T4 教训），故保留回退分支。

## 任务上下文

摘录与当前任务直接相关的需求/约束：

- **任务约束**（task.md）：保持纯 MoonBit 实现，不引入 C FFI；不修改 pkg.generated.mbti；代码命名遵循 snake_case 风格；每轮优化后必须运行 moon test 确保不回归。
- **验证标准**（task.md 阶段一）：moon test 全部通过；benchmark 结果有可测量的改进；无新 warning 引入。
- **hotspot_analysis.md 序 6**：D4 ColorMap::split 去重，收益中、难度低、风险低，备注"ColorMap::split 去重，减少 |csets| 直接放大 H1 收益"。关联 H5（colorize/split 无去重 push）+ H1（flatten 256 × |csets| × Ī）。
- **hotspot_analysis.md §6 附注**："Ast::colorize 对每个 Set 调用 ColorMap::split，但 split 无去重（H5），相同 cset 会重复进入 flatten。实际 |csets| 可能因重复翻倍。这进一步支持 D4（split 去重）的优先级。"（注：此附注为静态推测，§6 表格标注"大致 cset 数"，非实测确认）
- **T3 后 flatten 实现**（color_map.mbt:136-188）：`let csets = self.csets` :139 → `BoundaryTable::create(csets)` :140 → 256 循环 `for csetid in 0..<csets.length() { if Cset::mem(i, csets[csetid]) ... }` :153-157。已用 HashMap 对 ids 去重（A1+D3，:148），但未对 csets 去重。
- **Cset API**：`Cset::hash`（cset.mbt:327）O(Ī) 算 hash；`Cset::equal`（cset.mbt，线性扫描 intervals）做内容比较。@hashmap.HashMap 已在 T3 使用（color_map.mbt:148），moonbitlang/x 依赖。
- **mbti 约束**：ColorMap pub struct `{ csets : Array[Cset] }` 暴露于 mbti:169-171，不可改字段。flatten 是 `pub fn ColorMap::flatten(Self) -> (ColorTable, BoundaryTable, ColorRepr)`（mbti:172），签名不可改，但函数体可自由改。

## 已有产出上下文

工作目录中已有的相关产出概述：

- **baseline.md**：10 section 原始基线，Section 1 Perl compile=951ms 为原始基准（历史参考，不用于本轮回退决策）。
- **hotspot_analysis.md**：compile 路径热点分析，12 个热点函数（H1-H12），3 类优化方向（A1-A5 算法层/M1-M5 内存层/D1-D5 数据结构层），10 项优先级排序。H1（ColorMap::flatten）为 ★★★ 主热点，H5（colorize/split 无去重）放大 H1 成本。
- **opt_v3.md**：T3 优化报告，ColorMap::flatten 哈希去重 unique_lists（A1+D3）+ ids 缓冲复用（M1）。Section 1 951ms → 571.1ms（-39.95%）。**这是当前 color_map.mbt 的 flatten 实现**。
- **opt_v4.md**：T4 优化报告，flatten 内层 Cset::mem 位图尝试，负改进回退。代码 = T3 后版本。
- **opt_v5.md**：T5 优化报告，cset.mbt union/inter/diff result 预分配 + union_all/intersect_all 分治归并。Section 1 520.5ms → 504.8ms（-3.02%），所有 10 section 均正改进。**这是当前 cset.mbt 的实现**。T5 后 Section 1=504.8ms 为本轮同环境对比基准。
- **当前代码状态**：git HEAD = `6364b65 v5 done`，工作区干净（git status 无输出）。color_map.mbt = T3 后版本，cset.mbt = T5 后版本。
- **已确认技术**：@hashmap.HashMap[Array[Int], Int] 已在 flatten 中使用（T3），@hashmap.HashMap[Int, Array[Cset]] 同理可用。Cset::hash/Cset::equal 为 pub fn，可调用。
- **同环境 benchmark 方法**（参考 do_v5.md §3）：同一会话内用 git stash 切换版本，各版本跑 2 次 bench 取最优，消除环境漂移。T4 正是靠同环境对比才发现 +1.08% 负改进而正确回退。

## RETRY 说明

上一轮 plan_review_v6_r1.md REJECTED，3 个发现（1 个一般 + 2 个轻微），修改要求问题 1。本轮修正方向：

1. **[一般] 同环境 benchmark 对比未明确要求**（主要修正）：验证第 3 步原表述"运行 bench/run_bench.ps1 对比 baseline.md + opt_v5.md（T5 后）验证改进"倾向于直接用历史数值对比，未明确要求同环境重测。现改为明确要求同环境对比（git stash 切换 T5 后版本和 T6 版本，各 2 次取最优），同环境数值为回退决策唯一依据，baseline.md 历史数值仅用于三方对比表展示累积改进幅度。预期产出 §4 对比表标注"T5 后/本轮为同环境重测数值，baseline 为历史参考"。理由：T6 预期收益"中"，改进幅度可能较小（参考 T5 的 -3.02%），环境漂移可能与改进幅度相当导致回退决策误判（误回退失去收益 / 误保留引入性能回归），T4/T5 都实际用了同环境对比。
2. **[轻微] "在 split 中加去重需改 struct 加 seen 字段"理由表述不精确**：修正为"split 中高效去重需改 struct 加缓存字段，局部线性查找低效，故改在 flatten 入口一次性去重"。split 函数体内可用局部变量做线性去重（无需改 struct），只是低效；高效去重（跨调用缓存）才需改 struct。
3. **[轻微] 预期收益基于未实测假设**：在"预期收益"和"任务上下文"中明确标注 hotspot_analysis.md §6 附注为静态推测（非实测确认），补充开销-收益分析说明 256 倍放大使收益通常超开销，负改进风险较低，且保留回退分支兜底。
