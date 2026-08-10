# 任务指令（v2）

## 动作
NEW

## 任务描述
深入分析 compile 路径的代码层面热点，定位 Section 1（Perl compile 951ms）的具体瓶颈，为后续逐模块优化提供精确目标。

具体工作：
1. 阅读 re/ 目录下核心模块源码，理解 compile 调用链：
   - `cset.mbt`（12.1KB，字符集操作，匹配热路径）
   - `compile.mbt`（16.4KB，lazy DFA driver，匹配引擎核心）
   - `compile_translate.mbt`（8.0KB，编译翻译层）
   - `automata_state.mbt`（7.4KB，状态管理）
   - `automata_desc.mbt`（8.2KB，导数表达式操作）
   - `automata_expr.mbt`（4.3KB，自动机表达式）
   - `automata.mbt`（2.6KB，自动机入口）
   - `color_map.mbt`（4.3KB，颜色映射）
   - `core.mbt`（3.1KB，高层 API）
2. 阅读 Perl 前端 `perl.mbt`（14.0KB），梳理其 compile 调用链（从前端解析到 lazy DFA 构建的完整路径）。
3. 结合 benchmark 数据（Section 1=951ms、Section 5/7≈348ms、Section 3/4≈276-281ms、纯匹配类≤43ms）和代码结构，推断耗时集中的函数/方法及原因（如重复分配、高复杂度操作、缓存缺失、热路径上的不可变结构创建等）。
4. 产出热点分析报告 `hotspot_analysis.md`，写入路径 `D:\CodeWorkspace\forMoonbit\re-mbt\pdc\202608102057_perf_coverage\hotspot_analysis.md`，包含：
   - **compile 调用链概览**：从前端到 lazy DFA 构建的关键函数调用路径
   - **热点函数列表**：按推测耗时排序，每项含所在文件:行号、功能说明、推测耗时原因
   - **优化方向建议**：每个热点对应算法层/内存层/数据结构层的具体优化建议
   - **优先级排序**：综合耗时占比和优化难度，给出优化顺序建议

预期产出：`hotspot_analysis.md` 文件，内容完整且可指导后续优化。

## 选择理由
R1 已建立 benchmark 基线（T1 PASSED），定位到 compile 路径是主要瓶颈（Section 1 Perl compile 951ms 远高于其他）。但 benchmark 只给出 section 级别的耗时，需进一步在代码层面定位具体瓶颈函数，才能进行方法第 3 步"针对热点逐模块优化"。本任务是方法第 2 步"分析 benchmark 结果定位热点"的深化，为后续优化提供精确目标，避免盲目优化。这是性能优化阶段承上启下的关键一步。

## 任务上下文
摘自 task.md：
- 优化方向：算法层（cset/automata/compile 核心算法）、内存层（减少热路径内存分配，减少 @array/@hashmap 创建，使用可变结构）、数据结构层（bit_vector/hash_set/dense_map/cset 内部表示和操作）
- 核心模块优先级：cset.mbt > compile.mbt > automata_state.mbt > automata_desc.mbt > core.mbt > hash_set.mbt > bit_vector.mbt
- 方法：1.建立基线 ✓ → 2.分析 benchmark 结果定位热点（当前） → 3.针对热点逐模块优化 → 4.每次优化后重新运行 benchmark 验证 → 5.确保 moon test 全部通过
- 约束：保持纯 MoonBit，保持与 OCaml 上游行为一致性，不修改 pkg.generated.mbti

## 已有产出上下文
- `baseline.md`：测试基线（251/251 通过，0.21s）+ 10 section benchmark 数据。
  - 热点观察：Section 1（Perl compile）951ms 远高于其他；Section 5/7（Glob/Str compile+match）≈348ms 次之；Section 3/4（Emacs/POSIX compile+match）≈276-281ms 再次之；Section 2/9/10（纯匹配/分裂替换/大输入）均在 43ms 以下，说明 **compile 路径是主要瓶颈**。
  - 备注：moon 0.1.20260713，构建目标 native release，每 section 跑 3 次取最优，迭代数 5000。
