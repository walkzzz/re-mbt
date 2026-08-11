# 执行报告（v20）

## 概述
执行 coverage_gap_analysis.md §4 优先级 P13，向 `re/coverage_test.mbt` 末尾追加 4 个 test 块，覆盖 `GroupT::offset` / `GroupT::start` / `GroupT::stop` 三个 raise API 的越界 raise 路径（group.mbt:22-27/38-43/54-59）以及 `GroupT::create` 直接构造与基本操作 API。测试从 307 增至 311，全部通过。

## 产出清单
| 操作 | 文件路径 | 说明 |
|------|---------|------|
| 修改 | re/coverage_test.mbt | 末尾追加 4 个 test 块（:1180-1253），覆盖 P13 |

## 新增 test 块清单

| 块号 | test 名称 | 行号 | 覆盖 API/分支 | 覆盖路径 |
|------|-----------|------|--------------|---------|
| 1 | `GroupT::offset out of bounds raise` | :1182-1199 | `GroupT::offset`（group.mbt:22-27）| 越界 idx=99 → `offset_opt` 返回 None → `fail("Group.offset: not found")` raise |
| 2 | `GroupT::start out of bounds raise` | :1201-1218 | `GroupT::start`（group.mbt:38-43）| 越界 idx=99 → `start_opt` 返回 None → `fail("Group.start: not found")` raise |
| 3 | `GroupT::stop out of bounds raise` | :1220-1237 | `GroupT::stop`（group.mbt:54-59）| 越界 idx=99 → `stop_opt` 返回 None → `fail("Group.stop: not found")` raise |
| 4 | `GroupT::create direct construction` | :1239-1253 | `GroupT::create` / `nb_groups` / `matched` / `offset` / `start` / `stop` / `get` | 直接构造 GroupT 实例，验证 7 项基本操作行为正确 |

## 每个块的实现说明

### 块 1 `GroupT::offset out of bounds raise`（:1182-1199）
- 通过 `compile(Ast::seq([Ast::str("a"), Ast::group(Ast::str("b"))]))` 编译正则，`exec_opt(re, "ab")` 匹配获取含捕获组的 GroupT 实例 g（group 0 整体 + group 1 捕获组）
- 用越界 idx `99` 调用 `GroupT::offset(g, 99)`，通过 `try { ... false } catch { _ => true }` 模式断言 raise
- 覆盖 group.mbt:22-27 `match GroupT::offset_opt(g, i) { None => fail("Group.offset: not found") }` 的 None 分支

### 块 2 `GroupT::start out of bounds raise`（:1201-1218）
- 同块 1 获取 g，用越界 idx `99` 调用 `GroupT::start(g, 99)`，断言 raise
- 覆盖 group.mbt:38-43 `match GroupT::start_opt(g, i) { None => fail("Group.start: not found") }` 的 None 分支

### 块 3 `GroupT::stop out of bounds raise`（:1220-1237）
- 同块 1 获取 g，用越界 idx `99` 调用 `GroupT::stop(g, 99)`，断言 raise
- 覆盖 group.mbt:54-59 `match GroupT::stop_opt(g, i) { None => fail("Group.stop: not found") }` 的 None 分支

### 块 4 `GroupT::create direct construction`（:1239-1253）
- 直接用 `GroupT::create` 构造 GroupT 实例：
  - `s = sb_cov("hello")`（5 字节）
  - `marks = MarkInfos::make([(0, 0), (1, 1)])` → table=[0, 1]（group 0 的 start_mark=0、stop_mark=1）
  - `pmarks = PmarkSet::empty()`
  - `gpos = [0, 5]`（mark 0 → 位置 0，mark 1 → 位置 5）
  - `gcount = 1`
- 7 项断言验证基本操作：
  - (a) `GroupT::nb_groups(g) == 1` — gcount 正确
  - (b) `GroupT::matched(g, 0) == true` — group 0 存在（table[0]=0 != -1）
  - (c) `GroupT::matched(g, 1) == false` — group 1 越界（2*1 >= table.length()=2）
  - (d) `GroupT::offset(g, 0) == (0, 5)` — gpos[0]=0, gpos[1]=5
  - (e) `GroupT::start(g, 0) == 0` — offset 第一分量
  - (f) `GroupT::stop(g, 0) == 5` — offset 第二分量
  - (g) `bs_cov(GroupT::get(g, 0).unwrap()) == "hello"` — s[0..5] 切片

## 执行过程

### 1. 源码查阅确认 API 行为
- `group.mbt:22-27` `GroupT::offset` 越界 raise `fail("Group.offset: not found")`
- `group.mbt:38-43` `GroupT::start` 越界 raise `fail("Group.start: not found")`
- `group.mbt:54-59` `GroupT::stop` 越界 raise `fail("Group.stop: not found")`
- `compile.mbt:618-626` `GroupT::create` 5 参数直接构造
- `mark_infos.mbt:11-24` `MarkInfos::make([(0,0),(1,1)])` → table=[0,1]（len=max(p.0)+1=2，t=[-1,-1] → t[0]=0,t[1]=1）
- `mark_infos.mbt:27-33` `MarkInfos::has(t, 1)` → 2*1=2 >= table.length()=2 → false
- `mark_infos.mbt:71-85` `MarkInfos::offset(t, 0)` → start=table[0]=0 != -1 → Some((0,1))

### 2. 测试编写
- 块 1-3 采用与现有 `str group_beginning out of bounds raise`（:1166-1178）一致的 try-catch + assert_eq 模式
- 块 1-3 通过 `exec_opt` 获取 GroupT 实例（与现有 `GroupT::offset_opt` 测试 :597-612 同样的正则和输入）
- 块 4 直接构造，用 `assert_eq` 直接断言 7 项行为

### 3. 验证
- `moon test`：Total tests: 311, passed: 311, failed: 0（307 + 4 = 311，全绿）
- `moon check`：22 warnings, 0 errors（均为既有 struct_never_constructed / unused warning，无新 warning 引入）

## 与 coverage_gap_analysis.md P13 的对应关系

| P13 要求 | 实现 | 状态 |
|---------|------|------|
| `GroupT::offset` 越界 raise 路径（group.mbt:22-27） | 块 1 :1182-1199 | ✓ 已覆盖 |
| `GroupT::start` 越界 raise 路径（group.mbt:38-43） | 块 2 :1201-1218 | ✓ 已覆盖 |
| `GroupT::stop` 越界 raise 路径（group.mbt:54-59） | 块 3 :1220-1237 | ✓ 已覆盖 |
| `GroupT::create` 直接构造与基本操作 | 块 4 :1239-1253 | ✓ 已覆盖 |

对应 task.md 阶段二重点覆盖方向：
- (a) 核心模块边界条件：块 4 验证 group 0 有效 / group 1 越界边界
- (b) 错误路径和异常处理：块 1-3 覆盖三个 raise API 的越界 raise 路径

## 偏差说明
无。严格按 task_v20.md 要求实现 4 个 test 块，moon test 311/311 全绿，moon check 无新 warning。
