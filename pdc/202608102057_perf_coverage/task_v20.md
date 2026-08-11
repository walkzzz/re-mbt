# 任务指令（v20）

## 动作
NEW

## 任务描述
执行 coverage_gap_analysis.md §4 优先级 P13（阶段二方法第 3 步"补充缺失测试"），向 `re/coverage_test.mbt` 末尾追加 4 个 test 块，覆盖 `GroupT::offset` / `GroupT::start` / `GroupT::stop` 的越界 raise 路径 + `GroupT::create` 直接构造与基本操作。具体：

(1) **块 1 `GroupT::offset out of bounds raise`**——通过 `exec_opt` 获取一个含捕获组的 GroupT 实例 g（正则 `Ast::seq([Ast::str(sb_cov("a")), Ast::group(Ast::str(sb_cov("b")))])` 匹配 "ab"，有 group 0 整体 + group 1 捕获组），用越界 idx `99` 调用 `GroupT::offset(g, 99)`，断言 raise（group.mbt:22-27 `match GroupT::offset_opt(g, i) { None => fail("Group.offset: not found") }`）。用 `try { let _ = GroupT::offset(g, 99); false } catch { _ => true }` + `assert_eq(result, true)` 模式断言 raise。

(2) **块 2 `GroupT::start out of bounds raise`**——同块 1 获取 g，用越界 idx `99` 调用 `GroupT::start(g, 99)`，断言 raise（group.mbt:38-43 `match GroupT::start_opt(g, i) { None => fail("Group.start: not found") }`）。用同样的 try-catch + assert_eq 模式。

(3) **块 3 `GroupT::stop out of bounds raise`**——同块 1 获取 g，用越界 idx `99` 调用 `GroupT::stop(g, 99)`，断言 raise（group.mbt:54-59 `match GroupT::stop_opt(g, i) { None => fail("Group.stop: not found") }`）。用同样的 try-catch + assert_eq 模式。

(4) **块 4 `GroupT::create direct construction`**——直接用 `GroupT::create` 构造一个 GroupT 实例，验证构造器及基本操作 API（`GroupT::nb_groups` / `GroupT::get` / `GroupT::offset` / `GroupT::start` / `GroupT::stop` / `GroupT::matched`）行为正确。具体构造：`s = sb_cov("hello")`（5 字节），`marks = MarkInfos::make([(0, 0), (1, 1)])`（group 0 的 start_mark=0、stop_mark=1，table=[0, 1]），`pmarks = PmarkSet::empty()`，`gpos = [0, 5]`（mark 0 → 位置 0，mark 1 → 位置 5），`gcount = 1`。断言：(a) `GroupT::nb_groups(g) == 1`；(b) `GroupT::matched(g, 0) == true`；(c) `GroupT::matched(g, 1) == false`（越界 group 不存在）；(d) `GroupT::offset(g, 0) == (0, 5)`（g.gpos[0]=0, g.gpos[1]=5）；(e) `GroupT::start(g, 0) == 0`；(f) `GroupT::stop(g, 0) == 5`；(g) `bs_cov(GroupT::get(g, 0).unwrap()) == "hello"`（s[0..5]）。用 assert_eq 直接断言。

完成后运行 `moon test` 确认 311/311（307+4）全绿，运行 `moon check` 确认无新 warning。产出测试补充报告 do_v20.md（含新增 test 块清单、每个块覆盖的 API/分支、moon test 结果、moon check 结果、与 coverage_gap_analysis.md P13 的对应关系）。

## 选择理由
T19（P12）已 PASSED，coverage_gap_analysis.md §4 下一优先级为 P13（中风险 × 低难度 × 中价值：GroupT 异常路径和构造器未测）。当前 coverage_test.mbt 中 GroupT 测试覆盖了 `get_opt` / `offset_opt` / `start_opt` / `stop_opt` / `pmarks` 的正向路径（:562-633）+ `exec` + `GroupT::start(g, 0)` 正向（:732）+ `GroupT::get` 正向（:805-826），但 `GroupT::offset` / `GroupT::start` / `GroupT::stop` 三个 raise API 的越界 raise 路径（group.mbt:22-27/38-43/54-59）完全未测——coverage_gap_analysis.md §3.4 分支覆盖缺口明确列出"GroupT::offset 越界 raise / GroupT::start 越界 raise / GroupT::stop 越界 raise"三项未覆盖，§2.7 GroupT 模块未覆盖明细列出 `GroupT::create` / `offset` / `start_offset` / `stop_offset` 未直接测试。P13 共 4 个 test 块，每块 6-12 行，难度低（GroupT 实例可通过 exec_opt 获取或 GroupT::create 直接构造，raise 路径明确），风险中（GroupT 是匹配结果核心载体，异常路径影响调用方错误处理），价值中（GroupT API 完整性）。符合 task.md 阶段二重点覆盖方向 (a) 核心模块边界条件 + (b) 错误路径和异常处理。

## 任务上下文
`GroupT` 定义于 compile.mbt:609-615 `pub struct GroupT { s : Bytes; marks : MarkInfos; pmarks : PmarkSet; gpos : Array[Int]; gcount : Int }`，`GroupT::create`（compile.mbt:618-626）接受 5 参数直接构造。`GroupT::offset`（group.mbt:22-27）签名 `pub fn GroupT::offset(g : GroupT, i : Int) -> (Int, Int) raise`，越界时 `fail("Group.offset: not found")`。`GroupT::start`（group.mbt:38-43）越界时 `fail("Group.start: not found")`。`GroupT::stop`（group.mbt:54-59）越界时 `fail("Group.stop: not found")`。三者均通过 `GroupT::offset_opt` / `start_opt` / `stop_opt`（返回 Option）实现，越界时 Option 为 None 触发 fail。`MarkInfos::make(marks : Array[(Int, Int)])`（mark_infos.mbt:11-24）创建扁平 table：marks=[(0, 0), (1, 1)] → table=[0, 1]，group i 的 start=table[2*i]、stop=table[2*i+1]，-1=absent。`MarkInfos::offset(t, i)`（:71-85）i 越界（2*i+1 >= table.length()）或 start==-1 返回 None。`MarkInfos::has(t, i)`（:27-33）2*i >= table.length() 返回 false，否则 table[2*i] != -1。`PmarkSet::empty()`（pmark.mbt:52）构造空 PmarkSet。`GroupT::get(g, i)`（compile.mbt:629-647）返回 Bytes?，通过 MarkInfos::offset 获取 (start, stop) mark 索引，再 g.gpos[start]/g.gpos[stop] 取实际位置，s_start..s_stop 切片。`GroupT::nb_groups(g)`（group.mbt:67-69）返回 g.gcount。coverage_test.mbt 已有辅助函数 `sb_cov`（:4 String→Bytes）、`bs_cov`（:13 Bytes→String），已有 `exec_opt` + `GroupT::get_opt` / `offset_opt` / `start_opt` / `stop_opt` 正向测试（:562-633）可参考。T19 后 307/307 为基线，预期 311/311。约束：纯 MoonBit 无 C FFI，snake_case 命名，不修改 pkg.generated.mbti，不修改源码（仅追加测试），保持与 OCaml 上游行为一致性，保持 latin1 大小写处理，不运行 benchmark。

## 已有产出上下文
阶段一性能优化已完成 T1-T7（T3 大收益 -39.95% + T5 小收益 -3.02%，T4/T6/T7 负改进回退，T5-skip mbti BLOCKED），Section 1 累计 -46.9%。阶段二覆盖率已完成 T8 差距分析 + T9-T19 共 11 个优先级（P1-P12）的测试补充：P1-P2 match_str 四象限+越界（T9，258/258）、P3 前端解析错误路径（T10，265/265）、P4 Pcre 高级 API raise（T11，268/268）、P5 Str OCaml 风格 API 错误路径（T12，272/272）、P6 ParseBuffer::integer 错误路径（T13，278/278）、P7 Desc::initial/status/remove_duplicates（T14，284/284）、P8 Expr::rename 导数正确性（T15，288/288）、P9 Ast::colorize+ColorMap::split 一致性（T16，291/291）、P10 cset 边界（T17，298/298）、P11 PerlOpt 各 opt（T18，303/303）、P12 PcreFlag 各 flag（T19，307/307）。当前 moon test 307/307 全绿，moon check 26 warnings baseline。coverage_gap_analysis.md §4 剩余优先级：P13（本轮）、P14（Str 高级 API）、P15（CompileIdx+StateHashTable）。
