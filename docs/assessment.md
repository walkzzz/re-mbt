# re-mbt 工程质量评估（2026-11-20）

> 范围：walkzzz/re-mbt @ 0.2.1（工作区，待发布）· 工具：moon 0.1.20261117（Windows native 实测）
> 口径：所有数字附复现命令；历史文档中的 713/437/98.9% 已废弃。

## 总览

| 指标 | 实测 | 复现 |
| --- | --- | --- |
| 测试 | **777 测试 × 4 后端**（native / wasm / wasm-gc / js） | `moon test --target all` |
| 编译门禁 | 四目标 `--deny-warn` 零警告 | `moon check --deny-warn --target all` |
| 覆盖率（core，排除 bench） | **3857/4029 = 95.7%** | `node scripts/check_coverage.mjs` |
| 变异测试 | **10 / 10 KILLED**（待脚本复核） | `node scripts/mutation_test.mjs` |
| 文档断言 | **6 / 6** | `node scripts/check_docs.mjs` |
| 基准 | `bench/main`（10 section，native release） | `moon run bench/main --target native --release` |
| 契约 | `.mbti` 入库 + CI 严格 drift | `moon info && git diff --exit-code` |
| 版本 | `moon.mod` 0.2.1（0.2.0 已发布；0.2.1 待发布） | — |

## 本轮增强（0.2.1）

1. **测试 764 → 777**：
   - `Ast::witness` 全分支（cset 代数 Intersection/Complement/Difference/Cast、序列、Repeat clamp、零宽断言、Group/NoGroup/Nest/Pmark/Sem/SemGreedy、不可匹配 None）
   - `Posix_class`（14 类映射、正/负解析、非 class 输入、缺闭合括号/未知名称 panic）
   - `ast_to_dyn` 包装器分支（NoGroup/Sem/SemGreedy/NoCase）
2. **覆盖率门槛**：`scripts/check_coverage.mjs`（core ≥ 95%）；实测 95.7%；旧称 98.9% 不可复算，已修正。
3. **变异矩阵**：`scripts/mutation_test.mjs` 10 点（witness 语义 / posix 解析边界）。
4. **CI 分层**：quality（fmt / check / `.mbti` 严格 / docs）、test × 4、coverage、examples、bench smoke、手动 mutation。
5. **可运行示例**：`examples/demo`（Perl 匹配 / Replace / Search / Glob / 错误路径）。
6. **文档断言**：`scripts/check_docs.mjs`（版本=CHANGELOG、README=AGENTS 测试数、旧数字残留、死链、覆盖率门槛+CI、assessment 口径）。

## 覆盖率缺口（下一轮可选）

| 文件 | 覆盖 | 说明 |
| --- | --- | --- |
| `re_frontend/cache.mbt` | 85.4% | 缓存淘汰/清理分支 |
| `re_frontend/glob.mbt` | 86.0% | 极端 glob 语法分支 |
| `re_exec/search.mbt` | 89.2% | Seq 迭代边界 |
| `re_exec/view.mbt` | 90.4% | View 选项组合 |
| `re_exec/replace.mbt` | 93.3% | 替换窗口边界 |
| `re_frontend/perl.mbt` / `str.mbt` | 93.5% | 罕见语法/错误路径 |
| `re_ast/ast_witness.mbt` | 94.6% | 剩余不可匹配组合 |

> 门槛 95% 为当前红线；补到 97%+ 属 0.3.0 可选目标，不阻塞 0.2.1。

## 已知限制（事实源）

- 上游 ocaml-re 的 `Re.Seq` 惰性流式语义：当前 `Search::iter_*` 为物化实现（语义一致，内存非惰性）。
- 未实现完整 PCRE 特性（回溯/反向引用等上游本就有限）；以 `docs/design.md` 与前端测试为准。
- 无 C FFI；native 性能低于 PCRE/RE2 原生实现，基准见 `docs/bench-baseline.md`。

## 风险与提示

| 风险 | 现状 | 处置 |
| --- | --- | --- |
| 文档数字漂移 | README 残留 713/437；旧覆盖率 98.9% | 已统一 + `check_docs.mjs` 断言 |
| 变异覆盖不足 | 仅 witness/posix 两类 | 0.3.0 扩展到 cset/compile/search |
| 覆盖率产物误提交 | `cov.txt` 为临时产物 | 已加入 `.gitignore` 并删除 |
| 发布节奏 | 0.2.0 已发布，0.2.1 待发布 | 发布由维护者执行 |