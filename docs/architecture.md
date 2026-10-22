# 架构决策记录 / Architecture Decision Records

> 记录 re-mbt 项目的关键架构决策。

## ADR-001: 多根包结构

**决策**：项目采用多根包结构，将原单包 `re` 拆分为 5 个按职责分层的根包：`re_base`、`re_ast`、`re_compile`、`re_exec`、`re_frontend`。

**原因**：
- 按职责分层，降低耦合，提高可维护性
- 各层可独立编译与测试，加速迭代反馈
- 明确依赖方向，防止跨层循环引用

**后果**：
- 依赖链：`re_base` ← `re_ast` ← `re_compile` ← `re_exec` ← `re_frontend`
- 根包 `reexport.mbt` 统一重导出 5 子包公共 API
- 外部用户通过根包 `@re_mbt` 或各子包 `@re_base`/`@re_ast`/... 访问
- 跨包引用需使用 `@pkg.X` 全限定名

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
## ADR-006: 单包拆分为多根包

**决策**：将原单包 `re` 拆分为 5 个根包：`re_base`、`re_ast`、`re_compile`、`re_exec`、`re_frontend`。

**原因**：
- 按职责分层，降低耦合，提高可维护性
- 各层可独立编译与测试，加速迭代反馈
- 明确依赖方向，防止跨层循环引用
- 单包规模增长后编译时间与心智负担上升，拆分缓解

**依赖链**：

```
re_base      ← 字符集、位向量、工具函数等基础数据结构
  ↑
re_ast       ← AST 构造、着色、解析缓冲区
  ↑
re_compile   ← 自动机核心、惰性 DFA 驱动器、AST → 自动机翻译
  ↑
re_exec      ← 高层 Re API、Group、Search、Replace、View
  ↑
re_frontend  ← 6 个前端：Perl、PCRE、POSIX、Emacs、Glob、Str
```

**后果**：
- 跨包引用需使用 `@pkg.X` 全限定名
- 白盒测试（`_wbtest.mbt`）仅限包内作用域，跨包测试改用黑盒（`_test.mbt`）
- 根包 `reexport.mbt` 重导出 5 子包公共 API，对外提供统一入口
- 替代 ADR-001 原单包决策（Sprint 9-15 完成，commit af49f55 → b137343）