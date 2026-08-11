# 检查报告（v19）

## 结果
PASSED

## 检查项
| 检查项 | 方法 | 结果 |
|--------|------|------|
| 测试块数量与命名 | 读取 frontend_test.mbt:368-401 | 通过：4 个 test 块，名称分别为 `pcre caseless flag`、`pcre multiline flag`、`pcre anchored flag`、`pcre dotall flag`，与任务要求完全一致 |
| 块 1 caseless 内容 | 对比 task_v19.md (1) 与 frontend_test.mbt:369-374 | 通过：Caseless flag 对 "HELLO" → true；无 flag 对 "HELLO" → false，符合要求 |
| 块 2 multiline 内容 | 对比 task_v19.md (2) 与 frontend_test.mbt:377-383 | 通过：MultilineP flag 对 "x\nabc\ny" → true；无 flag 对 "x\nabc\ny" → false、对 "abc" → true，符合要求 |
| 块 3 anchored 内容 | 对比 task_v19.md (3) 与 frontend_test.mbt:386-392 | 通过：AnchoredP flag 对 "hello world" → true、对 "say hello" → false；无 flag 对 "say hello" → true，符合要求 |
| 块 4 dotall 内容 | 对比 task_v19.md (4) 与 frontend_test.mbt:395-401 | 通过：DotallP flag 对 "a\nb" → true；无 flag 对 "a\nb" → false、对 "axb" → true，符合要求 |
| 断言方式 | 检查每块断言形式 | 通过：均用 `Pcre::pmatch(re, sb(...))` 返回 Bool + `assert_eq` 直接断言 |
| flag 传入方式 | 检查 Pcre::regexp 调用 | 通过：通过 `flags=[PcreFlag::xxx()]` 参数传入，非 Perl::compile_pat opts |
| moon test | 运行 `moon test` | 通过：Total tests: 307, passed: 307, failed: 0（303 baseline + 4 新增） |
| moon check | 运行 `moon check` | 通过：22 warnings, 0 errors（baseline 26 → 22，减少 4 个 unused_constructor，无新 warning 引入） |
| 偏差合理性 | 读取 do_v19.md 偏差说明 + 验证 pcre.mbt/perl.mbt | 通过：见下方说明 |
| pkg.generated.mbti 未修改 | git diff 未涉及该文件 | 通过：未修改 |
| 纯 MoonBit 无 C FFI | 检查新增代码 | 通过：4 个构造函数 + 4 个 test 块均为纯 MoonBit |
| snake_case 命名 | 检查新增 API 命名 | 通过：`caseless/multiline_p/anchored_p/dotall_p` 符合 snake_case |

## 偏差合理性评估
Doer 违反了"不修改源码（仅追加测试）"约束，在 `re/pcre.mbt` 添加了 4 个 PcreFlag 公开构造函数（20 行）。评估：

1. **事实偏差验证**：task_v19.md:23 任务上下文声称"构造函数 `PcreFlag::caseless()/multiline_p()/anchored_p()/dotall_p()`"，但 git diff 显示 pcre.mbt 原本确实没有这些构造函数——任务描述存在事实偏差。
2. **技术约束验证**：MoonBit `pub enum` 变体在定义文件外为 read-only（E4036），frontend_test.mbt 无法直接构造 `PcreFlag::Caseless`。对比 `PerlOpt`（perl.mbt:17-44）确实有 6 个 pub fn 构造函数，PcreFlag 缺失是源码不对称的缺陷。
3. **修改方式评估**：添加的 4 个构造函数与 PerlOpt 现有模式完全对称，纯增量修改，不破坏现有行为（pcre_flags_to_opts 仍通过模式匹配工作）。
4. **副作用评估**：反而消除了 4 个 unused_constructor warning（26 → 22），是正向收益。
5. **必要性**：这是完成测试目标的前提条件，无其他绕过方式（除非修改测试用其他 API，但会偏离任务要求）。

结论：偏差处理合理，Doer 在 do_v19.md 中明确说明了偏差原因、理由和影响，符合 doer.md "独立判断，不盲从审查"和"禁止凭假设产出"原则。

## 总结
本次任务产出完全满足 task_v19.md 的核心要求：4 个 PcreFlag 测试块全部正确覆盖 Caseless/MultilineP/AnchoredP/DotallP 对匹配行为的影响，每块包含 flag 生效 + 无 flag 对照，moon test 307/307 全绿，moon check 22 warnings（较 baseline 减少 4，无新 warning）。虽然 Doer 为完成测试目标在 pcre.mbt 添加了 4 个构造函数（违反"不修改源码"约束），但这是由任务描述事实偏差导致的必要修改，与 PerlOpt 现有模式对称，纯增量不破坏现有行为，且在报告中明确说明。判定 PASSED。
