# Project Agents.md Guide

This is a [MoonBit](https://docs.moonbitlang.com) project.

You can browse and install extra skills here:
<https://github.com/moonbitlang/skills>

## Project Structure

- MoonBit packages are organized per directory; each directory contains a
  `moon.pkg` file listing its dependencies. Each package has its files and
  blackbox test files (ending in `_test.mbt`) and whitebox test files (ending in
  `_wbtest.mbt`).

- In the toplevel directory, there is a `moon.mod` file listing module
  metadata.

## Coding convention

- MoonBit code is organized in block style, each block is separated by `///|`,
  the order of each block is irrelevant. In some refactorings, you can process
  block by block independently.

- Try to keep deprecated blocks in file called `deprecated.mbt` in each
  directory.

## Tooling

- `moon fmt` is used to format your code properly.

- `moon ide` provides project navigation helpers like `peek-def`, `outline`, and
  `find-references`. See $moonbit-agent-guide for details.

- `moon info` is used to update the generated interface of the package, each
  package has a generated interface file `.mbti`, it is a brief formal
  description of the package. If nothing in `.mbti` changes, this means your
  change does not bring the visible changes to the external package users, it is
  typically a safe refactoring.

- In the last step, run `moon info && moon fmt` to update the interface and
  format the code. Check the diffs of `.mbti` file to see if the changes are
  expected.

- Run `moon test` to check tests pass. MoonBit supports snapshot testing; when
  changes affect outputs, run `moon test --update` to refresh snapshots.

- Prefer `assert_eq` or `assert_true(pattern is Pattern(...))` for results that
  are stable or very unlikely to change. For snapshot tests that record
  structured debugging output, derive `Debug` and use `debug_inspect`, rather
  than deriving `Show` for debugging. For solid, well-defined results (e.g.
  scientific computations), prefer assertion tests. You can use
  `moon coverage analyze > uncovered.log` to see which parts of your code are
  not covered by tests.
---

# moon-notepad 项目规则

> 优先级：防跑偏规则 > 项目规则 > 个人偏好。规则权威汇总见 `rules.md`，每次新增规则回写两处。工具链 MoonBit v0.1.20260920。

## 强制规则（编码前必读）

### R1 源码目录
全部源代码放根目录下，按 24 个领域分类子目录组织。

### R2 多手段测试
MoonBit 形式化证明 + AI/FAKE/MOCK/E2E 多手段测试。每个 Sprint 交付前 `moon check` 0 error、`moon test` 全通过。

### R3 代码文档注释
三级文档注释中英文（包级、类型级、方法级）。所有 `pub fn` 必须有 `///` 注释。

### R4 README 规范
README 中英文，美化，默认中文；每个子包也要 README.md。

### R5 迭代路线
先制定 `docs/roadmap.md` 迭代路线，按 Sprint 推进。

### R6 提交查证
每个 Sprint 完成回写 `roadmap.md` 状态 + commit hash。

### R7 自动迭代触发
没有任务迭代时，自动触发新的路线迭代计划。

### R8 文档治理
每次迭代后更新根 README、roadmap、CHANGELOG、子包 README。

### R9 经验沉淀（立即）
每完成一个有新发现的步骤（warning 治理、语法陷阱、规则增强），**立即**更新 memory（`C:\Users\Administrator\.codeartsdoer\memory\...`），不得拖延。memory 更新是步骤的一部分，不是事后补丁。

### R10 一级子包重导出
一级子包（如 `src/base`、`src/hull`）也要 README.md 并重导出子包 API。

### R11 防跑偏规则（记/锁/回）
每一步做三件事：
1. **记**：把已确认的"规则/负责人/截止时间"写进固定区块
2. **锁**：遇到与前序约定冲突的新要求，先停下，标注冲突来源，问"谁有权改"
3. **回**：每完成一环，回写一句"已交付 x，下环依赖 Y"

禁止在没确认的情况下，把群聊里的某句话当成最终决定。

### R12 根包重导出
项目根包（根目录 `moon.pkg` + `reexport.mbt`）重导出所有一级子包公共 API，对外提供统一入口。

### R13 Warning 治理（目标 0，无例外）
每次迭代完成后运行 `moon check` / `moon test`，对所有 warning 逐一**根因治理**，目标 **0 warning 无例外**。

**禁止简单抑制**：不得用 `#warnings("-...")` 或 `moon.pkg` warnings 字段掩盖 warning。

**根因治理方式**：
1. **删除**：函数/实现确实无用 → 删除定义
2. **加 `pub`**：是公共 API 的一部分 → 加 `pub` 关键字
3. **`ignore()`**：需保留私有且未使用 → 调用 `ignore(fn)`
4. **trait impl 治理**：`impl Trait for Type with fn method` 报 "Unused trait implementation" → 改为 `pub impl` + `pub extend Type with Trait::{method}`
5. **未使用参数**：`fn f(self : T)` 报 "Unused variable 'self'" → 改为 `fn f(_ : T)` 或实际使用 self
6. **unused_package（wbtest 局限）**：导入在 `_wbtest.mbt` 中使用但主源文件未使用 → 在主源文件中添加 `ignore(@pkg)` 或将导入移至测试专用

**验收门禁**：`moon check` 0 warning 0 error，`moon test` 全通过。

### R14 占位 todo 检查
所有占位 todo 项，每次迭代后检查是否具备条件完成。依赖已满足且资源就绪则立即推进；否则标注阻塞原因。

### R15 规则输出复用
所有规则输出到 `rules.md`，供 agent 与人类协作者复用。每次新增规则回写。

### R16 连续迭代不停顿
有迭代计划（roadmap 中有"待开始"且依赖已满足的 Sprint）时**不得停顿**，完成当前 Sprint 后立即推进下一个，直到所有依赖已满足的 Sprint 全部完成，或遇到需要用户决策的阻塞点（按 R11 锁规则停下）。

### R17 多手段测试工作流
所有设计文档补充、架构变更、新模块合入必须经过五类多手段测试验证，全 Pass 后方可进入下一阶段：

| 测试手段 | 职责 | 适用场景 |
|----------|------|----------|
| **形式化证明** | 校验文档结构完整性、跨章节一致性、引用闭环、规则完备性 | 架构文档、规则文档、输出契约 |
| **AI 测试** | 用 AI 智能体模拟工作流执行，验证设计可行性 | 工作流设计、算子语义、用户场景模拟 |
| **FAKE 测试** | 构造假数据结构，验证输出契约字段完整可构造 | 数据结构定义、类型完备性 |
| **MOCK 测试** | mock 外部依赖组件，验证编排逻辑正确 | 工作流编排、接口调用顺序 |
| **E2E 测试** | 端到端模拟完整流程，验证多组件串联闭环 | 用户需求 → 最终输出的完整链路 |

执行规则：
1. **全 Pass 才放行**：五类测试任一 Fail 则阻塞合入，修复后重跑全部五类
2. **测试报告落盘**：每次多手段测试输出 `docs/arch_test_report.md`（或追加章节），记录每类测试的输入、执行、输出、结论
3. **分级触发**：纯文档变更可只跑形式化证明 + docs 一致性；代码变更必须跑全五类
4. **发现即沉淀**：测试中发现的设计要点、契约缺口、边界场景必须立即回写到设计文档或 memory

### R18 Trait 抽象与去重
优先用 `pub(open) trait` 抽象公共行为模式，消除跨模块代码重复。实现 trait 时用 `pub impl Trait for Type with method` + `pub extend Type with Trait::{method}` 模式确保跨包可用且消除 deprecation warning。

### R19 尽可能使用 Trait
所有新代码必须优先使用 trait 抽象行为模式，而非裸函数：
1. **公共行为 trait 化**：任何被 2+ 个包/类型共享的行为模式（如 `version()`、`create()`、`check()`、`validate()`、`run()`、`reset()`），必须抽象为 `pub(open) trait`
2. **trait 优先于函数**：新增公共 API 时，优先设计 trait 方法而非独立函数。独立函数仅在行为不可复用时才允许
3. **现有代码 trait 化**：迭代时逐步将现有裸函数重构为 trait 实现，每次 Sprint 至少 trait 化一个公共模式
4. **trait 命名规范**：行为 trait 用形容词/动词命名（`Versioned`、`Checkable`、`Runnable`、`Resettable`、`Validatable`），而非名词
5. **默认实现**：trait 中提供默认实现 `method(Self) -> T = _`，减少实现样板代码

## MoonBit 技术要点（编码必查）

> 工具链 MoonBit v0.1.20261020（Feature flags: `rr_moon_mod`, `rr_moon_pkg`）。完整技术要点见 `rules.md` 第十二节。

| 要点 | 说明 |
| --- | --- |
| 方法定义语法 | **新**：`fn Type::meth(self : Type, ..)`；**废弃**：`fn meth(self : Type, ..)` |
| 异步箭头函数 | **新**：`(args) => { ... }`；**废弃**：`fn(args) { ... }` 隐式异步 |
| StringView 切片 | `s[a:b]` 返回 `StringView`，需 `.to_owned()` 转 `String` |
| Int vs Int32 | `Array.length()`/`String.length()` 返回 `Int`；`moon fmt` 将 struct 字段规范化为 `Int32` |
| JSON from_json | `@json.from_json(json)` + 类型注解 + `try/catch`；`Type::from_json(json, path)` 需 2 参数且 raise |
| JSON 构造 | `@json.object/boolean/number` 不存在；用 `derive(ToJson)` 或 `Json` 枚举 |
| HTTP headers | `extra_headers` 类型为 `Map[CaseInsensitiveString, String]`，可省略用默认 |
| 多行字符串 | `#|` 前缀标记每行，自动拼接为 `String` |
| Workspace | 单根 `moon.mod` + 子目录 `moon.pkg`（推荐）；多模块用 `moon.work` |
| 构建配置 | `supported_targets = "+wasm+wasm-gc+js+native"`；`pkgtype(kind: "executable")` |
| 白盒测试 | `_wbtest.mbt` 包内作用域，**不需要** `@pkg` 前缀 |
| 黑盒测试 | `_test.mbt` 包外作用域，**需要** `@pkg.fn()` 前缀 |
| 科学计数法 | 不支持 `1e-13` 字面量，用 `0.000000000001` |
| pub enum 跨包 | 构造子跨包不可构造，需提供 `pub fn` 构造函数 |
| 字符串插值 | `{}` 不生效，用 `+` 拼接 |
| 关键字 | `var` 是关键字，不能做函数名 |
| 布尔取反 | 用 `!expr`，`not(x)` 已 deprecated |
| 闭包调用 | record field 调用需 `(self.func)(x, y)` 而非 `self.func(x, y)` |
| trait 方法调用 | 跨包用 `Trait::method(obj, args)`，隐式提升已 deprecated |
| trait impl 可见性 | `pub impl Trait for Type with fn method` + `pub extend Type with Trait::{method}` 让 impl 跨包可用且消除 unused warning |
| Array.push | 不需要 `mut`（Array 默认可变），`mut` 仅用于变量重新赋值 |
| range 循环 | `for i in 0..<n`（字面量 OK）；表达式边界加括号 `0..<(n-1)`；返回值函数内用 C 风格 `for i = 0; i < n; i = i + 1` |
| Double sqrt | `value.sqrt()` 方法（非 `@math.sqrt`） |
| `pub(open) trait` | 跨包实现必须用 `pub(open) trait`（`pub trait` = readonly/sealed，只能在定义包内实现） |
| trait 默认实现 | `= _` 表示抽象方法（必须实现），非默认实现占位符 |
| `pub extend` vs `pub impl` | `pub impl` 提供 trait 方法实现；`pub extend Type with Trait::{method}` 将 trait 方法提升为常规方法（消除 implicit_impl_as_method warning） |
| derive + pub extend | `derive(ToJson, FromJson, Debug, Eq)` 后必须 `pub extend Type with Trait::{method}` 消除 warning |
| ignore() | `ignore(fn)` 抑制未使用函数 warning；`ignore(@pkg)` 抑制 unused_package |
| unused_package 局限 | MoonBit `unused_package` 不考虑 `_wbtest.mbt` 文件中的使用 |
| 形式化验证 | `moon prove`：`.mbt`（可执行+契约）+ `.mbtp`（谓词+引理）+ `proof_enabled=true`；依赖 Why3+z3/cvc5 |
| proof 契约 | `proof_require`（前置）/ `proof_ensure`（后置）/ `proof_assert`（中间事实）/ `proof_invariant`（循环不变量） |
| proof 注解 | `#proof_pure`（纯函数）/ `proof_decrease`（终止度量）/ `proof_axiomatized`（假定成立）/ `#proof_external`+`#proof_import`（外部理论） |
| 错误处理 | `raise E` / `try { } catch { E => }` / `suberror` 精细化错误 / `abort(msg)` 不可恢复 |
| 异步编程 | `async fn` / `await` / `@async.tg()` 任务组（native 后端）；JS 后端不支持 async/await |
| FFI 声明 | `extern "c"`（native）/ `extern "js"`（js/wasm）；`#borrow`（借用）/ `#owned`（所有权转移） |
| 迭代器 | `Iter[T]` trait / `for x in container` / `.map().filter().fold()` / `.enumerate()` |
| defer/errdefer | `defer expr`（作用域结束执行）/ `errdefer expr`（仅错误退出时执行） |
| 模式匹配 | `match` / `Pattern if guard`（守卫）/ `expr is Pattern`（简洁匹配）/ `Type::..`（非穷尽通配） |
| 运算符重载 | `Add`/`Sub`/`Mul`/`Div`/`Mod`/`Eq`/`Compare`/`BitAnd`/`BitOr`/`Shl`/`Shr` 内建 trait |
| moon ide | `peek-def` / `find-references` / `outline` / `doc` / `codelens` |
| .mbtx 脚本 | 单文件脚本，`moon run script.mbtx`，无需 moon.mod |
| moon coverage | `moon test --enable-coverage` + `moon coverage analyze` |
| 属性系统 | `#deprecated`/`#alias`/`#label_migration`/`#visibility`/`#internal`/`#export_name`/`#must_implement_one`/`#alert`/`#cfg`/`#borrow`/`#owned` |
| 数字类型 | `Int`(平台原生) / `Int32`/`Int64`/`UInt32`/`UInt64`/`Byte`/`Float`/`Double`/`Char` |
| 内建类型 | `Unit`/`Bool`/`Option[T]`/`Result[T,E]`/`Array[T]`/`FixedArray[T]`/`Map[K,V]`/`Ref[T]`/`Json`/元组 |
| 函数特性 | 标签参数 `x~` / 可选参数 `x~ = 0` / 部分应用 `f(1, _)` / `init` 初始化块 |

### 重导出语法
```
pub using @pkg { type T, name1, trait Trait1 }
```
- 必须带 `{}`；`pub using @pkg` 不带花括号报错 "expect `{`"
- 只能列类型/trait/顶层标识符，不能列方法 `Type::method`
- 重导出类型后，其 pub 方法自动随类型可见
- `moon.pkg` 不支持 `export` 段；`pub use` 非有效语法，应为 `pub using`

### 根包
项目根目录加 `moon.pkg` + `reexport.mbt` 即为模块根包，可重导出一级子包对外统一入口。

## Sprint 迭代流程

每个 Sprint 严格按以下步骤执行：

1. **查架构**：读 `docs/roadmap.md` 对应章节，明确范围
2. **实现**：写源码 + 白盒测试（`_wbtest.mbt`）
3. **验证**：`moon check` 0 error + `moon test` 全通过
4. **Warning 治理**（R13）：逐一处理 warning，目标 0 warning
5. **重导出**（R10/R12）：一级子包聚合 + 根包重导出
6. **文档治理**（R8）：更新 README / roadmap / CHANGELOG / 子包 README
7. **经验沉淀**（R9）：更新 memory
8. **占位检查**（R14）：检查占位 todo 是否可推进
9. **提交**（R6）：git commit + 回写 roadmap commit hash
10. **回写**（R11 回）：回写"已交付 x，下环依赖 Y"

## 验收门禁（每次交付前必过）

- `moon check` 输出 **0 warning 0 error**
- `moon test` 全通过
- 所有 `pub fn` 有 `///` 注释（R3）
- 中英文 README 同步（R4/R8）
- roadmap 状态 + commit hash 已回写（R6）
- memory 已更新（R9）

## 常用命令

```bash
moon check                          # 类型检查 + warning 治理（目标 0）
moon test                           # 运行全量测试
moon build                          # 构建
moon run                            # 运行
moon fmt                            # 格式化（仅生产 .mbt）
moon info                           # 生成 pkg.generated.mbti，检查 API 变更
moon clean                          # 切换版本后必须先 clean
moon ide find-references            # 查调用方（删除前必用）
```
