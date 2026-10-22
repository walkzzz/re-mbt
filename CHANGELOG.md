# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Warning 治理完成：2214 → 0 warning（R13 目标达成）

### Fixed
- `re/cset.mbt`：`Array::new(capacity=...)` → `Array(capacity=...)`，消除 3 个 deprecated warning (W0020)
- 为 11 个 derive(Debug/Eq/Compare) 类型添加 `pub extend Type with Trait::{method}` 声明，消除 26 个 implicit_impl_as_method warning (W0079)
- 批量替换测试文件和 README.mbt.md 中 2327 处裸标识符为 `@re.X` 全限定名，消除 2185 个 test_unqualified_package warning (W0025)

### Added
- `docs/roadmap.md` 迭代路线
- `CHANGELOG.md` 变更记录

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