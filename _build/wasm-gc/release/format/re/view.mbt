// View — a view of the top-level of a regex (port of lib/view.ml)
// This type is unstable and may change.

///|
pub struct CsetView {}

///|
pub struct View {}

///|
pub struct ViewRange {
  first : Char
  last : Char
}

///|
pub fn ViewRange::first(r : ViewRange) -> Char {
  r.first
}

///|
pub fn ViewRange::last(r : ViewRange) -> Char {
  r.last
}

///|
pub fn CsetView::view(t : Cset) -> Array[ViewRange] {
  let result : Array[ViewRange] = []
  for p in t.intervals {
    let (first, last) = p
    result.push({ first: CsetC::to_char(first), last: CsetC::to_char(last) })
  }
  result
}

///|
pub enum ViewT {
  SetT(Cset)
  SequenceT(Array[Ast])
  AlternativeT(Array[Ast])
  RepeatT(Ast, Int, Int?)
  BegOfLineT
  EndOfLineT
  BegOfWordT
  EndOfWordT
  NotBoundT
  BegOfStrT
  EndOfStrT
  LastEndOfLineT
  StartT
  StopT
  SemT(Sem, Ast)
  SemGreedyT(RepKind, Ast)
  GroupT(String?, Ast)
  NoGroupT(Ast)
  NestT(Ast)
  CaseT(Ast)
  NoCaseT(Ast)
  IntersectionT(Array[Ast])
  ComplementT(Array[Ast])
  DifferenceT(Ast, Ast)
  PmarkT(Pmark, Ast)
}

///|
fn[T] view_ast(f : (T) -> Ast, t : AstAlt[T]) -> ViewT {
  match t {
    Alternative(a) => AlternativeT(Array::map(a, f))
    NoCase(a) => NoCaseT(f(a))
    Case(a) => CaseT(f(a))
  }
}

///|
fn view_set(cset : AstCset) -> ViewT {
  match cset {
    CsetOf(set) => SetT(set)
    Intersection(sets) =>
      IntersectionT(Array::map(sets, fn(x) { Ast::t_of_cset(x) }))
    Complement(sets) =>
      ComplementT(Array::map(sets, fn(x) { Ast::t_of_cset(x) }))
    Difference(x, y) => DifferenceT(Ast::t_of_cset(x), Ast::t_of_cset(y))
    Cast(ast) => view_ast(fn(x) { Ast::t_of_cset(x) }, ast)
  }
}

///|
pub fn View::view(t : Ast) -> ViewT {
  match t {
    Set(s) => view_set(s)
    AstNode(s) => view_ast(fn(x) { x }, s)
    Sequence(s) => SequenceT(s)
    Repeat(t, x, y) => RepeatT(t, x, y)
    BegOfLine => BegOfLineT
    EndOfLine => EndOfLineT
    BegOfWord => BegOfWordT
    EndOfWord => EndOfWordT
    NotBound => NotBoundT
    BegOfStr => BegOfStrT
    EndOfStr => EndOfStrT
    LastEndOfLine => LastEndOfLineT
    Start => StartT
    Stop => StopT
    Sem(sem, a) => SemT(sem, a)
    SemGreedy(sem, a) => SemGreedyT(sem, a)
    Group(name, t) => GroupT(name, t)
    NoGroup(a) => NoGroupT(a)
    Nest(t) => NestT(t)
    Pmark(pmark, t) => PmarkT(pmark, t)
  }
}
