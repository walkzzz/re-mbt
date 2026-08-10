// Category — character categories for look-ahead/look-behind (port of lib/category.ml)
// OCaml: type t = int with bit flags. MoonBit: struct wrapping Int bits.

///|
pub struct Category {
  bits : Int
} derive(Debug, Eq, Compare)

///|
pub fn Category::from_int(i : Int) -> Category {
  { bits: i }
}

///|
pub fn Category::to_int(self : Category) -> Int {
  self.bits
}

///|
pub fn Category::equal(x : Category, y : Category) -> Bool {
  x.bits == y.bits
}

///|
pub fn Category::compare(x : Category, y : Category) -> Int {
  x.bits.compare(y.bits)
}

///|
pub fn Category::intersect(x : Category, y : Category) -> Bool {
  (x.bits & y.bits) != 0
}

///|
pub fn Category::add(x : Category, y : Category) -> Category {
  { bits: x.bits | y.bits }
}

///|
pub fn Category::dummy() -> Category {
  { bits: -1 }
}

///|
pub fn Category::inexistant() -> Category {
  { bits: 1 }
}

///|
pub fn Category::letter() -> Category {
  { bits: 2 }
}

///|
pub fn Category::not_letter() -> Category {
  { bits: 4 }
}

///|
pub fn Category::newline() -> Category {
  { bits: 8 }
}

///|
pub fn Category::lastnewline() -> Category {
  { bits: 16 }
}

///|
pub fn Category::search_boundary() -> Category {
  { bits: 32 }
}

// from_char: should match [cword] definition in Cset.
// latin1 word chars: a-z A-Z 0-9 _ º µ ª (170/181/186) À-Ö Ø-ö ø-ÿ

///|
pub fn Category::from_char(c : Char) -> Category {
  let i = c.to_int()
  let is_word = (i >= 97 && i <= 122) ||
    (i >= 65 && i <= 90) ||
    (i >= 48 && i <= 57) ||
    i == 95 ||
    i == 170 ||
    i == 181 ||
    i == 186 ||
    (i >= 192 && i <= 214) ||
    (i >= 216 && i <= 246) ||
    (i >= 248 && i <= 255)
  if is_word {
    Category::letter()
  } else if i == 10 {
    Category::add(Category::not_letter(), Category::newline())
  } else {
    Category::not_letter()
  }
}

///|
pub fn Category::to_dyn(self : Category) -> Dyn {
  Dyn::int(self.bits)
}
