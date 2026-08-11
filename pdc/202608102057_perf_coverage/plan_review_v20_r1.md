# 计划审查报告（v20 r1）

## 审查结果
APPROVED

## 发现
- **[轻微]** 块 1-3 构造描述未显式提及 `compile` 步骤——task_v20.md 表述为"通过 `exec_opt` 获取一个含捕获组的 GroupT 实例 g"，但 `exec_opt` 签名为 `(re : Re, s : Bytes, ...) -> GroupT?`，需要先 `compile(Ast::seq(...))` 得到 `Re` 再调用 `exec_opt`。不过任务上下文已明确指出"已有 `exec_opt` + `GroupT::get_opt` / `offset_opt` / `start_opt` / `stop_opt` 正向测试（:562-633）可参考"，且 coverage_test.mbt:563-566 正是 `compile(Ast::seq([Ast::str(sb_cov("a")), Ast::group(Ast::str(sb_cov("b")))]))` + `exec_opt(re, sb_cov("ab"))` 的完整模式，Doer 可从参考中理解，不影响执行正确性。
- **[轻微]** 块 4 `MarkInfos::make([(0, 0), (1, 1)])` 的输入语义表述略有歧义——task_v20.md 说"group 0 的 start_mark=0、stop_mark=1"，但 `MarkInfos::make` 的输入是 `(table_position, table_value)` 列表而非 `(group_index, (start, stop))` 列表。经源码验证（mark_infos.mbt:11-24），输入 `[(0,0),(1,1)]` 确实产生 table=[0,1]，group 0 的 start=table[0]=0、stop=table[1]=1，最终 `GroupT::offset(g, 0) = (g.gpos[0], g.gpos[1]) = (0, 5)`，断言正确。构造代码 `MarkInfos::make([(0, 0), (1, 1)])` 本身明确无歧义，Doer 可正确执行。
