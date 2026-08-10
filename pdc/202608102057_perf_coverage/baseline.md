# 性能优化基线

## 测试基线
- 日期：2026-08-10
- moon test 结果：251/251 通过，耗时 0.21 秒
- 失败清单：无

## Benchmark 基线
| Section | Name | Best(ms) | Per-iter(us) |
|---------|------|----------|--------------|
| 1 | Perl compile | 951.0 | 190.19 |
| 2 | Perl match | 43.3 | 8.67 |
| 3 | Emacs compile+match | 276.4 | 55.27 |
| 4 | POSIX compile+match | 281.1 | 56.22 |
| 5 | Glob compile+match | 347.4 | 69.49 |
| 6 | Pcre compile+match | 208.2 | 41.64 |
| 7 | Str compile+match | 348.5 | 69.69 |
| 8 | Search all+matches | 77.6 | 15.52 |
| 9 | Split+Replace | 42.3 | 8.47 |
| 10 | Large+Caseless | 25.8 | 5.16 |

## 备注
- moon 版本：moon 0.1.20260713 (75c7e1f 2026-07-13)
- 构建目标：native release
- Benchmark 方法：每个 section 构建 native release 后运行 3 次取最优（Best），迭代数 5000，Per-iter(us) = Best(ms) / 5000 * 1000
- 热点观察：Section 1（Perl compile）耗时 951ms 远高于其他 section，为首要优化目标；Section 5/7（Glob/Str compile+match）约 348ms 次之；Section 3/4（Emacs/POSIX）约 276-281ms 再次之
