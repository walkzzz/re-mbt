// AutomataExpr — expression type for automata (port of lib/automata.ml Expr module)
// Expr is a single enum with id baked into each variant (avoids struct+enum mutual recursion).

///|
pub(all) enum Expr {
  Cst(Int32, @base.Cset)
  Alt(Int32, Array[Expr])
  Seq(Int32, @base.Sem, Expr, Expr)
  Eps(Int32)
  Rep(Int32, @base.RepKind, @base.Sem, Expr)
  MarkOf(Int32, Int32)
  Erase(Int32, Int32, Int32)
  Before(Int32, @base.Category)
  After(Int32, @base.Category)
  PmarkOf(Int32, @base.Pmark)
} derive(Debug)

///|
pub extend Expr with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub fn Expr::id(e : Expr) -> Int32 {
  match e {
    Cst(i, _) => i
    Alt(i, _) => i
    Seq(i, _, _, _) => i
    Eps(i) => i
    Rep(i, _, _, _) => i
    MarkOf(i, _) => i
    Erase(i, _, _) => i
    Before(i, _) => i
    After(i, _) => i
    PmarkOf(i, _) => i
  }
}

///|
pub fn Expr::eps_expr() -> Expr {
  Eps(0)
}

///|
pub fn Expr::empty(ids : @base.Ids) -> Expr {
  Alt(ids.next(), [])
}

///|
pub fn Expr::cst(ids : @base.Ids, s : @base.Cset) -> Expr {
  if @base.Cset::is_empty(s) {
    Expr::empty(ids)
  } else {
    Cst(ids.next(), s)
  }
}

///|
pub fn Expr::eps(ids : @base.Ids) -> Expr {
  Eps(ids.next())
}

///|
pub fn Expr::rep(
  ids : @base.Ids,
  kind : @base.RepKind,
  sem : @base.Sem,
  x : Expr,
) -> Expr {
  Rep(ids.next(), kind, sem, x)
}

///|
pub fn Expr::mark(ids : @base.Ids, m : Int32) -> Expr {
  MarkOf(ids.next(), m)
}

///|
pub fn Expr::pmark(ids : @base.Ids, i : @base.Pmark) -> Expr {
  PmarkOf(ids.next(), i)
}

///|
pub fn Expr::erase(ids : @base.Ids, m : Int32, m2 : Int32) -> Expr {
  Erase(ids.next(), m, m2)
}

///|
pub fn Expr::before(ids : @base.Ids, c : @base.Category) -> Expr {
  Before(ids.next(), c)
}

///|
pub fn Expr::after(ids : @base.Ids, c : @base.Category) -> Expr {
  After(ids.next(), c)
}

///|
pub fn Expr::alt(ids : @base.Ids, l : Array[Expr]) -> Expr {
  if l.length() == 0 {
    Expr::empty(ids)
  } else if l.length() == 1 {
    l[0]
  } else {
    Alt(ids.next(), l)
  }
}

///|
pub fn Expr::seq(ids : @base.Ids, kind : @base.Sem, x : Expr, y : Expr) -> Expr {
  let x_empty = match x {
    Alt(_, arr) => arr.length() == 0
    _ => false
  }
  let y_empty = match y {
    Alt(_, arr) => arr.length() == 0
    _ => false
  }
  let x_eps = match x {
    Eps(_) => true
    _ => false
  }
  let y_eps = match y {
    Eps(_) => true
    _ => false
  }
  if x_empty {
    x
  } else if y_empty {
    y
  } else if x_eps {
    y
  } else if y_eps && kind == @base.First {
    x
  } else {
    Seq(ids.next(), kind, x, y)
  }
}

///|
pub fn Expr::is_eps(e : Expr) -> Bool {
  match e {
    Eps(_) => true
    _ => false
  }
}

///|
fn seq_as_list(sem : @base.Sem, t : Expr) -> Array[Expr] {
  match t {
    Eps(_) => []
    Seq(_, sem2, x, y) =>
      if sem == sem2 {
        let result : Array[Expr] = [x]
        let rest = seq_as_list(sem, y)
        for e in rest {
          result.push(e)
        }
        result
      } else {
        [t]
      }
    _ => [t]
  }
}

///|
pub fn Expr::rename(ids : @base.Ids, x : Expr) -> Expr {
  match x {
    Cst(_, s) => Cst(ids.next(), s)
    Eps(_) => Eps(ids.next())
    MarkOf(_, m) => MarkOf(ids.next(), m)
    PmarkOf(_, p) => PmarkOf(ids.next(), p)
    Erase(_, a, b) => Erase(ids.next(), a, b)
    Before(_, c) => Before(ids.next(), c)
    After(_, c) => After(ids.next(), c)
    Alt(_, l) => {
      let l2 = Array::map(l, fn(e) { Expr::rename(ids, e) })
      Alt(ids.next(), l2)
    }
    Seq(_, k, y, z) =>
      Seq(ids.next(), k, Expr::rename(ids, y), Expr::rename(ids, z))
    Rep(_, g, k, y) => Rep(ids.next(), g, k, Expr::rename(ids, y))
  }
}

///|
pub fn Expr::to_dyn(e : Expr) -> @base.Dyn {
  match e {
    Cst(_, cset) => cset.to_dyn()
    Alt(_, alt) => {
      let arr = Array::map(alt, fn(e2) { Expr::to_dyn(e2) })
      @base.Dyn::variant("Alt", arr)
    }
    Seq(_, sem, x, y) => {
      let ys = seq_as_list(sem, y)
      let args : Array[@base.Dyn] = [Expr::to_dyn(x)]
      for e2 in ys {
        args.push(Expr::to_dyn(e2))
      }
      @base.Dyn::variant("Seq:" + @base.Sem::to_string_short(sem), args)
    }
    Eps(_) => @base.Dyn::enum_("Eps")
    Rep(_, kind, sem, t) =>
      @base.Dyn::variant(
        "Rep" +
        @base.RepKind::to_string_short(kind) +
        ":" +
        @base.Sem::to_string_short(sem),
        [Expr::to_dyn(t)],
      )
    MarkOf(_, m) => @base.Dyn::variant("Mark", [@base.Mark::to_dyn(m)])
    PmarkOf(_, m) => @base.Dyn::variant("Pmark", [m.to_dyn()])
    Erase(_, x, y) =>
      @base.Dyn::variant("Erase", [@base.Mark::to_dyn(x), @base.Mark::to_dyn(y)])
    Before(_, c) => @base.Dyn::variant("Before", [c.to_dyn()])
    After(_, c) => @base.Dyn::variant("After", [c.to_dyn()])
  }
}
