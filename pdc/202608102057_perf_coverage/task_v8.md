# 任务指令（v8）

## 动作
NEW

## 任务描述
转入阶段二（测试覆盖率提升）第 1 步：分析未覆盖 pub API 和分支，产出覆盖率差距报告。

具体执行：
1. 读取 `re/pkg.generated.mbti`，提取全部 pub fn / pub struct / pub enum / pub let 的 API 面（签名、所在文件:行号、所属模块）。
2. 读取 re/ 下 9 个测试文件（含 coverage_test.mbt 103 个测试），提取所有 test 块覆盖的 API（按 test 名称和断言内容推断覆盖目标）。
3. 对照 API 面与已覆盖 API，识别未覆盖或仅浅覆盖的 pub API 及分支。
4. 产出覆盖率差距报告 `coverage_gap_analysis.md`，含：
   - **§1 API 清单总览**：按模块分组（cset / color_map / automata_state / automata_desc / automata_expr / compile / compile_translate / core / perl / posix / glob / pcre / str / re_ast / bit_vector / hash_set / dense_map 等），每模块列出 pub API 数量、已覆盖数、未覆盖数、覆盖率%。
   - **§2 未覆盖/浅覆盖 API 明细表**：每行含 API 签名、所在文件:行号、所属模块、覆盖状态（未覆盖 / 仅正向 / 仅边界缺错误路径）、推测风险等级（高/中/低）、建议测试方向（边界条件 / 错误路径 / 边缘 case / 内部操作间接测试）。
   - **§3 分支覆盖缺口**：重点列出错误路径和异常处理分支的覆盖情况，如：
     - compile 失败路径（无效 AST、空模式、嵌套深度超限等）
     - parse 错误路径（各前端解析器的语法错误、非法字符、未闭合括号等）
     - cset 边界（空集、全集、单元素、互补、256 字符全遍历）
     - automata 空状态、重复状态、死状态
     - core API 的 None/异常返回路径
   - **§4 建议补充测试优先级排序**：按 风险等级 × 覆盖难度 × 业务价值 排序，给出前 10-15 个最该补的测试目标，每项含目标 API/分支、建议测试文件（新增或追加到哪个 *_test.mbt）、建议 test 块数量、优先级理由。

约束：
- 仅分析，不改任何源码和测试代码。
- 不运行 benchmark（阶段二不关注性能）。
- 可运行 `moon test` 确认 251/251 基线（可选，用于报告开头声明基线）。
- 不修改 `re/pkg.generated.mbti`（仅作分析输入）。

预期产出：`pdc/202608102057_perf_coverage/coverage_gap_analysis.md`

## 选择理由
阶段一性能优化已充分探索 6 轮（T3-T7）：
- T3（序 1，flatten 哈希去重）PASSED 大收益 -39.95%
- T5（序 5，union_all 分治）PASSED 小收益 -3.02%
- T4（序 2，flatten 内层位图）/ T6（序 6，flatten 入口去重）/ T7（序 7，merge_sequences 迭代化）3 轮负改进回退
- T5-skip（序 3，CSetMap 哈希）mbti BLOCKED

剩余方向：序 4（A4 translate_colors 位图去重）有 T4/T6 双重同类负改进教训（位图构建固定开销 + 去重开销对当前规模超边际节省），预期负改进概率高；序 8（D1 Cset 公开表示改位图）风险高、改动面大、需全量测试；序 9（A5 Expr::rename）风险高、涉及导数正确性需与 OCaml 上游对照。task.md/hotspot_analysis.md 均标注序 8/9"放后期"。3 轮连续负改进 + 1 轮 BLOCKED 是边际收益递减的强信号。

性能优化已达成可量化目标：Section 1 951ms → 504.8ms（-46.9%，T3+T5 累计），全 section 正改进，moon test 251/251 无回归，moon check 26 warnings 无新 warning。task.md 明确"先性能后覆盖率"，阶段一已充分完成，转入阶段二。

阶段二方法第 2 步"分析未覆盖的 pub API 和分支（参考 re/pkg.generated.mbti 接口）"是后续补充测试（方法第 3 步）的前提。本任务产出差距报告，为后续 T9+ 补充测试提供精确目标清单和优先级排序，避免盲目补测试或重复覆盖。测试基线已建立（baseline.md 251/251 通过，每轮优化均跑 moon test 确认全绿），无需重复建立。

## 任务上下文
摘自 task.md 阶段二：
- 方法：(1) 运行现有测试确认全部通过（已由 baseline.md + 每轮 moon test 确认，251/251）；(2) 分析未覆盖的 pub API 和分支（参考 re/pkg.generated.mbti 接口）；(3) 补充缺失测试，重点覆盖：核心模块边界条件、错误路径和异常处理、各前端解析器边缘 case、cset/automata/compile 内部操作（通过公开 API 间接测试）。
- 现状：已有 251 个测试；coverage_test.mbt（103 个测试）专门补充 pub API 覆盖；测试层次：基础数据结构 → AST → 自动机 → 编译 → 核心 API → 各前端。
- 验证标准：moon test 全部通过；新增测试覆盖之前未覆盖的 API 和分支；无冗余/重复测试。

摘自 task.md 约束：
- 保持纯 MoonBit 实现，不引入 C FFI
- 保持与 OCaml 上游的行为一致性
- 保持 latin1 大小写处理
- 不修改 pkg.generated.mbti（由 moon info 自动生成）
- 代码命名遵循 snake_case 风格

## 已有产出上下文
工作目录 `pdc/202608102057_perf_coverage/` 已有产出：
- `baseline.md`：性能基线 + 测试基线（251/251 通过，0.21s）
- `hotspot_analysis.md`：compile 路径热点分析（12 个热点函数 H1-H12、3 类优化方向、10 项优先级排序）
- `opt_v3.md` ~ `opt_v7.md`：5 轮性能优化报告（T3/T4/T5/T6/T7，其中 T3/T5 正改进保留，T4/T6/T7 负改进回退）
- `plan.md`：完整计划日志（R1-R9，含 6 轮性能优化决策记录）
- `do_v1.md` ~ `do_v7.md`、`check_v1.md` ~ `check_v7.md`：7 轮执行/检查报告

当前代码状态：T5 后版本（HEAD e64ec54，working tree clean）
- `re/color_map.mbt`：含 T3 改动（flatten 哈希去重 + ids 复用）
- `re/cset.mbt`：含 T5 改动（union/inter/diff result 预分配 capacity + union_all/intersect_all 分治归并）
- 其他 re/ 源文件：原始版本
- `re/pkg.generated.mbti`：未修改（moon info 自动生成）

阶段二本任务为首个子任务，无前序阶段二产出。
