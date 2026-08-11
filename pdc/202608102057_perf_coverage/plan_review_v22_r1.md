# 计划审查报告（v22 r1）

## 审查结果
APPROVED

## 发现
- **[轻微]** plan.md R23 NEW 上下文行引用 "State（automata_state.mbt:6-23）" 行号范围偏宽（实际 pub struct State 定义于 :15-21，:6-23 含上方 Ctx priv enum 注释区），不影响 task_v22.md 执行正确性（task_v22.md 未引用具体行号，仅描述字段与构造函数行为，与源码一致）。
- **[轻微]** plan.md 块 6 描述含 "再验证 add 后 size 增长" 细节，task_v22.md 块 6 仅要求 "add 后对同一 key find 行为不变"。plan 比 task 多一句 size 增长描述属上下文补充，Doer 按 task_v22.md 执行不受影响。

## 验证要点
1. **CompileIdx 9 API**（compile.mbt:8-53）：unknown()=-2 / break_value()=-3 / of_idx(x)=x / is_idx(t)=t>=0 / is_break(x)=x<=-3 / is_unknown(x)=x==-2 / idx(t)=t / make_break(idx)=-5-idx / break_idx(t)=(t+5)*-1，全部与 task_v22.md 块 1-3 断言值吻合（含 round-trip make_break(3)=-8 → break_idx(-8)=3、make_break(0)=-5、break_idx(-5)=0）。
2. **StateHashTable 3 API**（compile.mbt:106-144）：create(capacity) capacity<1 钳制为 1（块 4 create(0) 边界正确）、find 按 hash 定位桶 + State::equal 线性查找返回 CompileState?、add push (key,value) + size+=1，与 task_v22.md 块 4-6 描述一致。
3. **CompileState struct literal 构造**（compile.mbt:67-70 pub struct { info : StateInfo; transitions : Array[CompileState] }）：同包测试可用 struct literal，字段名 info/transitions 匹配，transitions=[] 空数组对递归类型合法。
4. **StateInfo struct literal 构造**（compile.mbt:58-62 pub struct { idx : Int; final_ : Array[(Category, (Int, Status))]; desc : State }）：字段名 idx/final_/desc 匹配，final_ 后缀下划线为实际字段名，desc=State::dummy() 类型匹配。
5. **State::mk 签名**（automata_state.mbt:30 `pub fn State::mk(idx : Int, cat : Category, desc : Array[ET]) -> State`）：第三参数为 Array[ET]，ET 为 pub enum（automata_desc.mbt:112），[] 空数组可由函数签名类型推断为 Array[ET]，无 ET 值构造需求。
6. **State::dummy vs State::mk(1,...) 区分性**：dummy.idx=Idx::unknown()=-1（automata.mbt:148-150）、dummy.hash=-1；mk(1,...).idx=1、hash=state_compute_hash(1,...) 几乎必 ≠-1。State::equal 先比较 hash（automata_state.mbt:62-67），hash 不同即短路返回 false，块 6 find 未命中断言成立。
7. **CompileState::get_info**（compile.mbt:73-75）返回 StateInfo，StateInfo.idx 字段可访问，块 5 `CompileState::get_info(cs').idx == 0` 断言合法。
8. **测试文件命名**：compile_internal_test.mbt 以 _test.mbt 结尾，MoonBit 自动识别无需修改 moon.pkg（已确认 re/moon.pkg 仅含 hashmap import，无测试文件列表），与现有 basics_test/ast_test/.../parse_buffer_test 风格一致，无命名冲突。
9. **测试计数**：T21 后 317/317 + 6 块 = 323/323，plan.md 与 task_v22.md 一致。
10. **约束遵守**：纯 MoonBit 无 C FFI、snake_case 命名、不修改 pkg.generated.mbti、不修改源码（仅新增测试文件）、保持 OCaml 上游行为一致性、保持 latin1 大小写处理、不运行 benchmark——全部满足。
11. **P15 为最后一项**：coverage_gap_analysis.md §4 P1-P14 已由 T9-T21 完成，P15 完成后阶段二全部优先级项完成，与 task.md 阶段二目标对齐。
