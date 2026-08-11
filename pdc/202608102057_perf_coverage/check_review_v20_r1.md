# 检查审查报告（v20 r1）

## 审查结果
APPROVED

## 发现
- **[轻微]** check_v20.md 第 18 项"moon check 无新 warning"记录为 22 warnings baseline，而 task_v20.md 已有产出上下文记载"26 warnings baseline"。该差异可能源自前序轮次的 warning 治理，不属于本轮检查范围（审查员可见性限制：无法访问前序轮次产出），且本轮 moon check 实测 22 warnings 均为 struct_never_constructed / unused_value / unused_constructor 类型，与源码静态属性匹配，无证据表明本轮引入新 warning。不影响 PASSED 结论。

## 独立验证证据
1. **4 个 test 块实际存在且实现正确**：读取 re/coverage_test.mbt:1180-1253，确认 4 个 test 块行号与 do_v20.md/check_v20.md 完全一致（:1182-1199 / :1201-1218 / :1220-1237 / :1239-1253）。块 1-3 采用 compile(Ast::seq([Ast::str(sb_cov("a")), Ast::group(Ast::str(sb_cov("b")))])) + exec_opt(re, sb_cov("ab")) 获取 g，用 idx=99 触发越界，try { ... false } catch { _ => true } + assert_eq(result, true) 模式断言 raise。块 4 用 GroupT::create(s, marks, pmarks, gpos, 1) 直接构造，7 项 assert_eq 断言全部 present 且与 task_v20.md §(4) 要求一致。
2. **raise 路径源码验证**：读取 re/group.mbt:22-27/38-43/54-59，确认 GroupT::offset/start/stop 越界时分别 fail("Group.offset: not found") / fail("Group.start: not found") / fail("Group.stop: not found")，块 1-3 用 idx=99 触发 MarkInfos::offset(t, 99) → stop_i=199 >= table.length() → None → fail 路径正确。
3. **GroupT::create 签名验证**：读取 re/compile.mbt:618-626，确认 pub fn GroupT::create(s, marks, pmarks, gpos, gcount) 5 参数直接构造，块 4 调用顺序 (s, marks, pmarks, gpos, 1) 与签名一致。
4. **MarkInfos::make 行为推演验证**：读取 re/mark_infos.mbt:11-24，marks=[(0,0),(1,1)] → len=2, table=[0,1]；has(t,0)=true (table[0]=0≠-1), has(t,1)=false (2*1=2>=2), offset(t,0)=Some((0,1))。块 4 断言 (b)(c)(d) 与此推演一致。
5. **moon test 实测**：独立运行 `moon test`，结果 "Total tests: 311, passed: 311, failed: 0"，与 check_v20.md 第 17 项一致（307+4=311）。
6. **moon check 实测**：独立运行 `moon check`，结果 "22 warnings, 0 errors"，均为 struct_never_constructed / unused_value / unused_constructor baseline，与 check_v20.md 第 18 项一致。
7. **检查覆盖度评估**：check_v20.md 共 12 项检查，覆盖任务要求的所有关键方面——4 个 test 块内容、覆盖的 API/分支、raise 路径源码、构造器签名、MarkInfos 行为、moon test、moon check、约束遵守、报告完整性。无遗漏维度。
8. **检查方法可靠性**：check_v20.md 每项检查均实际读取文件或运行命令，非纸面推演。PASSED 结论有实测证据支撑。
