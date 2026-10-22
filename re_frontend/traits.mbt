// Traits — P3 trait abstractions for frontends (R18/R19)
// 前端方言统一入口的 pub(open) trait 抽象，消除跨前端代码重复。
// 注意：MoonBit v0.1.20261020 不支持泛型 trait（trait[Opt]），RegexParser
// 统一为不带 opts 的默认解析入口；trait 方法不支持默认参数值。

///|
/// 正则表达式解析器。
/// Regular expression parser trait.
/// 统一各前端默认解析入口 re(Self, Bytes) -> Ast。
pub(open) trait RegexParser {
  fn re(Self, Bytes) -> @ast.Ast raise
}

///|
/// 正则表达式编译器。
/// Regular expression compiler trait.
/// 统一编译入口，case 参数需显式传递。
pub(open) trait RegexCompiler {
  fn compile_pat(Self, Bytes, case~ : Bool) -> @compile.Re raise
}

///|
/// 可转义的正则表达式。
/// Quotable regular expression trait.
pub(open) trait Quotable {
  fn quote(Self, Bytes) -> Bytes
}

// --- Default trait 方法提升为常规方法（消除 implicit_impl_as_method warning） ---

///|
pub extend Perl with Default::{default}

///|
pub extend Posix with Default::{default}

///|
pub extend Pcre with Default::{default}

///|
pub extend Emacs with Default::{default}

///|
pub extend Str with Default::{default}

// --- RegexParser implementations ---
// Perl/Posix/Pcre: 默认 opts/flags=[]；Emacs: 默认 case=true。

///|
pub impl RegexParser for Perl with fn re(_self, s) {
  Perl::re(s)
}

///|
pub impl RegexParser for Posix with fn re(_self, s) {
  Posix::re(s)
}

///|
pub impl RegexParser for Pcre with fn re(_self, s) {
  Pcre::re(s)
}

///|
pub impl RegexParser for Emacs with fn re(_self, s) {
  Emacs::re(s)
}

// --- RegexCompiler implementations ---
// 仅 Emacs::compile_pat(s, case~ : Bool) 签名兼容。
// Perl/Posix::compile_pat 用 Array[Opt] 参数，不兼容；Glob::compile 多参数无 case。

///|
pub impl RegexCompiler for Emacs with fn compile_pat(_self, s, case~) {
  Emacs::compile_pat(s, case~)
}

// --- Quotable implementations ---
// Pcre::quote / Str::quote 均为关联函数 quote(Bytes) -> Bytes。
// 不使用 pub extend 以免覆盖现有关联函数签名。

///|
pub impl Quotable for Pcre with fn quote(_self, s) {
  Pcre::quote(s)
}

///|
pub impl Quotable for Str with fn quote(_self, s) {
  Str::quote(s)
}
