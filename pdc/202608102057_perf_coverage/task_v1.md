# 任务指令（v1）

## 动作
NEW

## 任务描述
建立性能优化基线，产出两部分：

1. **测试基线**：运行 `moon test`（工作目录 D:\CodeWorkspace\forMoonbit\re-mbt），确认 251 个测试全绿，记录通过数与耗时。若存在失败，停止并报告失败清单。
2. **Benchmark 基线**：运行 `bench\run_bench.ps1`，收集 10 个 section 的 `Best(ms)` 与 `Per-iter(us)` 数据。

将上述结果整理写入 `D:\CodeWorkspace\forMoonbit\re-mbt\pdc\202608102057_perf_coverage\baseline.md`，格式：

```markdown
# 性能优化基线

## 测试基线
- 日期：{YYYY-MM-DD}
- moon test 结果：{通过数}/{总数} 通过，耗时 {s} 秒
- 失败清单：（若有）

## Benchmark 基线
| Section | Name | Best(ms) | Per-iter(us) |
|---------|------|----------|--------------|
| 1 | Perl compile | ... | ... |
| ... |

## 备注
- moon 版本：{moon version}
- 构建目标：native release
```

预期产出：`baseline.md` 文件，含完整基线数据。

## 选择理由
这是性能优化阶段（任务描述要求"先性能后覆盖率"）的第一个子任务。任务描述方法第 1 步明确要求"运行现有 benchmark（bench/run_bench.ps1）建立基线"。没有基线则后续每次优化的"可测量的改进"无法判定（验证标准：benchmark 结果有可测量的改进）。同时 moon test 全绿是不回归验证的参照点。

## 任务上下文
摘自 task.md：
- 构建命令：moon check / moon test / moon build --target native --release
- Benchmark：bench/ 目录，10 个 section，bench/run_bench.ps1 自动化脚本
- 测试：9 个测试文件，251 个 test 块
- 验证标准：moon test 全部通过；benchmark 结果有可测量的改进；无新 warning 引入
- 约束：每轮优化后必须运行 moon test 确保不回归

## 已有产出上下文
工作目录当前仅有 task.md，无任何产出。本任务为整个 PDC 流程的起点。
