# 执行报告（v3）

## 概述
执行 hotspot_analysis.md 优先级序 1（A1 + D3 + M1），优化 `re/color_map.mbt` 的 `ColorMap::flatten`：将 `unique_lists` 线性去重改为 `@hashmap.HashMap[Array[Int], Int]` 哈希去重（A1 + D3），将 256 循环内每轮新建的 `ids : Array[Int]` 改为循环外预分配 `ids_buf` 缓冲复用（M1），并删除 else 分支死代码（ids 填充后未被读取）。产出 `opt_v3.md` 含改动摘要、diff、test 结果、benchmark 对比、收益分析、风险说明。moon test 251/251 全绿，benchmark Section 1（Perl compile）951.0ms → 571.1ms（-39.95%），所有含 compile 的 section 改进 34-46%，远超序 1 预期收益。

## 产出清单
| 操作 | 文件路径 | 说明 |
|------|---------|------|
| 修改 | D:\CodeWorkspace\forMoonbit\re-mbt\re\color_map.mbt | 删除 array_int_eq；重写 flatten（HashMap 哈希去重 + ids_buf 复用 + 死代码删除） |
| 修改 | D:\CodeWorkspace\forMoonbit\re-mbt\re\moon.pkg | 新增 moonbitlang/core/hashmap import |
| 新建 | D:\CodeWorkspace\forMoonbit\re-mbt\pdc\202608102057_perf_coverage\opt_v3.md | 优化报告（改动摘要/diff/test/benchmark/收益/风险） |

## 执行过程
1. **阅读任务上下文**：task_v3.md 要求执行 hotspot_analysis.md 序 1（A1 + D3 + M1），优化 `ColorMap::flatten`（color_map.mbt:149-199）。阅读 baseline.md（Section 1 = 951ms 基线）、hotspot_analysis.md（H1 ★★★ 主热点定位）、do_v2.md（T2 热点分析产出）。
2. **阅读目标代码**：re/color_map.mbt 全文 200 行，确认 flatten 结构：`unique_lists : Array[Array[Int]]` 线性去重（array_int_eq 逐个比较）+ 256 循环内 `let ids : Array[Int] = []` 每轮新建 + `prev_ids` 用于 else 分支复制（但 ids 填充后未被读取，死代码）。
3. **确认数据结构可用性**：`moon ide doc '@hashmap'` 确认 `HashMap[K, V]` 需 `K : Hash + Eq`；`moon ide doc 'Array'` 确认 `Array[Int]` 同时有 `Hash` 和 `Eq` 实例（因 Int 有 Hash + Eq）。可直接用 `HashMap[Array[Int], Int]`。
4. **确认 array_int_eq 仅内部使用**：grep 确认 `array_int_eq` 仅在 color_map.mbt 定义和使用（_build 副本是构建产物），可安全删除。
5. **设计优化方案**：
   - **M1**：`ids_buf : Array[Int] = []` 循环外预分配，循环内 `clear` 后复用，消除 256 次 Array 分配。
   - **A1 + D3**：`@hashmap.HashMap[Array[Int], Int]` 做 ids 内容 → color_id 映射。`get(ids_buf)` 哈希查找 O(|ids|)，未命中时深拷贝 ids_buf 作为 key 存入（仅命中新 color 时分配一次）。
   - **死代码删除**：else 分支 `for x in prev_ids { ids.push(x) }` 中 ids 填充后未被任何后续代码读取（仅 table_arr[i] 和 repr_arr[last_version] 被赋值，用 last_version 而非 ids）。删除是语义等价的，且是 M1 的必要前提（否则 prev_ids = ids_buf 与 clear 复用冲突）。
6. **执行修改**：用 edit 工具替换 color_map.mbt 的 array_int_eq + flatten（原 :135-199 → 新 :135-185）；用 write 工具创建 re/moon.pkg 添加 hashmap import。
7. **moon check**：0 errors，26 warnings（原 28 - 2 个 core_package_not_imported warning，因新增 import 消除）。无新 warning。
8. **moon test**：`Total tests: 251, passed: 251, failed: 0`，全绿，语义未回归。
9. **运行 benchmark**：`bench/run_bench.ps1`，10 section × 3 次取最优。结果：
   - Section 1（Perl compile）：951.0ms → 571.1ms（-39.95%）★ 主优化目标
   - Section 3/4/5/6/7（含 compile）：-34.84% ~ -46.25%
   - Section 2（纯 match）：-0.92%（噪声内，符合预期不变）
   - Section 8/9（少量 compile）：-8.75% ~ -10.82%
   - Section 10（Large+Caseless）：+2.33%（+0.6ms，噪声范围）
10. **撰写 opt_v3.md**：含改动摘要（3 处）、diff 关键行（before/after 代码片段）、moon test 结果、benchmark 10 section 对比表（重点标注 Section 1 -39.95%）、收益分析（实际 vs 预期、归因、Section 2 不变原因）、风险/回归说明（死代码删除等价性、Section 10 噪声、HashMap 通用开销、warning 情况、纯 MoonBit 约束）。
11. **关键判断**：
    - 死代码删除是 M1 的必要前提，已在 opt_v3.md §6.2 详细论证语义等价性。
    - HashMap 通用实现已带来 -39.95% 收益，专用开放寻址（如项目 HashSet 风格）边际收益有限，暂不引入复杂度。
    - Section 10 +2.33% 为噪声级（0.6ms / 25.8ms），若后续证实系统性回退可加 small-color-map 快速路径。

## 偏差说明
无。任务要求优化 flatten 的 A1 + D3 + M1，保持语义不变，验证 moon test + benchmark + warning，产出 opt_v3.md 含 6 项内容，均已覆盖。死代码删除是 M1 的必要前提（已在 opt_v3.md §6.2 论证语义等价），属于 M1 的合理组成部分，非偏差。
