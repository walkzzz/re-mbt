# 检查报告（v17）

## 结果
PASSED

## 检查项
| 检查项 | 方法 | 结果 |
|--------|------|------|
| 7 个 test 块已追加到 basics_test.mbt 末尾 | 读取 `re/basics_test.mbt`，统计 test 块数量与起止行 | 通过：原 19 块（行 1-167）→ 现 26 块（行 1-256），新增 7 块位于行 169-256，全部追加在末尾 |
| 块 1 `cset empty operations boundary` 符合规格 | 对比 task_v17.md §块规格 (1) 与文件行 170-175 | 通过：4 个 assert_eq 完全匹配（empty∪empty=[]、empty∩seq(0,255)=[]、seq(0,255)\empty=[(0,255)]、empty\seq(0,255)=[]） |
| 块 2 `cset cany combinations` 符合规格 | 对比 task_v17.md §块规格 (2) 与文件行 178-182 | 通过：3 个 assert_eq 完全匹配（cany∪single(65)=[(0,255)]、cany∩single(65)=[(65,65)]、cany\cany=[]） |
| 块 3 `cset single boundary 0 and 255` 符合规格 | 对比 task_v17.md §块规格 (3) 与文件行 185-194 | 通过：6 个 assert_eq 完全匹配（single(0)=[(0,0)]+mem(0)=true+mem(-1)=false、single(255)=[(255,255)]+mem(255)=true+mem(256)=false） |
| 块 4 `cset complement via diff cany` 符合规格 | 对比 task_v17.md §块规格 (4) 与文件行 197-206 | 通过：6 个 assert_eq 完全匹配（x=seq(65,90)，compl=diff(cany,x)，mem(64)=true/mem(65)=false/mem(90)=false/mem(91)=true/mem(0)=true/mem(255)=true） |
| 块 5 `cset full 256 traversal mem` 符合规格 | 对比 task_v17.md §块规格 (5) 与文件行 209-220 | 通过：for c in 0..<256 循环，每字节 4 个 assert_eq（cany全true、empty全false、single(65)仅65true、seq(48,57)仅48-57true），共 1024 断言 |
| 块 6 `cset union_singles non-decreasing input` 符合规格 | 对比 task_v17.md §块规格 (6) 与文件行 223-226 | 通过：调用 union_singles_in_strictly_decreasing_order([5,3,3,1]) 不 raise + assert_true(length>=1)。注：用 assert_true 而非 assert_eq 符合规格"记录实际行为而非断言特定结果" |
| 块 7 `cset case_insens latin1 and predefined` 符合规格 | 对比 task_v17.md §块规格 (7) 与文件行 229-256 | 通过：case_insens(single(192)) mem(192)=true/mem(224)=true；calnum 含 65/97/48/170/181/223/255；calpha 含 65/97/170 不含 48；clower 含 97/224 不含 65；cword 含 95/65/97/48 不含 32，共 18 断言 |
| moon test 全绿 | 运行 `moon test` | 通过：Total tests: 298, passed: 298, failed: 0（291+7=298，符合预期） |
| moon check 无新 warning | 运行 `moon check` | 通过：26 warnings 0 errors，与 baseline 26 warnings 一致 |
| 命名风格 snake_case | 检查新增 test 块名与 API 调用 | 通过：test 块名用空格分隔小写英文，API 用 snake_case（union_singles_in_strictly_decreasing_order、case_insens、calnum/calpha/clower/cword） |
| 不修改源码 | 确认仅 basics_test.mbt 被修改 | 通过：do_v17.md 产出清单仅列 `re/basics_test.mbt`，无源码修改 |
| do_v17.md 报告完整性 | 读取 do_v17.md，核对报告结构 | 通过：含概述、产出清单、新增 test 块清单、执行过程（基线确认/API 签名核实/case_insens 推导/测试编写/验证）、偏差说明；与 task_v17.md §预期产出一致 |

## 总结
任务核心要求全部满足：7 个 test 块严格按 task_v17.md §块规格追加到 `re/basics_test.mbt` 末尾，覆盖 §3.3 cset 边界缺口全部 7 项（空集组合/全集组合/单元素边界 0 和 255/互补验证/256 全遍历/union_singles 非递减/case_insens 128-255 + 预定义集）；moon test 298/298 全绿（291+7=298）；moon check 26 warnings baseline 不变；纯 MoonBit 无 C FFI，snake_case 命名，不修改源码。

附注（不影响 PASSED）：do_v17.md §产出清单中"167 行 → 231 行"描述有误，实际文件 167 行 → 256 行（新增 89 行非 64 行），此为 Doer 报告的行数计算偏差，不影响任务实质完成度。
