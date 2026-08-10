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

---

## R3 PASSED 分析 compile 路径代码热点 [ID: T2]
结果：产出 hotspot_analysis.md（18963 字节，214 行），含 compile 调用链概览（含 ASCII 调用树）、12 个热点函数列表（H1-H12 按推测耗时排序，每项含文件:行号、功能、耗时原因、复杂度、优化方向）、3 类优化方向建议（算法层 A1-A5 / 内存层 M1-M5 / 数据结构层 D1-D5）、10 项优先级排序表格。关键判断：编译期 lazy DFA 状态表为空，Section 1 的 190us 几乎全花在 AST 处理 + ColorMap flatten + translate 三段。H1（ColorMap::flatten @color_map.mbt:149-199）为 ★★★ 主热点。
检查：PASSED，9 项检查全部通过（产出存在性、4 部分内容完整性、调用链概览要求、热点函数列表要求、优化方向建议要求、优先级排序要求、关键行号引用准确性、与 baseline 数据一致性、任务边界遵守）。

## R3 NEW 优化 ColorMap::flatten unique_lists 哈希去重 + ids 缓冲复用 [ID: T3]
任务：执行 hotspot_analysis.md 优先级序 1（A1 + D3 + M1），修改 re/color_map.mbt 的 `ColorMap::flatten`（:149-199）：(1) A1+D3 将 `unique_lists : Array[Array[Int]]` 线性去重改为哈希去重（按 ids 内容计算哈希 key，桶内再内容比较），消除 O(256 × |unique| × |ids|) 线性查找；(2) M1 将每字节新建的 `ids : Array[Int]` 改为预分配缓冲复用（clear 后重用），消除 256 次 Array 分配。保持 ColorTable/ColorRepr 语义不变。完成后运行 `moon test` 确保不回归，运行 `bench/run_bench.ps1` 对比 baseline.md 验证改进；若实测无改进或负改进则回退改动并在 opt_v3.md 中标注原因。产出优化报告 opt_v3.md（含改动摘要、diff 关键行、test 结果、benchmark before/after 对比表、收益分析、风险/回归说明）。
选择理由：T2 已定位 `ColorMap::flatten`（H1 ★★★）为单次 compile 最重函数，hotspot_analysis.md 优先级序 1 明确建议"先做 1-3（局部、低风险、高收益）"。序 1 改动仅限 color_map.mbt::flatten 内部，不触及 Cset 公开表示，风险低；预期收益高（flatten 是 256 × |csets| × Ī 的主热点）。符合任务方法第 3 步"针对热点逐模块优化"和第 4 步"每次优化后重新运行 benchmark 验证改进"。注：color_map.mbt 不在 task.md 静态核心模块优先级列表（cset>compile>automata_state>...）中，此处依据 T2 实测热点分析结论（H1 ★★★ 位于 color_map.mbt::flatten）选择，实测数据比静态文件大小排序更可靠。
上下文：color_map.mbt:149-199 为 flatten 实现，当前 `unique_lists` 为 `Array[Array[Int]]`，去重靠 `array_int_eq`（:136）线性扫描；`ids` 在 256 循环内每轮新建。优化需保持 flatten 返回的 ColorTable（256 字节颜色表）+ BoundaryTable + ColorRepr 三者语义不变。baseline.md Section 1=951ms 为对比基准。约束：纯 MoonBit 无 C FFI，snake_case 命名，不修改 pkg.generated.mbti。
