# Compile 路径热点分析报告

> 基于 re-mbt 源码静态分析 + Section 1 benchmark 数据（Perl compile 951ms / 5000 iters / 8 patterns = 190.19us/compile）推断。
> 产出目的：为后续逐模块优化提供精确目标。

## 1. Compile 调用链概览

从前端 `Perl::compile_pat` 到 lazy DFA 构建的完整路径（编译期；match 期另算）：

```
Perl::compile_pat(s, opts)                          [perl.mbt:602]
└─ Perl::re(s, opts)                                [perl.mbt:577]      解析 → Ast
│  └─ perl_regexp → perl_branch → perl_piece → perl_atom ... 递归下降解析
│  └─ Ast::no_case(r)  (若 caseless)
└─ compile(r : Ast)                                 [compile_translate.mbt:294]
   ├─ Ast::anchored(r)                              [ast.mbt:224]       O(|AST|)
   ├─ Ast::seq([Ast::shortest(Ast::rep(Ast::any())), Ast::group(r)])  (若非锚定)
   └─ compile_1(r_nc)                               [compile_translate.mbt:257]
      ├─ Ast::handle_case(regexp, false)            [ast.mbt:173]       Ast → AstNoCase
      │  └─ handle_case_cset                        [ast.mbt:147]       递归，调用 Cset::union_all / diff / inter / case_insens
      ├─ ColorMap::make()                           [color_map.mbt:10]
      ├─ Ast::colorize(color_map, regexp_nc)        [ast.mbt:466]       遍历 AST，对每个 Set 调用 ColorMap::split
      │  └─ ColorMap::split → cset_or_compl         [color_map.mbt:22]
      │     └─ size_cset (Cset::iter)               [color_map.mbt:15]
      │     └─ Cset::diff(Cset::cany(), cset)       (若 size > 128)
      ├─ ColorMap::flatten(color_map)               [color_map.mbt:149] ★★★ 主热点
      │  ├─ BoundaryTable::create(csets)            [color_map.mbt:44]  257 字节 + Cset::iter
      │  └─ 256 循环:
      │     ├─ Cset::mem(i, csets[csetid])          [cset.mbt:316]      × csets.length()
      │     └─ array_int_eq(ids, unique_lists[j])   [color_map.mbt:136] × unique_lists.length()
      ├─ translate(ctx, regexp_nc)                  [compile_translate.mbt:95]  ★★ 次热点
      │  └─ 递归 AST:
      │     ├─ Set(s) → trans_set                   [compile_translate.mbt:32]
      │     │  └─ Cset::one_char(s)                 [cset.mbt:345]
      │     │  └─ CSetMap::find(cache, (hash, s))   [cset.mbt:667]      线性扫描
      │     │  └─ ColorTable::translate_colors      [color_map.mbt:90]  ★ 遍历 cset 字符
      │     │     └─ 逐字符 BoundaryTable::unsafe_next_boundary
      │     │     └─ Cset::union_singles_in_strictly_decreasing_order
      │     │     └─ CSetMap::add (push 到 entries)
      │     ├─ AstNode(Alternative(l)) → Ast::merge_sequences_no_case  [ast.mbt:423]  ★ 可能 O(n²)
      │     ├─ Repeat → make_repeater + iter_n      [compile_translate.mbt:57]
      │     └─ Expr::seq / alt / rep / mark ...     [automata_expr.mbt]  分配 Expr 节点
      └─ mk_re(...)                                 [compile.mbt:757]   O(1)，StateHashTable::create(64)
```

**关键观察**：编译期 lazy DFA 状态表 `Re.states` 为空（状态在 match 时 lazily 构建）。因此 Section 1 的 190us/compile 几乎全部花在 **AST 处理 + ColorMap 构建/flatten + translate** 三段，而非 DFA 状态探索。

## 2. 热点函数列表

按推测耗时占比排序。每项标注：文件:行号、功能、推测耗时原因、复杂度。

### H1 ★★★ `ColorMap::flatten` — color_map.mbt:149-199
- **功能**：把 ColorMap 中收集的 csets 转换为 256 字节 ColorTable + BoundaryTable + ColorRepr。
- **推测耗时原因**：
  1. **外层 256 次循环** 固定开销。
  2. 对每个 boundary 字节，**内层遍历所有 csets** 调用 `Cset::mem`（cset.mbt:316，线性扫描 intervals）。总计 **256 × |csets| × avg_intervals** 次 interval 比较。
  3. **`array_int_eq` 在 `unique_lists` 中线性查找**（color_map.mbt:170-174），最坏 **256 × |unique_lists| × |ids|** 次比较；`unique_lists` 无哈希索引，纯 O(n²) 去重。
  4. 每个字节构造新 `Array[Int]`（`ids`），**256 次 Array 分配**。
  5. `BoundaryTable::create` 中再次对每个 cset `Cset::iter`，叠加一次全 cset 扫描。
- **复杂度**：O(256 × |csets| × Ī + 256 × |unique| × |ids|)，对 8 个 Perl 模式 |csets| 典型 5-15，但每个模式都从头算。
- **优化方向**：数据结构层（unique_lists 用 HashSet/HashMap 按 ids 哈希去重）+ 内存层（ids 复用缓冲）+ 算法层（boundary 字节才需重算 ids，非 boundary 复用 prev_ids 已实现，但查找去重仍是瓶颈）。

### H2 ★★ `translate` + `trans_set` + `ColorTable::translate_colors` — compile_translate.mbt:95 / :32 + color_map.mbt:90
- **功能**：递归翻译 AST → Expr，对每个 `Set(s)` 把 Cset 按 ColorTable 重新着色为颜色 id 集合。
- **推测耗时原因**：
  1. **`ColorTable::translate_colors`（color_map.mbt:90-113）** 对 cset 的每个区间逐字符遍历，最坏 256 次 `BoundaryTable::unsafe_next_boundary` + `t.data[ci]` 访问 + 去重 push。
  2. **`CSetMap::find`（cset.mbt:667-676）** 是**线性扫描 entries**，每个 entry 调用 `Cset::equal`（又线性扫描 intervals）。缓存命中时仍是 O(|entries| × Ī)。`CSetMap::add` 直接 push，无去重无哈希。
  3. `Cset::union_singles_in_strictly_decreasing_order`（cset.mbt:362）每次创建新 Array。
  4. `trans_set` 中 `(Cset::hash(s), s)` 元组分配 + `Cset::hash`（cset.mbt:327，O(Ī)）每次都算（即使 one_char 短路也要先调 `Cset::one_char`）。
- **复杂度**：O(|AST| × 256) 最坏；实际取决于 cset 总字符数。
- **优化方向**：数据结构层（CSetMap 改哈希表）+ 算法层（translate_colors 按 boundary 跳跃已优化，但去重 `last_version` 仅对有序 cs 有效，可进一步用位图）+ 内存层（cs / cs_rev 复用）。

### H3 ★★ `Ast::handle_case` + `handle_case_cset` — ast.mbt:173 / :147
- **功能**：将 Ast（带 AstCset）转为 AstNoCase（Cset 已展平）。对每个 `CsetOf` / `Cast(Alternative)` / `Complement` / `Intersection` / `Difference` 调用 Cset 集合运算。
- **推测耗时原因**：
  1. `Cset::union_all` / `intersect_all`（cset.mbt:298 / :307）**累积式调用** `Cset::union`/`inter`，每次创建新 Cset + 新 Array，O(n) 次分配 + O(n × 总区间数) 拷贝。
  2. `Cset::case_insens`（cset.mbt:545）固定调用 `union_all` 3 路（含 2 次 `Cset::inter` + 2 次 `Cset::offset`）。
  3. `Cset::diff(Cset::cany(), ...)` 对 Complement 每次重算 0-255 全集差集，O(255) 级别。
  4. 递归遍历 AST，每个 Set 都触发上述运算。
- **复杂度**：O(|AST| × Cset 运算成本)；对含 `[^...]`、`\W`、`\D`、`[[:alpha:]]` 等的模式尤其重。
- **优化方向**：算法层（union_all 改一次性 k 路合并而非两两累积）+ 内存层（Cset 运算结果缓存，相同 AstCset 复用）+ 数据结构层（Cset 内部用位图 256bit 表示可让 union/inter/diff 变 O(1)）。

### H4 ★★ `Ast::merge_sequences_no_case` — ast.mbt:343-425（及 merge_sequences_from :252）
- **功能**：在 Alternative 分支间合并公共前缀，生成 NoCase 优化 AST。
- **推测耗时原因**：
  1. **递归实现**，每层 `start` 前进一步，最坏 O(n) 层。
  2. 每层构造新 `combined` / `y` / `y2` / `result` Array 并逐元素 push，**大量 Array 分配 + 拷贝**。
  3. `merged_rest[0] == x` 用 `Ast::Eq` 深比较，对大 AST 子树可能 O(子树大小)。
  4. 对 `Alternative(l2)` 分支把 l2 展开 + 余下元素重组，**可能 O(n²)**。
- **复杂度**：最坏 O(n²)（n = Sequence 长度 + Alternative 分支数）。
- **优化方向**：算法层（改迭代 + 共享不可变前缀）+ 内存层（避免每层新建 Array，用索引区间表示子数组）。注意：仅 Alternative 节点触发，对 8 个 Perl 模式中含 `(a|b)*c`、`(?:ab|cd|ef)+`、`[^aeiou][aeiou][^aeiou]` 等会命中。

### H5 ★ `Ast::colorize` + `ColorMap::split` + `cset_or_compl` — ast.mbt:466 + color_map.mbt:31 / :22
- **功能**：遍历 AST 收集所有 cset 到 ColorMap，为 flatten 做准备。
- **推测耗时原因**：
  1. `cset_or_compl` 对每个 cset 调用 `size_cset`（Cset::iter 累加区间大小），若 size > 128 则调用 `Cset::diff(Cset::cany(), cset)` **重新分配并计算补集**。
  2. `ColorMap::split` 直接 push 到 `self.csets`（Array），无去重——**相同 cset 会被重复 flatten**，放大 H1 成本。
- **复杂度**：O(|AST| × Ī)；但重复 cset 会放大 flatten 成本。
- **优化方向**：数据结构层（split 前去重：用 HashSet<Cset> 或按 hash 缓存）+ 算法层（cset_or_compl 的 size 阈值判断可缓存于 Cset 结构）。

### H6 ★ `Cset::union` / `inter` / `diff` — cset.mbt:105 / :166 / :189
- **功能**：排序区间列表的双指针合并/相交/差集。
- **推测耗时原因**：
  1. 每次调用**新建 result Array + 新建 Cset 结构**，频繁分配。
  2. `union` 中 `li_over` / `ri_over` Option 模式匹配，每步 match 开销。
  3. 被 `union_all` / `intersect_all` / `handle_case_cset` / `cset_or_compl` / 预定义 cset 初始化**大量调用**。
- **复杂度**：O(n+m) 每次；但累积调用次数高。
- **优化方向**：数据结构层（Cset 增加位图表示 256bit，union/inter/diff 变位运算 O(1)；区间表示仅用于序列化）+ 内存层（result Array 预分配 capacity = n+m）+ 算法层（union_all k 路归并而非两两）。

### H7 ★ `Cset::mem` — cset.mbt:316-324
- **功能**：判断字符 c 是否在 Cset 中。
- **推测耗时原因**：线性扫描 intervals。在 `ColorMap::flatten` 中被调用 **256 × |csets|** 次，是 flatten 内层热点。
- **复杂度**：O(Ī) 每次；总 O(256 × |csets| × Ī)。
- **优化方向**：数据结构层（Cset 增加位图或 256 字节查找表，mem 变 O(1)）；或 flatten 中预把每个 cset 展开为 256-bit 位图一次性构建。

### H8 ★ `BoundaryTable::create` — color_map.mbt:44-64
- **功能**：构建 257 字节"到下一边界的距离"表。
- **推测耗时原因**：对每个 cset 调用 `Cset::iter` 设置边界标记，然后 256 反向扫描填充 skip 距离。本身 O(256 + Σ|cset|)，但每次 compile 都重建。
- **复杂度**：O(256 + Σ|cset|)。
- **优化方向**：内存层（FixedArray 复用）；当前实现已较紧凑，优化优先级低。

### H9 `CSetMap` 线性查找 — cset.mbt:657-683
- **功能**：trans_set 的缓存，避免相同 Cset 重复 translate_colors。
- **推测耗时原因**：`find` 线性扫描 `entries`，每个 entry 调用 `Cset::equal`（O(Ī)）。`add` 直接 push 无去重。缓存小但每次 find O(|entries| × Ī)。
- **复杂度**：O(|entries| × Ī) 每次 find。
- **优化方向**：数据结构层（改哈希表：key = Cset::hash，bucket 内 Cset::equal）。注意 entries 在单次 compile 内累积，跨 compile 重建。

### H10 `Expr::rename` / `Expr::seq` / `Expr::alt` — automata_expr.mbt:158 / :100 / :89
- **功能**：translate 中构建 Expr 树。`rename` 在 Repeat 中复制子树（重新分配 id）。
- **推测耗时原因**：每个 Expr 节点分配 + Ids::next 计数。`rename` 递归复制整个子树，对深 Repeat 链可能 O(子树大小)。
- **复杂度**：O(|Expr|) 每次；rename 在 `make_repeater` 中被 `iter_n` 反复调用，对 `{m,n}` 重复可能 O((n-m) × |sub|)。
- **优化方向**：算法层（rename 改用共享 + 惰性 id，或避免不必要的 rename）+ 内存层（Expr 节点池化）。优先级中。

### H11 `Cset::hash` — cset.mbt:327-335
- **功能**：Cset 哈希，用于 CSetMap key。
- **推测耗时原因**：O(Ī) 每次调用，在 trans_set 中每个 Set 都算一次（即使缓存命中也要先算 hash 才能查缓存）。
- **复杂度**：O(Ī)。
- **优化方向**：内存层（Cset 结构缓存 hash，首次计算后存字段）；与 H9 一起优化。

### H12 `Ast::anchored` + `Ast::seq`/`rep`/`group` 包裹 — ast.mbt:224 + compile_translate.mbt:295-299
- **功能**：compile 入口检查锚定并包裹 `.*?` 前缀。
- **推测耗时原因**：O(|AST|) 遍历；包裹分配几个 Ast 节点。本身不重，但每次 compile 都做。
- **复杂度**：O(|AST|)。
- **优化方向**：低优先级；若 benchmark 证明可考虑 anchored 模式快速路径跳过包裹。

## 3. 优化方向建议

按算法层 / 内存层 / 数据结构层分类，每项关联热点编号。

### 算法层
- **A1**：`ColorMap::flatten` 中 `unique_lists` 去重改哈希表（key = ids 的内容哈希或滚动哈希），消除 O(256 × |unique| × |ids|) → O(256 × |ids|)。关联 H1。
- **A2**：`Cset::union_all` / `intersect_all` 改 k 路归并/堆合并，而非两两累积调用 union/inter。关联 H3、H6。
- **A3**：`Ast::merge_sequences_no_case` 改迭代 + 索引区间表示子数组，避免每层新建 Array。关联 H4。
- **A4**：`ColorTable::translate_colors` 内部去重用 256-bit 位图（按颜色 id 置位），最后再转回区间列表。关联 H2。
- **A5**：`Expr::rename` 评估是否可避免——OCaml 原版用 rename 给 Rep 副本分配新 id 以区分导数状态，可考虑共享 + 惰性 id。关联 H10。**风险高**，需行为一致性验证。

### 内存层
- **M1**：`ColorMap::flatten` 中 `ids` Array 复用（预分配 256 长度缓冲，clear 后重用），消除 256 次 Array 分配。关联 H1。
- **M2**：`Cset::union`/`inter`/`diff` 的 `result` Array 预分配 capacity = n+m，避免动态扩容。关联 H6。
- **M3**：`Cset::hash` 结果缓存到 Cset 结构字段（首次计算后存 `mut hash_cache : Int?`）。关联 H11、H9。
- **M4**：`translate` / `trans_set` 中 `(hash, s)` 元组与 `cs` / `cs_rev` Array 跨 compile 复用——但跨 compile 复用需注意线程安全（当前单线程，可行）。关联 H2。
- **M5**：`Ast::merge_sequences_no_case` 中间 Array 改用 Array::push 而非每层新建（部分已用 push，但 combined / y / y2 仍新建）。关联 H4。

### 数据结构层
- **D1** ★★★：**Cset 增加 256-bit 位图表示**（4×Int64 或 FixedArray[Byte] of 32 bytes），`union`/`inter`/`diff`/`mem`/`case_insens` 改位运算 O(1) 或 O(32)。区间表示保留用于序列化/调试。这是对 H3、H6、H7 的根本性优化，但改动面大（Cset 是核心类型，贯穿全库）。**需充分测试**。
- **D2**：`CSetMap` 改哈希表（bucket 数组 + Cset::equal 桶内比较）。关联 H9、H2。
- **D3**：`ColorMap::flatten` 中 `unique_lists` 改 HashMap<Array[Int], Int>（key = ids 内容哈希）。关联 H1、A1。
- **D4**：`ColorMap::split` 前对 cset 去重（HashSet<Cset> 或按 hash 缓存），避免重复 cset 进入 flatten 放大 H1 成本。关联 H5、H1。
- **D5**：`Cset::cset_or_compl` 的 size > 128 判断结果可缓存于 Cset 字段（若 Cset 不可变）。关联 H5。

## 4. 优先级排序

综合耗时占比（推测）× 优化难度 × 回归风险，给出优化顺序：

| 序 | 热点 | 优化项 | 层 | 预期收益 | 难度 | 风险 | 备注 |
|----|------|--------|----|---------|------|------|------|
| 1 | H1 | A1 + D3 + M1 | 算法+DS+内存 | **高** | 中 | 低 | flatten 是单次 compile 最重函数；unique_lists 哈希化 + ids 缓冲复用，改动局部 |
| 2 | H7 + H1 | D1（Cset 位图，仅 flatten 内联用） | DS | **高** | 中 | 中 | 可先不改 Cset 公开表示，仅在 flatten 中把每个 cset 预展开为 256-bit 位图，mem 变 O(1)；改动局部 |
| 3 | H9 + H11 | D2 + M3 | DS+内存 | 中-高 | 低 | 低 | CSetMap 哈希化 + Cset::hash 缓存，改动局部，收益随 |entries| 增长 |
| 4 | H2 | A4 | 算法 | 中 | 中 | 低 | translate_colors 去重用位图，消除 cs/cs_rev Array 分配 |
| 5 | H3 + H6 | A2 + M2 | 算法+内存 | 中 | 中 | 低 | union_all k 路合并 + result 预分配；handle_case_cset 受益 |
| 6 | H5 + H1 | D4 | DS | 中 | 低 | 低 | ColorMap::split 去重，减少 |csets| 直接放大 H1 收益 |
| 7 | H4 | A3 + M5 | 算法+内存 | 中 | 中 | 中 | merge_sequences_no_case 改迭代；需小心保持 NoCase 语义 |
| 8 | H6 | D1（Cset 公开表示改位图） | DS | **高** | **高** | **高** | 根本性优化，但改动面大，需全量测试；放后期 |
| 9 | H10 | A5 | 算法 | 低-中 | 高 | **高** | Expr::rename 涉及导数正确性，需与 OCaml 上游对照；暂缓 |
| 10 | H8/H12 | — | — | 低 | — | — | 已较紧凑或开销小，暂不优化 |

**建议执行顺序**：先做 1-3（局部、低风险、高收益），benchmark 验证后再做 4-7，最后评估 8-9 是否必要。每步后跑 `moon test` 确保不回归。

## 5. 验证建议

本报告基于静态代码分析 + benchmark section 级数据推断，**未做函数级 profiling**。建议在优化前用以下方式验证热点排序：
- MoonBit native 无内置 profiler，可在 H1-H5 各函数入口/出口插桩计次+计时（用 `@datetime` 或 native FFI clock），跑 Section 1 单 section（`bench_section = 1`）获取函数级耗时。
- 或用 moon native 的 `--release` + 外部 perf/VTune 采样（需 moon 工具链支持符号）。
- 优先验证 H1（flatten）和 H2（translate）的实际占比，确认二者合计是否 > 60% compile 时间；若是，则序 1-4 的优化预期成立。

## 6. 附：8 个 Perl 模式的 cset 规模估算

| 模式 | 大致 cset 数 | 含 Complement | 含 Alternative | 预期 flatten |csets| |
|------|------------|---------------|----------------|---------------------|
| `hello` | 5（h,e,l,l,o 去重 4） | 否 | 否 | 4 |
| `a*b` | 2 | 否 | 否 | 2 |
| `(a|b)*c` | 3 | 否 | 是 | 3 |
| `[a-z]+@[a-z]+\.[a-z]+` | 3（[a-z] 去重 1 + @ + .） | 否 | 否 | 3 |
| `(\w+\s*)+` | 2（\w、\s） | 否 | 是 | 2 |
| `a{2,5}b*c?` | 3 | 否 | 否 | 3 |
| `(?:ab\|cd\|ef)+` | 6 | 否 | 是 | 6 |
| `[^aeiou][aeiou][^aeiou]` | 2（[^aeiou] 去重 1 + [aeiou]） | 是 | 否 | 2 |

注：`Ast::colorize` 对每个 Set 调用 `ColorMap::split`，但 `split` 无去重（H5），相同 cset 会重复进入 `flatten`。上表为去重后估算；实际 |csets| 可能因重复翻倍。这进一步支持 D4（split 去重）的优先级。

---

**结论**：Section 1 的 190us/compile 主要由 `ColorMap::flatten`（H1）和 `translate`/`trans_set`（H2）主导，二者又都被 `Cset::mem`（H7）和 `CSetMap` 线性查找（H9）放大。建议从序 1-3 开始局部优化，预期可将 compile 时间显著降低，且不触及 Cset 公开表示（低风险）。
