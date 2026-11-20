# re-mbt 测试报告（2026-11-20）

> 口径纪律：所有数字实测并带日期；工具链差异与未覆盖项如实记录（见 `known-gaps.md`）。

## 测试矩阵

| 层 | 规模 | 结果 |
| --- | --- | --- |
| 单元/黑盒测试 | **777 测试** | 777/777 绿（native 本地实测；js / wasm / wasm-gc 经 `moon test --target all` 实测绿） |
| 编译器门禁 | 四目标 `--deny-warn` | 零警告（CI latest 对 deprecated 0020 例外，见 GAP-1） |
| 契约 | `.mbti` 入库 | `moon info` 无漂移（CI 严格 `git diff --exit-code`） |
| **变异测试** | **10 变异点 / 2 功能域** | **10/10 KILLED（击杀率 100%）**，MoonBit 脚本 `scripts/mutation_test.mbtx` |
| 覆盖率 | `moon coverage report -f full_summary` | **3857/4029 = 95.7%**（core 口径，排除 bench/examples） |
| 基准 | `bench/main` 10 section | 2407 ms（native release；Perl compile 955 / Perl match 44 / Glob 364 / POSIX 283 / Emacs 223 / Pcre 189 / Str 182 / Search 105 / Split+Replace 41 / Large+Caseless 21） |
| 形式化 | — | 未接入（0.3.0 候选：Cset 代数 / witness 不变量） |

## 覆盖率缺口（补测后）

| 文件 | 覆盖 | 说明 |
| --- | --- | --- |
| `re_frontend/cache.mbt` | 85.4% | 缓存淘汰/清理分支 |
| `re_frontend/glob.mbt` | 86.0% | 极端 glob 语法分支 |
| `re_exec/search.mbt` | 89.2% | Seq 迭代边界 |
| `re_exec/view.mbt` | 90.4% | View 选项组合 |
| `re_exec/replace.mbt` | 93.3% | 替换窗口边界 |
| `re_frontend/perl.mbt` / `str.mbt` | 93.5% | 罕见语法/错误路径 |
| `re_ast/ast_witness.mbt` | 94.6% | 剩余不可匹配组合 |

门槛 95%（当前 95.7%）；补到 97%+ 为 0.3.0 可选目标。

## 变异矩阵（10 点，`scripts/mutation_test.mbtx`）

| 编号 | 目标 | 结果 |
| --- | --- | --- |
| M01 | witness：空 Alternative 变为可匹配 | KILLED |
| M02 | witness：cset 恒不可求值 | KILLED |
| M03 | witness：代表字节替换为 NUL | KILLED |
| M04 | witness：NoCase cast 丢失 | KILLED |
| M05 | witness：Complement 塌缩为空集 | KILLED |
| M06 | witness：Repeat max=0 不再为空 | KILLED |
| M07 | posix class：前缀检查移除 | KILLED |
| M08 | posix class：名称扫描反转 | KILLED |
| M09 | posix class：闭合括号检查移除 | KILLED |
| M10 | witness：Intersection 恒不可求值 | KILLED |

## 方法说明

- 自动化脚本统一为 `.mbtx`（MoonBit 脚本），不引入 Python/Node（经验来自 agentskills.mbt / gbz185.mbt）。
- 覆盖率/变异/基准命令：
  ```bash
  node scripts/check_coverage.mjs
  moon run scripts/mutation_test.mbtx
  moon run bench/main --target native --release
  ```
- 文档数字由 `scripts/check_docs.mjs` 断言（版本 / 测试数 / 旧数字 / 死链 / 覆盖率门槛）。