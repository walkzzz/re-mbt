# 架构决策记录 / Architecture Decision Records

> 记录 re-mbt 项目的关键架构决策。

## ADR-001: 单包结构

**决策**：项目采用单包 `re` 结构，而非多包拆分。

**原因**：
- OCaml-re 上游是单库，移植保持结构一致
- 正则表达式各模块（AST、Cset、Compile、Exec）高度耦合，拆包增加导入开销
- 单包内白盒测试可直接访问私有成员，便于验证内部不变量

**后果**：
- 根包 `reexport.mbt` 统一重导出 `re` 包公共 API
- 外部用户通过 `@re` 或根包 `@re_mbt` 访问

## ADR-002: Brzozowski 导数 + 惰性 DFA

**决策**：采用 Brzozowski/Antimirov 导数构建惰性 DFA，而非 NFA 回溯或 Thompson 构造。

**原因**：
- 线性时间匹配保证（无回溯灾难）
- 与 OCaml-re 上游算法一致，忠实移植
- 惰性构造避免预编译整个 DFA

**后果**：
- `compile` 阶段构建 Expr → Desc → State
- `exec` 阶段按需展开 DFA 状态
- `WorkingArea` 维护运行时状态

## ADR-003: 字符集为排序区间列表

**决策**：`Cset` 用排序、不重叠、不邻接的 `Array[(Int, Int)]` 表示。

**原因**：
- 集合运算（并、交、差、补）高效（线性扫描）
- 内存紧凑（相比位图，稀疏字符集节省空间）
- 与 OCaml-re 上游一致

**后果**：
- `Cset::union` / `inter` / `diff` 维护排序不变量
- `Cset::mem` 二分查找 O(log n)

## ADR-004: 6 个前端共享核心

**决策**：Perl、PCRE、POSIX、Emacs、Glob、Str 6 个前端共享统一的 `compile` + `exec` 核心。

**原因**：
- 各前端语法不同但语义统一（都编译为 AST → Re）
- 避免重复实现匹配引擎
- 与 OCaml-re 上游架构一致

**后果**：
- 每个前端只实现 `parse`（语法 → AST）和 `compile_pat`（AST → Re）
- 匹配统一用 `exec` / `execp` / `match_str`

## ADR-005: API 最小化

**决策**：内部类型标记为 `priv`，仅暴露用户所需 API。

**原因**：
- 减少公共 API 表面，降低维护成本
- 防止用户依赖实现细节

**后果**：
- `Fmt`、`Slice`、`SliceL`、`DenseMap`、`PosixClass` 标记为 `priv`
- 根包 `reexport.mbt` 显式列出所有公共 API