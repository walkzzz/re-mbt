# 贡献指南（Contributing to re-mbt）

感谢关注 walkzzz/re-mbt —— ocaml-re 的纯 MoonBit 移植（线性时间惰性 DFA，6 种前端）。

## 开发环境

1. 安装 MoonBit 工具链（官方脚本）。
2. 克隆仓库：`git clone https://github.com/walkzzz/re-mbt.git`
3. `moon update`

## 质量门禁（合入前必须全绿）

```bash
moon fmt --check
moon check --deny-warn --target all
moon test --target all
node scripts/check_coverage.mjs        # core >= 95%
moon run scripts/mutation_test.mbtx    # 10/10 KILLED（慢）
node scripts/check_docs.mjs            # 版本/测试数/旧数字/死链/覆盖率
moon info && git diff --exit-code -- '*.mbti'
moon run bench/main --target native --release   # smoke
```

- CI：quality（fmt/check/`.mbti`/docs）、test × 4 后端、coverage、examples、bench smoke；mutation 手动触发。
- 已知工具链边界见 `docs/known-gaps.md`（latest 的 0020 与本地旧版差异）。

## 编码规范

- 纯 MoonBit、零 C FFI；四后端同源，禁止目标条件编译。
- 语义以上游 ocaml-re 为准；行为差异写入 `docs/design.md` / `docs/known-gaps.md`。
- 新增公开 API：补 `///` 文档与测试；更新 `pkg.generated.mbti` 与 CHANGELOG。
- 变异红线：新增核心逻辑（witness/前端解析/导数）应同步增加 `scripts/mutation_test.mbtx` 变异点。

## 提交流程

1. Fork → 特性分支（`feat/xxx`）
2. 跑全部门禁
3. PR → CI 全绿
4. CHANGELOG 补条目（Keep a Changelog + SemVer）

## 反馈

- Issues（缺陷/特性）；安全漏洞走 [SECURITY.md](SECURITY.md)。