# 任务指令（v17）

## 动作
NEW

## 任务描述
执行 coverage_gap_analysis.md §4 优先级 P10（阶段二方法第 3 步"补充缺失测试"），向 `re/basics_test.mbt` 末尾追加 7 个 test 块，覆盖 cset 边界条件（coverage_gap_analysis.md §3.3 cset 边界缺口）。

### 块规格

**(1) 块 1 `cset empty operations boundary`**
验证空集与 union/inter/diff 的组合：
- `Cset::union(Cset::empty(), Cset::empty()).intervals == []`
- `Cset::inter(Cset::empty(), Cset::seq(0, 255)).intervals == []`
- `Cset::diff(Cset::seq(0, 255), Cset::empty()).intervals == [(0, 255)]`
- `Cset::diff(Cset::empty(), Cset::seq(0, 255)).intervals == []`

**(2) 块 2 `cset cany combinations`**
验证全集 cany 与 union/inter/diff 的组合：
- `Cset::union(Cset::cany(), Cset::single(65)).intervals == [(0, 255)]`
- `Cset::inter(Cset::cany(), Cset::single(65)).intervals == [(65, 65)]`
- `Cset::diff(Cset::cany(), Cset::cany()).intervals == []`

**(3) 块 3 `cset single boundary 0 and 255`**
验证单元素边界值：
- `Cset::single(0).intervals == [(0, 0)]` + `Cset::mem(0, Cset::single(0)) == true` + `Cset::mem(-1, Cset::single(0)) == false`
- `Cset::single(255).intervals == [(255, 255)]` + `Cset::mem(255, Cset::single(255)) == true` + `Cset::mem(256, Cset::single(255)) == false`

**(4) 块 4 `cset complement via diff cany`**
验证 `Cset::diff(Cset::cany(), x)` 等价于补集：取 x = `Cset::seq(65, 90)`（A-Z），compl = `Cset::diff(Cset::cany(), x)`，断言：
- `Cset::mem(64, compl) == true`
- `Cset::mem(65, compl) == false`
- `Cset::mem(90, compl) == false`
- `Cset::mem(91, compl) == true`
- `Cset::mem(0, compl) == true`
- `Cset::mem(255, compl) == true`

**(5) 块 5 `cset full 256 traversal mem`**
验证 0..255 全遍历 mem 对代表性 csets。用 for 循环遍历 0..=255 逐字节断言：
- 对 `Cset::cany()` 全部 mem=true
- 对 `Cset::empty()` 全部 mem=false
- 对 `Cset::single(65)` 仅 65 为 true 其余 false
- 对 `Cset::seq(48, 57)`（0-9 数字）48-57 为 true 其余 false

**(6) 块 6 `cset union_singles non-decreasing input`**
验证 `Cset::union_singles_in_strictly_decreasing_order` 对非递减顺序输入的处理：传入 `[5, 3, 3, 1]`（非严格递减，含重复）。函数按 strictly decreasing 假设合并相邻区间，非递减输入会产生重叠/错误合并，测试记录实际行为而非断言特定结果——先调用确认不 raise，再断言 `result.intervals.length() >= 1`。

**(7) 块 7 `cset case_insens latin1 and predefined`**
验证 case_insens 在 latin1 128-255 范围的大小写处理 + calnum/calpha/clower/cword 预定义集：
- case_insens 部分：`Cset::case_insens(Cset::single(192))`（192=À）应包含 192 和 224（à），断言 `Cset::mem(192, ci) == true` + `Cset::mem(224, ci) == true`
- 预定义集部分：
  - `Cset::calnum()` 含 65(A)/97(a)/48(0)/170(ª)/181(µ)/223(ß)/255(ÿ)
  - `Cset::calpha()` 含 65/97/170 但不含 48
  - `Cset::clower()` 含 97(a)/224(à) 但不含 65(A)
  - `Cset::cword()` 含 95(_)/65/97/48 但不含 32(空格)

每块用 assert_eq 直接断言。

### 验证标准
- 运行 `moon test` 确认 298/298（291+7）全绿
- 运行 `moon check` 确认无新 warning（baseline 26 warnings）

### 预期产出
- 修改 `re/basics_test.mbt`：末尾追加 7 个 test 块
- 产出 `do_v17.md`：测试补充报告，含新增 test 块清单、每个块覆盖的 API/分支、moon test 结果、moon check 结果、与 coverage_gap_analysis.md P10 的对应关系

## 选择理由
T16（P9）已 PASSED，coverage_gap_analysis.md §4 下一优先级为 P10（中风险 × 低难度 × 高价值：cset 是匹配热路径，边界条件覆盖不足）。当前 basics_test.mbt 19 个 test 块覆盖 cset 基本操作（empty/single/cany/union/inter/diff/cdigit/set/one_char）+ Pmark/Category/BitVector/HashSet，但 §3.3 cset 边界缺口（空集组合/全集组合/单元素边界 0 和 255/互补验证/256 全遍历/union_singles 非递减/case_insens 128-255/calnum/calpha/clower/cword 预定义集）全部未覆盖。P10 共 7 个 test 块，每块 5-15 行，难度低（Cset API 签名简单，边界值明确），风险中（cset 是匹配热路径，边界条件影响匹配正确性），价值高（cset 边界是核心模块基础正确性）。符合 task.md 阶段二重点覆盖方向 (a) 核心模块边界条件。

## 任务上下文
- `re/basics_test.mbt` 当前 167 行 19 个 test 块（cset 11 块 + Pmark 2 块 + Category 2 块 + BitVector 1 块 + HashSet 2 块 + cset set/one_char 1 块）
- Cset API：
  - `Cset::empty()`（cset.mbt:228）返回 {intervals: []}
  - `Cset::single(c:Int)`（:240，经 cset_single_cache）返回 {intervals: [(c, c)]}
  - `Cset::cany()`（:234）返回 {intervals: [(0, 255)]}
  - `Cset::seq(c:Int, cp:Int)`（:271，c<=cp 则 [(c,cp)] 否则 [(cp,c)]）
  - `Cset::union/inter/diff`（:105/:166/:189）双指针合并/相交/差集
  - `Cset::mem(c:Int, s)`（:338，线性扫描 intervals）
  - `Cset::union_singles_in_strictly_decreasing_order(cs:Array[Int])`（:384，假设 strictly decreasing 合并相邻区间）
  - `Cset::case_insens(s)`（:567，union_all [s, offset(32, inter(s, upper)), offset(-32, inter(s, clower))]）
  - `Cset::calnum()/calpha()/clower()/cword()`（:562/:557/:532/:576，预定义集 cset_calnum/cset_calpha/cset_clower/cset_cword）
- 预定义集定义：
  - cset_upper（:423）= union_all [iseq(65,90), iseq(192,214), iseq(216,222)]
  - cset_clower（:430）= offset(32, cset_upper) 即 97-122/224-246/248-254
  - cset_calpha（:449）= union(cset_clower, cset_upper) + {170,181,186,223,255}
  - cset_calnum（:461）= union(cset_calpha, cset_cdigit)
  - cset_cword（:464）= cadd('_', cset_calnum)
- T16 后 291/291 为基线，预期 298/298
- 约束：纯 MoonBit 无 C FFI，snake_case 命名，不修改 pkg.generated.mbti，不修改源码（仅追加测试），保持与 OCaml 上游行为一致性，保持 latin1 大小写处理，不运行 benchmark

## 已有产出上下文
- 阶段一性能优化已完成 T1-T7（T3 大收益 -39.95%、T5 小收益 -3.02%，T4/T6/T7 负改进回退，T5-skip mbti BLOCKED），Section 1 累计 -46.9%
- 阶段二测试覆盖率提升已完成 T8（coverage_gap_analysis.md 413 API/219 覆盖/194 未覆盖/53.0%）+ T9（P1-P2 core API 7 块）+ T10（P3 前端解析错误路径 7 块）+ T11（P4 Pcre 高级 API 3 块）+ T12（P5 Str API 4 块）+ T13（P6 ParseBuffer 6 块）+ T14（P7 Desc 6 块）+ T15（P8 Expr::rename 4 块）+ T16（P9 Ast::colorize 3 块）
- 当前 moon test 291/291 全绿，moon check 26 warnings baseline
- coverage_gap_analysis.md §4 优先级 P10-P15 剩余 6 项待处理
