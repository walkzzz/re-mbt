# Warning Governance Plan v1

## Round 1 Scope
本轮目标：修复 3 类 warning，预计消除 191 个 warning（占总量 250 的 76.4%）

基线数据来源：`check_v1.md`（Total: 250, 有效需修复: 231，扣除 19 个 phantom structs）

---

## Batch 1: core_package_not_imported (120)

- **根因分析**：测试文件使用 `@test.assert_eq` 等 API，但 `re/moon.pkg` 中 test 配置导入的是旧路径 `moonbitlang/test`，MoonBit 核心包已迁移到 `moonbitlang/core/test`，导致编译器报 "Package `test` from `moonbitlang/core/` is used without import"。
- **修复策略**：将 `re/moon.pkg` 中 test import 路径从 `moonbitlang/test` 更新为 `moonbitlang/core/test`。一处配置修改即可消除全部 120 个 warning。
- **涉及文件**：
  - `re/moon.pkg`（唯一需修改的配置文件）
- **受影响测试文件**（无需修改，仅列出用于核对数量）：
  - `re/basics_test.mbt` (46)
  - `re/ast_test.mbt` (36)
  - `re/automata_test.mbt` (16)
  - `re/compile_test.mbt` (12)
  - `re/color_map_test.mbt` (10)
- **具体操作**：
  ```diff
   options(
  -  "test": { "import": [ "moonbitlang/test" ] },
  +  "test": { "import": [ "moonbitlang/core/test" ] },
   )
  ```
- **风险**：极低。纯配置路径迁移，API 用法不变。
- **验证**：`moon check` 后 120 个 0071 warning 全部消失，测试仍可通过。

---

## Batch 2: redundant_modifier (41)

- **根因分析**：`pub struct` 的字段默认即为 public，字段上再写 `pub` 修饰符属于冗余，编译器提示 "The public modifier is redundant here since field X is public by default"。
- **修复策略**：机械删除 struct 字段定义中的 `pub` 修饰符（仅删字段前的 `pub` 关键字，保留 struct 本身的 `pub`）。
- **涉及文件与行号**（共 41 处，8 个文件）：
  - `re/automata_state.mbt` (8): L16-20, L95-97
  - `re/bit_vector.mbt` (2): L6-7
  - `re/category.mbt` (1): L6
  - `re/compile.mbt` (24): L59-61, L68-69, L107-108, L148-157, L174-175, L605-609
  - `re/cset.mbt` (1): L45
  - `re/hash_set.mbt` (1): L8
  - `re/mark_infos.mbt` (2): L7, L37
  - `re/pmark.mbt` (2): L8, L48
- **具体操作示例**：
  ```diff
   ///|
   pub struct StateInfo {
  -  pub idx : Int
  -  pub final_ : Array[(Category, (Int, Status))]
  -  pub desc : State
  +  idx : Int
  +  final_ : Array[(Category, (Int, Status))]
  +  desc : State
   }
  ```
- **风险**：极低。`pub struct` 字段可见性不变，外部访问行为完全一致。
- **验证**：`moon check` 后 41 个 0008 warning 全部消失，`moon test` 通过。

---

## Batch 3: deprecated (30)

- **根因分析**：代码使用了已废弃的函数/语法，需更新为新语法。分 4 子类：
- **修复策略与子类**：

### 3a. `not(x)` → `!x` (23 处)
- **涉及文件与行号**：
  - `re/cset.mbt`: L185
  - `re/emacs.mbt`: L90, L192, L206
  - `re/fmt.mbt`: L65
  - `re/perl.mbt`: L154, L185, L194, L203, L301, L323, L327, L512, L515, L602
  - `re/pmark.mbt`: L131
  - `re/posix_class.mbt`: L37, L52
  - `re/posix.mbt`: L76, L105, L232, L235, L269
- **操作示例**：`if not(leftover)` → `if !leftover`

### 3b. `reinterpret_as_uint().to_int()` → `reinterpret_as_int()` (4 处)
- **涉及文件与行号**：
  - `re/compile.mbt`: L123, L139
  - `re/hash_set.mbt`: L49, L93
- **操作示例**：
  ```diff
  - let h = key.hash.reinterpret_as_uint().to_int() & (tbl.buckets.length() - 1)
  + let h = key.hash.reinterpret_as_int() & (tbl.buckets.length() - 1)
  ```

### 3c. `x.is_empty()` (Option) → `x is None` (2 处)
- **涉及文件与行号**：
  - `re/pcre.mbt`: L74 — `result.is_empty()` → `result is None`
  - `re/posix_class.mbt`: L43 — `cls.is_empty()` → `cls is None`
- **注意**：仅当 `x` 类型为 `Option` 时适用；需确认上下文类型为 `Bytes?`/`String?` 等 Option 类型。

### 3d. `Ref::new(x)` → `Ref::{val: x}` 或新构造语法 (1 处)
- **涉及文件与行号**：
  - `re/str.mbt`: L13 — `Ref::new(None)` → 按 MoonBit 新语法替换（`Ref::(None)` 或 `{val: None}` 视编译器提示）
- **风险**：低。需根据 `moon check` 的具体提示确定确切新语法。

- **整体风险**：低。均为等价语法替换，语义不变。
- **验证**：`moon check` 后 30 个 0020 warning 全部消失，`moon test` 通过。

---

## Out of Scope (本轮不处理)

以下 5 类 warning 共 59 个，本轮不处理，留待后续轮次：

| Code | Type | Count | 不处理原因 | 后续计划 |
|------|------|-------|-----------|---------|
| 0001/0002 | unused_value | 25 | 需逐个判断是否为预留 API（fmt.mbt 13 个格式化函数、compile_test.mbt 3 个测试辅助、str.mbt 4 个变量等） | Round 2 |
| 0009 | struct_never_constructed | 19 | phantom structs 是有意设计（newtype 类型安全标记：Mark/Idx/Desc/CompileIdx 等），**不应修复** | 永久排除 |
| 0004 | missing_priv | 8 | 需为 8 个类型添加 `priv` 修饰符（Ctx/CompileContext/GlobPiece/PerlOpts 等），涉及公共签名语义，需谨慎 | Round 2 |
| 0006 | unused_constructor | 4 | 4 个 PCRE variant (Caseless/MultilineP/AnchoredP/DotallP) 从未构造，需判断是否预留功能 | Round 3 |
| 0024 | unused_error_type | 3 | 3 个函数错误类型从未使用，涉及 pcre.mbt/perl.mbt，需评估 API 设计 | Round 3 |

---

## Execution Order

1. **Batch 1**（配置修复）→ `moon check` 验证 0071 消除
2. **Batch 2**（机械删除 pub）→ `moon check` 验证 0008 消除
3. **Batch 3**（语法替换）→ `moon check` 验证 0020 消除
4. **全量验证**：`moon check` + `moon test`，确认无回归

## Expected Outcome

- 本轮消除：120 + 41 + 30 = **191 个 warning**
- 剩余：250 - 191 = **59 个**（其中 19 个 phantom structs 永久排除，有效剩余 40 个）
- 产出：`check_v2.md`（剩余 warning 报告）
