# Benchmark 基线记录

> 运行环境：Windows 11 / MoonBit 0.1.20261104（moonc v0.10.20）/ native 后端 release 调试版
> 运行方式：`moon run --target native bench/main`（bench_section = 0，全部 10 段）
> 复跑日期：2026-11-18（v0.1.0 基线复跑，13 缺陷修复 + derive 迁移后）

## 当前基线（2026-11-18）

| Section | 名称 | 耗时 (ms) |
|---------|------|----------:|
| 1 | Perl compile | 1078 |
| 2 | Perl match | 78 |
| 3 | Emacs | 275 |
| 4 | POSIX | 305 |
| 5 | Glob | 414 |
| 6 | Pcre | 232 |
| 7 | Str | 203 |
| 8 | Search | 254 |
| 9 | Split+Replace | 61 |
| 10 | Large+Caseless | 37 |
| **合计** | | **2938** |

## 历史对照（README 记录）

- ColorMap::flatten 重写：Section 1（Perl compile）951ms → 505ms（−46.9%）
- Cset union/inter/diff 容量预分配 + 分治归并 → 全 section 正改进

> 注：bench 数字受机器/负载影响显著，本次复跑机器与历史记录环境不同，
> Section 1 的 1078ms 与历史 505ms 不可直接比较。后续优化对比请以同一环境连续两次复跑为准。

## 覆盖率现状（2026-11-18）

- `moon test --enable-coverage`：702 测试全过
- `moon coverage analyze`：**123 未覆盖行 / 20 文件**（约 98.9% 覆盖率）
- 长尾分布：单文件最多 9 行（re_ast/ast.mbt 的 ast_to_dyn 调试序列化函数），
  其余为 1-3 行防御分支/罕见错误路径，补测性价比低，记录在案
