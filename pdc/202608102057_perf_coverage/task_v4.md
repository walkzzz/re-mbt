# 任务指令（v4）

## 动作
NEW

## 任务描述
执行 hotspot_analysis.md 优先级序 2（D1 局部：flatten 内联 Cset 256-bit 位图），优化 `re/color_map.mbt` 的 `ColorMap::flatten`（当前 :136-188，T3 后版本）：

1. **预构建位图**：在 flatten 入口（`BoundaryTable::create(csets)` 之后、`for i in 0..<256` 循环之前），对 `self.csets` 中每个 cset 预构建一个 256-bit 位图。位图表示为 `FixedArray[Byte]` of 32 bytes（256 bits）。构建方式：对每个 cset 调用 `Cset::iter(cset, f=fn(c1, c2) { for c in c1..=c2 { bitmap[(c >> 3)] = (bitmap[(c >> 3)].to_int() | (1 << (c & 7))).to_byte() } })`。所有位图存于 `let bitmaps : Array[FixedArray[Byte]] = []`，长度 = csets.length()。

2. **替换 Cset::mem 为位测试**：将 256 循环内 `if Cset::mem(i, csets[csetid])`（O(Ī) 线性扫描 intervals）替换为 `if (bitmaps[csetid][i >> 3]).to_int() & (1 << (i & 7)) != 0`（O(1) 位测试），消除 H7 的 256 × |csets| × Ī 次 interval 比较。

3. **保持语义不变**：flatten 返回 `(ColorTable, BoundaryTable, ColorRepr)` 三元组结构与 T3 后版本一致。位图仅用于加速 mem 查询，不影响 ColorTable/ColorRepr 的计算逻辑。

4. **验证**：
   - 运行 `moon test`（在 D:\CodeWorkspace\forMoonbit\re-mbt），确保 251/251 全绿，不回归。
   - 运行 `moon check`，确保无新 warning（T3 后为 26 warnings）。
   - 运行 `bench/run_bench.ps1`，对比 baseline.md（原始基线）和 opt_v3.md（T3 后基线），验证改进。
   - 若实测无改进或负改进（Section 1 相对 T3 后基线无改善或回退），则回退改动并在 opt_v4.md 中标注原因。

5. **产出**：`opt_v4.md`，含：
   - 改动摘要（文件、行号、改动点）
   - diff 关键行（before/after 代码片段）
   - moon test 结果
   - benchmark before/after 对比表（含 baseline / T3 后 / 本轮三方数据，10 section，标注 Δ%）
   - 收益分析（实际 vs 预期、归因、为何 Section 2 不变）
   - 风险/回归说明（位图构建正确性、语义等价性、warning 情况、纯 MoonBit 约束）

## 选择理由
T3（序 1：ColorMap::flatten 哈希去重 + ids 复用）已 PASSED，Section 1 改进 -39.95%（独立复测 -43.12%），flatten 的 unique_lists 线性查找瓶颈已消除。flatten 内层 `Cset::mem`（H7 ★）成为剩余主要开销：对每个字节 i（0..<256）× 每个 cset 调用 `Cset::mem`，共 256 × |csets| 次，每次 O(Ī) 线性扫描 intervals，总计 O(256 × |csets| × Ī) 次 interval 比较。

hotspot_analysis.md 优先级序 2 明确建议"先做 1-3（局部、低风险、高收益）"，序 2 收益"高"、风险"中"、备注"可先不改 Cset 公开表示，仅在 flatten 中把每个 cset 预展开为 256-bit 位图，mem 变 O(1)；改动局部"。序 2 排在序 3 之前（综合耗时占比 × 优化难度 × 回归风险更高），且延续对 H1 ★★★ 主热点的优化，消除其内层 H7 瓶颈。

符合 task.md 方法第 3 步"针对热点逐模块优化"和第 4 步"每次优化后重新运行 benchmark 验证改进"。

## 任务上下文
- **当前 flatten 实现**：re/color_map.mbt:136-188（T3 后版本），256 循环在 :150-180，Cset::mem 调用在 :154。
- **Cset::mem 实现**：re/cset.mbt:316-324，线性扫描 `s.intervals`，O(Ī)。
- **Cset::iter 实现**：re/cset.mbt:338-342，遍历 `t.intervals` 调用 `f(p.0, p.1)`，用于构建位图。
- **位图表示**：`FixedArray[Byte]` of 32 bytes（256 bits）。索引 `c >> 3`（0-31）选字节，`c & 7`（0-7）选位。设置：`bitmap[c >> 3] = (bitmap[c >> 3].to_int() | (1 << (c & 7))).to_byte()`。测试：`(bitmap[c >> 3]).to_int() & (1 << (c & 7)) != 0`。纯整数位运算，无外部依赖。
- **基线数据**：
  - baseline.md Section 1 = 951.0ms（原始基线，T1 产出）
  - opt_v3.md Section 1 = 571.1ms（do_v3 声称）/ 540.8ms（check_v3 独立复测）（T3 后基线）
- **约束**：纯 MoonBit 无 C FFI（FixedArray[Byte] + Int 位运算是核心类型，支持全后端），snake_case 命名，不修改 pkg.generated.mbti，保持 latin1 大小写处理，保持与 OCaml 上游行为一致性。

## 已有产出上下文
- **baseline.md**（T1）：251/251 测试基线 + 10 section benchmark 基线（Section 1 = 951.0ms）。
- **hotspot_analysis.md**（T2）：compile 调用链 + 12 热点（H1-H12）+ 优化方向（A1-A5/M1-M5/D1-D5）+ 优先级序 1-10。H1 ★★★ flatten 主热点，H7 ★ Cset::mem 在 flatten 中被调用 256 × |csets| 次。
- **opt_v3.md**（T3）：ColorMap::flatten 哈希去重 + ids 复用优化报告，Section 1 -39.95%。当前 flatten 实现见 re/color_map.mbt:136-188。
- **do_v3.md / check_v3.md**：T3 执行报告 + 检查报告（PASSED，13 项检查全通过，独立 benchmark 复测验证）。
- **plan.md**：R1 T1 PASSED（基线）→ R2 T2 PASSED（热点分析）→ R3 T3 PASSED（序 1 优化）→ R4 T4 NEW（本轮，序 2 优化）。
