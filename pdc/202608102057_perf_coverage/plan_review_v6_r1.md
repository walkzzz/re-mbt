# 计划审查报告（v6 r1）

## 审查结果
REJECTED

## 发现

- **[一般]** 同环境 benchmark 对比未明确要求，可能导致回退决策误判。task_v6.md 验证第 3 步"运行 bench/run_bench.ps1 对比 baseline.md + opt_v5.md（T5 后）验证改进"倾向于直接用历史数值（baseline.md / opt_v5.md）与新测数值对比，没有明确要求同环境重测 T5 后版本和 T6 版本（git stash 切换消除环境漂移）。然而 T4（do_v4.md："同环境 benchmark 实测 Section 1 +1.08%（回退）"）和 T5（do_v5.md："同环境 benchmark（T5 2 次取最优 vs T3 后 2 次取最优，git stash 切换消除漂移）"）都实际采用了同环境对比，T4 正是通过同环境对比才发现 +1.08% 负改进而正确回退——若 T4 直接对比历史数值，环境漂移可能掩盖负改进导致错误保留。T6 预期收益标为"中"（hotspot_analysis.md 序 6），改进幅度可能较小（参考 T5 的 -3.02%），若环境漂移幅度与改进幅度相当，直接对比历史数值会导致：(a) 误回退——T6 实际正改进但显示负改进，回退失去收益；(b) 误保留——T6 实际负改进但显示正改进，保留引入性能回归，违反 task.md 验证标准"benchmark 结果有可测量的改进"。计划第 4 步"参考 T4 流程"仅指回退操作流程（git checkout + 标注原因），不隐含同环境对比要求。计划应明确要求同环境重测 T5 后版本和 T6 版本（参考 do_v5.md 的 git stash 切换方法），baseline.md 历史数值仅作参考展示累积改进幅度。

- **[轻微]** "在 split 中加去重需改 struct 加 seen 字段"理由表述不精确。task_v6.md 选择理由称"split 是 pub fn（mbti:174）且 ColorMap pub struct（mbti:169-171）只有 csets 字段，在 split 中加去重需改 struct 加 seen 字段 → 违反 mbti 约束"。但实际上 split（color_map.mbt:31-33，当前实现 `self.csets.push(cset_or_compl(set))`）是 pub fn，函数体内可用局部变量做去重——每次 split 调用时线性遍历 self.csets 用 Cset::equal 检查是否已含该 cset，无需改 struct。只是这种局部线性查找方案低效（每次 split O(|csets| × Ī)，总 O(|AST| × |csets| × Ī)），高效去重（struct 内 HashSet/HashMap 缓存跨调用维护）才需改 struct。计划的结论（改在 flatten 入口一次性去重）是合理替代方案（一次性 O(|csets| × Ī) vs split 逐个 O(|csets|² × Ī)），甚至更优，不影响可行性。但理由表述应修正为"split 中高效去重需改 struct 加缓存字段，局部线性查找低效，故改在 flatten 入口一次性去重"。

- **[轻微]** 预期收益基于未实测假设。task_v6.md 预期收益引用 hotspot_analysis.md §6 附注"实际 |csets| 可能因重复翻倍"作为去重收益依据，但该附注是静态推测（§6 表格标注"大致 cset 数"），非实测确认。若实际重复率低（|dedup| ≈ |csets|），去重收益小。不过从开销-收益分析看：去重开销 O(|csets| × Ī)（算 hash + 桶内 equal），收益 256 × (|csets| - |dedup|) × Ī（减少 256 循环 Cset::mem 调用），256 倍放大使收益通常超开销（只要 |csets| - |dedup| ≥ 1 且 |csets| < 256），负改进风险较低。且计划保留了回退分支兜底。此缺陷不影响计划可行性。

## 修改要求（仅 REJECTED 时）

### 问题 1：同环境 benchmark 对比未明确要求

**问题是什么**：task_v6.md 验证第 3 步"运行 bench/run_bench.ps1 对比 baseline.md + opt_v5.md（T5 后）验证改进"没有明确要求同环境重测 T5 后版本和 T6 版本（git stash 切换消除环境漂移），倾向于直接用历史数值对比。

**为什么是问题**：T6 预期收益"中"，改进幅度可能较小（参考 T5 的 -3.02%）。环境漂移可能与改进幅度相当，导致回退决策误判：(a) 误回退失去收益；(b) 误保留引入性能回归，违反"benchmark 结果有可测量的改进"验证标准。T4/T5 都实际用了同环境对比（git stash 切换），T4 正是靠同环境对比才发现负改进而正确回退。不同环境的历史数值对比无法可靠判定小幅改进。

**期望的修正方向**：在 task_v6.md 验证第 3 步明确要求同环境对比：在同一会话内用 git stash 切换 T5 后版本（re/color_map.mbt = T3 后、re/cset.mbt = T5 后）和 T6 版本（re/color_map.mbt 含去重改动、re/cset.mbt = T5 后），分别运行 bench/run_bench.ps1（各 2 次取最优），对比 T5 后和 T6 的同环境数值判定改进/回退。baseline.md 历史数值仅用于三方对比表展示累积改进幅度（Δ vs Baseline），不用于回退决策。预期产出 §4 benchmark 对比表应标注"T5 后/本轮同环境重测，baseline 为历史参考"。
