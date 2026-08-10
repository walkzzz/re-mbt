# 执行报告（v2）

## 概述
深入分析 re-mbt compile 路径的代码层面热点，基于静态源码分析 + Section 1 benchmark 数据（Perl compile 951ms / 5000 iters / 8 patterns = 190.19us/compile）推断，产出 `hotspot_analysis.md`，包含 compile 调用链概览、12 个热点函数列表（按推测耗时排序）、3 类优化方向建议（算法层/内存层/数据结构层）、10 项优先级排序及验证建议。

## 产出清单
| 操作 | 文件路径 | 说明 |
|------|---------|------|
| 新建 | D:\CodeWorkspace\forMoonbit\re-mbt\pdc\202608102057_perf_coverage\hotspot_analysis.md | compile 路径热点分析报告 |

## 执行过程
1. **阅读核心模块源码**（9 个文件）：compile.mbt（791 行）、compile_translate.mbt（301 行）、cset.mbt（683 行）、automata_state.mbt（335 行）、automata_desc.mbt（410 行）、automata_expr.mbt（205 行）、automata.mbt（195 行）、color_map.mbt（200 行）、core.mbt（194 行）。
2. **阅读 Perl 前端**：perl.mbt（604 行），梳理从 `Perl::compile_pat` → `Perl::re` 解析 → `compile` → `compile_1` 的完整调用链。
3. **阅读辅助模块**：ast.mbt（736 行，handle_case/colorize/merge_sequences_no_case）、hash_set.mbt、bit_vector.mbt、dense_map.mbt、mark_infos.mbt，理解 cset 运算与 color map 构建的依赖。
4. **阅读 benchmark**：bench/main/main.mbt Section 1（8 个 Perl 模式 × 5000 iters），确认 compile 路径无 match 参与、lazy DFA 状态表编译期为空。
5. **结合 baseline.md 数据**（Section 1=951ms 远高于其他）推断耗时集中点：`ColorMap::flatten`（256 循环 × Cset::mem × unique_lists 线性去重）为首要热点，`translate`/`trans_set`/`ColorTable::translate_colors`（逐字符着色 + CSetMap 线性查找）为次热点，`Ast::handle_case`/`merge_sequences_no_case`（Cset 运算 + 递归 Array 分配）再次之。
6. **撰写报告**：按任务要求产出 4 部分——调用链概览（含 ASCII 调用树）、热点函数列表（12 项，每项含文件:行号、功能、耗时原因、复杂度、优化方向）、优化方向建议（算法层 A1-A5 / 内存层 M1-M5 / 数据结构层 D1-D5）、优先级排序（10 项表格，综合耗时占比×难度×风险）。附加 8 个 Perl 模式的 cset 规模估算表，支撑 D4（split 去重）的优先级判断。
7. **关键判断**：编译期 lazy DFA 状态表为空（状态在 match 时 lazily 构建），故 Section 1 的 190us 几乎全花在 AST 处理 + ColorMap flatten + translate 三段，而非 DFA 状态探索。这一判断将优化焦点锁定在前端/编译翻译层而非自动机层。
8. **风险标注**：D1（Cset 公开表示改位图）和 A5（Expr::rename 改共享）标为高风险，建议暂缓或后期做；序 1-3（flatten 哈希化、Cset 位图仅 flatten 内联、CSetMap 哈希化）为低风险局部优化，建议优先执行。

## 偏差说明
无。任务要求产出 `hotspot_analysis.md` 包含 4 部分内容，均已覆盖；未做函数级 profiling（报告第 5 节已说明并给出验证建议），符合"深入分析 + 推断"的任务定位。
