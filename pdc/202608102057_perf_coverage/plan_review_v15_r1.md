# 计划审查报告（v15 r1）

## 审查结果
REJECTED

## 发现

- **[严重]** `Sem::Plain` 不存在，编译会失败。`Sem` enum（automata.mbt:5-9）实际变体为 `Longest`/`Shortest`/`First`，无 `Plain`。task_v15.md 块 2（:11）构造 `Expr::seq(ids1, Sem::Plain, a, b)`、块 4（:15）构造 `Expr::rep(ids1, RepKind::Star, Sem::Plain, a)` 及对应断言均使用了不存在的 `Sem::Plain`。task_v15.md:29 上下文亦错误描述"`Sem` enum（Plain 等）"。若 Doer 严格按 task_v15.md 执行，`moon check`/`moon test` 均报编译错误 `[4036] Unresolved constructor Sem::Plain`，任务直接失败。

- **[严重]** `RepKind::Star` 不存在，编译会失败。`RepKind` enum（automata.mbt:12-15）实际变体为 `Greedy`/`NonGreedy`，无 `Star`。task_v15.md 块 4（:15）构造 `Expr::rep(ids1, RepKind::Star, Sem::Plain, a)` 及断言 (a) 使用了不存在的 `RepKind::Star`。task_v15.md:29 上下文亦错误描述"`RepKind` enum（Star 等）"。同上，编译会失败。

- **[严重]** 块 3 断言 (c) `Expr::id(alt2) == 1` 与 `Expr::rename` Alt 分支实际执行顺序不符，测试断言会失败。Alt 分支实现（automata_expr.mbt:167-170）为 `Alt(_, l) => { let l2 = Array::map(l, fn(e) { Expr::rename(ids, e) }); Alt(ids.next(), l2) }`：`let l2 = Array::map(...)` 先执行，对 3 个子节点依次调用 rename 消耗 id 1/2/3，随后 `Alt(ids.next(), l2)` 分配根节点 id 得 4。故 `Expr::id(alt2)` 实际为 4，非 1。task_v15.md:13 断言 (c) `Expr::id(alt2) == 1` 的隐含假设"根节点先 rename"对 Alt 分支不成立（对比 Seq/Rep 分支确实是根节点先 rename，但 Alt 分支因 `let l2 = ...` 在前导致子节点先 rename）。若 Doer 严格按断言编写，`assert_eq(Expr::id(alt2), 1)` 会失败，导致 moon test 失败。

## 修改要求

1. **问题 1（Sem::Plain 不存在）**：task_v15.md 块 2 和块 4 使用了不存在的 `Sem::Plain`，编译会失败。期望修正：将所有 `Sem::Plain` 替换为实际存在的变体（如 `Sem::Longest`），同时修正 task_v15.md:29 上下文描述。

2. **问题 2（RepKind::Star 不存在）**：task_v15.md 块 4 使用了不存在的 `RepKind::Star`，编译会失败。期望修正：将 `RepKind::Star` 替换为实际存在的变体（如 `RepKind::Greedy`），同时修正 task_v15.md:29 上下文描述。

3. **问题 3（块 3 Alt id 断言错误）**：断言 (c) `Expr::id(alt2) == 1` 与 Alt 分支先 map 子节点后分配根节点 id 的执行顺序不符，测试会失败。期望修正：将断言 (c) 改为 `Expr::id(alt2) == 4`，并在描述中注明"Alt 分支先递归 rename 子节点消耗 id 1-3，根节点后分配 id 得 4"。
