# 执行报告（v17）

## 概述
执行 coverage_gap_analysis.md §4 优先级 P10（阶段二方法第 3 步"补充缺失测试"），向 `re/basics_test.mbt` 末尾追加 7 个 test 块，覆盖 cset 边界条件（§3.3 cset 边界缺口）。基线 291/291 → 298/298 全绿，moon check 26 warnings baseline 不变。

## 产出清单
| 操作 | 文件路径 | 说明 |
|------|---------|------|
| 修改 | `re/basics_test.mbt` | 末尾追加 7 个 test 块（167 行 → 231 行，19 块 → 26 块） |

## 新增 test 块清单

| # | 块名 | 覆盖的 API/分支 | 对应 §3.3 缺口 |
|---|------|----------------|---------------|
| 1 | `cset empty operations boundary` | `Cset::empty/union/inter/diff` 空集组合（4 断言） | 空集组合 |
| 2 | `cset cany combinations` | `Cset::cany/single/union/inter/diff` 全集组合（3 断言） | 全集组合 |
| 3 | `cset single boundary 0 and 255` | `Cset::single/mem` 边界值 0 与 255 + 越界 -1/256（6 断言） | 单元素边界 0 和 255 |
| 4 | `cset complement via diff cany` | `Cset::diff(cany, x)` 补集等价性，x=seq(65,90)，6 点采样（6 断言） | 互补验证 |
| 5 | `cset full 256 traversal mem` | `Cset::mem` 0..255 全遍历对 cany/empty/single(65)/seq(48,57)（1024 断言） | 256 全遍历 |
| 6 | `cset union_singles non-decreasing input` | `Cset::union_singles_in_strictly_decreasing_order` 非递减输入 [5,3,3,1] 不 raise + length>=1（1 断言） | union_singles 非递减 |
| 7 | `cset case_insens latin1 and predefined` | `Cset::case_insens` latin1 192↔224 + `calnum/calpha/clower/cword` 预定义集采样（18 断言） | case_insens 128-255 + 预定义集 |

## 执行过程

### 1. 基线确认
- 运行 `moon test`：291/291 全绿（与 task_v17.md §任务上下文一致）

### 2. API 签名核实
查阅 `re/cset.mbt` 确认 API 行为：
- `Cset::empty()`（cset.mbt:49）返回 `{intervals: []}`
- `Cset::cany()`（cset.mbt:59）返回 `{intervals: [(0, 255)]}`
- `Cset::single(c)`（cset.mbt:251）经 `cset_single_cache`（:246，0..<257 共 257 条目），返回 `{intervals: [(c, c)]}`，索引 0..256 合法
- `Cset::seq(c, cp)`（cset.mbt:271）c<=cp 返回 [(c,cp)] 否则 [(cp,c)]
- `Cset::union/inter/diff`（cset.mbt:105/166/195）双指针合并/相交/差集
- `Cset::mem(c, s)`（cset.mbt:338）线性扫描 intervals，c 在 [c1,c2] 内返回 true
- `Cset::union_singles_in_strictly_decreasing_order`（cset.mbt:384）假设 strictly decreasing，非递减输入会产生重叠但不 raise
- `Cset::case_insens(s)`（cset.mbt:567）= `union_all([s, offset(32, inter(s, cset_upper)), offset(-32, inter(s, cset_clower))])`
- 预定义集：`cset_upper`（:423）= union_all [iseq(65,90), iseq(192,214), iseq(216,222)]；`cset_clower`（:430）= offset(32, cset_upper) 即 97-122/224-246/248-254；`cset_calpha`（:449）= union(cset_clower, cset_upper) + {170,181,186,223,255}；`cset_calnum`（:461）= union(cset_calpha, cset_cdigit)；`cset_cword`（:464）= cadd('_', cset_calnum)

### 3. case_insens(192) 行为推导
- s = single(192) = [(192,192)]
- inter(s, cset_upper)：192 在 [192,214] 内 → [(192,192)]
- offset(32, [(192,192)]) = [(224,224)]
- inter(s, cset_clower)：192 不在 clower（97-122/224-246/248-254）内 → []
- offset(-32, []) = []
- union_all([[(192,192)], [(224,224)], []]) = [(192,192), (224,224)]
- 因此 mem(192, ci)=true, mem(224, ci)=true ✓

### 4. 测试编写
7 个 test 块严格按 task_v17.md §块规格编写，使用 `assert_eq` 直接断言（块 6 用 `assert_true` 因仅断言 length>=1 不断言具体值）。块 5 用 for 循环 0..<256 遍历，每字节 4 个 assert_eq 共 1024 断言。

### 5. 验证
- `moon test`：298/298 全绿（291+7=298，符合预期）
- `moon check`：26 warnings 0 errors（与 baseline 26 warnings 一致，无新 warning）

## 偏差说明
无。7 个 test 块严格按 task_v17.md §块规格编写，覆盖 §3.3 cset 边界缺口全部 7 项，moon test 298/298 与预期一致，moon check 26 warnings baseline 不变。
