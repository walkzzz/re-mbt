# 执行报告（v22）

## 概述
执行 coverage_gap_analysis.md §4 优先级 P15（最后一项），新增 `re/compile_internal_test.mbt` 测试文件，写入 6 个 test 块直接覆盖 `CompileIdx` 9 个 pub fn + `StateHashTable` 3 个 pub fn。moon test 323/323 全绿（317+6），moon check 22 warnings（与基线一致，无新 warning）。

## 产出清单
| 操作 | 文件路径 | 说明 |
|------|---------|------|
| 新建 | `re/compile_internal_test.mbt` | 6 个 test 块覆盖 CompileIdx 9 API + StateHashTable 3 API |

## 执行过程

### 测试块设计与 API 覆盖

| 块 | 测试名 | 覆盖 API | 覆盖分支/边界 |
|----|--------|---------|--------------|
| 1 | `compile_idx constants` | `CompileIdx::unknown()`, `CompileIdx::break_value()` | 常量值 -2/-3 |
| 2 | `compile_idx three state predicates` | `CompileIdx::is_idx()`, `is_break()`, `is_unknown()` | 三态判定：正数/负数/边界值(unknown/break_value) |
| 3 | `compile idx conversion functions` | `CompileIdx::of_idx()`, `idx()`, `make_break()`, `break_idx()` | 身份转换 + make_break/break_idx round-trip + 边界(make_break(0)=-5) |
| 4 | `state hash table create and find empty` | `StateHashTable::create()`, `find()` | 空表 find 返回 None；capacity=4/1/0（0 钳制为 1） |
| 5 | `state hash table add and find hit` | `StateHashTable::add()`, `find()` | add 后 find 命中，验证 info.idx 一致 |
| 6 | `state hash table find miss different state` | `StateHashTable::add()`, `find()` | 不同 State（idx 1 vs -1）find 未命中；add 后两 key 共存互不干扰 |

### 关键决策

**CompileState 构造问题**：task_v22 假设"CompileState 可用 struct literal 同包构造"，但实际 MoonBit 中 `pub struct CompileState` 的字段未标记 `pub(all)`，从测试文件（即使同包）无法用 struct literal 构造（E4036: Cannot create values of the read-only type）。

**解决方案**：通过 `compile(Ast::char('a'))` 编译正则表达式，再调用 `match_str_p` 触发匹配（内部调用 `find_initial_state` 填充 `re.initial_states`），然后从 `re.initial_states[0]` 提取已有 `CompileState` 实例（同包字段访问）。这样无需修改源码即可获取 CompileState 进行 StateHashTable::add 测试。

**CompileState? 的 assert_eq 问题**：`CompileState` 未实现 `Eq`/`Debug` trait，`assert_eq` 不能用于 `CompileState?`。改用 `match` pattern + `CompileState::get_info().idx` 间接比较。

### 验证结果
- `moon test`：Total tests: 323, passed: 323, failed: 0 ✓
- `moon check`：22 warnings, 0 errors（与 T21 基线 22 warnings 一致，无新 warning）✓

### 与 coverage_gap_analysis.md P15 的对应关系
- §1 CompileIdx 0/9 → 块 1-3 覆盖全部 9 个 pub fn
- §1 StateHashTable 0/3 → 块 4-6 覆盖全部 3 个 pub fn
- §2.5 明细 12 项未覆盖 → 全部覆盖
- §3.4 分支缺口（StateHashTable 命中/未命中 + 容量增长）→ 块 4（空表 find）、块 5（命中）、块 6（未命中 + 共存）

## 偏差说明
task_v22 假设 CompileState 可用 struct literal 同包构造，实际因 `pub struct` 字段非 `pub(all)` 不可行。改用编译正则 + 触发匹配的方式从 `re.initial_states` 获取 CompileState 实例，测试覆盖目标（StateHashTable::add + find 命中/未命中）完全达成，未修改任何源码。
