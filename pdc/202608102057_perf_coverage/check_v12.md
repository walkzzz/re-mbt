# 检查报告（v12）

## 结果
PASSED

## 检查项
| 检查项 | 方法 | 结果 |
|--------|------|------|
| 4 个 test 块已追加到 coverage_test.mbt 末尾 | 读取文件 1110-1178 行（Read 工具确认 Showing lines ... of 1178） | 通过：实际 1178 行（T11 后 1119 行 + 59 行），末尾追加 P5 分节注释 + 4 个 test 块 |
| 块 1 `str match_beginning no match raise` 构造与断言 | 核对 1124-1135 行 | 通过：`Str::regexp(sb_cov("abc"))` → `Str::string_match(re, sb_cov("xyz"), 0)` 不匹配清空 str_state → `try { Str::match_beginning(); false } catch { _ => true }` + `assert_eq(result, true)`，与任务指令一致 |
| 块 2 `str match_end no match raise` 构造与断言 | 核对 1138-1149 行 | 通过：同块 1 清空 str_state → `Str::match_end()` raise 断言，与任务指令一致 |
| 块 3 `str matched_string no match raise` 构造与断言 | 核对 1152-1163 行 | 通过：同块 1 清空 str_state → `Str::matched_string(sb_cov("xyz"))` raise 断言，与任务指令一致 |
| 块 4 `str group_beginning out of bounds raise` 构造与断言 | 核对 1166-1178 行（13 行） | 通过：1167 `Str::regexp(sb_cov("abc"))` → 1169 `Str::string_match(re, sb_cov("abc"), 0)` 匹配成功 → 1171-1177 `try { Str::group_beginning(5); false } catch { _ => true }` + `assert_eq(result, true)`，1178 `}`，与任务指令一致 |
| 4 个块均使用指定 raise 断言模式 | 逐块核对 try/catch/assert_eq 结构（块1:1128-1134, 块2:1142-1148, 块3:1156-1162, 块4:1171-1177） | 通过：均为 `try { <call>; false } catch { _ => true }` + `assert_eq(result, true)` |
| 覆盖 str.mbt 正确 raise 路径 | 阅读 str.mbt:83-112 | 通过：match_beginning(83-88)/match_end(91-96)/matched_string(99-104) 的 `None => fail("Str: no match")` 分支存在；group_beginning(107-112) 的 `Some(m) => GroupT::start(m, n)` 越界路径存在 |
| 覆盖 group.mbt 越界 raise 路径（块 4 链路独立验证） | 阅读 group.mbt:30-43 | 通过：`GroupT::start`(38-43) `None => fail("Group.start: not found")`；`GroupT::start_opt`(30-35) → `GroupT::offset_opt` → `MarkInfos::offset` 返回 None 链路存在，n=5 越界触发该路径 |
| str_state 清空机制正确 | 核对 str.mbt:58-69 | 通过：`Str::string_match` 不匹配时 `str_state.val = None`（65 行），re.mtch 带 `^` 锚点（str.mbt:18），`abc` 对 `xyz` 在 pos=0 不匹配 |
| moon test 272/272 全绿 | 运行 `moon test` | 通过：`Total tests: 272, passed: 272, failed: 0.`，268+4=272 与预期一致 |
| moon check 26 warnings baseline | 运行 `moon check` | 通过：`26 warnings, 0 errors`，与 baseline 一致，无新 warning |
| 仅追加测试未修改源码 | 对比任务约束 | 通过：仅 coverage_test.mbt 修改，str.mbt/group.mbt 等源码未动 |
| do_v12.md 报告内容准确性 | 阅读并逐项核对行号 | 部分通过：新增块清单、覆盖说明、moon test/check 结果、P5 对应关系均与实际一致；**但行号陈述有误**：do_v12.md 产出清单称"1119 → 1171 行，+52 行"（实际 1119 → 1178 行，+59 行），新增块清单称块 4 在 1166-1171 行（实际 1166-1178 行）。任务核心内容正确，行号为报告事实性偏差 |
| snake_case 命名 / 未修改 mbti | 检查测试名与 git status | 通过：测试名沿用现有空格分隔描述风格（与 :881/:888 一致），无 mbti 修改 |

## 发现的问题（报告事实性偏差，不影响任务执行正确性）
1. **do_v12.md 行号错误**：产出清单"1119 → 1171 行，+52 行"应为"1119 → 1178 行，+59 行"；新增块清单块 4 行号"1166-1171"应为"1166-1178"。do_v12.md 对块 4 行号的陈述少计 7 行（1172-1178 即 `let _ = Str::group_beginning(5)` 至闭合 `}`）。
2. 此系 Doer 报告事实性偏差，非任务执行缺陷：moon test 272/272 全绿直接证明 4 个块语法/语义正确，块 4 完整结构经本次独立核对确认无误。

## 总结
Doer 严格按 task_v12.md 执行：向 re/coverage_test.mbt 末尾追加 P5 分节注释 + 4 个 Str OCml 风格 API 错误路径 test 块，块命名/构造/断言模式/覆盖路径均与任务指令一致；moon test 272/272 全绿（268+4），moon check 26 warnings baseline 维持，无回归。任务核心要求全部满足。do_v12.md 存在行号事实性偏差（1171 应为 1178、+52 应为 +59、块 4 1166-1171 应为 1166-1178），不影响任务执行正确性，已在检查项中如实记录。

## 修订说明（v12 r1）

| 审查意见 | 修改措施 |
|---------|---------|
| 行号事实错误：检查报告多处称 1171 行/块 4 1166-1171，实际 1178 行/块 4 1166-1178 | 重新读取 coverage_test.mbt 1110-1178 行确认；修正检查项第 1 行（1171→1178、+52→+59）、第 4 行（块 4 1166-1171→1166-1178，补充 1167/1169/1171-1177/1178 逐行核对）、第 5 行（补充各块 try/catch 行号区间）；新增"发现的问题"节明确记录 |
| do_v12.md 行号错误未被发现：do_v12.md 称 1171 行/+52 行/1166-1171，检查报告原称"报告内容准确" | 修正"do_v12.md 报告内容准确"检查项为"部分通过"，明确标注行号陈述有误（1171→1178、+52→+59、块 4 1166-1171→1166-1178）；在"发现的问题"节逐条列出 |
| 未独立验证 group.mbt:38-43 越界 raise 路径 | 新增检查项"覆盖 group.mbt 越界 raise 路径（块 4 链路独立验证）"，阅读 group.mbt:30-43 确认 `GroupT::start` None 分支及 `start_opt`→`offset_opt`→`MarkInfos::offset` 链路 |
