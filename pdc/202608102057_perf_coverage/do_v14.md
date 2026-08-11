# 执行报告（v14）

## 概述
执行 coverage_gap_analysis.md §4 优先级 P7，新增 `re/desc_test.mbt` 测试文件，写入 6 个 test 块直接覆盖 `Desc::initial`、`Desc::status` 三分支（Failed/Match/Running）、`Desc::remove_duplicates` 去重正确性。moon test 284/284 全绿（278+6），moon check 26 warnings（与基线一致，无新 warning）。

## 产出清单
| 操作 | 文件路径 | 说明 |
|------|---------|------|
| 新建 | re/desc_test.mbt | 6 个 test 块覆盖 Desc::initial/status/remove_duplicates pub API |

## 执行过程

### 1. 基线确认
运行 `moon test` 确认 T13 后基线 278/278 全绿。

### 2. API 签名核实
查阅 `re/pkg.generated.mbti` 确认目标 API 签名：
- `pub fn Desc::initial(Expr) -> Array[ET]`（mbti:288）
- `pub fn Desc::status(Array[ET]) -> Status`（mbti:294）
- `pub fn Desc::remove_duplicates(HashSet, Array[ET], Expr) -> Array[ET]`（mbti:290）
- 构造辅助：`Desc::texp(Marks, Expr, Array[ET]) -> Array[ET]`（mbti:296）、`Desc::add_match(Array[ET], Marks) -> Array[ET]`（mbti:282）、`Desc::empty() -> Array[ET]`（mbti:283）

### 3. ET 枚举构造方式调整
task_v14.md 描述 "TExp(Marks::empty(), expr) / TMatch(Marks::empty()) 直接构造 ET 枚举值"，但实际编译器报错 `[4036] Cannot create values of the read-only type: TExp`。查阅 `pkg.generated.mbti:309-313` 确认 `pub enum ET` 的变体为 read-only，不可直接构造。改用 Desc 提供的构造函数：
- `[TExp(marks, e)]` → `Desc::texp(marks, e, Desc::empty())`
- `[TMatch(marks)]` → `Desc::add_match(Desc::empty(), marks)`
- `[TExp(m1, e1), TExp(m2, e2)]` → `Desc::texp(m1, e1, Desc::texp(m2, e2, Desc::empty()))`

### 4. 辅助函数
参考 automata_test.mbt:5-20 风格，定义 `desc_status_is_failed`/`desc_status_is_running`/`desc_status_is_match` 三个辅助函数（加 `desc_` 前缀避免与 automata_test.mbt 同名函数冲突），通过 match Status variant 返回 Bool。

### 5. test 块清单

| 块 | 名称 | 覆盖 API/分支 | 源码位置 |
|----|------|--------------|---------|
| 1 | `desc initial returns single TExp with empty marks` | Desc::initial 返回 `[TExp(Marks::empty(), expr)]` + status Running | automata_desc.mbt:144-146, 250 |
| 2 | `desc status empty array returns Failed` | Desc::status 空数组分支 | automata_desc.mbt:245-246 |
| 3 | `desc status TMatch head returns Match` | Desc::status TMatch 分支 | automata_desc.mbt:248-249 |
| 4 | `desc status TExp head returns Running` | Desc::status 非 TMatch 分支 | automata_desc.mbt:250 |
| 5 | `desc remove_duplicates dedup same expr TExp` | remove_duplicates 去重分支（seen.mem 命中跳过） | automata_desc.mbt:389-390 |
| 6 | `desc remove_duplicates keeps distinct expr TExp` | remove_duplicates 保留分支（seen.add 并保留） | automata_desc.mbt:391-397 |

### 6. 验证结果
- `moon test`：Total tests: 284, passed: 284, failed: 0 ✓
- `moon check`：26 warnings, 0 errors（与 T13 基线 26 warnings 一致，无新 warning）✓

### 7. 与 coverage_gap_analysis.md P7 的对应关系
P7 要求覆盖 `Desc::remove_duplicates`/`Desc::initial`/`Desc::status` 三个 pub fn（§1 Desc 5.6% 覆盖，§2.4 明细 17 项未覆盖/仅间接，§3.3 分支缺口含 status Failed/Match/Running 三分支 + remove_duplicates 去重）。本轮 6 个 test 块完整覆盖：
- Desc::initial：块 1
- Desc::status 三分支：块 2（Failed）、块 3（Match）、块 4（Running）
- Desc::remove_duplicates 去重/保留：块 5（去重）、块 6（保留）

## 偏差说明
task_v14.md 描述 "TExp(Marks::empty(), expr) / TMatch(Marks::empty()) 直接构造 ET 枚举值"，但 MoonBit 编译器报错 `[4036] Cannot create values of the read-only type: TExp`，ET 枚举变体不可直接构造。改用 `Desc::texp`/`Desc::add_match`/`Desc::empty` 构造函数间接构造 ET 值，测试语义不变（仍直接调用 `Desc::initial`/`Desc::status`/`Desc::remove_duplicates` 三个目标 pub fn，断言其行为）。此偏差不影响覆盖率目标——三个目标 pub fn 均被直接调用且分支被覆盖。
