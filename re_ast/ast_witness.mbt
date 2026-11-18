// Ast witness — 从 AST 生成一个匹配串（port of lib/witness.ml 的 AST 层语义）
// 生成规则：字符集取代表字节，顺序/替换结构递归组合，零宽断言产出空串。
// 返回 None 表示该 AST 不可能匹配（如空字符集 / 空 alt）。

///|
/// 将 AstCset 求值为具体 Cset（无大小写处理）；不可求值（子集为空）返回 None
/// evaluate an AstCset into a concrete Cset (no case handling); None if impossible
fn witness_cset(x : AstCset) -> @base.Cset? {
  match x {
    CsetOf(c) => Some(c)
    Intersection(l) => {
      let parts : Array[@base.Cset] = []
      for e in l {
        match witness_cset(e) {
          Some(c) => parts.push(c)
          None => return None
        }
      }
      Some(@base.Cset::intersect_all(parts))
    }
    Complement(l) => {
      let parts : Array[@base.Cset] = []
      for e in l {
        match witness_cset(e) {
          Some(c) => parts.push(c)
          None => return None
        }
      }
      Some(@base.Cset::diff(@base.Cset::cany(), @base.Cset::union_all(parts)))
    }
    Difference(r, r2) => {
      match witness_cset(r) {
        Some(rc) =>
          match witness_cset(r2) {
            Some(rc2) => Some(@base.Cset::diff(rc, rc2))
            None => None
          }
        None => None
      }
    }
    Cast(alt) =>
      match alt {
        Alternative(l) => {
          let parts : Array[@base.Cset] = []
          for e in l {
            match witness_cset(e) {
              Some(c) => parts.push(c)
              None => return None
            }
          }
          if parts.is_empty() {
            None
          } else {
            Some(@base.Cset::union_all(parts))
          }
        }
        NoCase(x) => witness_cset(x)
        Case(x) => witness_cset(x)
      }
  }
}

///|
/// 单字节转 Bytes | one latin1 byte to Bytes
fn witness_byte(b : Int32) -> Bytes {
  Bytes::from_array([b.to_byte()])
}

///|
/// 从 AST 生成一个匹配串；None 表示不可能匹配
/// generate a string matched by the AST; None if no match is possible
pub fn Ast::witness(self : Ast) -> Bytes? {
  match self {
    Set(c) =>
      match witness_cset(c) {
        Some(cset) =>
          match @base.Cset::first_byte(cset) {
            Some(b) => Some(witness_byte(b))
            None => None
          }
        None => None
      }
    AstNode(alt) =>
      match alt {
        Alternative(l) =>
          if l.is_empty() {
            None
          } else {
            Ast::witness(l[0])
          }
        NoCase(x) => Ast::witness(x)
        Case(x) => Ast::witness(x)
      }
    Sequence(l) => {
      let buf : Array[Byte] = []
      for e in l {
        match Ast::witness(e) {
          Some(w) => {
            for b in w {
              buf.push(b)
            }
          }
          None => return None
        }
      }
      Some(Bytes::from_array(buf))
    }
    Repeat(gen, min, max) =>
      match Ast::witness(gen) {
        Some(w) => {
          // 重复次数 = clamp(min, 1, max)：max 为 0 时取 0（空匹配），否则至少 1 次
          let n = match max {
            Some(m) => if m < 1 {
              0
            } else {
              if min < 1 { 1 } else { min }
            }
            None => if min < 1 { 1 } else { min }
          }
          let buf : Array[Byte] = []
          for _ in 0..<n {
            for b in w {
              buf.push(b)
            }
          }
          Some(Bytes::from_array(buf))
        }
        None => None
      }
    BegOfLine
  | EndOfLine
  | BegOfWord
  | EndOfWord
  | NotBound
  | BegOfStr
  | EndOfStr
  | LastEndOfLine
  | Start
  | Stop => Some(b"")
    Group(_, gen) => Ast::witness(gen)
    NoGroup(gen) => Ast::witness(gen)
    Nest(gen) => Ast::witness(gen)
    Pmark(_, gen) => Ast::witness(gen)
    Sem(_, gen) => Ast::witness(gen)
    SemGreedy(_, gen) => Ast::witness(gen)
  }
}