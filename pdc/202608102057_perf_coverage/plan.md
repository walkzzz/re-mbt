# 任务计划

任务描述：re-mbt 性能优化 + 测试覆盖率提升（先性能后覆盖率）
工作目录：D:\CodeWorkspace\forMoonbit\re-mbt\pdc\202608102057_perf_coverage

---

## R1 NEW 建立 benchmark 基线 [ID: T1]
任务：运行 bench/run_bench.ps1 建立 10 个 section 的性能基线，结果写入 baseline.md；同时运行 moon test 确认全绿基线。
选择理由：性能优化的第一步必须建立可复现的基线，否则后续无法量化改进。任务描述明确要求"先做性能优化"，且方法第 1 步即"运行现有 benchmark 建立基线"。
上下文：bench/ 目录含 run_bench.ps1（10 section：Perl compile/match、Emacs、POSIX、Glob、Pcre、Str、Search all、Split+Replace、Large+Caseless），每个 section 跑 3 次取最佳，每 iter 5000 次。构建命令 moon build --target native --release。需先确认 moon test 全绿作为不回归的参照基线。

---

## R2 PASSED 建立 benchmark 基线 [ID: T1]
结果：产出 baseline.md，含测试基线（251/251 通过，0.21s）和 10 个 section 的 Benchmark 基线数据（Section 1 Perl compile=951ms 最高，Section 5/7 Glob/Str≈348ms 次之，Section 3/4 Emacs/POSIX≈276-281ms 再次之，纯匹配类≤43ms）。
检查：PASSED，8 项检查全部通过（产出存在性、测试基线完整性、section 数量=10、字段完整性、Per-iter 计算一致性、备注段完整性、do_v1 与 baseline 一致性、格式符合模板）。

## R2 NEW 分析 compile 路径代码热点 [ID: T2]
任务：深入分析 Section 1（Perl compile 951ms）的代码层面瓶颈，阅读 re/ 下核心模块（cset/compile/compile_translate/automata_*）源码，梳理 Perl 前端 compile 调用链，定位耗时集中的函数/方法及原因，产出热点分析报告 hotspot_analysis.md，含调用链概览、热点函数列表（按推测耗时排序，含文件:行号）、每个热点的优化方向建议（算法层/内存层/数据结构层）、优先级排序。
选择理由：baseline.md 已定位 benchmark 层面热点（compile 路径是主要瓶颈），但仅有 section 级耗时，需进一步在代码层面定位具体瓶颈函数，才能进行方法第 3 步"针对热点逐模块优化"。本任务是方法第 2 步"分析 benchmark 结果定位热点"的深化，为后续优化提供精确目标，避免盲目优化。
上下文：核心模块均在 re/ 目录下，优先级 cset.mbt(12.1KB) > compile.mbt(16.4KB) > automata_state.mbt(7.4KB) > automata_desc.mbt(8.2KB)，另有 compile_translate.mbt(8.0KB)/automata_expr.mbt(4.3KB)/color_map.mbt(4.3KB)。前端 perl.mbt(14.0KB)。优化方向分算法层/内存层/数据结构层。
