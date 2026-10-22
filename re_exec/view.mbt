// View — a view of the top-level of a regex (port of lib/view.ml)
// This type is unstable and may change.

///|
#warnings("-struct_never_constructed")
pub struct CsetView {}

///|
#warnings("-struct_never_constructed")
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
pub fn CsetView::view(t : @base.Cset) -> Array[ViewRange] {
  let result : Array[ViewRange] = []
  for p in t.intervals {
    let (first, last) = p
    result.push({
      first: @base.CsetC::to_char(first),
      last: @base.CsetC::to_char(last),
    })
  }
  result
}

///|
pub enum ViewT {
  SetT(@base.Cset)
  SequenceT(Array[@ast.Ast])
  AlternativeT(Array[@ast.Ast])
  RepeatT(@ast.Ast, Int32, Int32?)
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
  SemT(@base.Sem, @ast.Ast)
  SemGreedyT(@base.RepKind, @ast.Ast)
  GroupT(String?, @ast.Ast)
  NoGroupT(@ast.Ast)
  NestT(@ast.Ast)
  CaseT(@ast.Ast)
  NoCaseT(@ast.Ast)
  IntersectionT(Array[@ast.Ast])
  ComplementT(Array[@ast.Ast])
  DifferenceT(@ast.Ast, @ast.Ast)
  PmarkT(@base.Pmark, @ast.Ast)
}

///|
fn[T] view_ast(f : (T) -> @ast.Ast, t : @ast.AstAlt[T]) -> ViewT {
  match t {
    Alternative(a) => AlternativeT(Array::map(a, f))
    NoCase(a) => NoCaseT(f(a))
    Case(a) => CaseT(f(a))
  }
}

///|
fn view_set(cset : @ast.AstCset) -> ViewT {
  match cset {
    CsetOf(set) => SetT(set)
    Intersection(sets) =>
      IntersectionT(Array::map(sets, fn(x) { @ast.Ast::t_of_cset(x) }))
    Complement(sets) =>
      ComplementT(Array::map(sets, fn(x) { @ast.Ast::t_of_cset(x) }))
    Difference(x, y) =>
      DifferenceT(@ast.Ast::t_of_cset(x), @ast.Ast::t_of_cset(y))
    Cast(ast) => view_ast(fn(x) { @ast.Ast::t_of_cset(x) }, ast)
  }
}

///|
pub fn View::view(t : @ast.Ast) -> ViewT {
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
    @ast.Sem(sem, a) => SemT(sem, a)
    SemGreedy(sem, a) => SemGreedyT(sem, a)
    Group(name, t) => GroupT(name, t)
    NoGroup(a) => NoGroupT(a)
    Nest(t) => NestT(t)
    @ast.Pmark(pmark, t) => PmarkT(pmark, t)
  }
}
