# 执行审查报告（v20 r1）

## 审查结果
APPROVED

## 发现
- **[轻微]** do_v20.md §3 验证部分记录 `moon check` 22 warnings，而 task_v20.md 已有产出上下文记为 26 warnings baseline。实际复跑 `moon check` 确认为 22 warnings, 0 errors，均为既有 `struct_never_constructed` / `unused_constructor` warning，未因新增测试引入新 warning。该差异不影响正确性，仅是 baseline 数字与当前实际不一致（可能前序轮次已减少 warning），Doer 报告的当前数字准确。

## 验证要点
1. **产出覆盖度**：coverage_test.mbt 末尾确实追加 4 个 test 块（:1182-1253），块 1 `GroupT::offset out of bounds raise`、块 2 `GroupT::start out of bounds raise`、块 3 `GroupT::stop out of bounds raise`、块 4 `GroupT::create direct construction`，与 task_v20.md 要求的 4 块完全对应。
2. **源码引用准确性**：group.mbt:22-27/38-43/54-59 三个 raise API 签名与 fail 消息核对一致；compile.mbt:609-615 GroupT 结构、:618-626 GroupT::create、:629-647 GroupT::get 行为核对一致；mark_infos.mbt:11-24 MarkInfos::make([(0,0),(1,1)]) → table=[0,1] 行为核对一致。
3. **块 1-3 raise 路径**：通过 `compile(Ast::seq([Ast::str("a"), Ast::group(Ast::str("b"))]))` + `exec_opt(re, "ab")` 获取含捕获组的 GroupT，用越界 idx=99 调用三个 raise API，采用 `try { ... false } catch { _ => true }` + `assert_eq(result, true)` 模式断言 raise，与现有 `str group_beginning out of bounds raise`（:1166-1178）模式一致。
4. **块 4 直接构造**：`s=sb_cov("hello")`、`marks=MarkInfos::make([(0,0),(1,1)])`、`pmarks=PmarkSet::empty()`、`gpos=[0,5]`、`gcount=1`，7 项断言均正确：(a) nb_groups==1、(b) matched(0)==true、(c) matched(1)==false（2*1>=table.length()=2）、(d) offset(0)==(0,5)、(e) start(0)==0、(f) stop(0)==5、(g) get(0).unwrap()=="hello"（s[0..5] 切片）。
5. **moon test**：复跑确认 Total tests: 311, passed: 311, failed: 0（307+4=311，全绿）。
6. **moon check**：复跑确认 22 warnings, 0 errors，无新 warning 引入。
7. **约束遵守**：纯 MoonBit 无 C FFI、snake_case 命名、仅追加测试未修改源码、未修改 pkg.generated.mbti，符合 task.md 全部约束。
