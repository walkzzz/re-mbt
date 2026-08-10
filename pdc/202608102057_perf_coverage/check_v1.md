# 检查报告（v1）

## 结果
PASSED

## 检查项
| 检查项 | 方法 | 结果 |
|--------|------|------|
| 产出文件存在性 | 读取工作目录列表 | 通过：baseline.md 存在于指定路径 |
| 测试基线完整性 | 读取 baseline.md 测试基线段 | 通过：日期 2026-08-10，251/251 通过，耗时 0.21 秒，失败清单为"无"，符合任务要求格式 |
| Benchmark 基线 section 数量 | 统计 baseline.md 表格行数 | 通过：10 个 section（1-10）齐全 |
| Benchmark 基线字段完整性 | 检查每行含 Section/Name/Best(ms)/Per-iter(us) | 通过：4 列完整，无空缺 |
| Per-iter 计算一致性 | 用 Best(ms)/5000*1000 复算全部 10 行 | 通过：10 行 Per-iter 值与 Best(ms) 计算一致（误差 ≤0.01us，属舍入） |
| 备注段完整性 | 检查 moon 版本与构建目标 | 通过：moon 0.1.20260713 (75c7e1f 2026-07-13)，构建目标 native release |
| do_v1.md 与 baseline.md 一致性 | 对比执行报告与产出数据 | 通过：251/251、0.21s、10 section、热点定位（Section 1=951ms、5/7≈348ms、3/4≈276-281ms）均一致 |
| 文件格式符合任务模板 | 对比 task_v1.md 要求的 markdown 模板 | 通过：含"性能优化基线/测试基线/Benchmark 基线/备注"四段，表格表头与模板一致 |

## 总结
Doer 产出完整满足 task_v1.md 的全部要求：baseline.md 位于指定路径，包含测试基线（251/251 通过 + 耗时）、10 个 section 的 Benchmark 基线（Best(ms) 与 Per-iter(us) 数据完整且计算自洽）、备注（moon 版本 + 构建目标）。do_v1.md 执行报告与产出文件数据一致，无偏差。
