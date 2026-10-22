# 迭代路线 / Roadmap

> **项目**：re-mbt — OCaml-re 正则表达式库的 MoonBit 移植
> **目标**：`moon check` 0 warning 0 error，`moon test` 全通过，文档完整
> **更新时间**：2026-10-22

---

## 当前状态

| 指标 | 值 |
|------|-----|
| MoonBit 代码行数 | ~11,347 行（52 个 .mbt） |
| 测试数量 | 437 个（全通过） |
| Warning 总数 | **0**（已治理） |
| Error | 0 |
| mooncakes 发布 | walkzzz/re-mbt@0.1.0 |

### Warning 分布

| 类型 | 数量 | 说明 |
|------|------|------|
| W0025 test_unqualified_package | 2185 | 测试中隐式导入包，应使用 `@re.X` 限定 |
| W0079 implicit_impl_as_method | 26 | derive 的 trait 方法隐式提升，需加 `pub extend` 声明 |
| W0020 deprecated | 3 | `Array::new(capacity=...)` 废弃，改用 `Array(capacity=...)` |

---

## Sprint 计划

### Sprint 0 — 文档基础设施 ✅ 已完成
- 创建 `docs/roadmap.md`
- 创建 `CHANGELOG.md`
- **交付**：迭代路线确立

### Sprint 1 — deprecated warning 治理 (W0020) ✅ 已完成
- **范围**：`re/cset.mbt` 第 109、170、197 行
- **动作**：`Array::new(capacity=...)` → `Array(capacity=...)`
- **结果**：W0020 降至 0

### Sprint 2 — implicit_impl_as_method 治理 (W0079) ✅ 已完成
- **范围**：26 处 derive(Debug/Eq/Compare) 类型
- **动作**：为每个 derive 类型添加 `pub extend Type with Trait::{method}` 声明
- **涉及类型**：AstAlt, AstCset, AstGen, Category, Cset, Dyn, ExecPartialResult, Expr, Pmark, RepKind, Sem
- **结果**：W0079 降至 0

### Sprint 3 — test_unqualified_package 治理 (W0025) ✅ 已完成
- **范围**：所有 `*_test.mbt` 文件 + `README.mbt.md` 代码块中的裸类型/函数引用
- **动作**：批量替换为 `@re.X` 全限定名（2327 处替换）
- **结果**：W0025 降至 0

### Sprint 4 — 文档治理 + 提交 ✅ 已完成
- 更新 README / CHANGELOG / roadmap
- git commit + 回写 commit hash

### Sprint 5 — moon.mod 配置 + pub fn 注释 (R33/R3) ✅ 已完成
- moon.mod 添加 `preferred_target = "wasm"` + `supported_targets = "+wasm+wasm-gc+js+native"`
- 为 3 个 `pub fn` 添加 `///` 文档注释（Category::from_int, Cset::empty, Pmark::equal）

### Sprint 6 — 根包重导出 (R10/R12) ✅ 已完成
- 创建根目录 `moon.pkg`（导入 `re` 子包）
- 创建 `reexport.mbt`（重导出 67 个公共类型和函数）
- 创建 `re/README.md`（子包 API 说明）

### Sprint 7 — 文档治理 (R8) ✅ 已完成
- 创建 `docs/api.md`（公共 API 参考）
- 创建 `docs/architecture.md`（5 条架构决策记录）
- 创建 `docs/design.md`（核心设计：类型层次、字符集算法、编译流水线）
- 创建 `docs/examples.md`（使用示例与最佳实践）

### Sprint 8 — 验证 + 提交 ✅ 已完成
- `moon check` 0 warning 0 error
- `moon test` 437/437 passed
- git commit + roadmap 回写

---

## 进度查证

| Sprint | 内容 | 状态 | commit |
|--------|------|------|--------|
| S0 | 文档基础设施 | ✅ 已完成 | 3c8119f |
| S1 | deprecated 治理 | ✅ 已完成 | 3c8119f |
| S2 | implicit_impl 治理 | ✅ 已完成 | 3c8119f |
| S3 | test_unqualified 治理 | ✅ 已完成 | 3c8119f |
| S4 | 文档治理 + 提交 | ✅ 已完成 | 3c8119f |
| S5 | moon.mod 配置 + pub fn 注释 | ✅ 已完成 | f49fbc1 |
| S6 | 根包重导出 + re/README | ✅ 已完成 | f49fbc1 |
| S7 | 文档治理 (api/arch/design/examples) | ✅ 已完成 | f49fbc1 |
| S8 | 验证 + 提交 | ✅ 已完成 | f49fbc1 || S9 | 创建 5 子包目录 + moon.pkg + 移动源文件 | ✅ 已完成 | af49f55 |
| S10 | 源文件跨包引用 + warning 治理 | ✅ 已完成 | af49f55 |
| S11 | 测试文件迁移 + 跨包引用 | ✅ 已完成 | bf182e8 |
| S12 | warning 治理 13→0 | ✅ 已完成 | bf182e8 |
| S13 | 根包 reexport.mbt 重导出 5 子包 API | ✅ 已完成 | b137343 |
| S14 | 5 子包 README.md | ✅ 已完成 | b137343 |
| S15 | 提交 | ✅ 已完成 | b137343 |
---

## 性能优化 Sprint（S16-S18）

> **R11 记**：R2 要求五类多手段测试全 Pass 才放行；R11 要求每步记/锁/回。
> **R11 锁**：性能优化与 R2 多手段测试无冲突，但之前未执行 R2 → 需补测。
> **R11 回**：已交付 S16-S17（Str 优化 + ReCache），下环依赖 S18（R2 补测）。

### Sprint 16 — 基准测试 + Str 延迟编译 ✅ 已完成
- 基线：编译占 85.6%，Str 911ms
- 优化：Str 延迟编译 mtch，911ms→334ms（-63%）
- commit: 76b5186
- **R2 状态**：⚠️ 未执行五类多手段测试

### Sprint 17 — ReCache memoization 缓存 ✅ 已完成
- 新增 ReCache + 7 个 _cached 前端变体
- 测试：437→454（+17 缓存测试）
- commit: a1a39f5
- **R2 状态**：⚠️ 未执行五类多手段测试

### Sprint 18 — R2 多手段测试补测 ✅ 已完成
- **形式化证明**：9 tests — ReCache key 唯一性 + Str 语义等价性
- **AI 测试**：4 tests — 重复编译缓存命中模拟
- **FAKE 测试**：5 tests — 空/超长模式 + get 不存在的 key
- **MOCK 测试**：4 tests — 缓存跳过编译 + 不同 opts 不命中
- **E2E 测试**：5 tests — 编译→匹配→缓存→clear→Str 延迟编译全链路
- 新增 27 tests，总 481/481 passed
- 报告：`docs/arch_test_report.md`
- commit: 见最新提交

> **R11 回**：已交付 S16-S18（Str 优化 + ReCache + R2 五类测试），下环无阻塞。
---

## Trait 抽象 Sprint（S19-S21）

> **R11 记**：R18/R19 要求 trait 化公共行为模式，P0 最高 ROI = Dynable（10 类型跨 2 包）。
> **R11 锁**：pub impl + pub extend 与现有 API 兼容，无冲突。
> **R11 回**：已交付 S19-S21（P0 trait 化 + R2 五类测试），下环无阻塞。

### Sprint 19 — P0 trait 化 ✅ 已完成
- 新增 3 pub(open) trait：Dynable / Hashable / Equatable
- 11 个 pub impl + pub extend（re_base 6 + re_ast 8）
- Cset::hash 签名统一为 hash(Self, Int32) -> Int32
- moon check 0 warning 0 error, moon test 481/481 passed

### Sprint 20 — R2 五类多手段测试 ✅ 已完成
- 形式化证明 18 tests / AI 6 / FAKE 8 / MOCK 4 / E2E 4
- 新增 40 tests，总 521/521 passed
- 报告追加到 docs/arch_test_report.md

### Sprint 21 — R11 回 + 提交 ✅ 已完成
- commit: 见最新提交
### Sprint 22 — P3 trait 化（前端方言统一）✅ 已完成
- 新增 3 pub(open) trait：RegexParser / RegexCompiler / Quotable
- 7 个 pub impl（RegexParser 4 + RegexCompiler 1 + Quotable 2）
- R13：删除 #warnings(-struct_never_constructed)，改用 derive(Default)

### Sprint 23 — R2 五类多手段测试 ✅ 已完成
- 形式化证明 7 / AI 4 / FAKE 4 / MOCK 3 / E2E 4
- 新增 22 tests，总 543/543 passed

### Sprint 24 — R11 回 + 提交 ✅ 已完成
- commit: 见最新提交

> **R11 回**：已交付 S22-S24（P3 前端 trait 化 + R2 五类测试），下环无阻塞。