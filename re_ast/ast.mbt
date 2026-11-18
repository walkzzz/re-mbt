// Ast — regular expression AST (port of lib/ast.ml)
// OCaml GADT ('a, 'case) gen with phantom [Cased|Uncased]. MoonBit has no GADT;
// we drop the phantom case parameter and use a unified generic enum AstGen[T].

///|
#derive(Debug, Eq)
pub(all) enum AstAlt[T] {
  Alternative(Array[T])
  NoCase(T)
  Case(T)
}

///|
pub extend AstAlt with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend AstAlt with Eq::{equal, not_equal}

///|
#derive(Debug, Eq)
pub(all) enum AstCset {
  CsetOf(@base.Cset)
  Intersection(Array[AstCset])
  Complement(Array[AstCset])
  Difference(AstCset, AstCset)
  Cast(AstAlt[AstCset])
}

///|
pub extend AstCset with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend AstCset with Eq::{equal, not_equal}

///|
#derive(Debug, Eq)
pub(all) enum AstGen[T] {
  Set(T)
  AstNode(AstAlt[AstGen[T]])
  Sequence(Array[AstGen[T]])
  Repeat(AstGen[T], Int32, Int32?)
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
  Pmark(@base.Pmark, AstGen[T])
  Sem(@base.Sem, AstGen[T])
  SemGreedy(@base.RepKind, AstGen[T])
}

///|
pub extend AstGen with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend AstGen with Eq::{equal, not_equal}

///|
pub type Ast = AstGen[AstCset]

///|
pub type AstNoCase = AstGen[@base.Cset]

// --- to_dyn (free functions to avoid generic method inference issues) ---

///|
fn ast_alt_to_dyn_cset(x : AstAlt[AstCset]) -> @base.Dyn {
  match x {
    Alternative(xs) =>
      @base.Dyn::variant(
        "Alternative",
        Array::map(xs, fn(a) { ast_cset_to_dyn(a) }),
      )
    NoCase(a) => @base.Dyn::variant("No_case", [ast_cset_to_dyn(a)])
    Case(a) => @base.Dyn::variant("Case", [ast_cset_to_dyn(a)])
  }
}

///|
fn ast_cset_to_dyn(x : AstCset) -> @base.Dyn {
  match x {
    CsetOf(cset) => @base.Dyn::variant("Cset", [cset.to_dyn()])
    Intersection(xs) =>
      @base.Dyn::variant(
        "Intersection",
        Array::map(xs, fn(a) { ast_cset_to_dyn(a) }),
      )
    Complement(xs) =>
      @base.Dyn::variant(
        "Complement",
        Array::map(xs, fn(a) { ast_cset_to_dyn(a) }),
      )
    Difference(x, y) =>
      @base.Dyn::variant("Difference", [ast_cset_to_dyn(x), ast_cset_to_dyn(y)])
    Cast(c) => @base.Dyn::variant("Cast", [ast_alt_to_dyn_cset(c)])
  }
}

///|
fn ast_to_dyn(x : Ast) -> @base.Dyn {
  match x {
    Set(a) => @base.Dyn::variant("Set", [ast_cset_to_dyn(a)])
    AstNode(ast) => @base.Dyn::variant("Ast", [ast_alt_to_dyn_ast(ast)])
    Sequence(xs) =>
      @base.Dyn::variant("Sequence", Array::map(xs, fn(a) { ast_to_dyn(a) }))
    Repeat(gen, min, max) => {
      let base : Array[@base.Dyn] = match max {
        None => []
        Some(x) => [@base.Dyn::int(x)]
      }
      @base.Dyn::variant(
        "Repeat",
        [ast_to_dyn(gen), @base.Dyn::int(min), ..base],
      )
    }
    BegOfLine => @base.Dyn::enum_("Beg_of_line")
    EndOfLine => @base.Dyn::enum_("End_of_line")
    BegOfWord => @base.Dyn::enum_("Beg_of_word")
    EndOfWord => @base.Dyn::enum_("End_of_word")
    NotBound => @base.Dyn::enum_("Not_bound")
    BegOfStr => @base.Dyn::enum_("Beg_of_str")
    EndOfStr => @base.Dyn::enum_("End_of_str")
    LastEndOfLine => @base.Dyn::enum_("Last_end_of_line")
    Start => @base.Dyn::enum_("Start")
    Stop => @base.Dyn::enum_("Stop")
    Group(name, t) => {
      let args : Array[@base.Dyn] = match name {
        None => [ast_to_dyn(t)]
        Some(n) => [@base.Dyn::string(n), ast_to_dyn(t)]
      }
      @base.Dyn::variant("Group", args)
    }
    NoGroup(x) => @base.Dyn::variant("No_group", [ast_to_dyn(x)])
    Nest(x) => @base.Dyn::variant("Nest", [ast_to_dyn(x)])
    Pmark(pmark, t) =>
      @base.Dyn::variant("Pmark", [pmark.to_dyn(), ast_to_dyn(t)])
    Sem(sem, t) =>
      @base.Dyn::variant("Sem", [@base.Sem::to_dyn(sem), ast_to_dyn(t)])
    SemGreedy(rep, t) =>
      @base.Dyn::variant("Sem_greedy", [
        @base.RepKind::to_dyn(rep),
        ast_to_dyn(t),
      ])
  }
}

///|
fn ast_alt_to_dyn_ast(x : AstAlt[Ast]) -> @base.Dyn {
  match x {
    Alternative(xs) =>
      @base.Dyn::variant("Alternative", Array::map(xs, fn(a) { ast_to_dyn(a) }))
    NoCase(a) => @base.Dyn::variant("No_case", [ast_to_dyn(a)])
    Case(a) => @base.Dyn::variant("Case", [ast_to_dyn(a)])
  }
}

///|
pub fn Ast::to_dyn(self : Ast) -> @base.Dyn {
  ast_to_dyn(self)
}

// --- cset constructor ---

///|
pub fn Ast::cset(c : @base.Cset) -> Ast {
  Set(CsetOf(c))
}

///|
pub fn Ast::t_of_cset(x : AstCset) -> Ast {
  Set(x)
}

// --- handle_case ---

///|
fn handle_case_cset(x : AstCset, ign_case : Bool) -> @base.Cset {
  match x {
    CsetOf(s) => if ign_case { @base.Cset::case_insens(s) } else { s }
    Cast(Alternative(l)) => {
      let arr = Array::map(l, fn(x) { handle_case_cset(x, ign_case) })
      @base.Cset::union_all(arr)
    }
    Complement(l) => {
      let arr = Array::map(l, fn(x) { handle_case_cset(x, ign_case) })
      @base.Cset::diff(@base.Cset::cany(), @base.Cset::union_all(arr))
    }
    Difference(r, r2) =>
      @base.Cset::inter(
        handle_case_cset(r, ign_case),
        @base.Cset::diff(@base.Cset::cany(), handle_case_cset(r2, ign_case)),
      )
    Intersection(l) => {
      let arr = Array::map(l, fn(x) { handle_case_cset(x, ign_case) })
      @base.Cset::intersect_all(arr)
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
fn merge_sequences_from(l : Array[Ast], start : Int32) -> Array[Ast] {
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
  start : Int32,
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
    BegOfLine => ColorMap::split(color_map, @base.Cset::nl())
    EndOfLine => ColorMap::split(color_map, @base.Cset::nl())
    BegOfWord => ColorMap::split(color_map, @base.Cset::cword())
    EndOfWord => ColorMap::split(color_map, @base.Cset::cword())
    NotBound => ColorMap::split(color_map, @base.Cset::cword())
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
  let lnl = Ref::{ val: false, }
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
let ast_char_cache : (Int32) -> Ast = @base.DenseMap::make(size=256, f=fn(i) {
  Set(CsetOf(@base.Cset::single(i)))
})

///|
pub fn Ast::char(c : Char) -> Ast {
  ast_char_cache(c.to_int())
}

///|
pub fn Ast::any() -> Ast {
  Set(CsetOf(@base.Cset::cany()))
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
pub fn Ast::repn(r : Ast, i : Int32, j : Int32?) -> Ast {
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
  preserve_set(fn(r) { Sem(@base.Longest, r) }, t)
}

///|
pub fn Ast::shortest(t : Ast) -> Ast {
  preserve_set(fn(r) { Sem(@base.Shortest, r) }, t)
}

///|
pub fn Ast::first(t : Ast) -> Ast {
  preserve_set(fn(r) { Sem(@base.First, r) }, t)
}

///|
pub fn Ast::greedy(t : Ast) -> Ast {
  preserve_set(fn(r) { SemGreedy(@base.Greedy, r) }, t)
}

///|
pub fn Ast::non_greedy(t : Ast) -> Ast {
  preserve_set(fn(r) { SemGreedy(@base.NonGreedy, r) }, t)
}

///|
pub fn Ast::group(name~ : String? = None, r : Ast) -> Ast {
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
  Set(CsetOf(@base.Cset::set(str)))
}

///|
pub fn Ast::mark(r : Ast) -> (@base.Pmark, Ast) {
  let i = @base.Pmark::gen()
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
