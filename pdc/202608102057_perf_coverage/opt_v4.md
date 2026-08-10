# 优化报告（v4）：ColorMap::flatten 内联 Cset 256-bit 位图（D1 局部）— 回退

> 对应 hotspot_analysis.md 优先级序 2（D1 局部：flatten 内联 Cset 256-bit 位图）
> **结论：实测负改进，已回退改动。代码回到 T3 后版本。**

## 1. 改动摘要

| 文件 | 行号 | 改动点 | 状态 |
|------|------|--------|------|
| `re/color_map.mbt` | :139-157（新增） | flatten 入口预构建 `bitmaps : Array[FixedArray[Byte]]`（|csets| × 32 bytes），对每个 cset 用 `Cset::iter` 遍历区间，对区间内每个字符置位 | **已回退** |
| `re/color_map.mbt` | :170-176（替换） | 256 循环内 `Cset::mem(i, csets[csetid])`（O(Ī) 区间扫描）→ `((bitmap[i >> 3]).to_int() & (1 << (i & 7))) != 0`（O(1) 位测试） | **已回退** |

净变化（已回退）：`re/color_map.mbt` 0 行（回到 T3 后版本）。

### 回退原因

同环境 benchmark 实测：Section 1（主优化目标）相对 T3 后基线 **+1.08%（回退）**，含 compile 的 section（3/4/5/6/7）**全部回退 4-7%**。位图构建的固定开销（|csets| × 32 bytes 分配 + Σ interval_length 次位设置）超过了 mem 查询的边际节省（256 × |csets| × Ī → 256 × |csets|）。按任务要求"若实测无改进或负改进，则回退改动并标注原因"，已回退。

## 2. diff 关键行（已回退的尝试性改动）

### 2.1 位图预构建（原 T3 后 :139-140 之间插入）

```moonbit
// 尝试性改动（已回退）
let num_csets = csets.length()
let bitmaps : Array[FixedArray[Byte]] = []
for _ in 0..<num_csets {
  bitmaps.push(FixedArray::make(32, (0).to_byte()))
}
for csetid in 0..<num_csets {
  let bitmap = bitmaps[csetid]
  Cset::iter(csets[csetid], f=fn(c1, c2) {
    for c in c1..<(c2 + 1) {
      let idx = c >> 3
      bitmap[idx] = (bitmap[idx].to_int() | (1 << (c & 7))).to_byte()
    }
  })
}
```

### 2.2 Cset::mem → 位测试（原 T3 后 :153-156 替换）

```moonbit
// before（T3 后，保留）
for csetid in 0..<csets.length() {
  if Cset::mem(i, csets[csetid]) {
    ids_buf.push(csetid + 1)
  }
}

// after（尝试性，已回退）
for csetid in 0..<num_csets {
  let bitmap = bitmaps[csetid]
  if ((bitmap[i >> 3]).to_int() & (1 << (i & 7))) != 0 {
    ids_buf.push(csetid + 1)
  }
}
```

## 3. moon test 结果

- **命令**：`moon test`（在 `D:\CodeWorkspace\forMoonbit\re-mbt`）
- **T4 尝试版本**：`Total tests: 251, passed: 251, failed: 0`（语义正确，位图与 mem 等价）
- **回退后（T3 后版本）**：`Total tests: 251, passed: 251, failed: 0`
- **回归**：无（位图实现语义正确，但性能负改进故回退）

## 4. benchmark before/after 对比表

> bench/run_bench.ps1，native release，每 section 3 次取最优，5000 iters
> **同环境对比**：T3 后与 T4 均在本轮同一会话内连续运行，各运行 2 次取最优，消除环境漂移
> baseline.md 为 T1 时运行（不同环境），仅作参考

| Section | Name | Baseline(ms) | T3 后(ms) | T4(ms) | Δ vs T3(ms) | Δ vs T3(%) | 备注 |
|---------|------|--------------|-----------|--------|-------------|-----------|------|
| **1** | **Perl compile** | **951.0** | **528.2** | **533.9** | **+5.7** | **+1.08%** | **★ 主优化目标，回退** |
| 2 | Perl match | 43.3 | 40.8 | 39.8 | -1.0 | -2.45% | 纯 match，噪声内 |
| 3 | Emacs compile+match | 276.4 | 151.1 | 158.4 | +7.3 | +4.83% | 含 compile，回退 |
| 4 | POSIX compile+match | 281.1 | 158.9 | 165.4 | +6.5 | +4.09% | 含 compile，回退 |
| 5 | Glob compile+match | 347.4 | 219.7 | 234.5 | +14.8 | +6.74% | 含 compile，回退最大 |
| 6 | Pcre compile+match | 208.2 | 128.0 | 135.3 | +7.3 | +5.70% | 含 compile，回退 |
| 7 | Str compile+match | 348.5 | 183.6 | 190.9 | +7.3 | +3.98% | 含 compile，回退 |
| 8 | Search all+matches | 77.6 | 69.1 | 68.5 | -0.6 | -0.87% | 含少量 compile，噪声内 |
| 9 | Split+Replace | 42.3 | 41.6 | 39.1 | -2.5 | -6.01% | 含少量 compile，噪声内 |
| 10 | Large+Caseless | 25.8 | 25.8 | 25.2 | -0.6 | -2.33% | 噪声内 |

### 原始测量数据（2 次运行）

**T3 后（同环境）**：
| Section | Run1(ms) | Run2(ms) | Best(ms) |
|---------|----------|----------|----------|
| 1 | 531.6 | 528.2 | 528.2 |
| 2 | 40.8 | 41.3 | 40.8 |
| 3 | 164.8 | 151.1 | 151.1 |
| 4 | 176.1 | 158.9 | 158.9 |
| 5 | 222.8 | 219.7 | 219.7 |
| 6 | 131.5 | 128.0 | 128.0 |
| 7 | 183.6 | 185.0 | 183.6 |
| 8 | 69.1 | 69.5 | 69.1 |
| 9 | 44.3 | 41.6 | 41.6 |
| 10 | 25.8 | 26.9 | 25.8 |

**T4（同环境）**：
| Section | Run1(ms) | Run2(ms) | Best(ms) |
|---------|----------|----------|----------|
| 1 | 533.9 | 551.1 | 533.9 |
| 2 | 41.4 | 39.8 | 39.8 |
| 3 | 168.8 | 158.4 | 158.4 |
| 4 | 165.4 | 175.8 | 165.4 |
| 5 | 234.5 | 251.5 | 234.5 |
| 6 | 135.3 | 149.1 | 135.3 |
| 7 | 190.9 | 191.0 | 190.9 |
| 8 | 68.6 | 68.5 | 68.5 |
| 9 | 41.5 | 39.1 | 39.1 |
| 10 | 26.3 | 25.2 | 25.2 |

**Section 1 回退幅度：+1.08%（528.2ms → 533.9ms，+5.7ms）**

## 5. 收益分析

### 5.1 实际改进 vs 预期

- **预期**：hotspot_analysis.md 序 2 标注收益"高"，预期消除 Cset::mem 的 O(Ī) 因子，将 256 × |csets| × Ī 次区间比较降为 256 × |csets| 次 O(1) 位测试 + |csets| × 256 次位图构建。
- **实际**：Section 1 +1.08%（回退），含 compile 的 section（3/4/5/6/7）全部回退 4-7%。**负改进**，与预期相反。

### 5.2 负改进归因

1. **位图构建开销显著**：对每个 cset 遍历所有区间，对区间内**每个字符**设置位（`for c in c1..<(c2+1)`）。对于覆盖较大范围的 cset（如 `[a-zA-Z]` 52 字符、`\w` 63 字符、补集等），位图构建需迭代数十到上百个字符。总构建成本 = O(Σ cset_size) = O(|csets| × avg_cset_size)。加上 |csets| 个 FixedArray[Byte] of 32 bytes 的分配开销和 Byte↔Int 转换。

2. **原 Cset::mem 已经很快**：cset 的区间数通常很少（1-5 个，因 `cset_or_compl` 将 size > 128 的 cset 转为补集），mem 平均 1-3 次整数比较即可判定。256 × |csets| × Ī 的总操作数虽多，但每次是简单的 `c >= c1 && c <= c2` 比较，cache 友好，CPU 分支预测有效。

3. **位测试单次开销更大**：`(bitmap[i >> 3]).to_int() & (1 << (i & 7))) != 0` 涉及 FixedArray 索引、Byte→Int 转换、两次位运算、一次比较，比直接区间比较的开销大。虽然渐近 O(1) vs O(Ī)，但常数因子更高。

4. **分配开销与 GC 压力**：每次 flatten 调用分配 |csets| 个 FixedArray（各 32 bytes）。对 5000 iters × 多个 compile，累积分配增加 GC 压力。

5. **cache 局部性退化**：位图 |csets| × 32 bytes 占用额外内存，可能挤占 cache，影响热路径局部性。

6. **规模不匹配**：D1 位图优化在 hotspot_analysis.md 中标注"风险：中"，备注"可先不改 Cset 公开表示，仅在 flatten 中预展开"。但实测表明，当前 cset 规模（|csets| ≈ 5-15，Ī ≈ 1-5，avg_cset_size ≈ 10-60）下，位图构建的固定开销超过 mem 查询的边际节省。此优化更适合 |csets| 或 Ī 很大的场景（如 cset 数 > 50 或区间数 > 10）。

### 5.3 为什么 Section 2/8/9/10 不回退

Section 2（Perl match）纯 match 不触发 flatten，不受影响。Section 8/9/10 含少量 compile 但 match 占比高，compile 回退的绝对量小（数 ms），被 match 部分的噪声（±1-2ms）掩盖，表现为噪声内波动。

### 5.4 为什么含 compile 的 section 全部回退

Section 1/3/4/5/6/7 均含大量 compile（每 iter 多次 flatten），位图构建开销被放大，回退幅度与 compile 占比正相关：Section 5（Glob）+6.74% 最大，Section 7（Str）+3.98% 最小。

## 6. 风险/回归说明

### 6.1 测试回归

无。T4 尝试版本 251/251 全绿，位图与 Cset::mem 语义等价（位图构建遍历与 mem 相同的区间，置位逻辑正确）。回退后 251/251 仍全绿。

### 6.2 位图构建正确性（尝试性改动）

位图构建使用 `Cset::iter(cset, f=fn(c1, c2) { for c in c1..<(c2+1) { ... } })`，与 `Cset::mem(c, s)`（遍历 `s.intervals`，检查 `c >= c1 && c <= c2`）基于相同的 `intervals` 数据。对区间 `[c1, c2]` 内每个字符置位，位测试等价于 mem。moon test 251/251 全绿验证了语义等价。

### 6.3 warning 情况

T4 尝试版本 `moon check`：26 warnings, 0 errors（与 T3 后一致，无新 warning）。回退后同样 26 warnings。

### 6.4 纯 MoonBit 约束

位图使用 `FixedArray[Byte]` + Int 位运算，均为 MoonBit 核心类型，非 C FFI，支持全后端。回退后无影响。

### 6.5 回退决策

根据 task_v4.md 要求："若实测无改进或负改进（Section 1 相对 T3 后基线无改善或回退），则回退改动并在 opt_v4.md 中标注原因。" Section 1 相对 T3 后同环境基线 +1.08%（回退），含 compile 的 section 全部回退 4-7%，符合"负改进"条件，已回退 `re/color_map.mbt` 到 T3 后版本（`git checkout re/color_map.mbt`）。

### 6.6 后续建议

D1 局部（flatten 内联位图）在当前 cset 规模下负优化，不建议采用。若后续 cset 规模增大（如支持更复杂的字符类），可重新评估。替代方向：
- **D1 全局**（Cset 公开表示改位图）：让 union/inter/diff/mem 全部位运算 O(1)，位图构建成本摊销到所有操作，但改动面大（hotspot_analysis.md 序 8，风险高）。
- **A4**（translate_colors 去重位图）：针对 H2 而非 H7，收益独立。
- **其他序**：hotspot_analysis.md 序 3-10 的其他优化方向。
