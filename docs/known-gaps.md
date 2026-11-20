# 已知边界与缺口（真话台账）

> 维护者人工维护的诚实台账：README 只描述能力；本文件描述边界。评审/集成前请先读此页。

## 平台与工具链

| 编号 | 描述 | 影响面 | 状态/规避 |
| --- | --- | --- | --- |
| GAP-1 | latest moon 将 `Iter::new` 判为 deprecated（0020，deny-warn 升级为 error）；本地 0.1.20261117 只支持 `Iter::new`，新语法 `Iter(f, size_hint=...)` 仅 latest 可用 | `Search::all` 及 CI quality | CI 用 `moon check --warn-list -0020` 暂时屏蔽；0.3.0 迁移新语法（需本地工具链升级到 latest 后移除屏蔽） |
| GAP-2 | Windows 本地 `moon fmt` 受安全策略限制（改写源码），只能用 `moon fmt --check` + `_build/.../format` 产物对齐 | 开发期格式 | 门禁以 `moon fmt --check` 为准 |
| GAP-3 | 无 `verify` / `moon prove` 包（形式化未接入） | 证明证据 | 0.3.0 候选：Cset 代数不变量、witness 生成即匹配、前端 roundtrip |
| GAP-4 | `Search::iter_*` 为物化实现（语义对齐上游 `Re.Seq`，内存非惰性） | 大输入内存 | 文档披露；惰性流式列为 0.3.0 |

## 覆盖率与测试缺口

| 编号 | 描述 | 状态 |
| --- | --- | --- |
| GAP-5 | `re_frontend/cache`（85.4%）、`glob`（86.0%）、`re_exec/search`（89.2%）、`view`（90.4%）等长尾未覆盖 | 门槛 95% 已过（95.7%）；97%+ 为 0.3.0 目标 |
| GAP-6 | 无 quickcheck 属性测试（agentskills.mbt 有 6 条） | 0.3.0 候选：Cset union/inter 代数、parse→exec 一致、witness→exec 命中 |
| GAP-7 | 变异矩阵仅覆盖 witness/posix（10 点） | 0.3.0 扩展到 cset/compile/search |

## 功能边界

- 上游 ocaml-re 的完整 PCRE 特性（回溯/反向引用等）未实现（上游本身有限子集）；以 `docs/design.md` 与前端测试为准。
- 纯 MoonBit 无 C FFI，native 性能低于 PCRE/RE2 原生实现（基准见 `docs/bench-baseline.md`）。
- 0.x 阶段 API 未冻结；破坏性变更需在 CHANGELOG 注明并提供迁移说明。