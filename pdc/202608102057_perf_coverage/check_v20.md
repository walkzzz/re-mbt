# 检查报告（v20）

## 结果
PASSED

## 检查项
| 检查项 | 方法 | 结果 |
|--------|------|------|
| 4 个 test 块已追加到 coverage_test.mbt 末尾 | 读取 re/coverage_test.mbt:1180-1253 | 通过 — 4 个 test 块均存在，行号与 do_v20.md 一致（:1182-1199 / :1201-1218 / :1220-1237 / :1239-1253） |
| 块 1 `GroupT::offset out of bounds raise` 实现符合要求 | 对比 task_v20.md §(1) 与 coverage_test.mbt:1182-1199 | 通过 — compile(Ast::seq([Ast::str(sb_cov("a")), Ast::group(Ast::str(sb_cov("b")))])) + exec_opt(re, sb_cov("ab")) 获取 g，GroupT::offset(g, 99) 越界，try { ... false } catch { _ => true } + assert_eq(result, true) 模式断言 raise |
| 块 2 `GroupT::start out of bounds raise` 实现符合要求 | 对比 task_v20.md §(2) 与 coverage_test.mbt:1201-1218 | 通过 — 同块 1 获取 g，GroupT::start(g, 99) 越界，try-catch + assert_eq 模式断言 raise |
| 块 3 `GroupT::stop out of bounds raise` 实现符合要求 | 对比 task_v20.md §(3) 与 coverage_test.mbt:1220-1237 | 通过 — 同块 1 获取 g，GroupT::stop(g, 99) 越界，try-catch + assert_eq 模式断言 raise |
| 块 4 `GroupT::create direct construction` 实现符合要求 | 对比 task_v20.md §(4) 与 coverage_test.mbt:1239-1253 | 通过 — s=sb_cov("hello"), marks=MarkInfos::make([(0,0),(1,1)]), pmarks=PmarkSet::empty(), gpos=[0,5], gcount=1；7 项 assert_eq 断言全部 present：(a) nb_groups==1 (b) matched(g,0)==true (c) matched(g,1)==false (d) offset(g,0)==(0,5) (e) start(g,0)==0 (f) stop(g,0)==5 (g) bs_cov(get(g,0).unwrap())=="hello" |
| 覆盖 group.mbt 三个 raise 路径 | 读取 re/group.mbt:22-27/38-43/54-59 确认 raise 分支 | 通过 — GroupT::offset/start/stop 越界时分别 fail("Group.offset: not found") / fail("Group.start: not found") / fail("Group.stop: not found")，块 1-3 用 idx=99 触发 None 分支 raise |
| GroupT::create 构造器签名匹配 | 读取 re/compile.mbt:618-626 | 通过 — pub fn GroupT::create(s, marks, pmarks, gpos, gcount) 5 参数直接构造，块 4 调用顺序与签名一致 |
| MarkInfos::make 行为正确 | 读取 re/mark_infos.mbt:11-24 推演 | 通过 — marks=[(0,0),(1,1)] → len=2, table=[0,1]；has(t,0)=true (table[0]=0≠-1), has(t,1)=false (2*1>=2), offset(t,0)=Some((0,1))，与块 4 断言 (b)(c)(d) 一致 |
| moon test 全绿 | 运行 `moon test` | 通过 — Total tests: 311, passed: 311, failed: 0（307+4=311，与 do_v20.md 一致） |
| moon check 无新 warning | 运行 `moon check` | 通过 — 22 warnings, 0 errors（均为既有 struct_never_constructed / unused_value baseline，与 do_v20.md 一致，无新 warning 引入） |
| 约束遵守 | 审查产出 | 通过 — 纯 MoonBit 无 C FFI（仅追加测试使用现有 API）；snake_case 命名；未修改 pkg.generated.mbti；未修改源码（仅追加测试）；未运行 benchmark |
| do_v20.md 报告完整性 | 对比 task_v20.md 要求与 do_v20.md 内容 | 通过 — 含新增 test 块清单、每块覆盖 API/分支、moon test 结果、moon check 结果、与 P13 对应关系、偏差说明（无偏差） |

## 总结
Doer 严格按 task_v20.md 要求向 re/coverage_test.mbt 末尾追加 4 个 test 块，覆盖 GroupT::offset / start / stop 三个 raise API 的越界 raise 路径（group.mbt:22-27/38-43/54-59）及 GroupT::create 直接构造与 7 项基本操作。moon test 311/311 全绿（307+4），moon check 22 warnings 0 errors（baseline，无新 warning）。所有约束（纯 MoonBit、snake_case、不修改 mbti/源码、不运行 benchmark）均遵守。do_v20.md 报告完整准确，与实际产出一致。
