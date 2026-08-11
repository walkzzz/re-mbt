# 检查审查报告（v22 r1）

## 审查结果
APPROVED

## 发现
- **[轻微]** 块 6 未显式断言 `dummy_key` 与 `other_key` 是否落入同一 hash 桶（task_v22 §(6) 注释提到"add 覆盖同 hash 桶但 State::equal 区分"）。当前测试通过 `State::mk(1, Category::dummy(), [])` 构造 other_key，其 hash 由 `state_compute_hash` 计算，与 `State::dummy()`（hash=-1）未必同桶。但这不影响核心目标（验证 find 未命中 + 两 key 共存互不干扰），且 hash 桶分布属实现细节，测试层面难以精确控制，结论可靠。
- **[轻微]** 块 5 中 task_v22 原期望 `CompileState::get_info(cs').idx == 0`（因原计划用 struct literal 构造 idx=0 的 CompileState），实际测试改为 `assert_eq(get_info(cs_found).idx, get_info(cs0).idx)`。这是 do_v22.md 已记录的合理偏差（pub struct 字段非 pub(all) 导致 struct literal 不可用），改用从 `re.initial_states` 提取的真实 CompileState，断言改为一致性比较，语义等价，结论可靠。
