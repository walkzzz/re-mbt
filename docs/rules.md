# MoonBit 开发规则全集 / Development Rules

> **用途**：本文件是 MoonBit 项目所有开发规则的权威汇总，供 agent 与人类协作者复用。
> **维护**：每次新增规则时回写本文件。
> **优先级**：防跑偏规则 > 项目规则 > 个人偏好。
> **适用版本**：MoonBit v0.1.20261020（Feature flags: `rr_moon_mod`, `rr_moon_pkg`）

---

## 一、项目结构规则 / Project Structure

### R1 — 源码目录

全部源代码放在**项目根目录**下（不设 `src` 子目录），按**领域/职责**划分为多个**根包**（每个根包有自己的 `moon.pkg`）。包粒度与团队认知负载匹配；目录即包，包名即命名空间。

```moonbit
// ✅ 正确：根目录下多根包，按领域/平台划分
{{PROJECT_NAME}}/
├── moon.mod                    // 模块配置
├── moon.pkg                    // 根包（统一重导出入口）
├── reexport.mbt                // 根包重导出
├── Makefile
├── shared/                     // 共享领域逻辑（前后端共用）
│   ├── moon.pkg
│   ├── shared_test.mbt
│   └── task.mbt
├── backend/                    // 后端（native target）
│   ├── moon.pkg
│   ├── main.mbt
│   └── api.hurl
├── frontend/                   // 前端（js target）
│   ├── moon.pkg
│   └── main.mbt
└── cli/                        // CLI 工具（可选）
    ├── moon.pkg
    └── main.mbt

// ❌ 错误：所有代码塞进 src 单目录
{{PROJECT_NAME}}/
├── src/
│   ├── shared/
│   ├── backend/
│   └── frontend/
└── moon.mod

// ❌ 错误：按技术层而非领域/平台划分
{{PROJECT_NAME}}/
├── types/
├── impls/
└── tests/
```

**要点**：
- 不设 `src` 目录，源代码直接在根目录下按包组织
- 每个一级子目录是独立的根包（有自己的 `moon.pkg`）
- `moon.mod` 的 `source` 字段设为 `"."`（或省略）
- 跨 target 的项目（如全栈）天然适合此结构：`backend/` → native，`frontend/` → js，`shared/` → 与平台无关

### R5 — 迭代路线

先制定 `docs/roadmap.md` 迭代路线，按 Sprint 推进。

### R6 — 提交查证

提交历史有迹可循——每个 Sprint 完成回写 `roadmap.md` 状态 + commit hash。

### R7 — 自动迭代触发

没有任务迭代时，自动触发新的路线迭代计划。

### R8 — 文档治理

每次迭代后进行开源项目文档治理，更新以下文档：

| 文档 | 职责 | 更新时机 |
|------|------|----------|
| 根 `README.md` | 项目总览、快速开始、架构图 | 每次迭代 |
| `docs/roadmap.md` | 迭代路线与进度 | 每次迭代 |
| `CHANGELOG.md` | 版本变更记录 | 每次发布 |
| 子包 `README.md` | 子包 API 说明与使用示例 | 子包 API 变更时 |
| **`docs/api.md`** | 公共 API 参考文档（从 `moon doc` 生成或手写） | API 变更时 |
| **`docs/architecture.md`** | 架构决策记录（ADR） | 架构变更时 |
| **`docs/design.md`** | 核心设计文档（类型系统、算法、协议） | 设计变更时 |
| **`docs/examples.md`** | 使用示例与最佳实践 | 新增功能时 |

```bash
# ✅ 正确：迭代后同步更新
git commit -m "feat: add X

- Update docs/roadmap.md
- Update docs/api.md
- Update CHANGELOG.md
- Update README.md"

# ❌ 错误：只提交代码不更新文档
git commit -m "feat: add X"
```

### R10 — 多根包结构

项目采用**多根包**架构：根目录下每个一级子目录是一个独立根包（含自己的 `moon.pkg`），各自有自己的 `README.md` 并重导出本包公共 API。

```moonbit
// ✅ 正确：每个根包独立管理
shared/
├── moon.pkg          // package(moonbitlang/core, ...)
├── README.md         // 本包 API 说明
├── reexport.mbt      // 本包公共 API 重导出
└── task.mbt

backend/
├── moon.pkg          // package(moonbitlang/async, ...)
├── README.md
└── main.mbt

// ❌ 错误：根包没有 README 和重导出
shared/
├── moon.pkg
└── task.mbt          // 外部使用者不知道有哪些公共 API
```

**每个根包必须**：
1. 有 `README.md`（说明本包职责、API 概览、使用示例）
2. 有 `reexport.mbt` 或等价文件（聚合本包公共 API 供外部 `pub using`）
3. 在 `moon.pkg` 中正确声明依赖

### R12 — 根包统一重导出

项目**根目录**的 `moon.pkg` + `reexport.mbt` 重导出所有一级根包的公共 API，对外提供统一入口 `@{{PROJECT_NAME}}`。

```moonbit
// reexport.mbt — 根目录统一入口
pub using @shared { type Task, trait Validatable }
pub using @backend { fn run_server }
pub using @frontend { fn render }

// ❌ 错误：根包不重导出，使用者必须逐个包导入
// import "{{USERNAME}}/{{PROJECT_NAME}}/shared"
// import "{{USERNAME}}/{{PROJECT_NAME}}/backend"
// → 应该只需 import "{{USERNAME}}/{{PROJECT_NAME}}"
```

**多根包依赖关系**：
- `shared` 不依赖任何本项目内包（纯领域逻辑）
- `backend` 依赖 `shared`
- `frontend` 依赖 `shared`
- `cli` 可依赖 `shared` 或全部
- 根包 `reexport.mbt` 聚合所有包供外部使用者一键导入

---

## 二、命名与可见性 / Naming & Visibility

### R25 — `pub(all)` 审慎使用

`pub(all)` 暴露类型 + 字段 + 构造器。仅当类型确实作为公共数据载体（配置、DTO、请求/响应）时使用。领域实体默认 `pub` + 私有字段 + 构造器方法。

```moonbit
// ✅ 正确：领域实体，封装校验
pub struct Positive {
  priv value : Int32
}

pub fn Positive::Positive(x : Int32) -> Positive raise NegativeInput { ... }

// ❌ 错误：pub(all) 暴露后无法保证不变量
pub(all) struct Positive {
  value : Int32  // 调用方可以绕过校验直接构造
}
```

### R31 — `#visibility` 渐进式可见性变更

类型从 `pub(all)` 向 `readonly`/`abstract` 迁移时用 `#visibility(change_to=...)` 提示下游。

```moonbit
// ✅ 正确：预告未来变更
#visibility(change_to="readonly", "Point will be readonly in v2.")
pub(all) struct Point {
  x : Double
  y : Double
}
```

---

## 三、类型设计 / Type Design

### R21 — 构造器优先 `TypeName::TypeName`

公开类型的构造逻辑必须通过自定义构造器封装，禁止让调用方直接写 `Type::{ field: value }` 绕过校验。

```moonbit
// ✅ 正确
pub fn Positive::Positive(x : Int32) -> Positive raise NegativeInput {
  if x < 0 { raise NegativeInput }
  { value: x }
}

// ❌ 错误
let p = Positive::{ value: -1 }  // 绕过校验
```

### R22 — `declare` 先行（API 契约优先）

公共 API 的函数签名必须先用 `declare` 声明（放在 `reexport.mbt` 或 `api.mbt` 中），实现可以后置。

```moonbit
// api.mbt — 声明契约
declare pub fn compute_area(shape : Shape) -> Double

// impl.mbt — 后置实现
pub fn compute_area(shape : Shape) -> Double { ... }
```

### R27 — `extenum` 用于扩展点设计

当类型需要被其他包扩展构造器时，用 `pub extenum` 声明；否则用普通 `enum`（封闭）。

```moonbit
// ✅ 正确：插件扩展点
pub extenum LogEvent[T]

pub(all) extenum LogEvent[T] += {
  Info(T)
  Warning(T)
}

// ❌ 错误：用普通 enum 模拟开放类型
pub(all) enum LogEvent[T] {
  Info(T)
  Warning(T)
  // 下游无法添加构造器
}
```

### R28 — `#non_exhaustive` 标记库枚举

作为库发布的枚举，如果未来可能增加构造器，必须标注 `#non_exhaustive`，下游 `match` 必须加 `Type::..`。

```moonbit
// 库定义
#non_exhaustive
pub(all) enum Response {
  Ok(String)
  NotFound
}

// 下游使用
pub fn render(r : @lib.Response) -> String {
  match r {
    @lib.Ok(body) => body
    @lib.NotFound => "not found"
    @lib.Response::.. => "unsupported"  // 必须
  }
}
```

### R30 — `#non_exhaustive` 强制下游通配

发布为库的 `enum` 若未来可能加构造器，必须标注 `#non_exhaustive`。这是兼容变更的前提。

```moonbit
// ✅ 正确：新增构造器是兼容变更
#non_exhaustive
pub(all) enum Status {
  Running
  Stopped
}
// 未来可加：Paused

// ❌ 错误：下游用 `_` 通配，新增构造器会静默改变行为
match status {
  Running => ...
  Stopped => ...
  _ => ...  // 危险：未来 Paused 会走这里
}
```

### R34 — `suberror` 用于精细化错误建模

领域错误类型用 `suberror` 而非扁平 `enum`，便于组合和扩展。

```moonbit
// ✅ 正确
pub(all) suberror ValidationError {
  EmptyField
  TooLong(Int32)
  InvalidFormat
}

// ❌ 错误：扁平 enum 难以组合
pub(all) enum AppError {
  ValidationEmpty
  ValidationTooLong
  IoError(String)
  // 难以按维度组织
}
```

### R35 — `derive(ToJson, FromJson)` 用于共享类型

全栈项目中前后端共享的 DTO 必须 `derive(ToJson, FromJson)`。

```moonbit
pub(all) struct CreateUserRequest {
  name : String
  email : String
} derive(Eq, ToJson, FromJson)
```

---

## 四、方法与 Trait / Methods & Traits

### R18 — Trait 抽象与去重

优先用 `pub(open) trait` 抽象公共行为模式，消除跨模块代码重复。实现 trait 时用 `pub impl Trait for Type with method` + `pub extend Type with Trait::{method}` 模式。

```moonbit
// ✅ 正确
pub impl Show for MyType with output(self, logger) {
  logger.write("MyType")
}

pub extend MyType with Show::{to_string, output}

// ❌ 错误：裸函数无法多态调度
fn my_type_to_string(x : MyType) -> String { ... }
```

### R19 — 尽可能使用 Trait

所有新代码必须优先使用 trait 抽象行为模式，而非裸函数。

```moonbit
// ✅ 正确：2+ 包共享的行为抽象为 trait
pub(open) trait Versioned {
  version(Self) -> String = _
}

// ❌ 错误：独立函数无法被多态调度
fn get_version(x : AnyType) -> String { ... }
```

**trait 命名规范**：行为 trait 用形容词/动词命名（`Versioned`、`Checkable`、`Runnable`、`Resettable`、`Validatable`）。

### R20 — 方法定义禁止 `self` 简写

所有方法**必须**用 `TypeName::method` 语法定义。

```moonbit
// ✅ 正确
fn List::length(xs : List[X]) -> Int32 { ... }

// ❌ 禁止（未来可能废弃）
fn length(self : List[X]) -> Int32 { ... }
```

### R38 — `#must_implement_one` 约束 trait 设计

要求实现者至少显式实现一个方法，防止"空 trait 全靠默认实现"的反模式。

```moonbit
#must_implement_one
pub(open) trait Handler {
  handle(Self, Request) -> Response = _
  name(Self) -> String = _
}
```

### R13.4 — trait impl 完整写法（关键）

```moonbit
// ✅ 正确：impl 声明实现 + extend 挂方法
pub impl Show for MyType with output(self, logger) {
  logger.write("MyType")
}

pub extend MyType with Show::{to_string, output}

// ❌ 错误：只写 impl，不写 extend，点调用会报 E0079
pub impl Show for MyType with output(self, logger) { ... }
// 调用方只能用 Show::to_string(x)，不能 x.to_string()
```

**验收**：`moon check` 不得出现 `implicit_impl_as_method`（E0079）警告。

---

## 五、控制流与函数 / Control Flow

### R23 — `guard` / `is` 替代嵌套 `match`

当模式匹配只是为了提取并校验一个值，后续逻辑超过 3 行时，**必须**用 `guard! expr is Pattern` 或 `guard expr is Pattern else { ... }` 替代嵌套 `match`。

```moonbit
// ✅ 正确
fn process(x : Option[Int32]) -> Int32 {
  guard x is Some(v) else { return 0 }
  guard v > 0 else { return 0 }
  v * 2
}

// ❌ 错误：嵌套过深
fn process(x : Option[Int32]) -> Int32 {
  match x {
    Some(v) => {
      if v > 0 { v * 2 } else { 0 }
    }
    None => 0
  }
}
```

### R24 — `defer` / `errdefer` 资源管理

所有获取的资源（文件句柄、socket、锁）**必须**用 `defer`（正常+异常都释放）或 `errdefer`（仅失败时释放）管理。

```moonbit
// ✅ 正确
fn read_file(path : String) -> String raise IoError {
  let file = @fs.open(path)
  defer file.close()
  file.read_to_string()
}

// ❌ 错误：多个退出点需重复写释放
fn read_file(path : String) -> String raise IoError {
  let file = @fs.open(path)
  if some_cond { file.close(); return "" }
  let content = file.read_to_string()
  file.close()  // 容易遗漏
  content
}
```

---

## 六、测试 / Testing

### R2 — 多手段测试

MoonBit 形式化验证 + AI/FAKE/MOCK/E2E 多手段测试，确保无 bug。每个 Sprint 交付前 `moon check` 0 error、`moon test` 全通过。

### R17 — 多手段测试工作流

所有设计文档补充、架构变更、新模块合入必须经过**五类多手段测试**验证，全 Pass 后方可进入下一阶段：

| 测试手段 | 职责 | 适用场景 |
|----------|------|----------|
| **形式化验证** | 校验文档结构完整性、跨章节一致性、引用闭环 | 架构文档、规则文档 |
| **AI 测试** | 用 AI 智能体模拟工作流执行 | 工作流设计、算子语义 |
| **FAKE 测试** | 构造假数据结构，验证类型完备性 | 数据结构定义 |
| **MOCK 测试** | mock 外部依赖组件，验证编排逻辑 | 工作流编排 |
| **E2E 测试** | 端到端模拟完整流程 | 用户需求→最终输出 |

**分级触发**：
- 纯文档变更 → 形式化验证 + 文档一致性
- 代码变更 → 全五类

### R26 — 测试文件命名与可见性

- `*_test.mbt` → 黑盒测试（不能访问私有成员）
- `*_wbtest.mbt` → 白盒测试（可访问私有成员）

每个包**至少**有一个 `*_test.mbt` 验证公共 API 的可见性行为。

```moonbit
// mylib_test.mbt — 黑盒测试，模拟外部用户
test "public api" {
  let result = @mylib.public_function()
  assert_eq(result, expected)
}

// mylib_wbtest.mbt — 白盒测试，验证内部逻辑
test "internal invariant" {
  let internal_state = build_internal()
  assert(internal_state.is_valid())
}
```

### 文档测试

`moon test --doc` 运行文档中的 `///|` 代码块。文档即测试。

```moonbit
///|
/// Examples:
/// ```moonbit
/// let x = List::Cons(1, List::Nil)
/// assert_eq(x.length(), 1)
/// ```
pub fn List::length(self : List[X]) -> Int32 { ... }
```

---

## 七、属性系统 / Attributes

### R29 — `#deprecated` + `#alias` 用于 API 迁移

旧 API 重命名时，用 `#alias(old_name, deprecated)` 创建弃用别名，平滑过渡。

```moonbit
// ✅ 正确：平滑迁移
#alias(old_function, deprecated="Use new_function instead")
pub fn new_function() -> Unit { ... }

// 下游收到弃用警告，但有迁移窗口
old_function()  // warning: Use new_function instead
```

### R32 — `#cfg` 条件编译

跨 target 的代码用 `#cfg(target=...)` 而非文件级 `targets`。

```moonbit
// ✅ 正确
#cfg(target="wasm")
fn platform_specific() -> Unit { ... }

#cfg(target="native")
fn platform_specific() -> Unit { ... }

// ❌ 错误：用文件级 targets 做细粒度条件编译不够灵活
```

### R36 — `#export_name` 优先于 link exports

需要导出函数时用 `#export_name("symbol")` 而非 `moon.pkg` 的 `exports` 配置。

```moonbit
#export_name("add")
pub fn add_one(value : Int32) -> Int32 { value + 1 }
```

### R37 — FFI 声明必须用 `#borrow`/`#owned`

外部函数参数涉及 `Bytes`/`String`/`FixedArray` 时必须标注生命周期。

```moonbit
// ✅ 正确：只读参数用 #borrow
#borrow(filename)
extern "C" fn open(filename : Bytes, flags : Int32) -> Int32 = "open"

// ✅ 正确：接管所有权用 #owned
#owned(buffer)
extern "C" fn consume(buffer : Bytes) -> Unit = "consume"
```

### R39 — `#alert(unsafe, "...")` 标记不安全 API

unsafe 函数必须标注 alert，下游可通过 `alert_unsafe` 配置控制。

```moonbit
#alert(unsafe, "This function bypasses bounds checking.")
fn unsafe_get(arr : Array[Int32], index : Int32) -> Int32 {
  arr[index]
}
```

### R40 — `#label_migration` 用于参数演进

重命名/改可选性时用此属性给下游迁移窗口期。

```moonbit
#label_migration(old_name, alias=new_name, msg="Use new_name")
pub fn example(new_name~ : Int32) -> Unit { ... }
```

### R42 — `#warnings(...)` 局部警告控制

特定函数需要关闭/开启特定警告时用此属性，不污染全局。

```moonbit
#warnings("-unused_value")
fn legacy_wrapper() -> Unit {
  let _ = old_api()  // 已知 unused，局部抑制
}
```

**注意**：`#warnings` 局部属性是最后手段，优先用 R13 的根因治理。

### R43 — 形式化验证规范（`moon prove`）

涉及安全关键、算法正确性、数据结构不变量的代码，应使用 MoonBit 形式化验证（`moon prove`）提供机检证明。

**启用条件**：在 `moon.pkg` 中设置 `proof_enabled = true`

**文件分工**：
- `.mbt`：可执行代码 + 契约（`proof_require`/`proof_ensure`）+ `proof_assert` + 循环不变量
- `.mbtp`：`predicate`（谓词）+ `lemma`（引理）+ 抽象模型 + 表示不变量

**必须遵循**：
1. **程序侧与逻辑侧分离**：`.mbt` 中的定义是可执行的，`.mbtp` 中的定义仅用于证明
2. **具名谓词优先**：用 `predicate sorted(xs)` 而非内联 `∀ i, ∀ j, ...`
3. **基于模型的验证**：数据结构验证必须定义 `model()` + `type_inv()`，针对抽象模型编写规范
4. **`proof_axiomatized` 谨慎使用**：标记为假定的项目属于可信边界，必须在文档中明确标注
5. **循环不变量描述局部窗口**：描述当前搜索窗口/已处理区域，而非整个算法
6. **函数式风格优先**：命令式可变状态验证限制更多，`FixedArray` 逃逸式使用不受支持

**环境依赖**：Why3 1.7.2 + z3/cvc5/alt-ergo（至少一个求解器）

**验证命令**：
```bash
moon prove                    # 证明所有启用证明的包
moon prove path/to/package    # 仅证明指定包
```

**可信边界**：
- 验证推理的是数学整数（无界），不建模运行时溢出
- `proof_axiomatized` 项目作为假设，不被证明
- `#proof_external`/`#proof_import` 声明正确性属于可信边界

详细指南见技能参考 `formal-verification-guide.md`

---

## 八、工具链与配置 / Toolchain

### R33 — `preferred_target` + `supported_targets` 必须声明

每个模块 `moon.mod` 中必须设置 `preferred_target`，包级 `supported_targets` 与模块级取交集。

```toml
# moon.mod
name = "{{USERNAME}}/{{PROJECT_NAME}}"
version = "0.1.0"
preferred_target = "native"
supported_targets = "+wasm+wasm-gc+js+native"

import {
  "moonbitlang/async@0.22.4",
}
```

### R13 — Warning 治理（目标 0，无例外）

每次迭代完成后必须进行 **warning 治理**：运行 `moon check` / `moon test`，对所有 warning 逐一**根因治理**，目标 **0 warning**。

**禁止简单抑制**：不得用 `#warnings("-...")` 属性或 `moon.pkg` warnings 字段掩盖 warning。

**根因治理方式**：
1. **删除**：函数/实现确实无用 → 删除定义
2. **加 `pub`**：是公共 API 的一部分 → 加 `pub` 关键字
3. **`ignore()`**：需保留私有且未使用 → 调用 `ignore(fn)` 强制使用
4. **trait impl 治理**：`impl Trait for Type with fn method` 报 "Unused trait implementation" → 改为 `pub impl` + `pub extend Type with Trait::{method}`
5. **未使用参数**：`fn f(self : T)` 报 "Unused variable 'self'" → 改为 `fn f(_ : T)` 或实际使用 self
6. **unused_package**（wbtest 局限）：导入在 `_wbtest.mbt` 中使用但主源文件未使用 → 在主源文件中添加 `ignore(@pkg)` 或将导入移至测试专用

**CI 命令**：`moon check --deny-warn` 将 warning 当 error。

**验收门禁**：`moon check` 输出 0 warning 0 error，`moon test` 全通过。

---

## 九、文档规范 / Documentation

### R3 — 代码文档注释

代码三级文档注释中英文（包级、类型级、方法级）。所有 `pub fn` 必须有 `///` 注释。

```moonbit
/// 计算列表中元素的数量。
/// Counts the number of elements in the list.
pub fn List::length(self : List[X]) -> Int32 {
  // ...
}
```

### R4 — README 规范

README 中英文，美化，默认中文；每个子包也要 README.md。

### R15 — 规则输出复用

所有规则输出到本文件 `docs/rules.md`，供 agent 与人类协作者复用。每次新增规则回写。

---

## 十、迭代流程 / Iteration Workflow

每个 Sprint 执行步骤：

1. **查架构**：读 `docs/roadmap.md` 对应章节，明确范围。
2. **实现**：写源码 + 白盒测试（`_wbtest.mbt`）。
3. **验证**：`moon check` 0 error + `moon test` 全通过。
4. **Warning 治理**（R13）：逐一处理 warning，目标 0 warning。
5. **重导出**（R10/R12）：一级子包聚合 + 根包重导出。
6. **文档治理**（R8）：更新 README / roadmap / CHANGELOG / 子包 README。
7. **经验沉淀**（R9）：更新 memory。
8. **占位检查**（R14）：检查占位 todo 是否可推进。
9. **提交**（R6）：git commit + 回写 roadmap commit hash。
10. **回写**（R11 回）：回写"已交付 x，下环依赖 Y"。

---

## 十一、防跑偏与治理 / Anti-Drift

### R9 — 经验沉淀（立即）⭐

开发经验教训**立即沉淀**复用：每完成一个有新发现的步骤（warning 治理、语法陷阱、规则增强），**立即**更新 memory，**不得拖延**。

**执行时机**：在当前动作完成时、进入下一个动作之前执行 memory 更新。在 todo 流程中，memory 更新是步骤的一部分，不是事后补丁。

### R11 — 防跑偏规则（记/锁/回）

每一步做三件事：
1. **记**：把已确认的"规则/负责人/截止时间"写进固定区块；
2. **锁**：遇到与前序约定冲突的新要求，先停下，标注冲突来源，问"谁有权改"；
3. **回**：每完成一环，回写一句"已交付 x，下环依赖 Y"。

禁止在没确认的情况下，把群聊里的某句话当成最终决定。

### R14 — 占位 todo 检查

所有的占位 todo 项，每次迭代后都要检查是否具备条件完成。若依赖已满足且资源就绪，立即推进；否则标注阻塞原因。

### R16 — 连续迭代不停顿 ⭐

有迭代计划（roadmap 中有"待开始"且依赖已满足的 Sprint）时**不得停顿**，完成当前 Sprint 后立即推进下一个，直到：
- 所有依赖已满足的 Sprint 全部完成，或
- 遇到需要用户决策的阻塞点（按 R11 锁规则停下问谁有权改）

禁止在无阻塞的情况下中途停顿等待用户指令。

---

## 十二、技术要点 / Technical Notes

### 重导出语法

```moonbit
pub using @pkg { type T, name1, trait Trait1 }
```

- 必须带 `{}`；`pub using @pkg` 不带花括号报错 "expect `{`"
- 只能列类型/trait/顶层标识符，不能列方法 `Type::method`
- 重导出类型后，其 pub 方法自动随类型可见
- `using` 统一替代 `fnalias` / `traitalias` / 简单 `typealias`（后三者将废弃）
- `pub using` = 重导出；不带 `pub` = 包内别名

### 根包

- 项目根目录的 `moon.pkg` + `reexport.mbt` 是模块的统一入口，对外提供 `@{{PROJECT_NAME}}`
- 每个一级子目录也是独立根包（有自己的 `moon.pkg`），可被单独导入：`@{{PROJECT_NAME}}/shared`、`@{{PROJECT_NAME}}/backend`
- 根包 `reexport.mbt` 用 `pub using` 聚合各子包 API
- 子包之间依赖通过 `moon.pkg` 的 `import` 声明（而非目录引用）

### `extenum` 扩展规则

- `extenum` 声明只定义类型，不包含构造器
- 通过 `extenum Type += { ... }` 添加初始构造器
- 跨包扩展时，构造器由定义该构造器的包限定：`@pkg.Constructor`
- 模式匹配必须包含通配符分支 `_`
- 只有 `extenum` 可被扩展；普通 `enum` 是封闭的

### `#non_exhaustive` 下游规则

- 下游必须用 `Type::..` 处理未来构造器
- `_` 通配符不能替代 `Type::..`
- `Type::..` 必须放在所有已知构造器之后

### 条件编译

- 文件级：`moon.pkg` 的 `targets` 字段
- 声明级：`#cfg(target=...)` / `#cfg(platform=...)` / `#cfg(not(...))`
- `#cfg` 优先级高于文件级 `targets`

### 方法定义语法（v0.1.20261020+）

- **废弃**：`fn meth(self : Type, ..)` 语法已 deprecated
- **新语法**：`fn Type::meth(self : Type, ..)`，`self` 需显式声明且带类型注解
- trait impl 内部仍用 `fn method(self, ..)`（无 `Type::` 前缀）

```moonbit
// ✅ 正确（新语法）
pub fn DocumentManager::active_content(self : DocumentManager) -> String { ... }

// ❌ 废弃（旧语法）
pub fn active_content(self : DocumentManager) -> String { ... }
```

### 异步与箭头函数语法

- **废弃**：`fn(args) { ... }` 隐式异步推断已 deprecated
- **新语法**：箭头函数 `(args) => { ... }` 或显式 `async fn(args) { ... }`
- `async fn main { ... }` 为后端入口（native 目标）
- `fn main { ... }` 为前端入口（js 目标，非 async）

```moonbit
// ✅ 正确
server.run_forever((request, body, conn) => { ... })

// ❌ 废弃
server.run_forever(fn(request, body, conn) { ... })
```

### StringView 与字符串切片

- `s[a:b]` 返回 `StringView`，不是 `String`
- `StringView` → `String` 转换：用 `.to_owned()`（推荐）或 `.to_string()`（deprecated warning）
- 字符串拼接 `StringView + String` 返回 `StringView`，需最终 `.to_owned()`

```moonbit
// ✅ 正确
let part = (s[0:5] + "world" + s[10:]).to_owned()

// ❌ 错误：StringView 不能赋给 String 字段
let part : String = s[0:5]  // Type Mismatch
```

### Int vs Int32 类型系统

- `Array.length()` 返回 `Int`（非 `Int32`）
- `String.length()` 返回 `Int`（非 `Int32`）
- `moon fmt` 会将 struct 字段的 `Int` 规范化为 `Int32`
- trait 方法签名中 `Int` 和 `Int32` 不兼容，需统一
- **建议**：struct 字段用 `Int32`，局部变量/循环用 `Int`，必要时转换

### 不存在的标准库函数（v0.1.20261020）

| 不存在的函数 | 替代方案 |
|---|---|
| `@string.to_lower(s)` | 手动实现或 `s` 方法 |
| `@string.ends_with(s, suffix)` | 手动实现：`s[s.length()-suffix.length():] == suffix` |
| `@string.contains(s, sub)` | 手动实现：遍历查找 |
| `@json.object([...])` | 用 `derive(ToJson)` 或 `Json` 枚举构造 |
| `@json.boolean(true)` | `@json.Json::Boolean(true)` |
| `@json.number(x)` | `@json.Json::Number(x)` |
| `@http.Header::ContentType` | headers 为 `Map[CaseInsensitiveString, String]`，或省略 `extra_headers` |
| `StringBuilder::new()` | 用 `Array[String]` + 循环拼接 |
| `Int.to_int32()` | `Int32::from(x)` 或统一用 `Int` |

### JSON API 正确用法

- `derive(ToJson, FromJson)` 自动生成 `to_json()` / `from_json()`
- `Type::from_json(json, path)` 需 2 参数且 `raise`，不返回 `Result`
- **推荐**：`@json.from_json(json)` + 类型注解 + `try/catch`

```moonbit
// ✅ 正确
let back : MyType = try { @json.from_json(json) } catch { _ => default }

// ❌ 错误：from_json 需 2 参数
let back = MyType::from_json(json).unwrap()  // 编译错误
```

### derive + pub extend 消除 warning

```moonbit
pub(all) struct Foo { x : Int } derive(ToJson, FromJson, Debug, Eq)

// 必须显式 pub extend 消除 implicit_impl_as_method warning
pub extend Foo with ToJson::{to_json}
pub extend Foo with FromJson::{from_json}
pub extend Foo with Debug::{to_repr}
pub extend Foo with Eq::{not_equal, equal}
```

### trait 默认实现语法

- trait 中 `method(Self, ..) -> T = _` 表示**抽象方法**（必须实现）
- **不是**默认实现占位符；`= _` 要求实现方提供具体实现
- 如需默认实现：在 trait 中提供方法体，impl 中用 `fn method(self) { ... }`（不带 `pub`）覆盖

### HTTP 服务器 API（moonbitlang/async/http）

- `@http.Server(@socket.Addr::parse("127.0.0.1:8080"))` 创建服务器
- `server.run_forever((request, body, conn) => { ... })` 处理请求
- `request.meth`：`Get` / `Post` / ...（无 `@http.` 前缀）
- `request.path`：路径字符串
- `conn..send_response(code, reason)..write(body).end_response()` 链式响应
- `extra_headers` 参数类型：`Map[@http.CaseInsensitiveString, String]`（非 `Array[(String, String)]`）
- 可省略 `extra_headers` 使用默认 headers

### 多行原始字符串

```moonbit
let html : String =
  #|<!doctype html>
  #|<html>
  #|  <body>hello</body>
  #|</html>
```

- `#|` 前缀标记每行，自动拼接为单个 `String`
- 适用于 HTML 模板、SQL 查询等

### Workspace vs 单根模块

- **单根模块**：根目录 `moon.mod` + 子目录 `moon.pkg`（推荐，官方全栈指南用法）
- **Workspace**：根目录 `moon.work` + 子目录各自 `moon.mod`（多模块场景）
- 子包导入：`"{{username}}/{{module}}/shared" @shared`
- `moon.work` 声明 `members = ["./shared", "./backend", "./frontend"]`

**Workspace 操作**：
```bash
moon work init mod_a mod_b        # 初始化工作区，注册成员
moon work use mod_c               # 添加新成员
moon work sync                    # 同步成员版本（更新过期依赖）
moon -C mod_a publish             # 在成员目录执行模块级命令
```

### 构建配置

```moonbit
// moon.mod
supported_targets = "+wasm+wasm-gc+js+native"  // + 前缀表示启用
preferred_target = "native"

// moon.pkg
pkgtype(kind: "executable")  // 可执行包（有 main）
supported_targets = "native"  // 限制目标
```

### 模块配置（moon.mod 完整语法）

**moon.mod 字段一览**：

| 字段 | 必需 | 说明 |
|---|---|---|
| `name` | ✅ | 模块名称（发布到 mooncakes.io 须以用户名开头） |
| `version` | 发布必需 | 语义化版本 `MAJOR.MINOR.PATCH` |
| `import` | — | 依赖声明（`moon add`/`moon remove` 自动管理） |
| `readme` | — | README 文件路径 |
| `repository` | — | 源码仓库 URL |
| `license` | — | SPDX 许可证 |
| `keywords` | — | 关键字数组 |
| `description` | — | 简短描述 |
| `preferred_target` | — | 默认目标（`wasm`/`wasm-gc`/`js`/`native`/`llvm`） |
| `supported_targets` | — | 支持目标集合（`+js+wasm-gc` / `+all-js` / 数组语法） |
| `source` | — | 源目录（默认 `src`，空字符串 `""` = 当前目录） |
| `warnings` | — | 警告列表配置（`-2` 禁用 / `+31` 启用 / 组合 `-2-4+31`） |

**supported_targets 语法**：
- `js`：单个后端
- `+js+wasm-gc`：显式指定一组
- `+all-js`：除 js 外所有
- `["js", "wasm-gc"]`：旧数组语法（兼容）
- 包级 `supported_targets` 与模块级取交集

**本地依赖**（通过 moon.work）：
```moonbit
// moon.work
members = ["./module1", "./module2"]

// module1/moon.mod — @version 被忽略，从本地源码解析
import { "user/module2@0.1.0" }
```

### .moonignore 控制发布文件

- gitignore 风格模式，控制 `moon package` / `moon publish` 归档内容
- 发布时默认遵循 `.gitignore`；`.moonignore` 代替同目录的 `.gitignore`（不合并）
- `!` 前缀重新包含：`!fixtures/expected.log`
- `/` 开头锚定根目录：`!/.gitignore`
- 默认排除 `.` 开头的文件/目录和 `_build/`
- `_build/` 固定排除，无法通过忽略规则重新包含
- 用 `moon package --list` 检查将要打包的文件

### 警告列表（warnings 字段 + moonc check -warn-help）

**配置方式**：
```moonbit
// moon.mod
warnings = "-2-4+31"  // 禁用 2,4，启用 31
```

**关键警告编号**（R13 Warning 治理参考）：

| ID | mnemonic | 说明 | 默认状态 |
|---|---|---|---|
| 1 | unused_value | Unused variable or function | warn |
| 2 | unused_value | Unused variable | warn |
| 3 | unused_type_declaration | Unused type declaration | warn |
| 6 | unused_constructor | Unused constructor | warn |
| 7 | unused_field | Unused field or constructor argument | warn |
| 11 | partial_match | Partial pattern matching | error |
| 12 | unreachable_code | Unreachable code | warn |
| 15 | unused_mut | Unused mutability | error |
| 20 | deprecated | Deprecated API usage | warn |
| 27 | deprecated_syntax | Deprecated syntax | warn |
| 29 | unused_package | Unused package | warn |
| 30 | missing_package_alias | Empty package alias | warn |
| 34 | implicit_use_builtin | Implicit use of `moonbitlang/core/builtin` | warn |
| 55 | unannotated_ffi | Unannotated FFI param type | error |
| 71 | core_package_not_imported | Packages in `moonbitlang/core` need explicit import | warn |
| 79 | implicit_impl_as_method | `impl` implicitly promoted as method | warn |
| 93 | unknown_constr_pat_on_exhaustive_type | `TypeName::..` on non-`#non_exhaustive` type | warn |

- 完整列表：`moonc check -warn-help`
- **禁止简单抑制**（R13）：不得用 `warnings = "-..."` 掩盖 warning，必须根因治理

### 错误代码索引与治理（R13 参考）

> 官方文档：https://docs.moonbitlang.cn/language/error_codes/E0001.html

**E0001 — `unused_value`（未使用的变量或函数）**

触发条件：定义了函数/变量但从未被调用或引用。

**根因治理方式**（按优先级）：

1. **删除**：函数/变量确实无用 → 删除定义
```moonbit
// ❌ 治理前：unused 警告
fn unused() -> String { "Hello, world!" }

// ✅ 治理后：直接删除
```

2. **`ignore()`**：需保留私有且未使用（如 API 预留、测试占位）→ 调用 `ignore(fn)`
```moonbit
// ✅ 治理后：显式标记保留
fn unused() -> String { "Hello, world!" }

test {
  ignore(unused)
}
```

3. **加 `pub`**：是公共 API 的一部分 → 加 `pub` 关键字
```moonbit
// ✅ 治理后：公开 API
pub fn greeting() -> String { "Hello!" }
```

**局部函数同理**：
```moonbit
test {
  // ❌ 治理前：local_greeting 未使用
  fn local_greeting() -> String { "Hello, world!" }

  // ✅ 治理后
  fn local_greeting() -> String { "Hello, world!" }
  ignore(local_greeting)
}
```

**其他常见错误代码**（待补充）：

| 错误代码 | Warning name | 治理方式 |
|---|---|---|
| E0001 | `unused_value` | 删除 / `ignore()` / 加 `pub` |
| — | `unused_package` | 删除导入 / `ignore(@pkg)` / 移至测试专用 |
| — | `implicit_impl_as_method` | `pub extend Type with Trait::{method}` |
| — | `deprecated_syntax` | 迁移到新语法（如 `fn Type::meth` / 箭头函数） |
| — | `core_package_not_imported` | 在 `moon.pkg` 添加 `moonbitlang/core/...` 导入 |
| — | `unannotated_ffi` | FFI 参数加 `#borrow` 或 `#owned` 标注 |

### Rule 和 dev_build

- 模块级 `rule(name: "...", command: "...")`：声明可复用预构建命令
- 命令可引用 `$input` 和 `$output`（由包级 `dev_build` 提供）
- 模块级 rule 不自行运行；需在 `moon.pkg` 中添加 `dev_build` 条目触发

```moonbit
// moon.mod
rule(name: "tool", command: "tool $input -o $output")
```

### 模块脚本配置

```moonbit
// moon.mod — postadd 脚本（模块添加后自动运行）
options(
  scripts: {
    "postadd": "python3 build.py",
  },
)
```

- `[实验性]` 预构建配置脚本：`options("moonbit-unstable-prebuild": "path/to/script")`
- 支持 `.js`/`.cjs`/`.mjs`（node 执行）和 `.py`（python3 执行）
- 脚本从 stdin 接收 JSON 环境，stdout 输出 JSON 配置（vars/link_configs）

### 包配置（moon.pkg 完整语法）

**moon.pkg 字段一览**：

| 字段 | 说明 |
|---|---|
| `import` | 包依赖（`@alias` 别名） |
| `import for "test"` | 黑盒测试依赖 |
| `import for "wbtest"` | 白盒测试依赖 |
| `pkgtype(kind: "...")` | 包类型：`library`（默认）/ `executable` / `foreign_library` |
| `supported_targets` | 支持目标集合（与模块级取交集） |
| `warnings` | 包级警告列表（`-mnemonic` / `+mnemonic`） |
| `native-stub` | native 构建的 C 存根源文件 |
| `link` | 链接选项（wasm/wasm-gc/js/native 各后端） |
| `formatter(ignore: [...])` | 格式化跳过的文件 |
| `virtual` | 虚拟包声明/实现 |
| `targets` | 文件级条件编译 |
| `rule` / `dev_build` | 包级预构建规则 |
| `proof_enabled` | 启用形式化验证 |
| `max-concurrent-tests` | 最大并发测试数 |

**包类型**：
```moonbit
pkgtype(kind: "executable")      // 可执行包（有 fn main），替代旧 options("is-main": true)
pkgtype(kind: "foreign_library") // 外部库包，替代旧 link: true
// 默认 library，无需声明
```

**导入依赖**（含测试导入）：
```moonbit
import {
  "moonbit-community/starter/rabbit",           // 默认别名 @rabbit
  "moonbit-community/starter/rabbit" @r,        // 自定义别名
} for "test"                                     // 黑盒测试依赖

import {
  "path/to/package" @pkg,
} for "wbtest"                                   // 白盒测试依赖
```

- `core` 包需显式导入（避免 `core_package_not_imported` warning）
- `prelude` 默认可用，无需显式导入

**条件编译**（文件级）：
```moonbit
options(
  targets: {
    "only_js.mbt": ["js"],
    "not_js.mbt": ["not", "js"],
    "all_wasm.mbt": ["wasm", "wasm-gc"],
    "only_debug.mbt": ["debug"],
    "js_and_release.mbt": ["and", ["js"], ["release"]],
  }
)
```
- 支持 `and`/`or`/`not` 逻辑运算符（`or` 可省略）
- 后端条件：`wasm`/`wasm-gc`/`js`/`native`
- 优化层次：`debug`/`release`
- 未列出的文件默认在所有条件下编译

**原生存根文件**：
```moonbit
options(
  "native-stub": ["stub.c", "helpers.c"],
)
```

**链接选项**（各后端）：
```moonbit
options(
  link: {
    "wasm": { "exports": ["hello", "foo:bar"], "import-memory": { "module": "env", "name": "memory" } },
    "wasm-gc": { "exports": ["hello"], "use-js-builtin-string": true },
    "js": { "exports": ["hello"], "format": "esm" },  // format: esm(默认)/cjs/iife
    "native": { "cc": "gcc", "cc-flags": "-DMOONBIT", "cc-link-flags": "-s" },
  }
)
```
- 新函数导出优先用 `#export_name("name")` 属性，而非 `exports` 配置
- native 后端：`cc`（编译器）、`cc-flags`（编译标志）、`cc-link-flags`（链接标志）、`stub-cc`/`stub-cc-flags`

**包级 Rule 和 dev_build**：
```moonbit
// moon.pkg
rule(name: "copy", command: "cat $input > $output")
dev_build(rule: "copy", input: "a.txt", output: "a.mbt")
```
- 预构建步骤在 `moon check`/`moon build`/`moon test` 之前运行
- 作为依赖被下游使用时**不会触发**（安全原因）
- 生成的输出文件应提交到仓库
- rule 解析顺序：先包级 → 再模块级

**包级警告列表**：
```moonbit
warnings = "-unused_value-unreachable_code+unused_optional_argument"
```
- 使用 mnemonic 名称（非数字）：`-unused_value` / `+unused_optional_argument`
- `@` 前缀（提升为错误）已弃用，用 `--deny-warn` 替代
- alert 警告：`+alert-alert_unsafe`（启用除 unsafe 外的所有 alert）

**虚拟包**：
```moonbit
// 声明虚拟包（有默认实现）
virtual(has_default: true)

// 实现虚拟包
virtual(implement: "moonbitlang/core/abort")

// 覆盖实现
options(
  overrides: ["moonbitlang/dummy_abort/abort_show_msg"],
)
```

### 文档注释与文学化文件

**文档注释（`///`）**：
- 逐行写在 `fn`/`let`/`enum`/`struct`/`type` 等顶层条目前面
- 内容使用 Markdown 编写
- `` ```mbt check `` 代码块被视作文档测试，`moon check` 和 `moon test` 自动检查并运行
- 文档测试为**黑盒测试**，私有定义不能有文档测试

```moonbit
/// 返回一个新数组，其中元素被反转。
///
/// Example:
/// ```mbt check
/// test {
///   inspect(@misc.incr(41), content="42")
/// }
/// ```
pub fn incr(x : Int32) -> Int32 {
  x + 1
}
```

**代码块语言标记**：

| 标记 | 行为 |
|---|---|
| `mbt` | 编译 MoonBit 代码，但不创建测试入口 |
| `mbt check` | 文档测试代码，需用 `test { .. }` 或 `async test` 断言 |
| `mbt nocheck` | 展示 MoonBit 代码，不编译不测试 |
| `moonbit` | 普通文档展示，不编译不测试 |
| `c` / 其他 | 非测试代码块 |

**文学化 `.mbt.md` 文件**：
- 包内可检查文档 + `moon check`/`moon test` 独立单文件输入
- `moon check README.mbt.md` / `moon test README.mbt.md`

**front matter**（指定导入和后端）：
```yaml
---
moonbit:
  import:
    - path: moonbitlang/core/ref
      alias: ref
  backend: native
---
```
- `moonbit.import`：显式指定可导入的包
- `moonbit.deps`：声明模块依赖，让 Moon 自动合成导入

### 白盒测试 vs 黑盒测试

| 类型 | 后缀 | 作用域 | `@pkg` 前缀 | 导入配置 |
|---|---|---|---|---|
| 白盒测试 | `_wbtest.mbt` | 包内（可访问私有） | **不需要**，直接调用 | `import` + `import for "wbtest"` |
| 黑盒测试 | `_test.mbt` | 包外（仅公共 API） | **需要** `@pkg.fn()` | `import` + `import for "test"` + 当前包 |

- 白盒测试文件导入 `import` 和 `wbtest-import` 配置的包
- 黑盒测试文件导入当前包 + `import` 和 `test-import` 配置的包

### 测试块与断言

**测试块**：`test "name" { ... }`，类型为 `() -> Unit raise Error`
- `assert_eq(actual, expected)`：相等断言
- `debug_inspect(x, content="...")`：Show 快照断言
- `json_inspect(x, content=...)`：JSON 快照断言
- 测试名以 `"panic"` 开头表示预期触发 panic
- `moon test` 以模块根目录为 cwd，相对路径从模块根解析

```moonbit
test "test_name" {
  assert_eq(1 + 1, 2)
  debug_inspect([1, 2, 3], content="[1, 2, 3]")
}

test "panic_test" {
  let _ : Int32 = Option::None.unwrap()  // 预期 panic
}
```

### 快照测试（三种）

**1. Show 快照**（`debug_inspect`）：
```moonbit
test "show snapshot" {
  debug_inspect({ x: 10 }, content="{ x: 10 }")
  // content 可省略，moon test --update 自动插入
}
```

**2. JSON 快照**（`json_inspect`）：格式化后更易读
```moonbit
test "json snapshot" {
  json_inspect(r, content=["Constructor", ["Nested", "End"]])
}
```

**3. 任意内容快照**（`@test.T`）：记录整个过程输出
```moonbit
test "record anything" (t : @test.Test) {
  t.write("Hello, world!")
  t.writeln(" And hello, MoonBit!")
  t.snapshot(filename="record_anything.txt")  // 写入 __snapshot__/ 目录
}
```
- `t.snapshot` 应在测试块末尾使用（总是引发异常）
- 所有快照可用 `moon test --update` 自动插入/更新

### 基于性质的测试（@quickcheck）

**导入**（在 `moon.pkg` 中）：
```moonbit
import { "moonbitlang/core/quickcheck" } for "test"
```

**检查性质**：
```moonbit
test "adding zero preserves int" {
  @quickcheck.check((x : Int32) => x + 0 == x, count=100, seed=2026)
}
```
- `check`：生成输入逐一调用，返回 false 或抛错则失败
- `count`：检查用例数，`seed`：可复现
- 输入类型需实现 `Arbitrary` + `Shrink` + `Debug`（常见类型已提供）

**理解反例**（`report`）：
```moonbit
test "adding one overflow" {
  let report = @quickcheck.report((x : Int32) => x + 1 > x, count=100, seed=2026)
  debug_inspect(report, content="Falsified(counterexample=2147483647, ...)")
}
```
- `report` 返回结果而非抛异常，可用快照记录
- `Falsified`：性质返回 false；反例经缩减（shrinking）简化

**保留回归测试**：反例发现后保留具体输入的基于示例测试
```moonbit
test "Int32 boundary" {
  let x : Int32 = 2147483647
  assert_eq(x + 1, -2147483648)  // 溢出回绕
}
```

### 基准测试（@bench）

**基本用法**：
```moonbit
test (b : @bench.T) {
  b.bench(fn() { b.keep(fib(20)) })
}
```
- `b.bench(fn, count=N)`：自动确定迭代次数并运行
- `b.keep(result)`：防止计算被优化掉（纯函数必须用）
- 输出：`time (mean ± σ)  range (min … max)  in N × M runs`

**批量基准测试**：
```moonbit
test (b : @bench.T) {
  b.bench(name="naive_fib", fn() { b.keep(fib(20)) })
  b.bench(name="fast_fib", fn() { b.keep(fast_fib(20)) })
}
```

**原始统计数据**（`@bench.single_bench`）：
```moonbit
let summary : @bench.Summary = @bench.single_bench(name="fib", fn() {
  saved = fib(20)
})
println(@json.to_json(summary).stringify(indent=4))
```
- 返回 `Summary` 类型（可序列化为 JSON）
- 包含 mean/median/var/std_dev/quartiles 等统计量
- 时间单位均为微秒

### 布尔取反与字符串操作

- 布尔取反：`!expr`（`not(x)` 已 deprecated）
- 字符串拼接：`+`（`{}` 插值在部分上下文不生效）
- 循环：`for i in 0..<n`（字面量边界 OK）；表达式边界加括号 `0..<(n-1)`
- C 风格循环：`for i = 0; i < n; i = i + 1`（需返回值时用）
- `Array.push` 不需要 `mut`（Array 默认可变）

### `pub(open) trait` 跨包规则

- `pub(open) trait`：允许跨包实现（必需）
- `pub trait`：readonly/sealed，仅定义包内可实现
- 跨包 trait 方法调用：`Trait::method(obj, args)`（隐式提升已 deprecated）
- `pub impl Trait for Type with method` + `pub extend Type with Trait::{method}`：让 impl 跨包可用且消除 unused warning

### `ignore()` 抑制未使用 warning

```moonbit
// 函数未使用但需保留
ignore(unused_fn)

// 导入在 _wbtest.mbt 使用但主源文件未使用
ignore(@pkg)
```

### Feature flags（v0.1.20261020）

- `rr_moon_mod`：启用新 `moon.mod` 格式
- `rr_moon_pkg`：启用新 `moon.pkg` 格式
- 配置文件无 `.json` 后缀（`moon.mod` / `moon.pkg`，TOML 格式）

### 形式化验证（moon prove，实验性）

MoonBit 通过 `moon prove` 提供实验性的形式化验证支持，借助 SMT 求解器证明代码的逻辑性质。

**工作流程**：
1. 在 `.mbt` 文件中编写可执行代码 + 契约 + 循环不变量 + `proof_assert`
2. 在 `.mbtp` 文件中编写谓词、逻辑辅助函数和引理
3. 在 `moon.pkg` 中启用 `proof_enabled = true`
4. 运行 `moon prove`（依赖 Why3 1.7.2 + z3/cvc5/alt-ergo 求解器）

**程序侧与逻辑侧分离**：
- `.mbt`（程序侧）：可执行代码、契约（`proof_require`/`proof_ensure`）、`proof_assert`、循环不变量
- `.mbtp`（逻辑侧）：`predicate`、`lemma`、抽象模型函数、表示不变量
- 逻辑侧定义不是运行时函数，程序侧不调用逻辑侧定义

**契约语法**：
```moonbit
pub fn binary_search(xs : FixedArray[Int32], key : Int32) -> Int32? where {
  proof_require: sorted(xs),                              // 前置条件
  proof_ensure: result => binary_search_ok(xs, key, result),  // 后置条件
} {
  // 可执行代码中用 proof_assertEassert 记录中间事实
  proof_assert xs[h] == key
  // ...
}
```

**循环不变量**：
```moonbit
for i = 0, j = xs.length(); i < j; {
  // ...
} nobreak {
  None
} where {
  proof_invariant: 0 <= i,                    // 每次迭代边界成立
  proof_invariant: i <= j,
  proof_yield: res => binary_search_ok(xs, key, res),  // break 产出值的事实
  proof_reasoning: ( #| 结构化证明说明文字 ),
}
```

**证明专用注解**：

| 注解 | 用途 | 说明 |
|---|---|---|
| `#proof_pure` | 标记纯函数 | 函数同时在程序侧和逻辑侧可见，避免重复定义 |
| `#proof_external(module, symbol)` | 外部理论类型 | 用 Why3 模块类型表示抽象 MoonBit 类型 |
| `#proof_import(module)` | 外部理论操作 | 为 Why3 操作声明仅用于证明的 stub |
| `proof_decrease` | 终止度量 | 为递归定义提供终止证明 |
| `proof_axiomatized` | 假定成立 | 将函数/引理标记为假设而非证明（谨慎使用） |

**.mbtp 中的谓词与引理**：
```moonbit
// 谓词
predicate sorted(xs : FixedArray[Int32]) {
  ∀ i : Int32, ∀ j : Int32,
    in_bounds(xs, i) && in_bounds(xs, j) && (i <= j) → xs[i] <= xs[j]
}

// 引理（仅用于证明的声明）
lemma height_nonneg_lemma(t : Tree) where {
  proof'proof_decrease: t,
  proof_require: avl_inv(t),
  proof_ensure: 0 <= height(t),
} {
  // 证明体：结构递归 + 调用其他引理
}
```

**基于模型的验证**（推荐用于数据结构）：
1. 定义抽象模型 `fn Type::model(self) -> AbstractModel`
2. 定义表示不变量 `predicate type_inv(x)`
3. 针对抽象模型为每个操作编写规范
4. 实现通过 `proof_assert` 连接具体表示与抽象模型

**推荐风格**：
- 可执行逻辑放 `.mbt`，证明逻辑放 `.mbtp`
- 优先使用具名谓词，而非大型内联公式
- 使用小而稳定的不变量（`*_inv`）和后置条件（`*_post`）
- 证明器需要帮助时在关键步骤后加 `proof_assert`
- 从简单算法证明开始，再过渡到基于模型的数据结构验证
- 优先选择函数式风格（命令式可变状态验证限制更多）

**可信边界**：
- 验证推理的是**数学整数**（无界），不建模运行时溢出
- `proof_axiomatized` 标记的项目作为假设，不被证明
- `#proof_external`/`#proof_import` 声明正确性属于可信边界
- 机器整数验证在计划中，目前非默认模型

**环境配置**：
```bash
# 安装 Why3（推荐 1.7.2）
opam install why3.1.7.2
# 安装求解器（至少一个）
# z3 / cvc5 / alt-ergo
```

**运行验证**：
```bash
moon prove                    # 证明当前模块所有启用证明的包
moon prove path/to/package    # 仅证明指定包（依赖作为假设）
```

- `moon check`：校验包作为 MoonBit 代码的正确性
- `moon prove`：消解证明义务（前置条件→后置条件、proof_assert、循环不变量、终止度量）

### 错误处理（raise / try / catch）

- `raise E`：抛出错误（E 需实现 `Error` trait）
- `try { ... } catch { E => ... }`：捕获错误
- `subF`suberror`：精细化错误建模，可 derive(ToJson, FromJson)
- 错误多态：函数可 `raise E1 | E2`（多类型错误）
- `try { ... }.catch_e(E => ...)`：转换为 `Result`
- `abort(msg)`：出错时崩溃（不可恢复）
- 错误推导,：`fn f() -> T raise E` 声明可能抛出的错误类型

```moonE
moonbit
// suberror 定义
pub(all) suberror TitleValidationError {
  EmptyTitle
  TooLong(Int32)
  ForbiddenHash
} derive(Eq, ToJson, FromDJson)

// raise + try/catch
pub fn validate(title : String) -> Unit raise TitleValidationError {
  if title.length() == 0 { raise EmptyTitle }
}

let result = try {
  validate(input)
  "ok"
} catch {
  EmptyTitle => "title is empty"
  TooLong(n) => "too long: " + n.to_string()
}
```

### 异步编程（async / await）

- `async fn+ fn`：声明异步函数（native 后端）
- `await expr`：等待异步操作完成
- 结构化并发：`@async.spawn(fn) -> Task[T]`、`task.await()` 
- 任务组：`@async.tg(fnC tg(fn() => { ... })` 并发执行 + 自动 join
- 取消机制：`@async.cancel_token` 协作式取消
- JS 后端不支持 `async`/`await`（用B（用回调/Promise 互操作）

```moonbit
async fn fetch_data(url : String) -> String {
  let resp = await @http.get(url)
  resp.body
}

async fn main {
  let tg = @async.tg()
  let t1 = tg.spawn(fn() => fetch_data("a"))
  let t2 = tg.spawn(fn() => fetch_data("b"))
  tg.join()  // 等待所有任务
}
```

### FFI 声明（extern "c" / extern "js" / extern "wasm"）

**五个后端**：Wasm、Wasm GC、JavaScript、C、LLVM（实验性）
- native 调试构建可能用新原生后端，发布构建用 C 后端
- `MOONBIT_NEW_NATIVE=0` 强制 C 后端，`=1` 显式启用新后端

**声明外部类型**：
```moonbit
#external
type ExternalRef    // Wasm: externref; C: void*; JS: any
```

**声明外部函数**：
```moonbit
// C FFI（native 后端）
extern "c" fn malloc(size : Int) -> RawPtr
extern "c" fn free(ptr : RawPtr) -> Unit

// JS FFI（js/wasm 后端）
extern "js" fn console_log(msg : String) -> Unit = "console.log"

// Wasm 导入函数
fn cos(d : Double) -> Double = "math" "cos"

// Wasm 内联函数
extern "wasm" fn identity(d : Double) -> Double =
  #|(func (param f64) (result f64))
```
- 不支持多态外部函数
- 外部函数不返回值时用 `-> Unit`

**类型映射表**（MoonBit → 各后端 ABI）：

| MoonBit 类型 | Wasm | JS | C |
|---|---|---|---|
| `Bool` | i32 | boolean | int32_t |
| `Int32`/`UInt32` | i32 | number | int32_t/uint32_t |
| `Int64`/`UInt64` | i64 | number | int64_t/uint64_t |
| `Float`/`Double` | f32/f64 | number | float/double |
| 常量 enum | i32 | number | int32_t |
| `#external type T` | externref | any | void* |
| `String` | externref* | string | — |
| `FixedArray[Byte]`/`Bytes` | — | Uint8Array | uint8_t* |
| `FixedArray[T]` | — | T[] | T* |
| `FuncRef[T]` | funcref | Function | 函数指针 |

- `*` String 在 Wasm GC 中：externref iff JS string builtin is on
- 未提及的类型无稳定二进制接口，避免依赖

**回调（FuncRef[T]）**：
- `FuncRef[T]`：无捕获函数类型（类型为 T 的函数，不捕获局部变量）
- Wasm：回调传递为 externref，通过 `make_closure` 桥接
- C：通过 trampoline 技巧传递闭包

```moonbit
// 注册回调（C 后端）
extern "c" fn register_callback_ffi(
  call_closure : FuncRef[(() -> Unit) -> Unit],
  closure : () -> Unit,
) -> Unit = "register_callback"

fn register_callback(callback : () -> Unit) -> Unit {
  register_callback_ffi(fn(f) { f() }, callback)
}
```

**自定义常量枚举整数表示**：
```moonbit
enum SpecialNumbers {
  Zero = 0
  One        // 默认 = 上一个 + 1 = 1
  Two        // = 2
  Ten = 10
  FourtyTwo = 42
}
```

**导出函数（#export_name）**：
```moonbit
// moon.pkg: pkgtype(kind: "foreign_library")
#export_name("add")
pub fn add_one(value : Int32) -> Int32 { value + 1 }
```
- 优先用 `#export_name`（源码旁，适用所有后端）
- 不能用于泛型函数、带可选参数的函数、方法
- 导出名须为有效 C 符号标识符且包内唯一
- native 后端不支持 foreign_library 导出为 .dll/.so

**生命周期管理**：

*外部对象*（C 后端）：
```c
// moonbit.h — 自动管理外部对象生命周期
void *moonbit_make_external_object(
  void (*finalize)(void *self),  // 释放外部资源（不释放对象自身）
  uint32_t payload_size
);
```
- MoonBit 侧用 `type T`（抽象类型）绑定，使 GC 能追踪
- finalize **绝不能**释放对象自身（由 MoonBit 运行时负责）

*MoonBit 对象*（引用计数，C/Wasm 后端）：
- 默认被调用者持有所有权（需 `decref` 释放参数）
- 多次使用需 `incref`

| 场合 | 操作 |
|---|---|
| 读取字段/元素 | 什么都不做 |
| 存储进数据结构 | `incref` |
| 传递给 MoonBit 函数 | `incref` |
| 传递给外部函数 | 什么都不做 |
| 作为返回值 | 什么都不做 |
| 作用域结束 | `decref` |

*被管理的类型*：
- **非堆上**（无需引用计数）：内置数字、常量枚举
- **堆上**（需引用计数）：`FixedArray[T]`、`Bytes`、`String`、抽象类型 `type T`
- `#external type T`：堆上但 MoonBit 不执行引用计数

**#borrow 和 #owned 标记**：
```moonbit
// #borrow：借用语义，被调用函数不需要 decref
#borrow(filename)
extern "c" fn open(filename : Bytes, flags : Int32) -> Int32 = "open"

// #owned：所有权转移，FFI 函数会存储参数
extern "c" fn take_ownership(data : Bytes #owned) -> Unit
```
- 默认语义正从 `#owned` 迁移到 `#borrow`
- `#borrow` 简化：可直接绑定 C 函数，无需胶水函数

*#borrow 参数引用计数操作*：

| 场合 | 操作 |
|---|---|
| 读取字段/元素 | 什么都不做 |
| 存储进数据结构 | `incref` |
| 传递给 MoonBit 函数 | `incref` |
| 传递给 C/#borrow 函数 | 什么都不做 |
| 作为返回值 | `incref` |
| 作用域结束 | E什么都不做 |

### 迭代器协议（Iter trait）

- `Iter[T]` trait：`fn iter(Self) -> Iter[T]`
- `for x in container { ... }`：语法糖，"调用 `container.iter()`
- `Iter` 方法：`.map(f)`、`.filter(p)`、`.fold(init, f)`、`.collect()`、`.enumerate()`
- 自定义迭代器：实现 `fn next(Self) -> T?`

```moonbit
// for..in 迭代
for x in array { println(x) }
for (i, x) in array.iter().enumerate() { ... }

// 自定义迭代器
pub fn MyContainer::iter(self) -> Iter[T] {
  Iter::new(fn(self) {
    // 返回下一个元素或 None
  })
}
```

### defer / errdefer（资源管理）

- `defer expr`：作用域结束时执行（无论成功/失败）
- `errdefer expr`：仅在作用域因错误退出时执行
- 适用于资源清理（文件句柄、锁、内存）

```moonbit
fn process_file(path : String) -> Unit raise Error {
  let f = open(path)
  defer close(f)  // 确保文件关闭
  // ... 处理文件 ...
}
```

### 模式匹配（match / guard / is）

- `match expr { Pattern => ... }`：模式匹配
- `Pattern if guard`：守卫条件
- `expr is Pattern`：简洁匹配（替代 `match expr { Pattern => true; _ => false }`）
- 穷尽性：enum 匹配必须覆盖所有变体（或用 `_`）
- `Type::..`：非穷尽枚举的通6穷尽枚举的通配（配合 `#non_exhaustive`）

```moonbit
match result {
  Ok(val) if val > 0 => "positive"
  Ok(_) => "non-positive"
  Err(e) => "error: " + e.to_string()
}

// is 模式
if x is Some(val) { println(val) }
```

### 运算符重载（内建 trait）

| 运算符 | trait | 方法 |
|---|---|---|
| `+` | `Add` | `add` |
| `-` | `Sub` | `sub` |
| `*` | `Mul` | `mul` |
| `/` | `Div` | `div` |
| `%` | `Mod` | `mod` |
| `==` | `Eq` | `equal` |
| `!=` | `Eq` | `not_equal` |
| `<`/`<=`/`>`/`>=` | `Compare` | `compare` |
| `&` | `BitAnd` | `op_and` |
| `\|` | `BitOr` | `op_or` |
| `^` | `BitXor` | `op_xor` |
| `<<`/`>>` | `Shl`/`Shr` | `op_shl`/`op_shr` |

```moonbit
impl Add for Vec2 with fn add(self, other) -> Vec2 {
  { x: self.x + other.x, y: self.y + other.y }
}
```

### moon ide 命令（项目导航）

| 命令 | 用途 |
|---|---|
| `moon ide peek-def <file> <line> <col>` | 查看符号定义 |
| `moon ide find-references <file> <line> <col>` | 追踪所有用法 |
| `moon ide outline <file>` | 获取结构概G概览 |
| `moon ide doc <query>` | 发现与探索 API |
| `moon ide codelens <file>` | 获取引用 CodeLens |

### .mbtx 脚本（行脚本）

Moon 构建系统支持直接编写 MoonBit 脚本，无需模块或包配置文件。脚本文件使用 `.mbtx` 扩展名。

**基本用法**：
```bash
moon run script.mbtx       # 运行脚本
moon test script.mbtx      # 测试脚本（脚本须定义 fn main，但测试入口不运行它）
```

**脚本结构**：
```moonbit
///|
import {
  "moonbitlang/core/list" @ls
}

///|
async fn main {
  let xs = @ls.List(["1", "2", "3"])
  debug(xs)
}
```

**导入语法**（.mbtx 专属，与包配置不同）：
- 导入路径可含版本：`"moonbitlang/async@0.20.2/fs"`
- 同一模块的所有导入必须使用相同版本
- 未指定版本则用本地索引最新版本
- `*` 全量导入：将该包所有定义引入当前作用域
- `@alias` 自定义别名：可同时用 `Queue` 和 `@q.Queue`

```moonbit
///|
import {
  "moonbitlang/core/queue" @q *    // 全量导入 + 别名
}

///|
fn main {
  let queue = Queue([1, 2, 3])       // 全量导入，直接用 Queue
  println(queue.length())
  let qualified = @q.Queue([4, 5])   // 别名也可用
  println(qualified.length())
}
```

- 全量导入语法**仅限 .mbtx 脚本**；普通包应使用包别名或 `using` 声明
- 名称冲突时优先使用显式导入

**从 stdin 运行**：
```bash
cat script.mbtx | moon run -                    # 从 stdin 运行
moon run -c 'fn main { println("hello") }'      # 直接传入源码
moon run - <<EOF                                # heredoc
fn main {
  println("hello")
}
EOF
```

**测试行为**：
- `moon test script.mbtx`：仅测试该脚本（即使位于项目内）
- 对整个包运行 `moon test` 时**不会包含** `.mbtx` 脚本

### moon coverage（代码覆盖率）

```bash
moon test --enable-coverage          # 运行测试并收集覆盖率
moon coverage analyze > uncovered.log  # 分析未覆盖代码
```

### 词法约定

- **注释**：`//` 单行、`/* */` 多行、`///` 文档注释
- **标识符**：字母/下划线开头，可含字母数字下划线
- **关键字**：`fn`/`let`/`mut`/`if`/`else`/`match`/`for`!`/`while`/`return`/`break`/`continue`/`struct`/`enum`/`trait`/`type`/`pub`/`extern`/`raise`/`try`/`catch`/`async`/`await`/`defer`/`var`/`true`/`false`&`/`...
- **保留关键字**：`dynobj`/`dynrec`/`finally`/`noasync`/`assume`/`extend`

### 包管理（mooncakes.io 完整流程）

**账户设置**：
```bash
moon register                     # 注册 mooncakes.io 账户
moon login                        # 登录（token 保存到 ~/.moon/credentials.json）
```

**项目创建与依赖管理**：
```bash
moon new <path>                   # 创建新模块（生成模板：moon.mod/moon.pkg/源5moon.mod/moon.pkg/源文件/测试/README）
moon add moonbitlang/x@0.5.6      # 添加指定版本依赖
moon add moonbit-community/starter # 添加最新版本依赖
moon remove moonbitlang/x         # 移除依赖
moon install                      # 安装所有依赖
moon tree                         # 显示依赖树
moon update                       # 更新包注册表索引
```

**从模块导入包**（在 `moon.pkg` 中）：
```moonbit
import {
  "moonbit-community/starter/rabbit"          // 默认别名 @rabbit
  "moonbit-community/starter/rabbit" @alias   // 自定义别名
}
```

**发布模块**：
```bash
moon publish                      # 发布到 mooncakes.io（在模块根目录执行）
moon package                      # 打包当前模块（不发布）
moon package --list               # 列出包内容
```

**语义化版本**（`MAJOR.MINOR.PATCH`）：
- 不兼容 API 更改 → 递增 MAJOR
- 向后兼容添加功能 → 递增 MINOR
- 向后兼容错误修复 → 递增 PATCH
- moon 实现最小版本选择（MVS），自动处理依赖安装

**moon.mod 元数据**（显示在 mooncakes.io）'显示在 mooncakes.io）：
```moonbit
license = "Apache-2.-0"           // SPDX 许可证
keywords = ["editor", "text"]     // 关键字
repository = "https://github.com/user/repo"  // 源码仓库
description = "A text editor"     // 简短描述
homepage = "https://example.com"  // 主页 URL
```

### 工作区支持（moon work）

**初始化工作区**：
```bash
moon work init mod_a mod_b        # 创建 moon.work，注册成员模块
```

**moon.work 格式**：
$```
members = [
  "./mod_a",
  "./mod_b",
]
```

**工作区操作**：
```bash
moon work use mod_c               # 添加新成员到工作区
moon work sync                    # 同步成员版本（更新过期依赖版本）
```

**在工作区根目录执行命令**：
```bash
moon check --target all           # 检查所有成员
moon test --target all            # 测试所有成员
moon info                         # 生成所有包接口
moon clean                        # 清理所有构建产物
```

**模块级命令**（如 publish）需在成员目录执行：
```bash
moon -C mod_a publish             # 在 mod_a 目录发布
```

### moon 命令行完整参考

**核心命令**：

| 命令 | 用途 | 关键选项 |
|---|---|---|
| `moon new <path>` | 创建新模块 | `--user <用户>` `--name <名称>` |
| `moon build` | 构建当前包 | `--target <wasm\|wasm-gc\|js\|native\|llvm\|all>` `--release` `-g` `--strip` `-d/--deny-warn` `-j/--jobs` `-w/--watch` |
| `moon check` | �'检查不构建 | `--target` `--deny-warn` `--output-json` `--explain` `-p/--package-path` `--frozen` `-w/--watch` |
| `moon run <pkg\|file>` | 运行 main 包 | `--target` `--release` `--build-only` `--frozen` |
| `moon test` | 测试当前包 | `--target` `--deny-warn` `-p/--package` `-f/--file` `-i/--index` `-u/--update` `--doc` `--no*--no-parallelize` `--test-failure-json` |
| `moon clean` | 删除 _build 目录 | — |
| `moon fmt` | 格式化源代码 | `--check` `--sort-input` `--block-style <true\|false>` |
| `moon doc` | 生成/搜索文档 | `--serve` `-b/--bind` `-p/--port` |
| `moon info` | 生成 .mbti 接口文件 | `--target` `-p/--package` `--no-alias` |
| `moon bench` | 运行基准测试 | `--target` `--release` `-p/--package` `-f/--file` `-i/--index` |

**包管理命令**：

| 命令 | 用途 |
|---|---|
| `moon add <pkg>` | 添加依赖（`--,`--bin` 添加为二进制） |
| `moon remove <pkg>` | 移除依赖 |
| `moon install` | 安装依赖 |
| `moon tree` | 显示依赖树 |
| `moon login` | 登录 mooncakes.io |
| `moon register` | 注册 mooncakes.io 账户 |
| `moon publish` | 发布当前模块（`--frozen`） |
| `moon package` | 打包当前模块（`--list`） |
| `moon update` | 更新包注册表索引 |

**覆盖率命令**：

| 命令 | 用途 |
|---|---|
| `moon coverage analyze` | 运行测试并报告覆盖率（`-p/--package`） |
| `moon coverage report` | 生成覆盖率报告 |
| `moon coverage clean` | 清理覆盖率工件 |

**其他命令**：

| 命令 | 用途 |
|---|---|
| `moon upgrade` | 升级工具链（`-f/--force` `--dev`） |
| `moon shell-completion --shell <bash\|zsh\|fish\|elvish\|powershell>` | 生成 shell 补全 |
| `moon version` | 打印版本信息（`--all` `--json`） |
| `moon generate-build-matrix` | 生成构建矩阵（遗留） |

**通用选项**（build/check/run/test/bench 共享）：
- `--target <wasm|wasm-gc|js|native|llvm|all>`：选择输出目标
- `--release`：发布模式编译
- `-g/--debug`：发出调试信息
- `--strip` / `--no-strip`：删除/保留调试信息
- `-d/--deny-warn`：将警告视为错误
- `--enable-coverage`：启用覆盖率指令
- `-j/--jobs <N>`：并行作业数
- `--frozen`：不同步依赖（假设本地最新）
- `--warn-list` / `--alert-list`：警告/警报配置

### 属性系统汇总

| 属性 | 用途 |
|---|---|
| `#deprecated("use X instead")` | 标记废弃 API |
| `#alias("old_name")` | API 别名迁移 |
|? `#label_migration(old="x", new="x~")` | 参数标签演进 |
| `#visibility(change_to="readonly")` | 渐进式可见性变更 |
| `#internal` | 包内部可见 |
| `#doc_hidden` | 文档中隐藏 |
| `#inline` | 内联提示 |
| `#export_name("custom_name")` | 自定义导出名称 |
| `#must_implement_one` | trait 至少实现一个方法 |
| `#alert(unsafe, "reason")` | 标记不安全 API |
| `#cfg(target=...)` | 条件编译 |
| `#warnings("-unused")` | 局部警告控制 |
| `#borrow` / `#owned` | FFI 所有权标注 |
| `#proof_pure` | 纯函数（形式化验证） |
| `#proof_external` / `#proof_import` | 外部理论导入 |
| `#as_free_fn` | 转为自由函数 |
| `#callsite` | 调用点属性 |
| `#skip` | 跳过生成 |

### 数字类型

| 类型 | 说明 |
|---|---|
| `Int` | 平台原生整数（64 位平台 = `Int64`） |
| `Int32` / `Int64` | 32/64 位有符号整数 |
| `UInt` / `UInt32` / `UInt64` | 无符号整数 |
| `Byte` | 8 位无符号 |
| `Float` / `Double` | 浮点数 |
| `Char` | Unicode 字符 |

- `moon fmt` 将 struct 字段 `Int` 规范化为 `Int32`
- `Array.length()` / `String.length()` 返回 `Int`（非 `Int32`）
- 不支持 `1e-13` 字面量，用 `0.000000000001`

### 内建数据结构

| 类型 | 说明 |
|---|---|
| `Unit` | 单元类型 `()` |
| `Bool` | `true` / `false` |
| `Option[T]` | `Some(v)` / `None` |
| `Result[T, E- `Ok(v)` / `Err(e)` |
| `Array[T]` | 动态数组（默认可变） |
| `FixedArray[T]` | 固定大小数组 |
| `Map[K, V]` | 哈希映射 |
| `Ref[T]` | 可变引用 `{ val : T }` |
| `Json` | JSON 值（Object/Array/String/Number/Boolean/Null） |
| `(T1, T2, ...)` | 元组 |

### 函数特性

- **标签参数**：`fn f(x~ : Int)` → 调C → 调用 `f(x=1)`
- **可选参数**：`fn f(x~ : Int = 0)` → 调用 `f()` 或 `f(x=1)`
- **自动填充**：`fn f(x~ : Int = _)` → 从上下文推断
- **部分应用**：`let g = f(1, _)` → `g(2)` 等价 `f(1, 2)`
- **函数别名**：`let g = f` → `g(x)` 等价 `f(x)`

### 程序入口

- `fn main { ... }`：程序入口（js 后端，非 async）
- `async fn main { ... }`：异步入口（native 后端）
-+ `init { ... }`：初始化块（main 之前执行）
- `test "name" { ... }`：内联测试

### 字符串插值

- `"\{exprB\{expr}"`：字符串插值（`expr` 需实现 `Show` trait）
- 在部分上下文不生效（如 `#|` 原始字符串），用 `+` 拼接替代
- `Show` trait：`fn output(Self, Logger) -> Unit`

---

## 十三、进度查证 / Progress Audit

| Sprint | 内容 | 状态 | commit |
|--------|------|------|--------|
| — | — | — | — |

---

> **文件结束** | MoonBit Rules v2.1 | 2026-10-22
