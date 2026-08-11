# 执行审查报告（v9 r1）

## 审查结果
REJECTED

## 发现

- **[一般] P2 块 5/7 命名与实际验证内容不符**：块 5 命名 `"match_str_no_bounds pos negative no raise"`、块 7 命名 `"match_str_no_bounds pos+len overflow no raise"`，命名中包含 `match_str_no_bounds` 和 `no raise`，自然读法为"验证 match_str_no_bounds 在越界参数下不 raise"。但实际块 5/7 的代码体仅调用 `match_str` 验证其 raise 行为，**完全未调用 `match_str_no_bounds`**。这违反 task_v9.md P2 章节明确要求"对每组越界参数调用 `match_str_no_bounds(...)`"。

  Doer 在 do_v9.md 偏差 1 中解释了原因：任务前提错误，`match_str_no_bounds` 在 `pos<0` 和 `pos+len>slen` 时会产生不可捕获的 RuntimeError（非 fail 异常），try-catch 无法验证不 raise。这个解释合理，Doer 无法完成不可能的验证。

  但 Doer 选择保留暗示"验证 match_str_no_bounds 不 raise"的块名，而实际未调用 match_str_no_bounds，导致块名与代码体语义脱节。test 块名是测试报告中的标识，会误导后续维护者认为块 5/7 验证了 match_str_no_bounds 的不 raise 行为。

  块内注释虽说明"故此处仅对照验证 match_str raise"，但注释无法抵消块名的语义暗示。块名应反映块的实际验证内容。

- **[轻微] P2 块 6 未按 task_v9.md 要求使用 try-catch 模式**：task_v9.md P2 章节明确要求"用 `try { ...; true } catch { _ => false }` 断言不 raise"。块 6 实际改为直接调用 `match_str_no_bounds` 并 match 返回值。

  Doer 在 do_v9.md 偏差 2 中解释：`match_str_no_bounds` 不声明 raise，try-catch 包裹会触发 `unused_try` warning，导致 moon check 从 26 增至 27 warnings，违反"无新 warning"标准。选择保留更硬性的验证标准（无新 warning），调整验证方式（直接调用），两者语义等效。

  这个调整合理——直接调用成功即证明不产生错误，语义等效于 try-catch 验证不 raise，且避免了 warning。属于验证方式的合理变通，不影响正确性。

## 修改要求（仅 REJECTED 时）

### 问题 1：P2 块 5/7 命名与实际验证内容不符

**问题是什么**：块 5/7 命名包含 `match_str_no_bounds` 和 `no raise`，暗示验证 match_str_no_bounds 的不 raise 行为，但块内代码仅调用 `match_str` 验证其 raise 行为，未调用 match_str_no_bounds。

**为什么是问题**：test 块名是测试报告中的标识符，会出现在 `moon test` 输出和后续维护者的检索中。命名暗示的验证内容与实际代码体不符，会误导后续维护者认为块 5/7 验证了 match_str_no_bounds 的不 raise 行为，影响代码可维护性。task_v9.md P2 章节明确要求"对每组越界参数调用 match_str_no_bounds(...)"，块 5/7 未调用即偏离此要求（虽有合理原因）。

**期望的修正方向**：调整块 5/7 的命名以反映实际验证内容。例如：
- 块 5：`"match_str pos negative bounds raise"`（反映实际验证 match_str 的 raise 行为）
- 块 7：`"match_str pos+len overflow bounds raise"`

或采用其他能准确反映"仅验证 match_str raise"语义的命名。保留块内注释说明为何未验证 match_str_no_bounds（现有注释已足够）。块 6 命名 `"match_str_no_bounds len below -1 no raise"` 准确（实际调用了 match_str_no_bounds），无需调整。
