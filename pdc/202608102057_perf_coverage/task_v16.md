# 任务指令（v16）

## 动作
NEW

## 任务描述
执行 coverage_gap_analysis.md §4 优先级 P9（阶段二方法第 3 步"补充缺失测试"），向 `re/color_map_test.mbt` 末尾追加 3 个 test 块，覆盖 `Ast::colorize`（ast.mbt:466-470）与 `ColorMap::split`（color_map.mbt:31-33）的一致性——验证通过 Ast::colorize 遍历 AstNoCase 树调用 ColorMap::split 后 flatten 的 ColorTable/ColorRepr，与手动 ColorMap::split 等价 csets 后 flatten 的结果一致。

具体：

(1) **块 1 `colorize single char matches manual split`**
- 构造 `let r = Ast::char('a')`（= `Set(CsetOf(Cset::single(97)))`，ast.mbt:489-491 经 ast_char_cache）
- `let rnc = Ast::handle_case(r, false)` 得 AstNoCase `Set(Cset::single(97))`
- `let cm1 = ColorMap::make()`；`let lnl1 = Ast::colorize(cm1, rnc)`；`let (t1, _bt1, rep1) = ColorMap::flatten(cm1)`
- 对比手动路径：`let cm2 = ColorMap::make()`；`ColorMap::split(cm2, Cset::single(97))`；`let (t2, _bt2, rep2) = ColorMap::flatten(cm2)`
- 断言：
  - `assert_eq(ColorRepr::length(rep1), ColorRepr::length(rep2))`
  - `assert_eq(ColorTable::get(t1, 0), ColorTable::get(t2, 0))`
  - `assert_eq(ColorTable::get(t1, 64), ColorTable::get(t2, 64))`
  - `assert_eq(ColorTable::get(t1, 97), ColorTable::get(t2, 97))`（'a'）
  - `assert_eq(ColorTable::get(t1, 98), ColorTable::get(t2, 98))`
  - `assert_eq(ColorTable::get(t1, 255), ColorTable::get(t2, 255))`
  - `assert_eq(lnl1, false)`（无 LastEndOfLine 节点）

(2) **块 2 `colorize str matches manual split`**
- 构造 `let r = Ast::str(b"ab")`（= `Sequence([Set(CsetOf(single(97))), Set(CsetOf(single(98)))])`，ast.mbt:499-504）
- `let rnc = Ast::handle_case(r, false)` 得 `Sequence([Set(single(97)), Set(single(98))])`
- `let cm1 = ColorMap::make()`；`let lnl1 = Ast::colorize(cm1, rnc)`；`let (t1, _bt1, rep1) = ColorMap::flatten(cm1)`
- 对比手动路径：`let cm2 = ColorMap::make()`；`ColorMap::split(cm2, Cset::single(97))`；`ColorMap::split(cm2, Cset::single(98))`；`let (t2, _bt2, rep2) = ColorMap::flatten(cm2)`
- 断言：
  - `assert_eq(ColorRepr::length(rep1), ColorRepr::length(rep2))`
  - `assert_eq(ColorTable::get(t1, 0), ColorTable::get(t2, 0))`
  - `assert_eq(ColorTable::get(t1, 64), ColorTable::get(t2, 64))`
  - `assert_eq(ColorTable::get(t1, 97), ColorTable::get(t2, 97))`（'a'）
  - `assert_eq(ColorTable::get(t1, 98), ColorTable::get(t2, 98))`（'b'）
  - `assert_eq(ColorTable::get(t1, 99), ColorTable::get(t2, 99))`（'c'）
  - `assert_eq(ColorTable::get(t1, 255), ColorTable::get(t2, 255))`
  - `assert_eq(lnl1, false)`

(3) **块 3 `colorize alternative matches manual split`**
- 构造 `let r = Ast::alt([Ast::char('a'), Ast::char('b')])`（= `AstNode(Alternative([Set(CsetOf(single(97))), Set(CsetOf(single(98)))]))`，ast.mbt:525-529）
- `let rnc = Ast::handle_case(r, false)` 得 `AstNode(Alternative([Set(single(97)), Set(single(98))]))`
- `let cm1 = ColorMap::make()`；`let lnl1 = Ast::colorize(cm1, rnc)`；`let (t1, _bt1, rep1) = ColorMap::flatten(cm1)`
- 对比手动路径：`let cm2 = ColorMap::make()`；`ColorMap::split(cm2, Cset::single(97))`；`ColorMap::split(cm2, Cset::single(98))`；`let (t2, _bt2, rep2) = ColorMap::flatten(cm2)`
- 断言：
  - `assert_eq(ColorRepr::length(rep1), ColorRepr::length(rep2))`
  - `assert_eq(ColorTable::get(t1, 0), ColorTable::get(t2, 0))`
  - `assert_eq(ColorTable::get(t1, 64), ColorTable::get(t2, 64))`
  - `assert_eq(ColorTable::get(t1, 97), ColorTable::get(t2, 97))`（'a'）
  - `assert_eq(ColorTable::get(t1, 98), ColorTable::get(t2, 98))`（'b'）
  - `assert_eq(ColorTable::get(t1, 99), ColorTable::get(t2, 99))`（'c'）
  - `assert_eq(ColorTable::get(t1, 255), ColorTable::get(t2, 255))`
  - `assert_eq(lnl1, false)`

**字节字面量注意**：MoonBit 中 `b"ab"` 是 Bytes 字面量。若 `Ast::str` 需要 Bytes 参数，用 `b"ab"`。若编译报错，改用 `#b"ab"` 或 `Bytes::from_string("ab")`。

完成后运行 `moon test` 确认 291/291（288+3）全绿，运行 `moon check` 确认无新 warning（baseline 26 warnings）。

## 预期产出
1. `re/color_map_test.mbt` 末尾追加 3 个 test 块（块 1/2/3 如上）
2. `do_v16.md` 测试补充报告，含：
   - 新增 test 块清单（块名 + 覆盖的 API/分支）
   - 每个 test 块覆盖的 API/分支说明
   - moon test 结果（预期 291/291）
   - moon check 结果（预期 26 warnings）
   - 与 coverage_gap_analysis.md P9 的对应关系

## 选择理由
T15（P8）已 PASSED（288/288 基线），coverage_gap_analysis.md §4 下一优先级为 P9（高风险 × 中难度 × 中价值：colorize 是 compile 前置步骤，颜色分配正确性影响匹配）。当前 color_map_test.mbt 4 个 test 块全部直接测试 ColorMap::make/split/flatten/translate_colors，`Ast::colorize` pub fn（mbti:87）完全未直接测试——colorize 内部对 Set(s) 调用 ColorMap::split(color_map, s)，对 BegOfLine/EndOfLine 调用 ColorMap::split(color_map, Cset::nl()) 等，是 compile_1（compile_translate.mbt:258-261）的核心前置步骤。P9 共 3 个 test 块，每块 8-15 行，难度中（需构造 Ast → handle_case → colorize 与手动 split 两条路径并对比 flatten 结果），风险高（颜色分配正确性影响 lazy DFA 匹配正确性），价值中（compile 前置步骤正确性）。符合 task.md 阶段二重点覆盖方向 (a) 核心模块边界条件 + (d) cset/automata/compile 内部操作（通过公开 API 间接测试）——此处通过 Ast::colorize + ColorMap::split + ColorMap::flatten 公开 API 组合测试颜色分配一致性。

## 任务上下文
- **目标 API**：`Ast::colorize`（ast.mbt:466-470，mbti:87 `pub fn AstGen::colorize(ColorMap, Self[Cset]) -> Bool`）+ `ColorMap::split`（color_map.mbt:31-33，mbti:174 `pub fn ColorMap::split(Self, Cset) -> Unit`）
- **colorize 实现**：`ast_colorize_rec`（ast.mbt:428-462）对 Set(s) 调用 `ColorMap::split(color_map, s)`，对 BegOfLine/EndOfLine 调用 `ColorMap::split(color_map, Cset::nl())`，对 BegOfWord/EndOfWord/NotBound 调用 `ColorMap::split(color_map, Cset::cword())`，对 BegOfStr/EndOfStr/Start/Stop 不 split，对 LastEndOfLine 设 lnl.val=true，返回 lnl.val
- **ColorMap::split 实现**：`self.csets.push(cset_or_compl(set))`，cset_or_compl（color_map.mbt:22-28）size > 128 取补集否则原样。Cset::single(97) size=1 ≤ 128，push 原样
- **Ast::handle_case**（ast.mbt:173-200）：将 Ast (AstGen[AstCset]) 转为 AstNoCase (AstGen[Cset])，对 Set(s) 调用 `Set(handle_case_cset(s, ign_case))`，handle_case_cset 对 CsetOf(c) 返回 c
- **Ast::char('a')** = `Set(CsetOf(Cset::single(97)))`（ast.mbt:489-491 经 ast_char_cache :484-486），handle_case(false) 得 `Set(Cset::single(97))`
- **Ast::str(b"ab")** = `Ast::seq([Ast::char('a'), Ast::char('b')])` = `Sequence([Set(CsetOf(single(97))), Set(CsetOf(single(98)))])`（ast.mbt:499-504，length=2 ≠ 1 故 Sequence）
- **Ast::alt([a, b])** = `AstNode(Alternative([Set(CsetOf(single(97))), Set(CsetOf(single(98)))]))`（ast.mbt:525-529）
- **compile_1 调用链**（compile_translate.mbt:257-261）：`regexp_nc = Ast::handle_case(regexp, false)` → `color_map = ColorMap::make()` → `need_lnl = Ast::colorize(color_map, regexp_nc)` → `ColorMap::flatten(color_map)`
- **color_map_test.mbt 现状**：4 个 test 块（:2 `ColorMap empty flatten`、:10 `ColorMap single char split`、:20 `ColorMap two chars split`、:32 `ColorMap translate_colors`），直接用 ColorMap::make/Cset::single，无辅助函数
- **相关 API 签名**（mbti）：`ColorMap::make() -> Self`（:173）、`ColorMap::split(Self, Cset) -> Unit`（:174）、`ColorMap::flatten(Self) -> (ColorTable, BoundaryTable, ColorRepr)`（:172）、`ColorTable::get(Self, Int) -> Int`（:185）、`ColorRepr::length(Self) -> Int`（:179）、`Cset::single(Int) -> Self`（:252）、`AstGen::char(Char) -> Self[AstCset]`（:86）、`AstGen::str(Bytes) -> Self[AstCset]`（:120）、`AstGen::alt(Array[Self[AstCset]]) -> Self[AstCset]`（:78）、`AstGen::handle_case(Self[AstCset], Bool) -> Self[Cset]`（:99）、`AstGen::colorize(ColorMap, Self[Cset]) -> Bool`（:87）
- **T15 后基线**：moon test 288/288 全绿，moon check 26 warnings
- **约束**：纯 MoonBit 无 C FFI，snake_case 命名，不修改 pkg.generated.mbti，不修改源码（仅追加测试），保持与 OCaml 上游行为一致性，保持 latin1 大小写处理，不运行 benchmark

## 已有产出上下文
- **阶段一性能优化**（T1-T7）：Section 1 951ms → 504.8ms（-46.9%，T3 ColorMap::flatten 哈希去重 + T5 cset 分治归并累计），T4/T6/T7 负改进回退，T5-skip mbti BLOCKED。代码状态 = T3 后（color_map.mbt）+ T5 后（cset.mbt）
- **阶段二测试覆盖率提升**（T8-T15）：
  - T8：coverage_gap_analysis.md（413 API，219 已覆盖，194 未覆盖，53.0%）
  - T9：P1-P2 match_str 四象限 + match_str_no_bounds 越界（7 块，258/258）
  - T10：P3 Perl/Emacs/Pcre 解析错误路径（7 块，265/265）
  - T11：P4 Pcre 高级 API raise 路径（3 块，268/268）
  - T12：P5 Str OCaml 风格 API 错误路径（4 块，272/272）
  - T13：P6 ParseBuffer::integer 错误路径（6 块，278/278，新增 parse_buffer_test.mbt）
  - T14：P7 Desc::initial/status/remove_duplicates（6 块，284/284，新增 desc_test.mbt）
  - T15：P8 Expr::rename 导数正确性（4 块，288/288，追加 automata_test.mbt）
- **当前测试文件**：basics_test/ast_test/automata_test/color_map_test/compile_test/core_test/coverage_test/frontend_test/view_test/desc_test/parse_buffer_test（11 个 _test.mbt）
- **本轮目标**：向 color_map_test.mbt 追加 3 块，覆盖 P9 Ast::colorize + ColorMap::split 一致性，291/291
