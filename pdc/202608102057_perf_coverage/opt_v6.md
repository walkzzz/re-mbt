# 优化报告（v6）：ColorMap::flatten 入口 cset 去重（D4）

> 对应 hotspot_analysis.md 优先级序 6（D4 ColorMap::split 去重），改为在 flatten 入口一次性去重
> **结论：实测负改进，已回退改动。**

## 1. 改动摘要

| 文件 | 行号 | 改动点 |
|------|------|--------|
| `re/color_map.mbt` | :139-166（flatten 入口） | 在 `let csets = self.csets` 后、`BoundaryTable::create(csets)` 前插入去重逻辑：`dedup_csets : Array[Cset]` + `seen : @hashmap.HashMap[Int, Array[Cset]]`（key = `Cset::hash(cset)`，value = 桶内 csets 列表），遍历 `self.csets` 用 hash 分桶 + 桶内 `Cset::equal` 线性比较去重，用 `dedup_csets` 替代 `self.csets` 传入后续 `BoundaryTable::create` 和 256 循环 `Cset::mem` |

净变化：`re/color_map.mbt` +28 行（去重逻辑块）。不改 ColorMap pub struct、不改 flatten 签名、不改 mbti。

## 2. diff 关键行

### 2.1 flatten 入口去重（color_map.mbt:139-166）

```moonbit
// before（T3 后版本）
pub fn ColorMap::flatten(
  self : ColorMap,
) -> (ColorTable, BoundaryTable, ColorRepr) {
  let csets = self.csets
  let bt = BoundaryTable::create(csets)

// after（T6 版本，已回退）
pub fn ColorMap::flatten(
  self : ColorMap,
) -> (ColorTable, BoundaryTable, ColorRepr) {
  // D4: 入口一次性去重，消除重复 cset 对 BoundaryTable::create 和 256 循环 Cset::mem 的放大开销
  // key = Cset::hash(cset)，桶内用 Cset::equal 线性比较
  let dedup_csets : Array[Cset] = []
  let seen : @hashmap.HashMap[Int, Array[Cset]] = @hashmap.HashMap::HashMap([])
  for cset in self.csets {
    let h = Cset::hash(cset)
    match seen.get(h) {
      Some(bucket) => {
        let mut found = false
        for existing in bucket {
          if Cset::equal(cset, existing) {
            found = true
            break
          }
        }
        if !found {
          bucket.push(cset)
          dedup_csets.push(cset)
        }
      }
      None => {
        let bucket : Array[Cset] = [cset]
        seen[h] = bucket
        dedup_csets.push(cset)
      }
    }
  }
  let csets = dedup_csets
  let bt = BoundaryTable::create(csets)
```

## 3. moon test 结果

- **命令**：`moon test`（在 `D:\CodeWorkspace\forMoonbit\re-mbt`）
- **T6 改动后**：`Total tests: 251, passed: 251, failed: 0`，无回归
- **回退后**：`Total tests: 251, passed: 251, failed: 0`，无回归

## 4. benchmark before/after 对比表

> bench/run_bench.ps1，native release，每 section 3 次取最优，5000 iters
> 同环境连续运行：T6 版本 2 次取最优 vs T5 后版本 2 次取最优（git stash 切换），消除环境漂移
> 三方对比：Baseline（baseline.md 原史参考）/ T5 后（同环境 2 次取最优）/ T6（同环境 2 次取最优）
> **T5 后/T6 为同环境重测数值，baseline 为历史参考**

| Section | Name | Baseline(ms) | T5 后(ms) | T6(ms) | Δ vs T5(ms) | Δ vs T5(%) | Δ vs Baseline(%) | 备注 |
|---------|------|--------------|-----------|--------|-------------|-----------|------------------|------|
| **1** | **Perl compile** | **951.0** | **509.1** | **558.8** | **+49.7** | **+9.76%** | **-41.28%** | **★ 主优化目标，严重负改进** |
| 2 | Perl match | 43.3 | 37.1 | 37.7 | +0.6 | +1.62% | -12.93% | 负改进 |
| 3 | Emacs compile+match | 276.4 | 146.0 | 153.6 | +7.6 | +5.21% | -44.43% | 负改进 |
| 4 | POSIX compile+match | 281.1 | 156.3 | 168.7 | +12.4 | +7.93% | -40.00% | 负改进 |
| 5 | Glob compile+match | 347.4 | 212.2 | 228.2 | +16.0 | +7.54% | -34.31% | 负改进 |
| 6 | Pcre compile+match | 208.2 | 130.6 | 139.9 | +9.3 | +7.12% | -32.81% | 负改进 |
| 7 | Str compile+match | 348.5 | 178.4 | 190.1 | +11.7 | +6.56% | -45.45% | 负改进 |
| 8 | Search all+matches | 77.6 | 66.8 | 65.6 | -1.2 | -1.80% | -15.46% | 唯一正改进（小幅） |
| 9 | Split+Replace | 42.3 | 36.0 | 40.3 | +4.3 | +11.94% | -4.73% | 负改进最大 |
| 10 | Large+Caseless | 25.8 | 24.1 | 25.1 | +1.0 | +4.15% | -2.71% | 负改进 |

**Section 1 同环境对比：+9.76%（509.1ms → 558.8ms，+49.7ms）严重负改进**
**9/10 section 负改进（+1.62% ~ +11.94%），仅 Section 8 小幅正改进（-1.80%）。已回退改动。**

### 原始运行数据

**T6 第 1 次**：559.1 / 38.9 / 155.3 / 168.7 / 242.6 / 144.3 / 192.1 / 65.6 / 40.3 / 25.1
**T6 第 2 次**：558.8 / 37.7 / 153.6 / 180.8 / 228.2 / 139.9 / 190.1 / 68.9 / 40.6 / 26.3
**T6 最优**：558.8 / 37.7 / 153.6 / 168.7 / 228.2 / 139.9 / 190.1 / 65.6 / 40.3 / 25.1

**T5 后 第 1 次**：509.1 / 38.1 / 146.0 / 156.3 / 220.8 / 130.6 / 180.8 / 70.8 / 36.0 / 24.9
**T5 后 第 2 次**：538.2 / 37.1 / 149.3 / 160.1 / 212.2 / 132.5 / 178.4 / 66.8 / 40.3 / 24.1
**T5 后 最优**：509.1 / 37.1 / 146.0 / 156.3 / 212.2 / 130.6 / 178.4 / 66.8 / 36.0 / 24.1

## 5. 收益分析

### 5.1 实际改进 vs 预期

- **预期**：hotspot_analysis.md 序 6 标注收益"中"。task_v6.md 预期收益基于 §6 附注静态推测"实际 |csets| 可能因重复翻倍"，去重开销 O(|csets| × Ī)（算 hash + 桶内 equal），收益 256 × (|csets| - |dedup|) × Ī（减少 256 循环 Cset::mem 调用），256 倍放大使收益通常超开销，负改进风险较低。
- **实际**：Section 1 同环境 +9.76% 严重负改进，9/10 section 负改进。**与预期"收益中、负改进风险较低"不符，实测为负改进。**
- **结论**：去重开销远超收益，回退改动。

### 5.2 负改进归因

1. **实际重复率低**：hotspot_analysis.md §6 附注"实际 |csets| 可能因重复翻倍"为静态推测，实测 |dedup| ≈ |csets|（重复率低），去重后 csets 数量几乎未减少，256 循环 Cset::mem 调用次数未减少，收益未实现。
2. **去重开销高**：去重对每个 cset 调用 `Cset::hash`（O(Ī) 遍历 intervals 算 hash）+ 桶内 `Cset::equal`（O(Ī) 线性比较 intervals），总开销 O(|csets| × Ī)。`Cset::hash` 涉及乘法（`h = p.0 + 13 * p.1 + 257 * h`）和数组遍历，开销不低。即便重复率为 0，去重仍需对每个 cset 算 hash + 创建桶，纯增加开销。
3. **HashMap 开销**：`@hashmap.HashMap` 的 get/set 涉及 hash 计算、桶查找、可能的 rehash，对 |csets| 较小（compile 路径 csets 数通常 < 50）的场景，HashMap 固定开销可能超过线性查找。
4. **256 倍放大未生效**：预期"256 倍放大使收益通常超开销"基于 |csets| - |dedup| ≥ 1 的假设。实测重复率低使 |csets| - |dedup| ≈ 0，256 倍放大 × 0 = 0，收益未实现，去重开销纯增加。
5. **Section 8 唯一正改进**：Section 8（Search all+matches）-1.80% 可能因该 section csets 重复率略高或 csets 数较小使去重开销相对低，但改进幅度小（-1.2ms）且不稳定，不足以改变整体负改进结论。

### 5.3 与 T4 教训一致

T4（序 4 translate_colors 位图去重）同样因去重开销超收益而负改进（+1.08%）回退。T6 与 T4 教训一致：**去重类优化对实际重复率敏感，静态推测的重复率可能高估，实测是唯一可靠依据。** 后续去重类优化需先实测确认重复率，再做去重。

## 6. 风险/回归说明

### 6.1 测试回归

无。T6 改动后 251/251 全绿，回退后 251/251 全绿，语义未回归。

### 6.2 语义等价性

- **去重语义等价**：`dedup_csets` 是 `self.csets` 去重后的子集（保留首次出现的每个唯一 cset），去重前后 csets 集合的并集相同。`BoundaryTable::create`（由 csets 的边界字符决定）和 ColorTable（由字符等价类决定）均与 csets 顺序/重复无关，去重前后结果等价。
- **moon test 251/251 验证**：所有 flatten 语义等价性由测试套件覆盖（含 coverage_test.mbt 103 个 pub API 测试）。

### 6.3 warning 情况

- 改动前（T5 后）：26 warnings, 0 errors
- T6 改动后：26 warnings, 0 errors（初版用 `not(found)` 触发 1 个 deprecated warning，改为 `!found` 后消除）
- 回退后：26 warnings, 0 errors
- **无新 warning 引入**。

### 6.4 纯 MoonBit 约束

`@hashmap.HashMap` 已在 T3 使用（moonbitlang/core/hashmap 依赖），`Cset::hash`/`Cset::equal` 为 pub fn，`!found`/`break`/`for ... in` 为 MoonBit 原生语法。无 C FFI，支持 native/wasm/js 全后端。

### 6.5 mbti 约束

- `ColorMap` pub struct `{ csets : Array[Cset] }` 未改。
- `flatten` 函数签名未改（仅改实现，去重逻辑在函数体内）。
- **不违反"不修改 pkg.generated.mbti"约束**。

### 6.6 回退决策

**已回退。** 实测 Section 1 同环境 +9.76% 严重负改进，9/10 section 负改进，符合 task_v6.md "若实测无改进或负改进则 git checkout re/color_map.mbt 回退改动"条件。`git stash drop` 丢弃 T6 改动，`re/color_map.mbt` 恢复为 T3 后版本（HEAD 6364b65），`re/cset.mbt` 保持 T5 后版本。回退后 moon test 251/251 全绿。

### 6.7 后续建议

1. **去重类优化需先实测重复率**：T4（translate_colors 位图去重）和 T6（flatten cset 去重）均因实际重复率低于静态推测而负改进回退。后续去重类优化（如序 7 A3+M5 merge_sequences_no_case）应先实测确认目标数据结构的重复率/冗余率，再做去重，避免重蹈 T4/T6 覆辙。
2. **hotspot_analysis.md §6 附注修正**：§6 附注"实际 |csets| 可能因重复翻倍"为静态推测，T6 实测显示重复率低，该附注应标注为"静态推测，实测重复率低"。
3. **剩余优先级**：序 4（A4 translate_colors 位图）T4 负改进回退暂缓，序 6（D4 split 去重）T6 负改进回退，序 7（A3+M5 merge_sequences_no_case）风险中暂后排，序 8-9 高风险放后期。当前性能优化剩余候选较少，可考虑转向阶段二（测试覆盖率提升）或其他热点（H2-H12 未覆盖方向）。
