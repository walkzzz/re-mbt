# 任务指令（v7）

## 动作
NEW

## 任务描述
执行 hotspot_analysis.md 优先级序 7（A3 + M5），修改 re/ast.mbt 的 `merge_sequences_no_case_from`（:343-420）和 `merge_sequences_from`（:252-324）：

(1) **A3 算法层**：将递归改迭代 + 索引区间表示子数组，避免每层新建 Array。当前递归每层新建 `combined`/`y`/`y2`/`result` Array 并逐元素 push 拷贝（如 :353-359 combined、:365-368 y、:374-377 y2、:382-385 result），改迭代用索引区间（start/end）引用原数组子段，仅在最终结果时按需构建 Array。

(2) **M5 内存层**：中间 Array（combined/y/y2/result）改预分配 capacity 或复用，消除动态扩容和每层新建分配。当前已用 push 但每层新建 Array，可预分配上界 capacity（combined 上界 = |l2| + |l| - start - 1，y/y2 上界 = |xs| - 1，result 上界 = |merged_rest| + 1）。

保持 `merge_sequences_no_case`/`merge_sequences` 语义不变（公共前缀合并 NoCase 优化，pub fn 签名不改，mbti 不改）。

完成后：
1. 运行 `moon test` 确保不回归（251/251 全绿）
2. 同环境 benchmark 对比（T7 vs T5 后，各 2 次取最优，git stash 切换消除漂移），验证改进
3. 若实测无改进或负改进则 `git checkout re/ast.mbt` 回退改动并在 opt_v7.md 中标注原因（参考 T4/T6 流程）

预期产出：opt_v7.md，含 6 项：
- §1 改动摘要
- §2 diff 关键行（before/after 代码片段）
- §3 moon test 结果
- §4 benchmark before/after 对比表（含 baseline/T5/本轮三方，10 section，标注 Δ vs T5 和 Δ vs Baseline，附原始 4 次运行数据，T5 后/本轮为同环境重测，baseline 为历史参考）
- §5 收益分析（实际 vs 预期）
- §6 风险/回归说明

## 选择理由
T6 已 PASSED（回退），性能优化已完成序 1（T3 大收益 -39.95%）/序 5（T5 小收益 -3.02%），序 2（T4 负改进回退）/序 6（T6 负改进回退）/序 3（mbti BLOCKED）已处理。

剩余候选：
- 序 4（A4 translate_colors 位图去重）— 有 T6 同类去重负改进教训暂缓
- 序 7（A3+M5）— hotspot_analysis.md 建议范围（4-7）内未尝试的方向
- 序 8/9 — 风险高放后期

序 7 非去重/位图类优化（算法层递归改迭代 + 内存层 Array 复用），与 T4/T6 负改进教训不同，关联 H4 ★★（merge_sequences_no_case 最坏 O(n²)，每层新建 Array 大量分配+拷贝）。`merge_sequences_no_case_from`（ast.mbt:343）和 `merge_sequences_from`（ast.mbt:252）均为内部 fn 不暴露 mbti，`pub fn Ast::merge_sequences_no_case`（:423）和 `pub fn Ast::merge_sequences`（:327）签名不改，技术可行。

序 7 收益中、难度中、风险中（需保持 NoCase 语义），是 T5 后剩余 compile 路径热点。符合任务方法第 3 步"针对热点逐模块优化"和第 4 步"每次优化后重新运行 benchmark 验证改进"。

## 任务上下文
- ast.mbt:343-420 `merge_sequences_no_case_from`（递归，每层新建 combined/y/y2/result Array，已用 push 但每层新建）
- ast.mbt:252-324 `merge_sequences_from`（带 case 版本，结构类似）
- ast.mbt:423-425 `pub fn Ast::merge_sequences_no_case`（mbti:105，签名 `Array[AstNoCase] -> Array[AstNoCase]` 不改）
- ast.mbt:327-329 `pub fn Ast::merge_sequences`（mbti:104，签名 `Array[Ast] -> Array[Ast]` 不改）
- compile_translate.mbt:106 调用 merge_sequences_no_case
- 仅 Alternative 节点触发，对含 `(a|b)*c`、`(?:ab|cd|ef)+`、`[^aeiou][aeiou][^aeiou]` 等模式命中
- baseline.md Section 1=951ms 原始基线
- opt_v5.md T5 后=504.8ms（do_v5）/509.1ms（check_v6 同环境重测）为上一轮基线，本轮同环境对比 T7 vs T5 后

约束：
- 纯 MoonBit 无 C FFI
- snake_case 命名
- 不修改 pkg.generated.mbti
- 保持 merge_sequences_no_case/merge_sequences 语义不变（公共前缀合并 NoCase 优化）
- 保持 latin1 大小写处理

## 已有产出上下文
- baseline.md：10 section 基线（Section 1 Perl compile=951ms 最高）
- hotspot_analysis.md：12 个热点函数（H1-H12）+ 3 类优化方向（A1-A5/M1-M5/D1-D5）+ 10 项优先级排序
- opt_v3.md：T3 序1 ColorMap::flatten 哈希去重 + ids 复用，Section 1 -39.95%
- opt_v4.md：T4 序2 flatten 内层 Cset::mem 位图，负改进回退
- opt_v5.md：T5 序5 union_all/intersect_all 分治 + capacity 预分配，Section 1 -3.02%（T3 后累计）
- opt_v6.md：T6 序6 flatten 入口 csets 去重，负改进回退
- 当前代码状态：re/color_map.mbt = T3 后版本，re/cset.mbt = T5 后版本，git HEAD=e64ec54 v6 done，working tree clean
- 同环境 benchmark 方法：git stash 切换版本，各 2 次取最优，参考 do_v5.md §3 / do_v6.md §3
