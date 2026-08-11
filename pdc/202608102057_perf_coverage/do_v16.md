# 执行报告（v16）

## 概述
向 `re/color_map_test.mbt` 末尾追加 3 个 test 块，覆盖 `Ast::colorize`（ast.mbt:466-470）与 `ColorMap::split`（color_map.mbt:31-33）的一致性——验证通过 Ast::colorize 遍历 AstNoCase 树调用 ColorMap::split 后 flatten 的 ColorTable/ColorRepr，与手动 ColorMap::split 等价 csets 后 flatten 的结果一致。对应 coverage_gap_analysis.md §4 优先级 P9。

## 产出清单
| 操作 | 文件路径 | 说明 |
|------|---------|------|
| 修改 | `re/color_map_test.mbt` | 末尾追加 3 个 test 块（块 1/2/3） |

## 新增 test 块清单

### 块 1 `colorize single char matches manual split`
- **覆盖 API/分支**：`Ast::char`（ast.mbt:489-491）、`Ast::handle_case`（ast.mbt:173-175，Set 分支）、`Ast::colorize`（ast.mbt:466-470）→ `ast_colorize_rec` Set(s) 分支（ast.mbt:428-462）→ `ColorMap::split`（color_map.mbt:31-33）、`ColorMap::flatten`、`ColorTable::get`、`ColorRepr::length`
- **测试逻辑**：构造 `Ast::char('a')`（= `Set(CsetOf(Cset::single(97)))`），handle_case(false) 得 `Set(Cset::single(97))`，通过 colorize 路径与手动 split 路径对比 flatten 后的 ColorRepr::length 和 ColorTable::get(0/64/97/98/255)，并断言 lnl1=false（无 LastEndOfLine 节点）
- **行数**：16 行

### 块 2 `colorize str matches manual split`
- **覆盖 API/分支**：`Ast::str`（ast.mbt:499-504，length=2 走 Sequence 分支）、`Ast::handle_case` Sequence 分支（ast.mbt:176-177）、`ast_colorize_rec` Sequence 分支（递归调用两个 Set）、`ColorMap::split` ×2
- **测试逻辑**：构造 `Ast::str(b"ab")`（= `Sequence([Set(CsetOf(single(97))), Set(CsetOf(single(98)))])`），handle_case(false) 得 `Sequence([Set(single(97)), Set(single(98))])`，colorize 路径递归 split 两个 cset，与手动 split(97)+split(98) 对比 flatten 结果（ColorRepr::length + ColorTable::get(0/64/97/98/99/255)），lnl1=false
- **行数**：17 行

### 块 3 `colorize alternative matches manual split`
- **覆盖 API/分支**：`Ast::alt`（ast.mbt:525-529，length=2 走 Alternative 分支）、`Ast::handle_case` Alternative 分支（ast.mbt:178-181）、`ast_colorize_rec` Alternative 分支（递归调用两个 Set）、`ColorMap::split` ×2
- **测试逻辑**：构造 `Ast::alt([Ast::char('a'), Ast::char('b')])`（= `AstNode(Alternative([Set(CsetOf(single(97))), Set(CsetOf(single(98)))]))`），handle_case(false) 得 `AstNode(Alternative([Set(single(97)), Set(single(98))]))`，colorize 路径递归 split 两个 cset，与手动 split(97)+split(98) 对比 flatten 结果（ColorRepr::length + ColorTable::get(0/64/97/98/99/255)），lnl1=false
- **行数**：17 行

## 执行过程

### 1. 确认 API 签名
查阅 ast.mbt:466-470 确认 `Ast::colorize(color_map : ColorMap, regexp : AstNoCase) -> Bool`，ast.mbt:173-202 确认 `Ast::handle_case(self : Ast, ign_case : Bool) -> AstNoCase`，color_map.mbt:31-33 确认 `ColorMap::split(self : ColorMap, set : Cset) -> Unit`。Ast::str 接受 Bytes 参数（ast.mbt:499），使用 `b"ab"` 字节字面量。

### 2. 构造测试
3 个 test 块均采用双路径对比模式：
- **colorize 路径**：`Ast::char/str/alt` → `Ast::handle_case(false)` → `Ast::colorize(cm1, rnc)` → `ColorMap::flatten(cm1)`
- **手动 split 路径**：`ColorMap::make()` → 多次 `ColorMap::split(cm2, Cset::single(...))` → `ColorMap::flatten(cm2)`
- **断言**：ColorRepr::length 相等 + 多个代表性字节（0/64/97/98/99/255）的 ColorTable::get 相等 + lnl1=false

### 3. 验证结果
- `moon test`：**Total tests: 291, passed: 291, failed: 0**（288 → 291，+3 块全绿）
- `moon check`：**26 warnings, 0 errors**（与 baseline 一致，无新 warning）

## 与 coverage_gap_analysis.md P9 的对应关系
- **P9 描述**：`Ast::colorize` + `ColorMap::split` 一致性，color_map_test.mbt 追加 3 块，高风险 × 中难度 × 中价值
- **对应行**：coverage_gap_analysis.md:396
- **覆盖目标**：`Ast::colorize`（mbti:87，原标记"未覆盖"）通过 3 个 test 块直接测试，覆盖 Set/Sequence/Alternative 三种 AstNoCase 节点类型的 colorize 递归路径
- **task.md 阶段二重点方向**：(a) 核心模块边界条件 + (d) cset/automata/compile 内部操作（通过公开 API 间接测试）——通过 Ast::colorize + ColorMap::split + ColorMap::flatten 公开 API 组合测试颜色分配一致性

## 偏差说明
无。严格按 task_v16.md 块 1/2/3 规格实现，3 块命名、构造、断言、行数均与指令一致。moon test 291/291 符合预期（288+3），moon check 26 warnings 符合 baseline。
