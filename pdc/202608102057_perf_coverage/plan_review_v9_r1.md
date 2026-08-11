# 计划审查报告（v9 r1）

## 审查结果
REJECTED

## 发现

- **[一般]** plan.md T9 条目内部矛盾：test 块数量描述与预期产出不一致。line 108 声明"追加 7 个 test 块"，line 111 预期"258/258（251+7）"，均指向 7 块；但 line 110 P2 描述中写"同时补充 1 个对照块：`match_str` 对相同越界参数应 raise"，若该对照块为独立块，则 P2 = 3 + 1 = 4 块，总计 4（P1）+ 4（P2）= 8 块，应为 259/259，与 258/258 矛盾。task_v9.md line 27 已澄清"可与上述 3 块合并，每块同时验证 no_bounds 不 raise + match_str raise"（即合并后 7 块、258/258），但 plan.md T9 条目自身未表述合并意图，"补充 1 个对照块"自然读法为新增独立块。plan.md 作为计划顶层文档应自洽，该矛盾可能误导 Do 环节创建 8 块（导致 259/259 与验证标准 258/258 不符）或误导 Check 环节以 8 块为预期判定 7 块产出不合格。

- **[轻微]** task_v9.md P1 四象限描述中，`(groups=true, partial=false)` 与 `(groups=false, partial=false)` 的预期行为均写"命中返回 `MatchInfo(GroupT)`，不命中返回 `FailedInfo`"，未说明 groups=true 与 groups=false 的实际差异（GroupT 内 group marks 是否填充，由 `Positions::make(groups~, re)` 控制）。对测试断言而言只需区分 variant 类型即可，不影响正确性，但描述精度可提升。

## 修改要求（仅 REJECTED 时）

### 问题 1（一般）：plan.md T9 条目 test 块数量自相矛盾

**问题是什么**：plan.md line 108 声明"追加 7 个 test 块"，line 111 预期"258/258（251+7）"，但 line 110 P2 描述写"同时补充 1 个对照块"，自然读法为在 P2 的 3 块之外再新增 1 个独立对照块，使总计变为 8 块（251+8=259），与 258/258 矛盾。

**为什么是问题**：plan.md 是计划顶层文档，应自洽。Do 环节执行者若按"补充 1 个对照块"字面意思创建独立第 8 块，则实际产出 259/259，与验证标准 258/258 不符，Check 环节会误判失败；反之若执行者按 258/258 创建 7 块，Check 环节若以"补充 1 个对照块"为预期则可能误判缺少对照块。task_v9.md 已通过"可与上述 3 块合并"消解此歧义，但 plan.md T9 条目自身未同步该澄清，二者存在表述分歧。

**期望的修正方向**：将 plan.md line 110"同时补充 1 个对照块：`match_str` 对相同越界参数应 raise "Re.exec: out of bounds"。"修正为"同时补充对照断言：在上述 3 块中每块同时验证 `match_str` 对相同越界参数 raise "Re.exec: out of bounds"（与 `match_str_no_bounds` 不 raise 形成对比）。"使 P2 明确为 3 块（对照合并入 3 块内），总计 7 块，与 line 108"追加 7 个 test 块"和 line 111"258/258（251+7）"一致。
