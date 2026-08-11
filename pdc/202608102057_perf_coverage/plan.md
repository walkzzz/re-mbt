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

---

## R3 PASSED 优化 ColorMap::flatten unique_lists 哈希去重 + ids 缓冲复用 [ID: T3]
结果：产出 opt_v3.md，ColorMap::flatten 重写为 HashMap[Array[Int], Int] 哈希去重（A1+D3）+ ids_buf 循环外预分配复用（M1）+ 删除 else 分支死代码。moon test 251/251 全绿。benchmark Section 1（Perl compile）951.0ms → 571.1ms（-39.95%，do_v3 声称）/ 540.8ms（-43.12%，check_v3 独立复测），所有含 compile 的 section 改进 32-46%，远超序 1 预期。moon check 26 warnings（较 baseline -2），无新 warning。
检查：PASSED，13 项检查全部通过（A1 哈希去重/D3 HashMap/M1 ids 复用/array_int_eq 删除/死代码语义等价/flatten 返回语义/moon test/moon check/benchmark Section 1/benchmark 全 section/opt_v3.md 完整性/纯 MoonBit/snake_case/不修改 mbti），独立 benchmark 复测验证 do_v3 声称真实可信。

## R4 NEW 优化 ColorMap::flatten 内层 Cset::mem 改 256-bit 位图 O(1) 查询 [ID: T4]
任务：执行 hotspot_analysis.md 优先级序 2（D1 局部：flatten 内联 Cset 位图），修改 re/color_map.mbt 的 `ColorMap::flatten`（:136-188）：(1) 在 flatten 入口（BoundaryTable::create 之后、256 循环之前）对 self.csets 中每个 cset 预构建 256-bit 位图（`Array[FixedArray[Byte]]` of 32 bytes/each），用 Cset::iter 遍历区间 [c1,c2] 逐位设置（bitmap[(c >> 3)] |= 1 << (c & 7)）；(2) 将 256 循环内 `Cset::mem(i, csets[csetid])`（O(Ī) 线性扫描 intervals）替换为位测试 `(bitmaps[csetid][i >> 3]).to_int() & (1 << (i & 7)) != 0`（O(1)），消除 H7 的 256 × |csets| × Ī 次 interval 比较。保持 flatten 返回 (ColorTable, BoundaryTable, ColorRepr) 语义不变。完成后运行 `moon test` 确保不回归，运行 `bench/run_bench.ps1` 对比 baseline.md + opt_v3.md 验证改进；若实测无改进或负改进则回退改动并在 opt_v4.md 中标注原因。产出优化报告 opt_v4.md（含改动摘要、diff 关键行、test 结果、benchmark before/after 对比表含 baseline/T3/本轮三方、收益分析、风险/回归说明）。
选择理由：T3（序 1）已 PASSED，flatten 的 unique_lists 哈希去重瓶颈已消除（Section 1 -39.95%）。flatten 内层 `Cset::mem`（H7 ★）成为剩余主要开销：对每个字节 i × 每个 cset 调用 Cset::mem，共 256 × |csets| 次，每次 O(Ī) 线性扫描 intervals，总计 O(256 × |csets| × Ī)。hotspot_analysis.md 序 2 明确建议"先做 1-3（局部、低风险、高收益）"，序 2 收益"高"、风险"中"、备注"可先不改 Cset 公开表示，仅在 flatten 中把每个 cset 预展开为 256-bit 位图，mem 变 O(1)；改动局部"。序 2 排在序 3 之前（综合优先级更高），且延续对 H1 ★★★ 主热点的优化，消除其内层 H7 瓶颈。符合任务方法第 3 步"针对热点逐模块优化"和第 4 步"每次优化后重新运行 benchmark 验证改进"。
上下文：color_map.mbt:150-157 为当前 flatten 的 256 循环 + Cset::mem 调用点（T3 后版本）；cset.mbt:316-324 为 Cset::mem 实现（线性扫描 intervals）；Cset::iter（cset.mbt:338）可遍历区间构建位图。位图表示选 FixedArray[Byte] of 32 bytes（256 bits），索引 c>>3（0-31）选字节、c&7（0-7）选位，纯整数位运算无依赖。baseline.md Section 1=951ms 为原始基线；opt_v3.md After=571.1ms（do_v3）/540.8ms（check_v3）为序 1 后基线，本轮对比二者。约束：纯 MoonBit 无 C FFI（FixedArray[Byte] + 位运算是核心类型），snake_case 命名，不修改 pkg.generated.mbti，保持 latin1 大小写处理。

---

## R5 PASSED 优化 ColorMap::flatten 内层 Cset::mem 改 256-bit 位图 O(1) 查询 [ID: T4]
结果：尝试性改动（color_map.mbt:139-157 预构建位图 + :170-176 位测试替换 Cset::mem），moon check 26 warnings/0 errors、moon test 251/251 全绿，但同环境 benchmark 实测 Section 1 +1.08%（回退），含 compile 的 section（3/4/5/6/7）全部回退 4-7%。位图构建固定开销（|csets| × 32 bytes 分配 + Σ interval_length 次位设置）超过 mem 查询的边际节省（原 Cset::mem 平均 1-3 次比较即判定）。已 `git checkout re/color_map.mbt` 回退到 T3 后版本，产出 opt_v4.md 记录尝试 + 6 条负改进归因 + 回退决策。代码最终状态 = T3 后版本（git diff 无输出，无净改动）。
检查：PASSED，11 项检查全部通过（产出存在性、opt_v4.md 五项完整性、benchmark 三方对比表 10 section、re/color_map.mbt 回退验证、moon test 251/251、moon check 26 warnings、回退决策合规性、负改进归因 6 条、纯 MoonBit、语义等价性、diff 可读性、do_v4 一致性）。

## R5 BLOCKED 序 3 CSetMap 哈希化 + Cset::hash 缓存 [ID: T5-skip]
原因：D2（CSetMap 改哈希表）需改 CSetMap.entries 字段类型（当前 `Array[(Int, Cset, Cset)]` 暴露于 mbti:143-145），M3（Cset::hash 缓存）需给 Cset 加 `mut hash_cache : Int?` 字段（当前 `pub struct Cset { intervals } derive(Compare, Eq, Debug)` 暴露于 mbti:210-212，加 mut 字段破坏 derive）。二者均修改 pkg.generated.mbti，违反任务约束"不修改 pkg.generated.mbti"。跳过序 3，转向序 5。

## R5 NEW 优化 Cset::union_all/intersect_all 分治归并 + union/inter/diff result 预分配 capacity [ID: T5]
任务：执行 hotspot_analysis.md 优先级序 5（A2 + M2），修改 re/cset.mbt：(1) A2 将 `union_all`（:298-304）和 `intersect_all`（:307-313）的两两累积改分治归并——递归二分 ts，base case 单元素直接返回、空数组返回空集（union_all）/全集（intersect_all），递归 case 用 `Cset::union`/`Cset::inter` 合并两半，减少中间结果规模和总合并工作量从 O(k × |最终结果|) 到 O(总区间数 × log k)；(2) M2 给 `Cset::union`（:105-163）、`Cset::inter`（:166-186）、`Cset::diff`（:189-）的 `result : Array[(Int, Int)] = []` 改为 `Array::new(capacity=上界)` 预分配——union/diff 上界 = l.intervals.length() + r.intervals.length()，inter 上界 = min(l.intervals.length(), r.intervals.length())，消除动态扩容。保持 union/inter/diff/union_all/intersect_all 语义不变（输入输出 Cset 的 intervals 仍为排序不相交区间列表）。完成后运行 `moon test` 确保不回归，运行 `bench/run_bench.ps1` 对比 baseline.md + opt_v3.md 验证改进；若实测无改进或负改进则回退改动并在 opt_v5.md 中标注原因（参考 T4 流程）。产出优化报告 opt_v5.md（含改动摘要、diff 关键行、test 结果、benchmark before/after 对比表含 baseline/T3/本轮三方、收益分析、风险/回归说明）。
选择理由：T4（序 2）已 PASSED（尝试回退，代码 = T3 后版本），序 3（D2+M3）因 mbti 约束 BLOCKED，序 4（A4 translate_colors 位图去重）有 T4 负改进教训（位图构建固定开销对当前 cset 规模可能超边际节省）风险类似暂缓。序 5（A2+M2）可行：union_all/intersect_all/union/inter/diff 均为 cset.mbt 内部实现优化，不改 Cset pub struct（`{ intervals }` derive(Compare, Eq, Debug)）或 mbti；MoonBit Array 支持 `Array::new(capacity?)` 和 `reserve_capacity`（已确认），M2 技术可行。序 5 收益中、难度中、风险低，关联 H3（handle_case_cset 调用 union_all/intersect_all/case_insens）+ H6（Cset 运算频繁分配），是 T3 后剩余 compile 路径热点。符合任务方法第 3 步"针对热点逐模块优化"和第 4 步"每次优化后重新运行 benchmark 验证改进"。
上下文：cset.mbt:298-304 union_all（`acc=empty; for t { acc=union(acc,t) }` 两两累积）、:307-313 intersect_all（`acc=cany; for t { acc=inter(acc,t) }` 两两累积）、:105-163 union（双指针合并，result 无预分配）、:166-186 inter（双指针相交，result 无预分配）、:189- diff（双指针差集，result 无预分配）。handle_case_cset（ast.mbt:147）调用 union_all/intersect_all/case_insens，case_insens（cset.mbt:545）固定调用 union_all 3 路。baseline.md Section 1=951ms 为原始基线；opt_v3.md After=571.1ms（do_v3）/540.8ms（check_v3）为 T3 后基线，本轮对比二者。约束：纯 MoonBit 无 C FFI，snake_case 命名，不修改 pkg.generated.mbti，保持 latin1 大小写处理，保持 union/inter/diff 返回排序不相交区间列表语义。

---

## R6 PASSED 优化 Cset::union_all/intersect_all 分治归并 + union/inter/diff result 预分配 capacity [ID: T5]
结果：产出 opt_v5.md，cset.mbt union/inter/diff result 预分配 capacity（M2）+ union_all/intersect_all 分治归并（A2，新增 union_all_rec/intersect_all_rec 内部 fn）。moon test 251/251 全绿，moon check 26 warnings 0 errors（无新 warning）。同环境 benchmark（T5 2 次取最优 vs T3 后 2 次取最优，git stash 切换消除漂移）：Section 1（主优化目标）520.5ms → 504.8ms（-3.02%），所有 10 section 均正改进（-1.89% ~ -8.96%），无回退。改动保留。
检查：PASSED，11 项检查全部通过（代码改动符合 task_v5.md、moon test 251/251、moon check 26 warnings、mbti 未修改、新增辅助函数不暴露 mbti、Cset pub struct 未改、纯 MoonBit、opt_v5.md 6 项完整、benchmark 三方对比表 10 section 均正改进、回退决策合规、snake_case 命名、do_v5.md 偏差说明完整）。

## R6 NEW 优化 ColorMap::flatten 入口 csets 去重 [ID: T6]
任务：执行 hotspot_analysis.md 优先级序 6（D4 ColorMap::split 去重），但改为在 `ColorMap::flatten`（re/color_map.mbt:136-188，T3 后版本）入口一次性去重而非 split 中去重——避免改 ColorMap pub struct（`{ csets : Array[Cset] }` 暴露于 mbti:169-171）违反 mbti 约束。具体：(1) 在 flatten 入口（`let csets = self.csets` 之后、`BoundaryTable::create(csets)` 之前）对 self.csets 去重：用 `@hashmap.HashMap[Int, Array[Cset]]`（key = `Cset::hash(cset)`，value = 桶内 csets 列表），遍历 self.csets，对每个 cset 算 hash 查桶，桶内用 `Cset::equal` 线性比较，未命中则加入桶并 push 到去重后的 `dedup_csets : Array[Cset]`，命中则跳过；(2) 用 `dedup_csets` 替代 `self.csets` 传给 `BoundaryTable::create` 和 256 循环内的 `Cset::mem` 调用。保持 flatten 返回 (ColorTable, BoundaryTable, ColorRepr) 语义不变（去重前后 csets 集合的并集相同，boundary table 和 color table 由字符等价类决定，与 csets 顺序/重复无关）。完成后运行 `moon test` 确保不回归，运行 `bench/run_bench.ps1` 对比 baseline.md + opt_v5.md（T5 后）验证改进；若实测无改进或负改进则 `git checkout re/color_map.mbt` 回退并在 opt_v6.md 标注原因（参考 T4 流程）。产出优化报告 opt_v6.md（含改动摘要、diff 关键行、test 结果、benchmark before/after 对比表含 baseline/T5/本轮三方、收益分析、风险/回归说明）。
选择理由：T5（序 5）已 PASSED，性能优化已完成序 1（T3 大收益）/序 5（T5 中收益），序 2（T4 负改进回退）/序 3（mbti BLOCKED）已处理。剩余序 4（A4 translate_colors 位图）有 T4 负改进教训暂缓，序 6（D4 split 去重）是下一候选。原序 6 建议在 split 中去重，但 split 是 `pub fn`（mbti:174）且 ColorMap pub struct（mbti:169-171）只有 `csets` 字段，在 split 中加去重需改 struct 加 `seen` 字段 → 违反 mbti 约束（同 T5-skip 教训）。改为在 flatten 入口去重：flatten 是 `pub fn`（mbti:172）但内部实现可自由改，去重逻辑在函数体内，不改 struct/签名/mbti。收益：hotspot_analysis.md §6 附注"实际 |csets| 可能因重复翻倍"，去重后 256 循环内 `Cset::mem` 调用次数从 256 × |csets| 降到 256 × |dedup_csets|，BoundaryTable::create 工作量也相应减少，直接放大 T3 的 H1 优化收益。风险：去重本身 O(|csets| × Ī) 开销（算 hash + 桶内 equal），若重复率低则可能负改进（类似 T4 教训），故保留回退分支。符合任务方法第 3 步"针对热点逐模块优化"和第 4 步"每次优化后重新运行 benchmark 验证改进"。
上下文：color_map.mbt:136-188 为 T3 后 flatten 实现（`let csets = self.csets` :139 → `BoundaryTable::create(csets)` :140 → 256 循环 `for csetid in 0..<csets.length() { if Cset::mem(i, csets[csetid]) ... }` :153-157）。Cset::hash（cset.mbt:327）O(Ī) 算 hash，Cset::equal（cset.mbt，线性扫描 intervals）做内容比较。@hashmap.HashMap 已在 T3 使用（color_map.mbt:148），moonbitlang/x 依赖。baseline.md Section 1=951ms 为原始基线；opt_v5.md T5 后=504.8ms（do_v5）为上一轮基线，本轮对比二者。约束：纯 MoonBit 无 C FFI，snake_case 命名，不修改 pkg.generated.mbti，保持 latin1 大小写处理，保持 flatten 返回 (ColorTable, BoundaryTable, ColorRepr) 语义不变。

---

## R7 RETRY 优化 ColorMap::flatten 入口 csets 去重 [ID: T6]
原因：plan_review_v6_r1.md REJECTED，3 个发现（1 个一般 + 2 个轻微），修改要求问题 1。
修正方向：(1) [一般] 验证第 3 步明确要求同环境 benchmark 对比（git stash 切换 T5 后版本和 T6 版本，各 2 次取最优），同环境数值为回退决策唯一依据，baseline.md 历史数值仅用于三方对比表展示累积改进幅度；预期产出 §4 标注"T5 后/本轮为同环境重测，baseline 为历史参考"。(2) [轻微] "split 中加去重需改 struct 加 seen 字段"修正为"split 中高效去重需改 struct 加缓存字段，局部线性查找低效，故改在 flatten 入口一次性去重"。(3) [轻微] 预期收益标注为静态推测（非实测），补充开销-收益分析（256 倍放大使收益通常超开销，负改进风险较低）。
选择理由：T5 已 PASSED，T6 任务本身技术方案可行（flatten 入口去重不改 mbti），仅 task_v6.md 表述需按审议要求修订。修订后覆写 task_v6.md（动作 NEW → RETRY，添加 RETRY 说明），保持 ID T6 不变以追踪同一任务的多次尝试。
上下文：同环境 benchmark 方法参考 do_v5.md §3（git stash 切换版本，各 2 次取最优），T4 正是靠同环境对比才发现 +1.08% 负改进而正确回退。T6 预期收益"中"，改进幅度可能较小（参考 T5 的 -3.02%），环境漂移可能与改进幅度相当，直接对比历史数值会导致回退决策误判。

---

## R8 PASSED 优化 ColorMap::flatten 入口 csets 去重 [ID: T6]
结果：T6 按 task_v6.md 执行 flatten 入口 cset 去重（hash 分桶 + 桶内 Cset::equal），实测 Section 1 同环境 +9.76% 严重负改进（9/10 section 负改进），按预设回退分支 git stash drop 回退，代码 = T3 后版本（color_map.mbt）+ T5 后版本（cset.mbt）。opt_v6.md 记录尝试 + 5 条负改进归因（实际重复率低/去重开销高/256 倍放大未生效/与 T4 教训一致）+ 回退决策。性能净改进：Section 1 951ms → 504.8ms（-46.9%，T3+T5 累计），全 section 正改进。
检查：PASSED，10 项检查全部通过（git 回退状态、flatten 无去重残留、moon test 251/251、moon check 26 warnings、opt_v6.md 6 项完整性、对比表数据一致性、同环境 benchmark 方法、回退决策依据、偏差处理、mbti 与纯 MoonBit 约束）。

## R8 NEW 优化 Ast::merge_sequences_no_case_from 递归改迭代 + 中间 Array 复用 [ID: T7]
任务：执行 hotspot_analysis.md 优先级序 7（A3 + M5），修改 re/ast.mbt 的 `merge_sequences_no_case_from`（:343-420）和 `merge_sequences_from`（:252-324）：(1) A3 将递归改迭代 + 索引区间表示子数组，避免每层新建 Array——当前递归每层新建 `combined`/`y`/`y2`/`result` Array 并逐元素 push 拷贝，改迭代用索引区间（start/end）引用原数组子段，仅在最终结果时按需构建 Array；(2) M5 中间 Array（combined/y/y2/result）改预分配 capacity 或复用，消除动态扩容和每层新建分配。保持 `merge_sequences_no_case`/`merge_sequences` 语义不变（公共前缀合并 NoCase 优化，pub fn 签名不改，mbti 不改）。完成后运行 `moon test` 确保不回归，同环境 benchmark 对比（T7 vs T5 后，各 2 次取最优，git stash 切换消除漂移）验证改进；若实测无改进或负改进则 `git checkout re/ast.mbt` 回退改动并在 opt_v7.md 标注原因（参考 T4/T6 流程）。产出优化报告 opt_v7.md（含改动摘要、diff 关键行、test 结果、benchmark before/after 对比表含 baseline/T5/本轮三方、收益分析、风险/回归说明）。
选择理由：T6 已 PASSED（回退），性能优化已完成序 1（T3 大收益 -39.95%）/序 5（T5 小收益 -3.02%），序 2（T4 负改进回退）/序 6（T6 负改进回退）/序 3（mbti BLOCKED）已处理。剩余序 4（A4 translate_colors 位图去重）有 T6 同类去重负改进教训暂缓，序 7（A3+M5）是 hotspot_analysis.md 建议范围（4-7）内未尝试的方向，序 8/9 风险高放后期。序 7 非去重/位图类优化（算法层递归改迭代 + 内存层 Array 复用），与 T4/T6 负改进教训不同，关联 H4 ★★（merge_sequences_no_case 最坏 O(n²)，每层新建 Array 大量分配+拷贝）。`merge_sequences_no_case_from`（ast.mbt:343）和 `merge_sequences_from`（ast.mbt:252）均为内部 fn 不暴露 mbti，`pub fn Ast::merge_sequences_no_case`（:423）和 `pub fn Ast::merge_sequences`（:327）签名不改，技术可行。序 7 收益中、难度中、风险中（需保持 NoCase 语义），是 T5 后剩余 compile 路径热点。符合任务方法第 3 步"针对热点逐模块优化"和第 4 步"每次优化后重新运行 benchmark 验证改进"。
上下文：ast.mbt:343-420 `merge_sequences_no_case_from`（递归，每层新建 combined/y/y2/result Array，已用 push 但每层新建）、:252-324 `merge_sequences_from`（带 case 版本，结构类似）、:423-425 `pub fn Ast::merge_sequences_no_case`（mbti:105，签名 `Array[AstNoCase] -> Array[AstNoCase]` 不改）、:327-329 `pub fn Ast::merge_sequences`（mbti:104，签名 `Array[Ast] -> Array[Ast]` 不改）。compile_translate.mbt:106 调用 merge_sequences_no_case。仅 Alternative 节点触发，对含 `(a|b)*c`、`(?:ab|cd|ef)+`、`[^aeiou][aeiou][^aeiou]` 等模式命中。baseline.md Section 1=951ms 原始基线；opt_v5.md T5 后=504.8ms（do_v5）/509.1ms（check_v6 同环境重测）为上一轮基线，本轮同环境对比 T7 vs T5 后。约束：纯 MoonBit 无 C FFI，snake_case 命名，不修改 pkg.generated.mbti，保持 merge_sequences_no_case/merge_sequences 语义不变（公共前缀合并 NoCase 优化），保持 latin1 大小写处理。

---

## R9 PASSED 优化 Ast::merge_sequences 递归改迭代 + 中间 Array 复用 [ID: T7]
结果：T7 按 task_v7.md 执行 A3+M5（merge_sequences_from/no_case_from 迭代化 + 预分配 capacity），实测 Section 1 同环境 +0.80% 负改进（6/10 section 负改进），按预设回退分支 git stash drop 回退，代码 = T5 后版本（HEAD e64ec54，working tree clean）。opt_v7.md 记录尝试 + 6 条负改进归因（prefix 累积开销/递归点 2 仍递归/work-pos 重置开销/prefix 内存开销/Section 6 负改进最大/迭代化方案根本限制）+ 回退决策。性能净改进：Section 1 951ms → 504.8ms（-46.9%，T3+T5 累计）。
检查：PASSED，10 项检查全部通过（opt_v7.md 6 项完整性、diff 含 before/after、benchmark 三方对比表 10 section、数值与 do_v7 一致、回退条件触发正确、re/ast.mbt 回退到 HEAD、git stash 清理、moon test 251/251、约束遵守、负改进归因完整、偏差说明）。

## R9 NEW 分析未覆盖 pub API 和分支，产出覆盖率差距报告 [ID: T8]
任务：转入阶段二（测试覆盖率提升）第 1 步。分析 re/pkg.generated.mbti 中全部 pub fn/pub struct/pub enum/pub let 的 API 面，对照 re/ 下 9 个测试文件（含 coverage_test.mbt 103 个测试）的 test 块，识别未覆盖或仅浅覆盖的 pub API 及分支。产出覆盖率差距报告 coverage_gap_analysis.md，含：(1) API 清单总览（按模块分组：cset/color_map/automata_*/compile/core/perl/posix/glob/pcre/str/re_ast 等，每模块列出 pub API 数量、已覆盖数、未覆盖数、覆盖率%）；(2) 未覆盖/浅覆盖 API 明细表（API 签名、所在文件:行号、所属模块、覆盖状态[未覆盖/仅正向/仅边界缺错误路径]、推测风险等级[高/中/低]、建议测试方向[边界条件/错误路径/边缘 case/内部操作间接测试]）；(3) 分支覆盖缺口（重点列出错误路径和异常处理分支的覆盖情况，如 compile 失败路径、parse 错误路径、cset 边界[空集/全集/单元素/互补]、automata 空状态/重复状态等）；(4) 建议补充测试优先级排序（按风险等级 × 覆盖难度 × 业务价值排序，给出前 10-15 个最该补的测试目标）。仅分析不改代码，不运行 benchmark。
选择理由：阶段一性能优化已充分探索 6 轮（T3-T7），取得 Section 1 -46.9% 显著成果，3 轮连续负改进（T4/T6/T7）+ 1 轮 mbti BLOCKED 表明剩余方向（序 4 位图去重有 T4/T6 双重负改进教训；序 8/9 风险高 task.md 标注"放后期"）边际收益递减且风险高。task.md 明确"先性能后覆盖率"，阶段一已达成可量化目标（benchmark 全 section 正改进，无回归），转入阶段二。阶段二方法第 2 步"分析未覆盖的 pub API 和分支（参考 re/pkg.generated.mbti 接口）"是后续补充测试（方法第 3 步）的前提，需先产出差距报告为后续 T9+ 提供精确目标，避免盲目补测试。测试基线已建立（baseline.md 251/251 通过，每轮优化均跑 moon test 确认全绿），无需重复。
上下文：re/pkg.generated.mbti 为 moon info 自动生成的接口文件（约束：不修改此文件，仅作分析输入）。re/ 下 9 个测试文件：coverage_test.mbt（103 测试，专补 pub API 覆盖）+ 其他 8 个（基础数据结构/AST/自动机/编译/核心 API/各前端）。测试层次：基础数据结构 → AST → 自动机 → 编译 → 核心 API → 各前端。task.md 阶段二重点覆盖方向：(a) 核心模块边界条件、(b) 错误路径和异常处理、(c) 各前端解析器边缘 case、(d) cset/automata/compile 内部操作（通过公开 API 间接测试）。约束：纯 MoonBit 无 C FFI，snake_case 命名，不修改 pkg.generated.mbti，保持与 OCaml 上游行为一致性，保持 latin1 大小写处理。
