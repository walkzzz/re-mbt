# 执行报告（v1）

## 概述
建立 re-mbt 性能优化的测试基线与 Benchmark 基线。运行 `moon test` 确认 251 个测试全绿（0.21 秒），运行 `bench/run_bench.ps1` 收集 10 个 section 的 Best(ms) 与 Per-iter(us) 数据。产出物为 `baseline.md`，含完整基线数据及热点观察。

## 产出清单
| 操作 | 文件路径 | 说明 |
|------|---------|------|
| 新建 | D:\CodeWorkspace\forMoonbit\re-mbt\pdc\202608102057_perf_coverage\baseline.md | 性能优化基线：测试结果 + 10 section benchmark 数据 + 热点观察 |

## 执行过程
1. **环境确认**：获取 moon 版本为 `0.1.20260713 (75c7e1f 2026-07-13)`，确认 bench 目录结构与 run_bench.ps1 脚本逻辑（10 section，每 section 构建 native release 后运行 3 次取最优，迭代数 5000）。
2. **测试基线**：运行 `moon test`，结果 `Total tests: 251, passed: 251, failed: 0`，无失败。用脚本测量耗时为 0.21 秒。输出中存在既有的 struct_never_constructed / unused_constructor / unused_value warning（均为预存量，非本轮引入）。
3. **Benchmark 基线**：运行 `bench/run_bench.ps1`，脚本依次修改 bench_section=1..10、构建、运行 3 次取 Best，完成后恢复 main.mbt。收集到 10 行数据。
4. **热点定位**：Section 1（Perl compile）951ms 远高于其他，为首要优化目标；Section 5/7（Glob/Str）约 348ms 次之；Section 3/4（Emacs/POSIX）约 276-281ms 再次之。Section 2/9/10（纯匹配/分裂替换/大输入）均在 43ms 以下，说明 compile 路径是主要瓶颈。
5. **完整性校验**：验证 bench/main/main.mbt 已恢复为 `bench_section : Int = 0`，脚本正常完成。
6. **清理**：删除测量耗时用的临时脚本 `_measure_test.ps1`，工作目录仅保留 baseline.md 产出物。

## 偏差说明
无
