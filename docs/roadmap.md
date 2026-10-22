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

---

## 进度查证

| Sprint | 内容 | 状态 | commit |
|--------|------|------|--------|
| S0 | 文档基础设施 | ✅ 已完成 | — |
| S1 | deprecated 治理 | ✅ 已完成 | 见下方 commit |
| S2 | implicit_impl 治理 | ✅ 已完成 | 见下方 commit |
| S3 | test_unqualified 治理 | ✅ 已完成 | 见下方 commit |
| S4 | 文档治理 + 提交 | ✅ 已完成 | 见下方 commit |