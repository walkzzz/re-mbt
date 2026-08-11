# re-mbt 覆盖率差距分析报告

> 基线：`moon test` 251/251 通过（0.21s），T5 后版本（HEAD e64ec54）
> 分析输入：`re/pkg.generated.mbti`（795 行，API 面）+ 9 个测试文件（251 个 test 块）
> 分析时间：2026-08-11
> 约束：仅分析，未修改任何源码或测试代码

## §0 总体概览

| 指标 | 数值 |
|------|------|
| pub API 总数 | 413 |
| 已覆盖 API 数 | 219 |
| 未覆盖/浅覆盖 API 数 | 194 |
| 总体覆盖率 | 53.0% |
| 测试块总数 | 251 |
| 测试文件数 | 9 |
| 0% 覆盖模块数 | 14 |

**覆盖层次分布**：
- **100% 覆盖模块**（13 个）：BitVector, CSetMap, ColorMap, CsetC, CsetView, ExecPartialResult, MarkInfos, MarkOffset, PmarkSet, Replace, Search, View, ViewRange
- **近满覆盖模块**（≥80%，4 个）：Category(93.3%), Re(90%), Cset(89.6%), Pmark(80%)
- **0% 覆盖模块**（14 个）：BoundaryTable, CompileIdx, CompileState, ET, Mark, Marks, ParseBuffer, Positions, PosixClass, PosixOpt, PcreFlag, PcreSplitResult, StateHashTable, StrSplitResult
- **极低覆盖模块**（< 10%，1 个）：Desc(5.6%, 仅 `Desc::status` 间接覆盖)
- **中等覆盖模块**（rest）：AstGen, Expr, Str, Pcre, PerlOpt, Sem, RepKind, Idx, HashSet 等

**关键发现**：
1. 内部数据结构（Desc/ET/Marks/Mark/Positions/StateHashTable/CompileIdx/CompileState）几乎无直接测试，仅通过 `delta`/`advance`/`compile` 间接覆盖。
2. `Str` 前端 API 覆盖率仅 20%，大量 OCaml 风格 API（`match_beginning`/`group_beginning`/`global_replace` 等）未测。
3. `Pcre` 高级 API（`exec`/`split`/`full_split`/`names`/`get_named_substring`/`quote`）未测。
4. `ParseBuffer` 作为各前端解析器的基础设施，10 个 pub API 全未直接测试。
5. 各前端解析器的错误路径（非法语法、未闭合括号、非法字符）无系统性测试。

---

## §1 API 清单总览（按模块分组）

| 模块 | 所在文件 | pub API 数 | 已覆盖 | 未覆盖 | 覆盖率% |
|------|---------|-----------|--------|--------|---------|
| **顶层函数** | compile.mbt / automata_state.mbt / core.mbt | 15 | 11 | 4 | 73.3% |
| **AstGen (Ast)** | ast.mbt | 47 | 28 | 19 | 59.6% |
| **BitVector** | bit_vector.mbt | 7 | 7 | 0 | 100% |
| **BoundaryTable** | color_map.mbt | 1 | 0 | 1 | 0% |
| **CSetMap** | color_map.mbt | 3 | 3 | 0 | 100% |
| **Category** | category.mbt | 15 | 14 | 1 | 93.3% |
| **ColorMap** | color_map.mbt | 3 | 3 | 0 | 100% |
| **ColorRepr** | color_map.mbt | 2 | 1 | 1 | 50% |
| **ColorTable** | color_map.mbt | 3 | 2 | 1 | 66.7% |
| **CompileIdx** | compile.mbt | 9 | 0 | 9 | 0% |
| **CompileState** | compile.mbt | 4 | 0 | 4 | 0% |
| **Cset** | cset.mbt | 48 | 43 | 5 | 89.6% |
| **CsetC** | cset.mbt | 6 | 6 | 0 | 100% |
| **CsetView** | view.mbt | 1 | 1 | 0 | 100% |
| **Desc** | automata_desc.mbt | 18 | 1 | 17 | 5.6% |
| **ET** | automata_desc.mbt | 4 | 0 | 4 | 0% |
| **Emacs** | emacs.mbt | 3 | 1 | 2 | 33.3% |
| **ExecPartialResult** | core.mbt | 3 | 3 | 0 | 100% |
| **Expr** | automata_expr.mbt | 16 | 5 | 11 | 31.3% |
| **Glob** | glob.mbt | 2 | 1 | 1 | 50% |
| **GroupT** | compile.mbt / group.mbt | 16 | 12 | 4 | 75.0% |
| **HashSet** | hash_set.mbt | 10 | 4 | 6 | 40% |
| **Ids** | automata.mbt | 2 | 1 | 1 | 50% |
| **Idx** | automata.mbt | 5 | 2 | 3 | 40% |
| **Mark** | automata.mbt | 8 | 0 | 8 | 0% |
| **MarkInfos** | mark_infos.mbt | 6 | 6 | 0 | 100% |
| **MarkOffset** | mark_infos.mbt | 2 | 2 | 0 | 100% |
| **Marks** | automata_desc.mbt | 7 | 0 | 7 | 0% |
| **ParseBuffer** | parse_buffer.mbt | 10 | 0 | 10 | 0% |
| **Pcre** | pcre.mbt | 13 | 3 | 10 | 23.1% |
| **PcreFlag** | pcre.mbt | 4 | 0 | 4 | 0% |
| **PcreSplitResult** | pcre.mbt | 4 | 0 | 4 | 0% |
| **Perl** | perl.mbt | 2 | 1 | 1 | 50% |
| **PerlOpt** | perl.mbt | 6 | 1 | 5 | 16.7% |
| **Pmark** | pmark.mbt | 5 | 4 | 1 | 80% |
| **PmarkSet** | pmark.mbt | 3+7 | 10 | 0 | 100% |
| **Positions** | compile.mbt | 7 | 0 | 7 | 0% |
| **Posix** | posix.mbt | 3 | 1 | 2 | 33.3% |
| **PosixClass** | posix_class.mbt | 3 | 0 | 3 | 0% |
| **PosixOpt** | posix.mbt | 3 | 0 | 3 | 0% |
| **Re** | core.mbt / compile.mbt | 20 | 18 | 2 | 90% |
| **RepKind** | automata.mbt | 5 | 1 | 4 | 20% |
| **Replace** | replace.mbt | 2 | 2 | 0 | 100% |
| **Search** | search.mbt | 5 | 5 | 0 | 100% |
| **Sem** | automata.mbt | 6 | 2 | 4 | 33.3% |
| **State** | automata_state.mbt | 8 | 5 | 3 | 62.5% |
| **StateHashTable** | compile.mbt | 3 | 0 | 3 | 0% |
| **Str** | str.mbt | 20 | 4 | 16 | 20% |
| **StrSplitResult** | str.mbt | 2 | 0 | 2 | 0% |
| **View** | view.mbt | 1 | 1 | 0 | 100% |
| **ViewRange** | view.mbt | 2 | 2 | 0 | 100% |
| **WorkingArea** | automata_state.mbt | 3 | 2 | 1 | 66.7% |
| **合计** | — | **413** | **219** | **194** | **53.0%** |

---

## §2 未覆盖/浅覆盖 API 明细表

### 2.1 顶层函数（4 个未覆盖）

| API 签名 | 文件:行号 | 模块 | 覆盖状态 | 风险 | 建议测试方向 |
|---------|----------|------|---------|------|------------|
| `copy_re(Re) -> Re` | compile.mbt:781 | core | 未覆盖 | 中 | 边界条件（深拷贝后独立执行） |
| `match_str(groups~, partial~, Re, Bytes, pos~, len~) -> MatchInfo raise` | compile.mbt:727 | core | 未覆盖 | 高 | 正向+错误路径（groups=true/false × partial=true/false 四象限） |
| `match_str_no_bounds(...) -> MatchInfo` | compile.mbt:692 | core | 未覆盖 | 高 | 边界条件（越界 pos/len 不 raise）+ 正向 |
| `mk_re(initial~, colors~, color_repr~, ncolor~, lnl~, group_names~, group_count~) -> Re` | compile.mbt:757 | core | 未覆盖 | 低 | 内部操作间接测试（构造后 exec） |

### 2.2 AstGen (Ast)（19 个未覆盖）

| API 签名 | 文件:行号 | 模块 | 覆盖状态 | 风险 | 建议测试方向 |
|---------|----------|------|---------|------|------------|
| `Ast::anchored_ast(AstAlt[Ast]) -> Bool` | ast.mbt:207 | ast | 未覆盖 | 中 | 边界条件（Alternative/Case/NoCase 各分支） |
| `Ast::bow() -> Ast` | ast.mbt:588 | ast | 未覆盖 | 中 | 边缘 case（词首边界构造+匹配） |
| `Ast::eow() -> Ast` | ast.mbt:593 | ast | 未覆盖 | 中 | 边缘 case（词尾边界构造+匹配） |
| `Ast::colorize(ColorMap, AstNoCase) -> Bool` | ast.mbt:466 | ast | 未覆盖 | 高 | 内部操作间接测试（colorize 后 split 一致性） |
| `Ast::compl(Array[Ast]) -> Ast raise` | ast.mbt:710 | ast | 未覆盖 | 中 | 正向+错误路径（补集构造+匹配） |
| `Ast::cset(Cset) -> Ast` | ast.mbt:135 | ast | 未覆盖 | 低 | 边界条件（空集/单元素/全集） |
| `Ast::diff(Ast, Ast) -> Ast raise` | ast.mbt:715 | ast | 未覆盖 | 中 | 正向+错误路径（差集构造+匹配） |
| `Ast::first(Ast) -> Ast` | ast.mbt:656 | ast | 未覆盖 | 中 | 边缘 case（First 语义匹配优先级） |
| `Ast::greedy(Ast) -> Ast` | ast.mbt:661 | ast | 未覆盖 | 中 | 边缘 case（贪婪语义包装） |
| `Ast::inter(Array[Ast]) -> Ast raise` | ast.mbt:705 | ast | 未覆盖 | 中 | 正向+错误路径（交集构造+匹配） |
| `Ast::leol() -> Ast` | ast.mbt:623 | ast | 未覆盖 | 中 | 边缘 case（行末边界构造+匹配） |
| `Ast::merge_sequences(Array[Ast]) -> Array[Ast]` | ast.mbt:327 | ast | 未覆盖 | 中 | 内部操作间接测试（合并相邻 seq） |
| `Ast::merge_sequences_no_case(Array[AstNoCase]) -> Array[AstNoCase]` | ast.mbt:423 | ast | 未覆盖 | 低 | 内部操作间接测试 |
| `Ast::non_greedy(Ast) -> Ast` | ast.mbt:666 | ast | 未覆盖 | 中 | 边缘 case（非贪婪语义包装） |
| `Ast::not_boundary() -> Ast` | ast.mbt:603 | ast | 未覆盖 | 中 | 边缘 case（非边界构造+匹配） |
| `Ast::set(Bytes) -> Ast` | ast.mbt:686 | ast | 未覆盖 | 低 | 边界条件（空 Bytes/单字符/多字符） |
| `Ast::shortest(Ast) -> Ast` | ast.mbt:651 | ast | 未覆盖 | 中 | 边缘 case（Shortest 语义匹配） |
| `Ast::t_of_cset(AstCset) -> Ast` | ast.mbt:140 | ast | 未覆盖 | 低 | 内部操作间接测试 |
| `Ast::to_dyn(Ast) -> Dyn` | ast.mbt:128 | ast | 未覆盖 | 低 | 正向（Dyn 结构断言） |

### 2.3 Expr（11 个未覆盖）

| API 签名 | 文件:行号 | 模块 | 覆盖状态 | 风险 | 建议测试方向 |
|---------|----------|------|---------|------|------------|
| `Expr::after(Ids, Category) -> Expr` | automata_expr.mbt:84 | automata_expr | 未覆盖 | 中 | 边界条件（After 节点构造） |
| `Expr::before(Ids, Category) -> Expr` | automata_expr.mbt:79 | automata_expr | 未覆盖 | 中 | 边界条件（Before 节点构造） |
| `Expr::empty(Ids) -> Expr` | automata_expr.mbt:40 | automata_expr | 未覆盖 | 中 | 边界条件（空 Expr 构造） |
| `Expr::eps_expr() -> Expr` | automata_expr.mbt:35 | automata_expr | 未覆盖 | 低 | 边界条件（无 ids 的 eps） |
| `Expr::erase(Ids, Int, Int) -> Expr` | automata_expr.mbt:74 | automata_expr | 未覆盖 | 中 | 内部操作间接测试 |
| `Expr::id(Expr) -> Int` | automata_expr.mbt:19 | automata_expr | 未覆盖 | 低 | 正向（id 提取） |
| `Expr::is_eps(Expr) -> Bool` | automata_expr.mbt:131 | automata_expr | 未覆盖 | 中 | 边界条件（eps/非 eps 判定） |
| `Expr::mark(Ids, Int) -> Expr` | automata_expr.mbt:64 | automata_expr | 未覆盖 | 中 | 内部操作间接测试 |
| `Expr::pmark(Ids, Pmark) -> Expr` | automata_expr.mbt:69 | automata_expr | 未覆盖 | 中 | 内部操作间接测试 |
| `Expr::rename(Ids, Expr) -> Expr` | automata_expr.mbt:158 | automata_expr | 未覆盖 | 高 | 内部操作间接测试（导数正确性关键） |
| `Expr::to_dyn(Expr) -> Dyn` | automata_expr.mbt:178 | automata_expr | 未覆盖 | 低 | 正向（Dyn 结构断言） |
| `Expr::alt/rep/seq/cst/eps` | automata_expr.mbt | automata_expr | 已覆盖 | — | automata_test 覆盖 |

### 2.4 Desc / ET / Marks（28 个未覆盖）

| API 签名 | 文件:行号 | 模块 | 覆盖状态 | 风险 | 建议测试方向 |
|---------|----------|------|---------|------|------------|
| `Desc::add_eps(Array[ET], Marks) -> Array[ET]` | automata_desc.mbt:183 | automata_desc | 未覆盖 | 中 | 内部操作间接测试 |
| `Desc::add_expr(Array[ET], ET) -> Array[ET]` | automata_desc.mbt:188 | automata_desc | 未覆盖 | 中 | 内部操作间接测试 |
| `Desc::add_match(Array[ET], Marks) -> Array[ET]` | automata_desc.mbt:178 | automata_desc | 未覆盖 | 中 | 内部操作间接测试 |
| `Desc::equal(Array[ET], Array[ET]) -> Bool` | automata_desc.mbt:358 | automata_desc | 未覆盖 | 中 | 正向+边界（自等/空/不等） |
| `Desc::first_match(Array[ET]) -> Marks?` | automata_desc.mbt:193 | automata_desc | 未覆盖 | 中 | 边界条件（空/有 match/无 match） |
| `Desc::fold_right(Array[ET], init~, f~) -> T` | automata_desc.mbt | automata_desc | 未覆盖 | 低 | 正向（折叠结果） |
| `Desc::hash(Array[ET], Int) -> Int` | automata_desc.mbt:363 | automata_desc | 未覆盖 | 低 | 正向（一致性） |
| `Desc::initial(Expr) -> Array[ET]` | automata_desc.mbt:144 | automata_desc | 未覆盖 | 高 | 内部操作间接测试（导数初始态） |
| `Desc::iter_marks(Array[ET], (Marks) -> Unit) -> Unit` | automata_desc.mbt:292 | automata_desc | 未覆盖 | 低 | 正向（遍历计数） |
| `Desc::remove_duplicates(HashSet, Array[ET], Expr) -> Array[ET]` | automata_desc.mbt:403 | automata_desc | 未覆盖 | 高 | 内部操作间接测试（去重正确性） |
| `Desc::remove_matches(Array[ET]) -> Array[ET]` | automata_desc.mbt:204 | automata_desc | 未覆盖 | 中 | 内部操作间接测试 |
| `Desc::set_idx(Int, Array[ET]) -> Array[ET]` | automata_desc.mbt:277 | automata_desc | 未覆盖 | 中 | 内部操作间接测试 |
| `Desc::split_at_match(Array[ET]) -> (Array[ET], Array[ET])` | automata_desc.mbt:216 | automata_desc | 未覆盖 | 中 | 边界条件（空/有 match/无 match） |
| `Desc::status(Array[ET]) -> Status` | automata_desc.mbt:244 | automata_desc | 仅间接 | 中 | 边界条件（Failed/Match/Running 三分支） |
| `Desc::status_is_ambiguous(Array[ET], Pmark) -> Bool` | automata_desc.mbt:256 | automata_desc | 未覆盖 | 中 | 边界条件（有/无歧义 mark） |
| `Desc::texp(Marks, Expr, Array[ET]) -> Array[ET]` | automata_desc.mbt:173 | automata_desc | 未覆盖 | 中 | 内部操作间接测试 |
| `Desc::tseq(Sem, Array[ET], Expr, Array[ET]) -> Array[ET]` | automata_desc.mbt:149 | automata_desc | 未覆盖 | 中 | 内部操作间接测试 |
| `ET::equal(ET, ET) -> Bool` | automata_desc.mbt:305 | automata_desc | 未覆盖 | 中 | 正向+边界 |
| `ET::equal_list(Array[ET], Array[ET]) -> Bool` | automata_desc.mbt:317 | automata_desc | 未覆盖 | 中 | 正向+边界 |
| `ET::hash(ET, Int) -> Int` | automata_desc.mbt:330 | automata_desc | 未覆盖 | 低 | 正向（一致性） |
| `ET::hash_list(Array[ET], Int) -> Int` | automata_desc.mbt:347 | automata_desc | 未覆盖 | 低 | 正向（一致性） |
| `Marks::empty() -> Marks` | automata_desc.mbt:13 | automata_desc | 未覆盖 | 低 | 边界条件 |
| `Marks::equal(Marks, Marks) -> Bool` | automata_desc.mbt:18 | automata_desc | 未覆盖 | 中 | 正向+边界 |
| `Marks::filter(Marks, Int, Int) -> Marks` | automata_desc.mbt:72 | automata_desc | 未覆盖 | 中 | 边界条件（空/全保留/全过滤） |
| `Marks::hash(Marks, Int) -> Int` | automata_desc.mbt:40 | automata_desc | 未覆盖 | 低 | 正向（一致性） |
| `Marks::marks_set_idx(Marks, Int) -> Marks` | automata_desc.mbt:67 | automata_desc | 未覆盖 | 中 | 内部操作间接测试 |
| `Marks::set_mark(Marks, Int) -> Marks` | automata_desc.mbt:84 | automata_desc | 未覆盖 | 中 | 内部操作间接测试 |
| `Marks::set_pmark(Marks, Pmark) -> Marks` | automata_desc.mbt:96 | automata_desc | 未覆盖 | 中 | 内部操作间接测试 |

### 2.5 CompileIdx / CompileState / StateHashTable / Positions（23 个未覆盖）

| API 签名 | 文件:行号 | 模块 | 覆盖状态 | 风险 | 建议测试方向 |
|---------|----------|------|---------|------|------------|
| `CompileIdx::break_idx(Int) -> Int` | compile.mbt:51 | compile | 未覆盖 | 中 | 内部操作间接测试 |
| `CompileIdx::break_value() -> Int` | compile.mbt:16 | compile | 未覆盖 | 低 | 正向（常量值） |
| `CompileIdx::idx(Int) -> Int` | compile.mbt:41 | compile | 未覆盖 | 中 | 内部操作间接测试 |
| `CompileIdx::is_break(Int) -> Bool` | compile.mbt:31 | compile | 未覆盖 | 中 | 边界条件（break/idx/unknown 三态） |
| `CompileIdx::is_idx(Int) -> Bool` | compile.mbt:26 | compile | 未覆盖 | 中 | 边界条件 |
| `CompileIdx::is_unknown(Int) -> Bool` | compile.mbt:36 | compile | 未覆盖 | 中 | 边界条件 |
| `CompileIdx::make_break(Int) -> Int` | compile.mbt:46 | compile | 未覆盖 | 中 | 内部操作间接测试 |
| `CompileIdx::of_idx(Int) -> Int` | compile.mbt:21 | compile | 未覆盖 | 中 | 内部操作间接测试 |
| `CompileIdx::unknown() -> Int` | compile.mbt:11 | compile | 未覆盖 | 低 | 正向（常量值） |
| `CompileState::follow_transition(Self, Int) -> Self` | compile.mbt:78 | compile | 未覆盖 | 中 | 内部操作间接测试 |
| `CompileState::get_info(Self) -> StateInfo` | compile.mbt:73 | compile | 未覆盖 | 低 | 内部操作间接测试 |
| `CompileState::is_unknown_transition(Self, Int) -> Bool` | compile.mbt:95 | compile | 未覆盖 | 中 | 内部操作间接测试 |
| `CompileState::set_transition(Self, Int, Self) -> Unit` | compile.mbt:86 | compile | 未覆盖 | 中 | 内部操作间接测试 |
| `StateHashTable::add(Self, State, CompileState) -> Unit` | compile.mbt:135 | compile | 未覆盖 | 中 | 内部操作间接测试 |
| `StateHashTable::create(Int) -> Self` | compile.mbt:112 | compile | 未覆盖 | 低 | 边界条件（capacity=0/1/大） |
| `StateHashTable::find(Self, State) -> CompileState?` | compile.mbt:122 | compile | 未覆盖 | 中 | 边界条件（空表/命中/未命中） |
| `Positions::all(Self) -> Array[Int]` | compile.mbt:218 | compile | 未覆盖 | 低 | 正向 |
| `Positions::empty() -> Self` | compile.mbt:181 | compile | 未覆盖 | 低 | 边界条件 |
| `Positions::first(Self) -> Int` | compile.mbt:223 | compile | 未覆盖 | 低 | 正向 |
| `Positions::length(Self) -> Int` | compile.mbt:186 | compile | 未覆盖 | 低 | 正向 |
| `Positions::make(groups~, Re) -> Self` | compile.mbt:228 | compile | 未覆盖 | 中 | 边界条件（groups=true/false） |
| `Positions::set(Self, Int, Int) -> Unit` | compile.mbt:210 | compile | 未覆盖 | 中 | 边界条件（越界 idx） |
| `Positions::unsafe_set(Self, Int, Int) -> Unit` | compile.mbt:191 | compile | 未覆盖 | 低 | 内部操作间接测试 |

### 2.6 Mark / ParseBuffer（18 个未覆盖）

| API 签名 | 文件:行号 | 模块 | 覆盖状态 | 风险 | 建议测试方向 |
|---------|----------|------|---------|------|------------|
| `Mark::compare(Int, Int) -> Int` | automata.mbt:138 | automata | 未覆盖 | 低 | 正向+边界 |
| `Mark::group_count(Int) -> Int` | automata.mbt:119 | automata | 未覆盖 | 中 | 正向（group 计数提取） |
| `Mark::next(Int) -> Int` | automata.mbt:109 | automata | 未覆盖 | 低 | 正向（后继 mark） |
| `Mark::next2(Int) -> Int` | automata.mbt:114 | automata | 未覆盖 | 低 | 正向（双重后继） |
| `Mark::outside_range(Int, start_inclusive~, stop_inclusive~) -> Bool` | automata.mbt:124 | automata | 未覆盖 | 中 | 边界条件（前/内/后/边界） |
| `Mark::prev(Int) -> Int` | automata.mbt:104 | automata | 未覆盖 | 低 | 正向（前驱 mark） |
| `Mark::start() -> Int` | automata.mbt:99 | automata | 未覆盖 | 低 | 正向（起始 mark 值） |
| `Mark::to_dyn(Int) -> Dyn` | automata.mbt:133 | automata | 未覆盖 | 低 | 正向 |
| `ParseBuffer::accept(Self, Char) -> Bool` | parse_buffer.mbt:44 | parse_buffer | 未覆盖 | 中 | 正向+错误路径（匹配/不匹配/eos） |
| `ParseBuffer::accept_s(Self, Bytes) -> Bool` | parse_buffer.mbt:60 | parse_buffer | 未覆盖 | 中 | 正向+错误路径 |
| `ParseBuffer::create(Bytes) -> Self` | parse_buffer.mbt:12 | parse_buffer | 未覆盖 | 低 | 边界条件（空 Bytes） |
| `ParseBuffer::eos(Self) -> Bool` | parse_buffer.mbt:27 | parse_buffer | 未覆盖 | 低 | 边界条件（空/非空/末尾） |
| `ParseBuffer::get(Self) -> Char` | parse_buffer.mbt:53 | parse_buffer | 未覆盖 | 中 | 错误路径（eos 时 get） |
| `ParseBuffer::integer(Self) -> Int? raise` | parse_buffer.mbt:97 | parse_buffer | 未覆盖 | 高 | 错误路径（非数字/空/溢出） |
| `ParseBuffer::junk(Self) -> Unit` | parse_buffer.mbt:22 | parse_buffer | 未覆盖 | 低 | 正向（跳过空白） |
| `ParseBuffer::peek(Self, Char) -> Bool` | parse_buffer.mbt:32 | parse_buffer | 未覆盖 | 低 | 正向+边界（eos 时 peek） |
| `ParseBuffer::peek2(Self, Char, Char) -> Bool` | parse_buffer.mbt:37 | parse_buffer | 未覆盖 | 低 | 正向+边界（长度<2） |
| `ParseBuffer::unget(Self) -> Unit` | parse_buffer.mbt:17 | parse_buffer | 未覆盖 | 低 | 边界条件（pos=0 时 unget） |

### 2.7 Str 前端（16 个未覆盖）

| API 签名 | 文件:行号 | 模块 | 覆盖状态 | 风险 | 建议测试方向 |
|---------|----------|------|---------|------|------------|
| `Str::bounded_split(StrRegexp, Bytes, Int) -> Array[Bytes] raise` | str.mbt:225 | str | 未覆盖 | 中 | 边界条件（limit=0/1/大） |
| `Str::compile_regexp(Bytes, Bool) -> StrRegexp raise` | str.mbt:16 | str | 未覆盖 | 低 | 正向+错误路径（非法模式） |
| `Str::full_split(StrRegexp, Bytes) -> Array[StrSplitResult] raise` | str.mbt:270 | str | 未覆盖 | 中 | 正向（含 delim 分隔符） |
| `Str::global_replace(StrRegexp, Bytes, Bytes) -> Bytes raise` | str.mbt:149 | str | 未覆盖 | 中 | 正向+边界（无匹配/全匹配） |
| `Str::group_beginning(Int) -> Int raise` | str.mbt:107 | str | 未覆盖 | 高 | 错误路径（未先 match / 越界 group） |
| `Str::group_end(Int) -> Int raise` | str.mbt:115 | str | 未覆盖 | 高 | 错误路径（未先 match / 越界 group） |
| `Str::match_beginning() -> Int raise` | str.mbt:83 | str | 未覆盖 | 高 | 错误路径（未先 match） |
| `Str::match_end() -> Int raise` | str.mbt:91 | str | 未覆盖 | 高 | 错误路径（未先 match） |
| `Str::matched_group(Int, Bytes) -> Bytes raise` | str.mbt:123 | str | 未覆盖 | 高 | 错误路径（未先 match / 越界 group） |
| `Str::matched_string(Bytes) -> Bytes raise` | str.mbt:99 | str | 未覆盖 | 高 | 错误路径（未先 match） |
| `Str::quote(Bytes) -> Bytes` | str.mbt:32 | str | 未覆盖 | 中 | 正向+边界（空/特殊字符） |
| `Str::regexp_case_fold(Bytes) -> StrRegexp raise` | str.mbt:27 | str | 未覆盖 | 中 | 正向（大小写不敏感匹配） |
| `Str::regexp_string(Bytes) -> StrRegexp raise` | str.mbt:53 | str | 未覆盖 | 低 | 正向（字面量匹配） |
| `Str::replace_first(StrRegexp, Bytes, Bytes) -> Bytes raise` | str.mbt:192 | str | 未覆盖 | 中 | 正向+边界（无匹配） |
| `Str::string_after(Bytes, Int) -> Bytes` | str.mbt:140 | str | 未覆盖 | 低 | 边界条件（pos=0/末尾/越界） |
| `Str::string_before(Bytes, Int) -> Bytes` | str.mbt:131 | str | 未覆盖 | 低 | 边界条件（pos=0/末尾/越界） |

### 2.8 Pcre 前端（10 个未覆盖）

| API 签名 | 文件:行号 | 模块 | 覆盖状态 | 风险 | 建议测试方向 |
|---------|----------|------|---------|------|------------|
| `Pcre::exec(Re, Bytes, pos?) -> GroupT raise` | pcre.mbt:53 | pcre | 未覆盖 | 高 | 正向+错误路径（无匹配时 raise） |
| `Pcre::full_split(Re, Bytes, max?) -> Array[PcreSplitResult] raise` | pcre.mbt:133 | pcre | 未覆盖 | 中 | 正向+边界（max=0/1/大） |
| `Pcre::get_named_substring(Re, String, GroupT) -> Bytes raise` | pcre.mbt:172 | pcre | 未覆盖 | 高 | 错误路径（无名 group / 未匹配） |
| `Pcre::get_named_substring_opt(Re, String, GroupT) -> Bytes?` | pcre.mbt:67 | pcre | 未覆盖 | 中 | 边界条件（有名/无名/未匹配） |
| `Pcre::get_substring(GroupT, Int) -> Bytes` | pcre.mbt:167 | pcre | 未覆盖 | 中 | 边界条件（越界 idx） |
| `Pcre::get_substring_ofs(GroupT, Int) -> (Int, Int) raise` | pcre.mbt:87 | pcre | 未覆盖 | 中 | 错误路径（越界 idx） |
| `Pcre::names(Re) -> Array[String]` | pcre.mbt:58 | pcre | 未覆盖 | 中 | 正向+边界（无名/多组） |
| `Pcre::quote(Bytes) -> Bytes` | pcre.mbt:97 | pcre | 未覆盖 | 中 | 正向+边界（空/特殊字符） |
| `Pcre::re(Bytes, flags?) -> Ast raise` | pcre.mbt:37 | pcre | 未覆盖 | 低 | 正向+错误路径（非法模式） |
| `Pcre::split(Re, Bytes) -> Array[Bytes] raise` | pcre.mbt:121 | pcre | 未覆盖 | 中 | 正向+边界（无分隔/全分隔） |

### 2.9 其他模块未覆盖 API（汇总）

| 模块 | 未覆盖 API | 文件:行号 | 风险 | 建议测试方向 |
|------|-----------|----------|------|------------|
| BoundaryTable | `unsafe_next_boundary(Self, Int) -> Int` | color_map.mbt:67 | 低 | 内部操作间接测试 |
| ColorRepr | `repr(Self, Int) -> Byte` | color_map.mbt:124 | 中 | 正向（颜色 repr 查询） |
| ColorTable | `get_char(Self, Int) -> Byte` | color_map.mbt:80 | 中 | 正向（字符颜色查询） |
| Cset | `calnum()`, `calpha()`, `clower()`, `cword()`, `to_dyn()` | cset.mbt:557,562,532,576,668 | 低-中 | 正向（大小写不敏感预定义集 + Dyn） |
| Emacs | `re(Bytes, case?) -> Ast raise`, `re_no_emacs(Bytes, case~) -> Ast raise` | emacs.mbt:183,197 | 中 | 正向+错误路径（非 emacs 语法） |
| Glob | `glob(Bytes, ...) -> Ast raise` | glob.mbt:487 | 低 | 正向（glob 模式构造） |
| GroupT | `create(...)`, `offset(Self, Int) raise`, `start_offset`, `stop_offset` | compile.mbt:618, group.mbt:22,72,82 | 中 | 边界条件+错误路径 |
| HashSet | `absent()`, `add_no_resize()`, `clear()`, `index_of_offset()`, `resize()`, `should_grow()` | hash_set.mbt:12,47,37,32,63,27 | 中 | 内部操作间接测试 + 边界 |
| Ids | `next(Self) -> Int` | automata.mbt:185 | 低 | 正向（计数器递增） |
| Idx | `to_dyn()`, `to_int()`, `used()` | automata.mbt:168,163,158 | 低 | 正向 |
| Perl | `re(Bytes, opts?) -> Ast raise` | perl.mbt:577 | 低 | 正向+错误路径 |
| PerlOpt | `anchored()`, `dollar_endonly()`, `dotall()`, `multiline()`, `ungreedy()` | perl.mbt | 中 | 边缘 case（各 opt 对匹配行为影响） |
| Pmark | `to_dyn(Self) -> Dyn` | pmark.mbt:37 | 低 | 正向 |
| Posix | `compile_pat(Bytes, opts?) -> Re raise`, `re(Bytes, opts?) -> Ast raise` | posix.mbt:270,249 | 中 | 正向+错误路径 |
| PosixClass | `names()`, `of_name(String) raise`, `parse(ParseBuffer) raise` | posix_class.mbt:28,7,59 | 中 | 正向+错误路径（未知类名） |
| Re | `group_count(Self) -> Int`, `group_names(Self) -> Array[(String, Int)]` | compile.mbt:163,168 | 中 | 正向（命名 group 提取） |
| RepKind | `non_greedy()`, `to_dyn()`, `to_string()`, `to_string_short()` | automata.mbt:55,27,69,86 | 低 | 正向 |
| Sem | `shortest()`, `to_dyn()`, `to_string()`, `to_string_short()` | automata.mbt:40,18,60,77 | 低 | 正向 |
| State | `mk(Int, Category, Array[ET])`, `status_no_mutex()`, `to_dyn()` | automata_state.mbt:30,70,87 | 中 | 内部操作间接测试 |
| WorkingArea | `index_count(Self) -> Int` | automata_state.mbt:106 | 低 | 正向 |
| Category | `to_dyn(Self) -> Dyn` | category.mbt:100 | 低 | 正向 |
| PcreFlag | `Caseless`, `MultilineP`, `AnchoredP`, `DotallP` | pcre.mbt | 中 | 边缘 case（各 flag 对匹配影响） |
| PcreSplitResult | `PcreText`, `PcreDelim`, `PcreGroup`, `PcreNoGroup` | pcre.mbt | 中 | 正向（full_split 结果匹配） |
| PosixOpt | `ICase`, `NoSub`, `Newline` | posix.mbt | 中 | 边缘 case |
| StrSplitResult | `StrText`, `StrDelim` | str.mbt | 低 | 正向（full_split 结果匹配） |

---

## §3 分支覆盖缺口

### 3.1 compile 失败路径

| 分支 | 所在文件:行号 | 覆盖状态 | 风险 | 说明 |
|------|-------------|---------|------|------|
| 无效 AST 编译 | compile.mbt | 未覆盖 | 高 | 构造非法 AstGen 结构后 compile 行为未测 |
| 空模式编译 | compile.mbt | 未覆盖 | 中 | `compile(Ast::empty())` 行为未测 |
| 嵌套深度超限 | compile.mbt | 未覆盖 | 低 | 深度嵌套 AST 编译路径未测 |
| `match_str` groups=false 路径 | compile.mbt:727 | 未覆盖 | 高 | groups 参数 false 分支未测 |
| `match_str` partial=true 路径 | compile.mbt:727 | 未覆盖 | 高 | partial 参数 true 分支未测 |
| `match_str_no_bounds` 越界 pos | compile.mbt:692 | 未覆盖 | 高 | 越界 pos/len 不 raise 的路径未测 |
| `copy_re` 深拷贝独立性 | compile.mbt:781 | 未覆盖 | 中 | 拷贝后修改原 Re 不影响拷贝未验证 |

### 3.2 parse 错误路径（各前端解析器）

| 分支 | 所在文件 | 覆盖状态 | 风险 | 说明 |
|------|---------|---------|------|------|
| Perl 非法语法 | perl.mbt | 未覆盖 | 高 | `(`未闭合、`*`无前置、`{`无闭合、非法转义等 |
| Perl 非法字符类 | perl.mbt | 未覆盖 | 中 | `[]`空类、`[z-a]`逆序范围 |
| Emacs 非法语法 | emacs.mbt | 未覆盖 | 高 | `\(`未闭合、非法转义 |
| Posix 非法语法 | posix.mbt | 未覆盖 | 中 | BRE 语法错误 |
| Glob 非法语法 | glob.mbt | 未覆盖 | 中 | 非法转义、`**`路径语义 |
| Pcre 非法语法 | pcre.mbt | 未覆盖 | 高 | 非法 flag 组合、未闭合 group |
| Pcre 未知 flag | pcre.mbt | 未覆盖 | 低 | flags 参数各组合未测 |
| Str 非法模式 | str.mbt | 未覆盖 | 中 | `compile_regexp` 错误路径未测 |
| PosixClass 未知类名 | posix_class.mbt:7 | 未覆盖 | 中 | `of_name("unknown")` raise 路径未测 |
| PosixClass parse 失败 | posix_class.mbt:59 | 未覆盖 | 中 | `parse` 返回 None 路径未测 |
| ParseBuffer::integer 非数字 | parse_buffer.mbt:97 | 未覆盖 | 高 | 非数字字符时 raise 路径未测 |
| ParseBuffer::get at eos | parse_buffer.mbt:53 | 未覆盖 | 中 | eos 时 get 行为未测 |

### 3.3 cset 边界

| 分支 | 所在文件:行号 | 覆盖状态 | 风险 | 说明 |
|------|-------------|---------|------|------|
| 空集操作 | cset.mbt | 仅正向 | 中 | `union(empty, empty)`、`inter(empty, x)`、`diff(x, empty)` 结果正确性仅部分测 |
| 全集操作 | cset.mbt | 未覆盖 | 中 | `cany` 与各操作的组合未测 |
| 单元素边界 | cset.mbt | 仅正向 | 中 | `single(0)`、`single(255)` 边界值仅部分测 |
| 互补操作 | cset.mbt | 未覆盖 | 中 | `diff(cany, x)` 应等价于补集，未验证 |
| 256 字符全遍历 | cset.mbt | 未覆盖 | 低 | 0..255 全遍历 mem 测试缺失 |
| `union_singles` 非递减顺序 | cset.mbt:384 | 未覆盖 | 中 | 函数名要求 strictly decreasing，传入非递减顺序行为未测 |
| `pick` 空集 raise | cset.mbt:376 | 已覆盖 | — | coverage_test 已测 |
| `case_insens` 非 ASCII | cset.mbt:567 | 未覆盖 | 中 | latin1 范围 128-255 的大小写处理未测 |
| `calnum/calpha/clower/cword` | cset.mbt:557,562,532,576 | 未覆盖 | 中 | 大小写不敏感预定义集未测 |

### 3.4 automata 空状态/重复状态/死状态

| 分支 | 所在文件:行号 | 覆盖状态 | 风险 | 说明 |
|------|-------------|---------|------|------|
| Desc::status Failed 分支 | automata_desc.mbt:244 | 仅间接 | 中 | 通过 delta 间接覆盖，无直接断言 |
| Desc::status Match 分支 | automata_desc.mbt:244 | 仅间接 | 中 | 通过 advance 间接覆盖 |
| Desc::status Running 分支 | automata_desc.mbt:244 | 仅间接 | 中 | 通过 delta 间接覆盖 |
| Desc::status_is_ambiguous | automata_desc.mbt:256 | 未覆盖 | 中 | 死状态/歧义 mark 检测未测 |
| Desc::remove_duplicates 去重 | automata_desc.mbt:403 | 未覆盖 | 高 | 重复 ET 去重正确性未直接测 |
| Desc::split_at_match 边界 | automata_desc.mbt:216 | 未覆盖 | 中 | 空 desc / 无 match / 多 match 未测 |
| Desc::first_match None 分支 | automata_desc.mbt:193 | 未覆盖 | 中 | 无 match 时返回 None 未测 |
| ET::equal_list 不等长 | automata_desc.mbt:317 | 未覆盖 | 低 | 不等长列表比较未测 |
| State::mk 构造 | automata_state.mbt:30 | 未覆盖 | 中 | 直接 mk 构造状态未测 |
| State::status_no_mutex | automata_state.mbt:70 | 未覆盖 | 中 | 无锁状态查询未测 |
| WorkingArea::index_count | automata_state.mbt:106 | 未覆盖 | 低 | 索引计数查询未测 |
| StateHashTable 命中/未命中 | compile.mbt:122 | 未覆盖 | 中 | find 命中/未命中分支未测 |
| StateHashTable 容量增长 | compile.mbt:135 | 未覆盖 | 中 | add 触发 resize 的分支未测 |

### 3.5 core API None/异常返回路径

| 分支 | 所在文件:行号 | 覆盖状态 | 风险 | 说明 |
|------|-------------|---------|------|------|
| `exec` 无匹配 raise | compile.mbt | 已覆盖 | — | coverage_test 已测 |
| `exec_opt` 无匹配 None | compile.mbt | 已覆盖 | — | core_test 已测 |
| `GroupT::offset` 越界 raise | group.mbt:22 | 未覆盖 | 中 | 越界 idx raise 路径未测 |
| `GroupT::start` 越界 raise | group.mbt:38 | 未覆盖 | 中 | 越界 idx raise 路径未测 |
| `GroupT::stop` 越界 raise | group.mbt:54 | 未覆盖 | 中 | 越界 idx raise 路径未测 |
| `GroupT::get` 未匹配返回 None | compile.mbt:629 | 仅正向 | 中 | 未匹配 group 的 get 返回 None 未测 |
| `Re::group_count` 正向 | compile.mbt:163 | 未覆盖 | 中 | 命名 group 计数提取未测 |
| `Re::group_names` 正向 | compile.mbt:168 | 未覆盖 | 中 | 命名 group 名称列表未测 |
| `Pcre::exec` 无匹配 raise | pcre.mbt:53 | 未覆盖 | 高 | raise 路径未测 |
| `Pcre::get_named_substring` 错误 | pcre.mbt:172 | 未覆盖 | 高 | 未知名/未匹配 raise 未测 |
| `Str::match_beginning` 未先 match | str.mbt:83 | 未覆盖 | 高 | 未先调用 string_match 时 raise 未测 |
| `Str::group_beginning` 越界 | str.mbt:107 | 未覆盖 | 高 | 越界 group idx raise 未测 |

---

## §4 建议补充测试优先级排序

按 **风险等级 × 覆盖难度 × 业务价值** 综合排序，给出前 15 个最该补的测试目标。

| 优先级 | 目标 API/分支 | 建议测试文件 | 建议 test 块数 | 优先级理由 |
|--------|-------------|------------|-------------|-----------|
| **P1** | `match_str` 四象限（groups × partial） | coverage_test.mbt 追加 | 4 | 高风险 × 低难度 × 高价值：core API 唯一入口，4 个参数组合全未测，影响 MatchInfo 返回路径 |
| **P2** | `match_str_no_bounds` 越界 pos/len | coverage_test.mbt 追加 | 3 | 高风险 × 低难度 × 高价值：不 raise 的越界行为是核心契约，与 match_str 形成对比 |
| **P3** | Perl/Emacs/Pcre 解析错误路径（未闭合括号、非法转义、非法字符类） | frontend_test.mbt 追加 | 6-8 | 高风险 × 中难度 × 高价值：各前端解析器错误路径全缺，用户输入非法模式时行为未验证 |
| **P4** | `Pcre::exec` / `Pcre::get_named_substring` raise 路径 | coverage_test.mbt 追加 | 3 | 高风险 × 低难度 × 高价值：Pcre 高级 API 异常路径未测，命名 group 错误处理缺失 |
| **P5** | `Str::match_beginning` / `match_end` / `matched_string` / `group_beginning` 错误路径 | coverage_test.mbt 追加 | 4 | 高风险 × 低难度 × 中价值：Str OCaml 风格 API 错误路径（未先 match / 越界）全缺 |
| **P6** | `ParseBuffer::integer` 非数字 raise + `ParseBuffer::get` at eos | 新增 parse_buffer_test.mbt | 4-6 | 高风险 × 低难度 × 中价值：解析基础设施错误路径，影响所有前端解析器鲁棒性 |
| **P7** | `Desc::remove_duplicates` / `Desc::initial` / `Desc::status` 三分支 | 新增 desc_test.mbt 或 automata_test.mbt 追加 | 5-6 | 高风险 × 高难度 × 高价值：自动机核心操作正确性，目前仅通过 delta/advance 间接覆盖 |
| **P8** | `Expr::rename` 导数正确性 | automata_test.mbt 追加 | 3-4 | 高风险 × 高难度 × 高价值：导数正确性关键，需与 OCaml 上游对照 |
| **P9** | `Ast::colorize` + `ColorMap::split` 一致性 | color_map_test.mbt 追加 | 3 | 高风险 × 中难度 × 中价值：colorize 是 compile 前置步骤，颜色分配正确性影响匹配 |
| **P10** | cset 边界（空集/全集/互补/256 全遍历/非递减顺序） | basics_test.mbt 追加 | 6-8 | 中风险 × 低难度 × 高价值：cset 是匹配热路径，边界条件覆盖不足 |
| **P11** | `PerlOpt` 各 opt（anchored/dotall/multiline/dollar_endonly/ungreedy） | frontend_test.mbt 追加 | 5 | 中风险 × 低难度 × 高价值：各 opt 对匹配行为影响未测，影响 Perl 兼容性 |
| **P12** | `PcreFlag` 各 flag（Caseless/MultilineP/AnchoredP/DotallP） | frontend_test.mbt 追加 | 4 | 中风险 × 低难度 × 高价值：Pcre flag 行为未测 |
| **P13** | `GroupT::offset/start/stop` 越界 raise + `GroupT::create` | coverage_test.mbt 追加 | 4 | 中风险 × 低难度 × 中价值：GroupT 异常路径和构造器未测 |
| **P14** | `Str` 高级 API（`global_replace`/`replace_first`/`full_split`/`bounded_split`/`quote`/`regexp_case_fold`） | frontend_test.mbt 追加 | 6-8 | 中风险 × 低难度 × 中价值：Str 前端 16 个 API 未覆盖，OCaml 兼容性需要 |
| **P15** | `CompileIdx` 三态判定 + `StateHashTable` 命中/未命中 | 新增 compile_internal_test.mbt | 6-8 | 中风险 × 中难度 × 中价值：compile 内部状态管理正确性，目前全靠端到端间接覆盖 |

### 补充说明

- **P1-P2** 是最高优先级，因为 `match_str` / `match_str_no_bounds` 是 core 模块的唯一直接入口，其参数组合和越界行为是核心契约，且覆盖难度极低（每个 test 块 3-5 行）。
- **P3-P6** 集中在错误路径，当前测试以正向为主，错误路径覆盖严重不足。补充后可显著提升鲁棒性。
- **P7-P9** 涉及自动机/编译核心正确性，目前仅通过端到端间接覆盖，直接测试可定位回归。
- **P10-P12** 是各前端 opt/flag 行为测试，影响兼容性契约。
- **P13-P15** 是剩余中优先级项，可在 P1-P12 完成后按需补充。

### 预期效果

- 完成 P1-P15 后，预计新增约 65-85 个 test 块，总测试数达 316-336。
- 总体 API 覆盖率从 53.0% 提升至约 75-80%（覆盖约 310-330 个 API）。
- 0% 覆盖模块从 14 个减少至约 6-8 个（剩余多为纯内部 Dyn/to_dyn 工具方法）。
- 错误路径覆盖率显著提升，各前端解析器鲁棒性验证完整。
