# 任务指令（v3）

## 动作
NEW

## 任务描述
执行 `hotspot_analysis.md` 优先级序 1（A1 + D3 + M1），优化 `re/color_map.mbt` 的 `ColorMap::flatten`（:149-199）：

1. **A1 + D3（unique_lists 哈希去重）**：将当前 `unique_lists : Array[Array[Int]]` 的线性去重（`array_int_eq` 逐个比较）改为哈希去重——按 `ids` 内容计算哈希 key（如滚动哈希或 FNV），用 HashMap/HashTable 维护 `ids 内容 → color_id` 映射，消除 O(256 × |unique| × |ids|) 线性查找。桶内冲突时再内容比较保证正确性。
2. **M1（ids 缓冲复用）**：将 256 循环内每轮新建的 `ids : Array[Int]` 改为循环外预分配缓冲（容量足够），循环内 `clear` 后重用，消除 256 次 Array 分配。注意：若哈希去重需要保留 ids 副本作为 key，需在命中新 color 时做一次深拷贝存入 map，其余情况复用缓冲。

**保持语义不变**：flatten 返回的 ColorTable（256 字节颜色表）+ BoundaryTable + ColorRepr 三者语义与原实现完全一致。

**验证**：
- 运行 `moon test`（在 D:\CodeWorkspace\forMoonbit\re-mbt），确保 251 个测试全绿，不引入回归。
- 运行 `bench/run_bench.ps1`，对比 `baseline.md` 验证改进（重点关注 Section 1 Perl compile）。
- 检查无新 warning。
- **无改进/回退策略**：若 `moon test` 出现回归，立即回退改动并标注；若 benchmark 实测无改进或负改进（Section 1 未下降或反升），回退改动并在 `opt_v3.md` 中分析原因（可能是哈希开销大于线性查找收益、或 flatten 非实际瓶颈），保留分析结论供后续轮次参考。

**产出**：`opt_v3.md`，含：
- 改动摘要（修改的文件:行号、改动点）
- diff 关键行（before/after 代码片段）
- `moon test` 结果（通过数/总数、耗时）
- benchmark before/after 对比表（10 个 section，重点标注 Section 1 改进幅度）
- 收益分析（实际改进 vs 预期，是否达到序 1 预期收益）
- 风险/回归说明

## 选择理由
T2（hotspot_analysis.md）已定位 `ColorMap::flatten`（H1 ★★★）为单次 compile 最重函数，其 `unique_lists` 线性去重（O(256 × |unique| × |ids|)）和 256 次 `ids` Array 分配是主要开销。hotspot_analysis.md 优先级序 1 明确建议"先做 1-3（局部、低风险、高收益），benchmark 验证后再做 4-7"。序 1 改动仅限 `color_map.mbt::flatten` 内部，不触及 Cset 公开表示，风险低、改动局部、预期收益高。本任务对应任务描述方法第 3 步"针对热点逐模块优化"和第 4 步"每次优化后重新运行 benchmark 验证改进"，是性能优化阶段的第一个实际代码改动。

## 任务上下文
- **目标文件**：`re/color_map.mbt:149-199`（`ColorMap::flatten`）
- **当前实现**：`unique_lists : Array[Array[Int]]`，去重靠 `array_int_eq`（:136）线性扫描；`ids` 在 256 循环内每轮 `Array::make` 新建
- **优化项**：A1（unique_lists 哈希去重）+ D3（HashMap<Array[Int], Int>）+ M1（ids 缓冲复用）
- **语义约束**：flatten 返回 ColorTable + BoundaryTable + ColorRepr 语义不变
- **对比基准**：`baseline.md` Section 1 = 951ms（Perl compile，5000 iters，8 patterns，190.19us/compile）
- **项目约束**：纯 MoonBit 无 C FFI；snake_case 命名；不修改 pkg.generated.mbti；保持 latin1 大小写处理；保持与 OCaml 上游行为一致
- **构建命令**：`moon test` / `moon build --target native --release` / `bench/run_bench.ps1`

## 已有产出上下文
- `baseline.md`：性能基线，含测试基线（251/251 通过，0.21s）+ 10 section benchmark 数据。Section 1 Perl compile=951ms 最高，是本任务优化的对比基准。
- `hotspot_analysis.md`：compile 路径热点分析报告。H1（`ColorMap::flatten` @color_map.mbt:149-199）为 ★★★ 主热点，优化方向 A1（unique_lists 哈希去重）+ D3（HashMap）+ M1（ids 复用）列于优先级序 1，预期收益高/难度中/风险低。
- `do_v2.md` / `check_v2.md`：T2 执行与检查报告，均 PASSED。
