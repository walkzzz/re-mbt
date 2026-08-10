// Ast — regular expression AST (port of lib/ast.ml)
// OCaml GADT ('a, 'case) gen with phantom [Cased|Uncased]. MoonBit has no GADT;
// we drop the phantom case parameter and use a unified generic enum AstGen[T].

///|
pub enum AstAlt[T] {
  Alternative(Array[T])
  NoCase(T)
  Case(T)
} derive(Debug, Eq)

///|
pub enum AstCset {
  CsetOf(Cset)
  Intersection(Array[AstCset])
  Complement(Array[AstCset])
  Difference(AstCset, AstCset)
  Cast(AstAlt[AstCset])
} derive(Debug, Eq)

///|
pub enum AstGen[T] {
  Set(T)
  AstNode(AstAlt[AstGen[T]])
  Sequence(Array[AstGen[T]])
  Repeat(AstGen[T], Int, Int?)
  BegOfLine
  EndOfLine
  BegOfWord
  EndOfWord
  NotBound
  BegOfStr
  EndOfStr
  LastEndOfLine
  Start
  Stop
  Group(String?, AstGen[T])
  NoGroup(AstGen[T])
  Nest(AstGen[T])
  Pmark(Pmark, AstGen[T])
  Sem(Sem, AstGen[T])
  SemGreedy(RepKind, AstGen[T])
} derive(Debug, Eq)

///|
pub type Ast = AstGen[AstCset]

///|
pub type AstNoCase = AstGen[Cset]

// --- to_dyn (free functions to avoid generic method inference issues) ---

///|
fn ast_alt_to_dyn_cset(x : AstAlt[AstCset]) -> Dyn {
  match x {
    Alternative(xs) =>
      Dyn::variant("Alternative", Array::map(xs, fn(a) { ast_cset_to_dyn(a) }))
    NoCase(a) => Dyn::variant("No_case", [ast_cset_to_dyn(a)])
    Case(a) => Dyn::variant("Case", [ast_cset_to_dyn(a)])
  }
}

///|
fn ast_cset_to_dyn(x : AstCset) -> Dyn {
  match x {
    CsetOf(cset) => Dyn::variant("Cset", [cset.to_dyn()])
    Intersection(xs) =>
      Dyn::variant("Intersection", Array::map(xs, fn(a) { ast_cset_to_dyn(a) }))
    Complement(xs) =>
      Dyn::variant("Complement", Array::map(xs, fn(a) { ast_cset_to_dyn(a) }))
    Difference(x, y) =>
      Dyn::variant("Difference", [ast_cset_to_dyn(x), ast_cset_to_dyn(y)])
    Cast(c) => Dyn::variant("Cast", [ast_alt_to_dyn_cset(c)])
  }
}

///|
fn ast_to_dyn(x : Ast) -> Dyn {
  match x {
    Set(a) => Dyn::variant("Set", [ast_cset_to_dyn(a)])
    AstNode(ast) => Dyn::variant("Ast", [ast_alt_to_dyn_ast(ast)])
    Sequence(xs) =>
      Dyn::variant("Sequence", Array::map(xs, fn(a) { ast_to_dyn(a) }))
    Repeat(gen, min, max) => {
      let base : Array[Dyn] = match max {
        None => []
        Some(x) => [Dyn::int(x)]
      }
      Dyn::variant("Repeat", [ast_to_dyn(gen), Dyn::int(min), ..base])
    }
    BegOfLine => Dyn::enum_("Beg_of_line")
    EndOfLine => Dyn::enum_("End_of_line")
    BegOfWord => Dyn::enum_("Beg_of_word")
    EndOfWord => Dyn::enum_("End_of_word")
    NotBound => Dyn::enum_("Not_bound")
    BegOfStr => Dyn::enum_("Beg_of_str")
    EndOfStr => Dyn::enum_("End_of_str")
    LastEndOfLine => Dyn::enum_("Last_end_of_line")
    Start => Dyn::enum_("Start")
    Stop => Dyn::enum_("Stop")
    Group(name, t) => {
      let args : Array[Dyn] = match name {
        None => [ast_to_dyn(t)]
        Some(n) => [Dyn::string(n), ast_to_dyn(t)]
      }
      Dyn::variant("Group", args)
    }
    NoGroup(x) => Dyn::variant("No_group", [ast_to_dyn(x)])
    Nest(x) => Dyn::variant("Nest", [ast_to_dyn(x)])
    Pmark(pmark, t) => Dyn::variant("Pmark", [pmark.to_dyn(), ast_to_dyn(t)])
    Sem(sem, t) => Dyn::variant("Sem", [Sem::to_dyn(sem), ast_to_dyn(t)])
    SemGreedy(rep, t) =>
      Dyn::variant("Sem_greedy", [RepKind::to_dyn(rep), ast_to_dyn(t)])
  }
}

///|
fn ast_alt_to_dyn_ast(x : AstAlt[Ast]) -> Dyn {
  match x {
    Alternative(xs) =>
      Dyn::variant("Alternative", Array::map(xs, fn(a) { ast_to_dyn(a) }))
    NoCase(a) => Dyn::variant("No_case", [ast_to_dyn(a)])
    Case(a) => Dyn::variant("Case", [ast_to_dyn(a)])
  }
}

///|
pub fn Ast::to_dyn(self : Ast) -> Dyn {
  ast_to_dyn(self)
}

// --- cset constructor ---

///|
pub fn Ast::cset(c : Cset) -> Ast {
  Set(CsetOf(c))
}

///|
pub fn Ast::t_of_cset(x : AstCset) -> Ast {
  Set(x)
}

// --- handle_case ---

///|
fn handle_case_cset(x : AstCset, ign_case : Bool) -> Cset {
  match x {
    CsetOf(s) => if ign_case { Cset::case_insens(s) } else { s }
    Cast(Alternative(l)) => {
      let arr = Array::map(l, fn(x) { handle_case_cset(x, ign_case) })
      Cset::union_all(arr)
    }
    Complement(l) => {
      let arr = Array::map(l, fn(x) { handle_case_cset(x, ign_case) })
      Cset::diff(Cset::cany(), Cset::union_all(arr))
    }
    Difference(r, r2) =>
      Cset::inter(
        handle_case_cset(r, ign_case),
        Cset::diff(Cset::cany(), handle_case_cset(r2, ign_case)),
      )
    Intersection(l) => {
      let arr = Array::map(l, fn(x) { handle_case_cset(x, ign_case) })
      Cset::intersect_all(arr)
    }
    Cast(NoCase(a)) => handle_case_cset(a, true)
    Cast(Case(a)) => handle_case_cset(a, false)
  }
}

///|
pub fn Ast::handle_case(self : Ast, ign_case : Bool) -> AstNoCase {
  match self {
    Set(s) => Set(handle_case_cset(s, ign_case))
    Sequence(l) =>
      Sequence(Array::map(l, fn(x) { Ast::handle_case(x, ign_case) }))
    AstNode(Alternative(l)) => {
      let l2 = Array::map(l, fn(x) { Ast::handle_case(x, ign_case) })
      AstNode(Alternative(l2))
    }
    Repeat(r, i, j) => Repeat(Ast::handle_case(r, ign_case), i, j)
    BegOfLine => BegOfLine
    EndOfLine => EndOfLine
    BegOfWord => BegOfWord
    EndOfWord => EndOfWord
    NotBound => NotBound
    BegOfStr => BegOfStr
    EndOfStr => EndOfStr
    LastEndOfLine => LastEndOfLine
    Start => Start
    Stop => Stop
    Sem(k, r) => Sem(k, Ast::handle_case(r, ign_case))
    SemGreedy(k, r) => SemGreedy(k, Ast::handle_case(r, ign_case))
    Group(n, r) => Group(n, Ast::handle_case(r, ign_case))
    NoGroup(r) => NoGroup(Ast::handle_case(r, ign_case))
    Nest(r) => Nest(Ast::handle_case(r, ign_case))
    AstNode(Case(r)) => Ast::handle_case(r, false)
    AstNode(NoCase(r)) => Ast::handle_case(r, true)
    Pmark(i, r) => Pmark(i, Ast::handle_case(r, ign_case))
  }
}

// --- anchored ---

///|
pub fn Ast::anchored_ast(ast : AstAlt[Ast]) -> Bool {
  match ast {
    Alternative(als) => {
      let mut all_anchored = true
      for x in als {
        if !Ast::anchored(x) {
          all_anchored = false
        }
      }
      all_anchored
    }
    NoCase(r) => Ast::anchored(r)
    Case(r) => Ast::anchored(r)
  }
}

///|
pub fn Ast::anchored(self : Ast) -> Bool {
  match self {
    AstNode(a) => Ast::anchored_ast(a)
    Sequence(l) => Array::exists(l, fn(x) { Ast::anchored(x) })
    Repeat(r, i, _) => i > 0 && Ast::anchored(r)
    NoGroup(r) => Ast::anchored(r)
    Sem(_, r) => Ast::anchored(r)
    SemGreedy(_, r) => Ast::anchored(r)
    Group(_, r) => Ast::anchored(r)
    Nest(r) => Ast::anchored(r)
    Pmark(_, r) => Ast::anchored(r)
    Set(_) => false
    BegOfLine => false
    EndOfLine => false
    BegOfWord => false
    EndOfWord => false
    NotBound => false
    EndOfStr => false
    LastEndOfLine => false
    Stop => false
    BegOfStr => true
    Start => true
  }
}

// --- merge_sequences and colorize ---

///|
fn merge_sequences_from(l : Array[Ast], start : Int) -> Array[Ast] {
  if start >= l.length() {
    return []
  }
  let head = l[start]
  match head {
    AstNode(Alternative(l2)) => {
      let combined : Array[Ast] = []
      for x in l2 {
        combined.push(x)
      }
      for i in (start + 1)..<l.length() {
        combined.push(l[i])
      }
      merge_sequences_from(combined, 0)
    }
    Sequence(xs) =>
      if xs.length() > 0 {
        let x = xs[0]
        let y : Array[Ast] = []
        for i in 1..<xs.length() {
          y.push(xs[i])
        }
        let merged_rest = merge_sequences_from(l, start + 1)
        if merged_rest.length() > 0 {
          match merged_rest[0] {
            Sequence(xs2) =>
              if xs2.length() > 0 && xs2[0] == x {
                let y2 : Array[Ast] = []
                for i in 1..<xs2.length() {
                  y2.push(xs2[i])
                }
                let alt = AstNode(Alternative([Ast::seq(y), Ast::seq(y2)]))
                let new_seq = Sequence([x, alt])
                let result : Array[Ast] = [new_seq]
                for i in 1..<merged_rest.length() {
                  result.push(merged_rest[i])
                }
                result
              } else {
                let result : Array[Ast] = [head]
                for x2 in merged_rest {
                  result.push(x2)
                }
                result
              }
            _ => {
              let result : Array[Ast] = [head]
              for x2 in merged_rest {
                result.push(x2)
              }
              result
            }
          }
        } else {
          [head]
        }
      } else {
        let result : Array[Ast] = [head]
        for x in merge_sequences_from(l, start + 1) {
          result.push(x)
        }
        result
      }
    _ => {
      let result : Array[Ast] = [head]
      for x in merge_sequences_from(l, start + 1) {
        result.push(x)
      }
      result
    }
  }
}

///|
pub fn Ast::merge_sequences(l : Array[Ast]) -> Array[Ast] {
  merge_sequences_from(l, 0)
}

///|
fn seq_no_case(l : Array[AstNoCase]) -> AstNoCase {
  if l.length() == 0 {
    Sequence([])
  } else if l.length() == 1 {
    l[0]
  } else {
    Sequence(l)
  }
}

///|
fn merge_sequences_no_case_from(
  l : Array[AstNoCase],
  start : Int,
) -> Array[AstNoCase] {
  if start >= l.length() {
    return []
  }
  let head = l[start]
  match head {
    AstNode(Alternative(l2)) => {
      let combined : Array[AstNoCase] = []
      for x in l2 {
        combined.push(x)
      }
      for i in (start + 1)..<l.length() {
        combined.push(l[i])
      }
      merge_sequences_no_case_from(combined, 0)
    }
    Sequence(xs) =>
      if xs.length() > 0 {
        let x = xs[0]
        let y : Array[AstNoCase] = []
        for i in 1..<xs.length() {
          y.push(xs[i])
        }
        let merged_rest = merge_sequences_no_case_from(l, start + 1)
        if merged_rest.length() > 0 {
          match merged_rest[0] {
            Sequence(xs2) =>
              if xs2.length() > 0 && xs2[0] == x {
                let y2 : Array[AstNoCase] = []
                for i in 1..<xs2.length() {
                  y2.push(xs2[i])
                }
                let alt = AstNode(
                  Alternative([seq_no_case(y), seq_no_case(y2)]),
                )
                let new_seq = Sequence([x, alt])
                let result : Array[AstNoCase] = [new_seq]
                for i in 1..<merged_rest.length() {
                  result.push(merged_rest[i])
                }
                result
              } else {
                let result : Array[AstNoCase] = [head]
                for x2 in merged_rest {
                  result.push(x2)
                }
                result
              }
            _ => {
              let result : Array[AstNoCase] = [head]
              for x2 in merged_rest {
                result.push(x2)
              }
              result
            }
          }
        } else {
          [head]
        }
      } else {
        let result : Array[AstNoCase] = [head]
        for x in merge_sequences_no_case_from(l, start + 1) {
          result.push(x)
        }
        result
      }
    _ => {
      let result : Array[AstNoCase] = [head]
      for x in merge_sequences_no_case_from(l, start + 1) {
        result.push(x)
      }
      result
    }
  }
}

///|
pub fn Ast::merge_sequences_no_case(l : Array[AstNoCase]) -> Array[AstNoCase] {
  merge_sequences_no_case_from(l, 0)
}

///|
fn ast_colorize_rec(
  color_map : ColorMap,
  lnl : Ref[Bool],
  r : AstNoCase,
) -> Unit {
  match r {
    Set(s) => ColorMap::split(color_map, s)
    Sequence(l) =>
      for x in l {
        ast_colorize_rec(color_map, lnl, x)
      }
    AstNode(Alternative(l)) =>
      for x in l {
        ast_colorize_rec(color_map, lnl, x)
      }
    AstNode(NoCase(r2)) => ast_colorize_rec(color_map, lnl, r2)
    AstNode(Case(r2)) => ast_colorize_rec(color_map, lnl, r2)
    Repeat(r2, _, _) => ast_colorize_rec(color_map, lnl, r2)
    BegOfLine => ColorMap::split(color_map, Cset::nl())
    EndOfLine => ColorMap::split(color_map, Cset::nl())
    BegOfWord => ColorMap::split(color_map, Cset::cword())
    EndOfWord => ColorMap::split(color_map, Cset::cword())
    NotBound => ColorMap::split(color_map, Cset::cword())
    BegOfStr => ()
    EndOfStr => ()
    Start => ()
    Stop => ()
    LastEndOfLine => lnl.val = true
    NoGroup(r2) => ast_colorize_rec(color_map, lnl, r2)
    Group(_, r2) => ast_colorize_rec(color_map, lnl, r2)
    Nest(r2) => ast_colorize_rec(color_map, lnl, r2)
    Pmark(_, r2) => ast_colorize_rec(color_map, lnl, r2)
    Sem(_, r2) => ast_colorize_rec(color_map, lnl, r2)
    SemGreedy(_, r2) => ast_colorize_rec(color_map, lnl, r2)
  }
}

///|
pub fn Ast::colorize(color_map : ColorMap, regexp : AstNoCase) -> Bool {
  let lnl = Ref::{ val: false }
  ast_colorize_rec(color_map, lnl, regexp)
  lnl.val
}

// --- Export: constructors ---

///|
pub fn Ast::seq(l : Array[Ast]) -> Ast {
  if l.length() == 1 {
    l[0]
  } else {
    Sequence(l)
  }
}

///|
let ast_char_cache : (Int) -> Ast = DenseMap::make(size=256, f=fn(i) {
  Set(CsetOf(Cset::single(i)))
})

///|
pub fn Ast::char(c : Char) -> Ast {
  ast_char_cache(c.to_int())
}

///|
pub fn Ast::any() -> Ast {
  Set(CsetOf(Cset::cany()))
}

///|
pub fn Ast::str(s : Bytes) -> Ast {
  let l : Array[Ast] = []
  for i in 0..<s.length() {
    l.push(Ast::char(s[i].to_int().unsafe_to_char()))
  }
  Ast::seq(l)
}

///|
pub fn Ast::empty() -> Ast {
  AstNode(Alternative([]))
}

///|
fn as_set_elems(elems : Array[Ast]) -> Array[AstCset]? {
  let result : Array[AstCset] = []
  for e in elems {
    match e {
      Set(x) => result.push(x)
      _ => return None
    }
  }
  Some(result)
}

///|
pub fn Ast::alt(elems : Array[Ast]) -> Ast {
  if elems.length() == 0 {
    Ast::empty()
  } else if elems.length() == 1 {
    elems[0]
  } else {
    AstNode(Alternative(elems))
  }
}

///|
pub fn Ast::epsilon() -> Ast {
  Ast::seq([])
}

///|
pub fn Ast::repn(r : Ast, i : Int, j : Int?) -> Ast {
  if i < 0 {
    abort("Ast.repn: negative min")
  }
  match j {
    Some(jv) => {
      if jv < i {
        abort("Ast.repn: max < min")
      }
      if jv == 0 && i == 0 {
        Ast::epsilon()
      } else if jv == 1 && i == 1 {
        r
      } else {
        Repeat(r, i, j)
      }
    }
    None => Repeat(r, i, j)
  }
}

///|
pub fn Ast::rep(r : Ast) -> Ast {
  Ast::repn(r, 0, None)
}

///|
pub fn Ast::rep1(r : Ast) -> Ast {
  Ast::repn(r, 1, None)
}

///|
pub fn Ast::opt(r : Ast) -> Ast {
  Ast::repn(r, 0, Some(1))
}

///|
pub fn Ast::bol() -> Ast {
  BegOfLine
}

///|
pub fn Ast::eol() -> Ast {
  EndOfLine
}

///|
pub fn Ast::bow() -> Ast {
  BegOfWord
}

///|
pub fn Ast::eow() -> Ast {
  EndOfWord
}

///|
pub fn Ast::word(r : Ast) -> Ast {
  Ast::seq([Ast::bow(), r, Ast::eow()])
}

///|
pub fn Ast::not_boundary() -> Ast {
  NotBound
}

///|
pub fn Ast::bos() -> Ast {
  BegOfStr
}

///|
pub fn Ast::eos() -> Ast {
  EndOfStr
}

///|
pub fn Ast::whole_string(r : Ast) -> Ast {
  Ast::seq([Ast::bos(), r, Ast::eos()])
}

///|
pub fn Ast::leol() -> Ast {
  LastEndOfLine
}

///|
pub fn Ast::start() -> Ast {
  Start
}

///|
pub fn Ast::stop() -> Ast {
  Stop
}

///|
fn preserve_set(f : (Ast) -> Ast, t : Ast) -> Ast {
  match t {
    Set(_) => t
    _ => f(t)
  }
}

///|
pub fn Ast::longest(t : Ast) -> Ast {
  preserve_set(fn(r) { Sem(Longest, r) }, t)
}

///|
pub fn Ast::shortest(t : Ast) -> Ast {
  preserve_set(fn(r) { Sem(Shortest, r) }, t)
}

///|
pub fn Ast::first(t : Ast) -> Ast {
  preserve_set(fn(r) { Sem(First, r) }, t)
}

///|
pub fn Ast::greedy(t : Ast) -> Ast {
  preserve_set(fn(r) { SemGreedy(Greedy, r) }, t)
}

///|
pub fn Ast::non_greedy(t : Ast) -> Ast {
  preserve_set(fn(r) { SemGreedy(NonGreedy, r) }, t)
}

///|
pub fn Ast::group(name? : String? = None, r : Ast) -> Ast {
  Group(name, r)
}

///|
pub fn Ast::no_group(t : Ast) -> Ast {
  preserve_set(fn(r) { NoGroup(r) }, t)
}

///|
pub fn Ast::nest(r : Ast) -> Ast {
  Nest(r)
}

///|
pub fn Ast::set(str : Bytes) -> Ast {
  Set(CsetOf(Cset::set(str)))
}

///|
pub fn Ast::mark(r : Ast) -> (Pmark, Ast) {
  let i = Pmark::gen()
  (i, Pmark(i, r))
}

///|
fn as_set_or_error(name : String, elems : Array[Ast]) -> Array[AstCset] raise {
  match as_set_elems(elems) {
    None => fail(name)
    Some(s) => s
  }
}

///|
pub fn Ast::inter(elems : Array[Ast]) -> Ast raise {
  Set(Intersection(as_set_or_error("Ast.inter", elems)))
}

///|
pub fn Ast::compl(elems : Array[Ast]) -> Ast raise {
  Set(Complement(as_set_or_error("Ast.compl", elems)))
}

///|
pub fn Ast::diff(r : Ast, r2 : Ast) -> Ast raise {
  match (r, r2) {
    (Set(a), Set(b)) => Set(Difference(a, b))
    (_, _) => fail("Ast.diff")
  }
}

///|
pub fn Ast::case(t : Ast) -> Ast {
  match t {
    Set(x) => Set(Cast(Case(x)))
    _ => AstNode(Case(t))
  }
}

///|
pub fn Ast::no_case(t : Ast) -> Ast {
  match t {
    Set(x) => Set(Cast(NoCase(x)))
    _ => AstNode(NoCase(t))
  }
}
