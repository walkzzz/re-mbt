# 计划审查报告（v21 r1）

## 审查结果
APPROVED

## 发现
- **[轻微]** 块 4 `bounded_split(re, text, 0)` 描述"0 = 无限制"虽与 `Str::split`（str.mbt:220-222）调用 `bounded_split(re, text, 0)` 的语义一致，但代码中并无 num=0 的显式无限制分支，而是因 n 从 0 递减永不等于 1 而 loop 条件 `n != 1` 恒真所达成的隐式无限制。描述精度可改进但不影响测试正确性（实测 trace 确认 `bounded_split(re, "a,b,c,d", 0) == ["a","b","c","d"]`，4 段）。
- **[轻微]** 块 1/块 2 测试 `global_replace`/`replace_first` 返回原文本的行为（`_repl` 未使用），实质验证的是 no-op 行为而非替换功能。这是源码事实（str.mbt:151/194 下划线前缀参数未使用，:173-176/206-209 push matched 原样放回），测试如实覆盖实际行为，对覆盖率目标有效，但若未来 OCaml 上游语义对齐需要真正实现替换，这两个块需重写。
