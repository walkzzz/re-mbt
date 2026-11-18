# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- 多根包拆分：将原单包 `re` 拆分为 5 个根包 `re_base`/`re_ast`/`re_compile`/`re_exec`/`re_frontend`（ADR-006）
- 5 子包 `README.md`（re_base、re_ast、re_compile、re_exec、re_frontend）
- 根包重导出：`moon.pkg` + `reexport.mbt`，统一重导出 5 子包公共 API（R10/R12）
- `re/README.md` 子包 API 说明（R10）
- `docs/api.md` 公共 API 参考文档（R8）
- `docs/architecture.md` 架构决策记录（5 条 ADR）（R8）
- `docs/design.md` 核心设计文档（R8）
- `docs/examples.md` 使用示例与最佳实践（R8）
- `docs/roadmap.md` 迭代路线
- `CHANGELOG.md` 变更记录

### Changed
- 架构决策更新：ADR-001 由"单包结构"改为"多根包结构"
- 源文件跨包引用：全部改为 `@pkg.X` 全限定名
- 测试文件迁移至对应子包，跨包测试改用黑盒 `_test.mbt`
- Warning 治理完成：2214 → 0 warning（R13 目标达成）；拆包阶段 13 → 0
- moon.mod 添加 `preferred_target` + `supported_targets`（R33）
- 为 3 个 `pub fn` 添加 `///` 文档注释（R3）

### Fixed
- `re/cset.mbt`：`Array::new(capacity=...)` → `Array(capacity=...)`，消除 3 个 deprecated warning (W0020)
- 为 11 个 derive(Debug/Eq/Compare) 类型添加 `pub extend Type with Trait::{method}` 声明，消除 26 个 implicit_impl_as_method warning (W0079)
- 批量替换测试文件和 README.mbt.md 中 2327 处裸标识符为 `@re.X` 全限定名，消除 2185 个 test_unqualified_package warning (W0025)
- Glob 解析器：字符类 `[abc]` 普通字符分支误报 parse error（`glob_enclosed_loop` 非转义分支直接 fail）；`[a-z]` 范围与 `[!abc]`/`[^abc]` 补集经 Cset 合并构造（`Ast::inter` 归约）；`[`/`[\` 未闭合 eos 防御
- Perl 前端：`\x{4F}` hex 转义数字序反转导致码点错误（去反转、支持任意位数）；`a{` 中游离 `{` 按字面量处理（对齐上游 ocaml-re）
- Emacs 前端：`emacs_pipe` 定义缺失反斜杠（`"\|"` 分支永不可达）；空模式与裸 `)` 报 parse error（对齐上游）
- POSIX 前端：`a{` 游离 `{` 字面量回退；空模式报 parse error
- `Replace::replace`：pos/len 窗口语义修复——窗口外前缀 `[0,pos)` 与后缀 `[limit,length)` 文本保留（上游 ocaml-re 行为）
- `Expr::cst` 空 Cset 构造为 `Eps`（对齐上游 ocaml-re automata.ml）
- `MarkInfos::make` 防御负索引（absent mark -1 跳过写入）
- 全项目 17 处 deprecated `derive(...)` 尾置语法迁移为 `#derive(...)` 前置声明，`moon check --deny-warn` 归零

## [0.1.0] - 2026-08-14

### Added
- 移植 ocaml-re 至 MoonBit，11,347 行代码，52 个 .mbt 文件
- 6 个前端：Perl, PCRE, POSIX, Emacs, Glob, Str
- 437 个测试，全部通过
- CI 配置 (`.github/workflows/ci.yml`)
- LICENSE 文件 (LGPL-2.1-or-later WITH OCaml-LGPL-linking-exception)
- `re/README.mbt.md` 可执行示例

### Fixed
- `Str::global_replace`/`replace_first` 忽略替换模板参数
- `global_substitute`/`substitute_first` 签名支持抛异常
- `core.mbt` 中 `to_repr` 废弃用法
- `coverage_test.mbt` 拆分为 5 个文件
- 内部类型暴露为 `pub` → 标记 `priv`

### Published
- 发布至 mooncakes.io: `walkzzz/re-mbt@0.1.0`