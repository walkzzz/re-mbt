# AGENTS.md — walkzzz/re-mbt

MoonBit 正则表达式库（ocaml-re 的纯 MoonBit 移植，线性时间惰性 DFA）。主模块 `moon.mod` v0.2.1（0.2.0 已发布；0.2.1 待发布）。

## 构建与验证（完成标准）

- `moon check --deny-warn --target all` — 四后端零警告
- `moon test --target all` — 777 测试 × 4 后端全绿（native / wasm / wasm-gc / js）
- `moon fmt --check` — 格式门禁
- `node scripts/check_coverage.mjs` — 覆盖率门槛（core ≥ 95%，排除 bench）
- `node scripts/mutation_test.mjs` — 10 变异点全 KILLED
- `node scripts/check_docs.mjs` — 文档数字断言（版本/测试数/旧数字/死链/覆盖率）
- `moon run bench/main --target native --release` — 基准 smoke
- `moon info && git diff --exit-code -- '*.mbti'` — 契约漂移

## 包结构

```
reexport.mbt      # 根包门面（@re 聚合导出）
re_base/          # 基础数据结构（Cset/Mark/ParseBuffer/Dyn/Fmt/Slice…）
re_ast/           # AST / 颜色映射 / 导数自动机 / witness
re_compile/       # Re 编译（惰性 DFA、Group、Replace）
re_exec/          # Core/Search/View/Replace 运行时
re_frontend/      # Perl / PCRE / POSIX / Emacs / Glob / Str 前端 + cache
bench/main/       # 基准可执行包
examples/demo/    # 可运行示例（6 前端 + witness + Search）
docs/             # api/architecture/design/examples/roadmap/bench-baseline/assessment
```

## 工程纪律

- **零 C FFI、四后端同源**：新增代码必须四目标 `deny-warn` 通过；禁止目标条件编译。
- **上游对齐**：语义以 ocaml-re 为基准；行为差异必须写入 `docs/design.md` 或 `docs/assessment.md` 的"已知限制"。
- **契约优先**：`pkg.generated.mbti` 入库；公开 API 变化必须更新 CHANGELOG（破坏性时写迁移说明），CI 严格阻断 drift。
- **覆盖率门槛**：core ≥ 95%（当前实测 95.7%，排除 bench）；不得为过门槛而排除被测代码。
- **变异红线**：`scripts/mutation_test.mjs` 必须 10/10 KILLED；新核心逻辑（witness/前端解析/导数）应同步增加变异点。
- **口径可复算**：README/AGENTS/assessment 中的测试数、覆盖率、基准数字必须能由 `scripts/*.mjs` 与 `moon` 复算；历史数字（713/437/98.9%）已废弃。
- **发布**：`moon publish` 由维护者执行；发版前四目标测试 + 覆盖率 + 变异 + docs 断言全绿，并回写 `moon.mod`/README/CHANGELOG/AGENTS。

## 版本纪律

- `moon.mod` 版本 = CHANGELOG 最新条目 = README 发布说明。
- 0.x 阶段允许破坏性变更，但必须写迁移说明；发布后打 `vX.Y.Z` tag。

## 已知限制（事实源）

见 `docs/assessment.md` 与 `docs/design.md`：`ast_witness` 长尾（不可匹配组合）、`re_frontend/cache` 缓存淘汰、glob/perl 极端语法分支的未覆盖行；不代表已实现未声明能力。