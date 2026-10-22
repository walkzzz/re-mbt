// Traits — P0 trait implementations for re_ast types (R18/R19)
// 跨包 impl re_base 定义的 pub(open) trait。

// --- Dynable implementations ---

///|
pub impl @base.Dynable for Ast with fn to_dyn(self) {
  Ast::to_dyn(self)
}

///|
pub impl @base.Dynable for State with fn to_dyn(self) {
  State::to_dyn(self)
}

///|
pub impl @base.Dynable for Expr with fn to_dyn(self) {
  Expr::to_dyn(self)
}

// --- Hashable implementations ---

///|
pub impl @base.Hashable for Marks with fn hash(self, accu) {
  Marks::hash(self, accu)
}

///|
pub impl @base.Hashable for ET with fn hash(self, accu) {
  ET::hash(self, accu)
}

// --- Equatable implementations ---

///|
pub impl @base.Equatable for State with fn equal(self, other) {
  State::equal(self, other)
}

///|
pub impl @base.Equatable for Marks with fn equal(self, other) {
  Marks::equal(self, other)
}

///|
pub impl @base.Equatable for ET with fn equal(self, other) {
  ET::equal(self, other)
}
