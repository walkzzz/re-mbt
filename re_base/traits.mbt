// Traits — P0 trait abstractions (R18/R19)
// 公共行为模式抽象为 pub(open) trait，消除跨模块代码重复。

///|
/// 可转换为动态值。
/// Convertible to dynamic value for debugging.
pub(open) trait Dynable {
  fn to_dyn(Self) -> Dyn
}

///|
/// 可哈希。
/// Hashable with accumulator.
pub(open) trait Hashable {
  fn hash(Self, Int32) -> Int32
}

///|
/// 可判等。
/// Equatable with custom equality.
pub(open) trait Equatable {
  fn equal(Self, Self) -> Bool
}

// --- Dynable implementations for re_base types ---

///|
pub impl Dynable for Sem with fn to_dyn(self) {
  Sem::to_dyn(self)
}

///|
pub impl Dynable for RepKind with fn to_dyn(self) {
  RepKind::to_dyn(self)
}

///|
pub impl Dynable for Cset with fn to_dyn(self) {
  Cset::to_dyn(self)
}

///|
pub impl Dynable for Pmark with fn to_dyn(self) {
  Pmark::to_dyn(self)
}

///|
pub impl Dynable for Category with fn to_dyn(self) {
  Category::to_dyn(self)
}

// --- Hashable implementations for re_base types ---

///|
pub impl Hashable for Cset with fn hash(self, accu) {
  Cset::hash(self, accu)
}
