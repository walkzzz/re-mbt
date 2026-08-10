# 优化报告（v3）：ColorMap::flatten 哈希去重 + ids 缓冲复用

> 对应 hotspot_analysis.md 优先级序 1（A1 + D3 + M1）

## 1. 改动摘要

| 文件 | 行号 | 改动点 |
|------|------|--------|
| `re/color_map.mbt` | :135-146（删除） | 删除 `array_int_eq`（线性逐元素比较），被 HashMap 内置 Eq 替代 |
| `re/color_map.mbt` | :148-187（重写） | `ColorMap::flatten` 重写：unique_lists 线性去重 → HashMap 哈希去重；ids 每轮新建 → ids_buf 循环外预分配复用 |
| `re/moon.pkg` | :1-3（新增） | 添加 `moonbitlang/core/hashmap` import |

净变化：`re/color_map.mbt` -33/+23 行（-10 行），`re/moon.pkg` +3 行。

## 2. diff 关键行

### 2.1 删除 array_int_eq（原 :135-146）

```moonbit
// before
fn array_int_eq(a : Array[Int], b : Array[Int]) -> Bool {
  if a.length() != b.length() { return false }
  for i in 0..<a.length() { if a[i] != b[i] { return false } }
  true
}

// after：删除（HashMap[Array[Int], Int] 内置 Array::equal 作为 Eq）
```

### 2.2 flatten 重写（原 :148-199 → 新 :135-185）

```moonbit
// before：unique_lists 线性去重 + ids 每轮新建
let unique_lists : Array[Array[Int]] = []
let mut prev_ids : Array[Int] = []
for i in 0..<256 {
  let ids : Array[Int] = []                    // 每轮分配
  if bt.data[i] == (0).to_byte() {
    // ... 填充 ids ...
    prev_ids = ids
    let mut found = -1
    for j in 0..<unique_lists.length() {       // O(|unique|) 线性扫描
      if found < 0 && array_int_eq(ids, unique_lists[j]) {  // O(|ids|) 逐元素比较
        found = j
      }
    }
    let v = if found >= 0 { found } else {
      unique_lists.push(ids)
      num_colors += 1
      num_colors - 1
    }
    // ...
  } else {
    for x in prev_ids { ids.push(x) }          // 死代码：ids 填充后未被读取
    // ...
  }
}

// after：HashMap 哈希去重 + ids_buf 循环外预分配复用
let ids_buf : Array[Int] = []                                  // M1: 单一缓冲复用
let color_map : @hashmap.HashMap[Array[Int], Int] = @hashmap.HashMap::HashMap([])  // A1+D3: 哈希表
let mut last_version = 0
for i in 0..<256 {
  if bt.data[i] == (0).to_byte() {
    ids_buf.clear()                                            // M1: clear 复用，无新分配
    for csetid in 0..<csets.length() {
      if Cset::mem(i, csets[csetid]) { ids_buf.push(csetid + 1) }
    }
    let v = match color_map.get(ids_buf) {                    // A1: O(|ids|) 哈希查找
      Some(id) => id
      None => {
        let key = Array::make(ids_buf.length(), 0)            // 仅未命中时深拷贝一次
        for k in 0..<ids_buf.length() { key[k] = ids_buf[k] }
        let id = num_colors
        color_map[key] = id
        num_colors += 1
        id
      }
    }
    // ...
  } else {
    // ...（删除死代码：for x in prev_ids { ids.push(x) }）
  }
}
```

### 2.3 moon.pkg 新增 import

```json5
// re/moon.pkg
import {
  "moonbitlang/core/hashmap",
}
```

## 3. moon test 结果

- **命令**：`moon test`（在 `D:\CodeWorkspace\forMoonbit\re-mbt`）
- **结果**：`Total tests: 251, passed: 251, failed: 0`
- **耗时**：约 0.21s（与 baseline 持平）
- **回归**：无

## 4. benchmark before/after 对比表

> bench/run_bench.ps1，native release，每 section 3 次取最优，5000 iters

| Section | Name | Baseline(ms) | After(ms) | Δ(ms) | Δ(%) | 备注 |
|---------|------|--------------|-----------|-------|------|------|
| **1** | **Perl compile** | **951.0** | **571.1** | **-379.9** | **-39.95%** | **★ 主优化目标，大幅改进** |
| 2 | Perl match | 43.3 | 42.9 | -0.4 | -0.92% | 纯 match 无 compile，符合预期不变 |
| 3 | Emacs compile+match | 276.4 | 159.6 | -116.8 | -42.26% | 含 compile，大幅改进 |
| 4 | POSIX compile+match | 281.1 | 161.1 | -120.0 | -42.69% | 含 compile，大幅改进 |
| 5 | Glob compile+match | 347.4 | 226.4 | -121.0 | -34.84% | 含 compile，大幅改进 |
| 6 | Pcre compile+match | 208.2 | 129.6 | -78.6 | -37.75% | 含 compile，大幅改进 |
| 7 | Str compile+match | 348.5 | 187.3 | -161.2 | -46.25% | 含 compile，改进最大 |
| 8 | Search all+matches | 77.6 | 69.2 | -8.4 | -10.82% | 含少量 compile，小幅改进 |
| 9 | Split+Replace | 42.3 | 38.6 | -3.7 | -8.75% | 含少量 compile，小幅改进 |
| 10 | Large+Caseless | 25.8 | 26.4 | +0.6 | +2.33% | 噪声范围（±0.6ms），详见 §6 |

**Section 1 改进幅度：-39.95%（951.0ms → 571.1ms，-379.9ms）**

## 5. 收益分析

### 5.1 实际改进 vs 预期

- **预期**：hotspot_analysis.md 序 1 标注收益"高"，预期消除 unique_lists 线性查找的 O(|unique|) 因子和 256 次 Array 分配。
- **实际**：Section 1 -39.95%，远超预期。所有含 compile 的 section（3/4/5/6/7）改进 34-46%，表明 flatten 是 compile 路径的真实主热点，且优化收益跨前端通用（Perl/Emacs/POSIX/Glob/Pcre/Str 均受益）。
- **跨前端一致性**：Section 3/4（Emacs/POSIX）改进 42%，Section 7（Str）改进 46%，Section 5（Glob）改进 35%，Section 6（Pcre）改进 38%。差异源于各前端 compile 占比不同，但趋势一致。

### 5.2 收益归因

1. **A1 + D3（哈希去重）**：原 `unique_lists` 线性查找最坏 O(256 × |unique| × |ids|)。对 8 个 Perl 模式，|unique|（distinct color 数）典型 10-40，|ids|（cset 数）5-15。哈希化后每次查找 O(|ids|)（计算 hash + 桶内比较），消除 |unique| 因子。这是主要收益来源。
2. **M1（ids 缓冲复用）**：消除 256 次 `Array[Int]` 分配（每次 compile）。单次分配开销小，但 5000 iters × 256 次 = 128 万次分配，累积可观。
3. **死代码消除**：删除 else 分支 `for x in prev_ids { ids.push(x) }`（ids 填充后未被读取），减少非 boundary 字节的无效拷贝。

### 5.3 为什么 Section 2（Perl match）不变

Section 2 纯 match（预编译 Re 复用），不触发 flatten。优化仅作用于 compile 路径，故 Section 2 不变（-0.92% 在噪声内），验证优化定位准确。

## 6. 风险/回归说明

### 6.1 测试回归

无。251/251 全绿，语义未回归。

### 6.2 死代码删除的语义等价性

删除 else 分支 `for x in prev_ids { ids.push(x) }` 及 `prev_ids` 变量。分析：
- 原代码 else 分支填充 `ids` 后，`ids` 在循环体剩余部分**未被任何代码读取**（仅 `table_arr[i] = last_version.to_byte()` 和 `repr_arr[last_version] = i.to_byte()` 被赋值，用 `last_version` 而非 `ids`）。
- 下一轮 `ids` 为新建（原代码）或 `clear`（新代码），不继承上一轮 `ids`。
- 因此 else 分支的 `ids` 填充是死代码，删除语义等价。
- **必要性**：M1 要求 `ids_buf` 循环内 `clear` 复用。若保留 `prev_ids = ids_buf`，下一轮 `clear` 会清空 `prev_ids`，破坏原语义。故死代码删除是 M1 的必要前提。

### 6.3 Section 10 轻微回退（+2.33%）

- Section 10（Large+Caseless）25.8ms → 26.4ms，+0.6ms（+2.33%）。
- 该 section 总耗时 25.8ms，单次 iter 5.16us，0.6ms 差异约 0.12us/iter，在 benchmark 噪声范围（native release 单次 5us 级测量，±5% 噪声常见）。
- Section 10 含 caseless compile（会触发 cset_or_compl + flatten），但 caseless 模式 cset 数少，unique_lists 小，哈希化收益小，HashMap 固定开销（初始化、trait dispatch）可能略大于线性查找收益。
- **结论**：噪声级回退，可接受。若后续证实为系统性回退，可对 small-color-map 场景加快速路径（|unique| < 阈值时回退线性查找）。

### 6.4 HashMap 通用实现开销

`@hashmap.HashMap` 是通用实现，key = `Array[Int]` 每次 `get` 计算 `Array::hash`（遍历 ids）+ 桶内 `Array::equal`（最坏遍历 ids）。相比手写专用开放寻址（如项目已有 HashSet 风格，key = 滚动哈希 Int），有 trait dispatch 和通用 Hasher 开销。但实测 Section 1 -39.95% 表明通用实现已足够，专用实现边际收益有限，暂不引入。

### 6.5 warning 情况

- 改动前：28 warnings（既有 struct_never_constructed / unused_constructor / unused_value）
- 改动后：26 warnings（消除 2 个 `core_package_not_imported`，因新增 `re/moon.pkg` 的 hashmap import）
- **无新 warning 引入**，反而减少 2 个。

### 6.6 纯 MoonBit 约束

`@hashmap` 属于 `moonbitlang/core`（标准库），非 C FFI，满足"纯 MoonBit 无 C FFI"约束。支持 native/wasm/js 全后端（HashMap 是纯 MoonBit 实现）。
