# Warning Governance Tracking

## Metadata
- 项目根目录：D:/CodeWorkspace/forMoonbit/re-mbt
- 治理启动时间：2026-08-10 11:55
- 基线报告：check_v1.md（Total: 250, 有效需修复: 231）
- 当前轮次：Round 1
- 当前计划：plan_v1.md

## Progress Overview

| Batch | Code | Type | 目标数 | 已修复 | 状态 | 执行者 |
|-------|------|------|--------|--------|------|--------|
| 1 | 0071 | core_package_not_imported | 120 | 0 | pending | - |
| 2 | 0008 | redundant_modifier | 41 | 0 | pending | - |
| 3 | 0020 | deprecated | 30 | 0 | pending | - |

**本轮合计**：目标 191 / 已修复 0 / 状态 pending

## Out of Scope (本轮)

| Code | Type | Count | 后续轮次 |
|------|------|-------|---------|
| 0001/0002 | unused_value | 25 | Round 2 |
| 0009 | struct_never_constructed | 19 | 永久排除（phantom structs） |
| 0004 | missing_priv | 8 | Round 2 |
| 0006 | unused_constructor | 4 | Round 3 |
| 0024 | unused_error_type | 3 | Round 3 |

## Round History

### Round 1 (2026-08-10)
- **计划**：plan_v1.md
- **范围**：Batch 1 (120) + Batch 2 (41) + Batch 3 (30) = 191
- **状态**：planning → pending execution
- **检查报告**：check_v1.md
- **备注**：Batch 1 为 moon.pkg 配置路径迁移（moonbitlang/test → moonbitlang/core/test）；Batch 2 为机械删除冗余 pub；Batch 3 为 deprecated 语法替换（not→!, reinterpret_as_uint().to_int()→reinterpret_as_int(), is_empty()→is None, Ref::new→新语法）。

## Verification Checklist
- [ ] Batch 1 执行完成，`moon check` 确认 0071 消除
- [ ] Batch 2 执行完成，`moon check` 确认 0008 消除
- [ ] Batch 3 执行完成，`moon check` 确认 0020 消除
- [ ] `moon test` 全量通过，无回归
- [ ] 生成 check_v2.md 剩余 warning 报告
- [ ] 更新 governance.md 最终进度
