# 任务计划

任务描述：re-mbt 性能优化 + 测试覆盖率提升（先性能后覆盖率）
工作目录：D:\CodeWorkspace\forMoonbit\re-mbt\pdc\202608102057_perf_coverage

---

## R1 NEW 建立 benchmark 基线 [ID: T1]
任务：运行 bench/run_bench.ps1 建立 10 个 section 的性能基线，结果写入 baseline.md；同时运行 moon test 确认全绿基线。
选择理由：性能优化的第一步必须建立可复现的基线，否则后续无法量化改进。任务描述明确要求"先做性能优化"，且方法第 1 步即"运行现有 benchmark 建立基线"。
上下文：bench/ 目录含 run_bench.ps1（10 section：Perl compile/match、Emacs、POSIX、Glob、Pcre、Str、Search all、Split+Replace、Large+Caseless），每个 section 跑 3 次取最佳，每 iter 5000 次。构建命令 moon build --target native --release。需先确认 moon test 全绿作为不回归的参照基线。
