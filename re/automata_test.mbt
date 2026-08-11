// Tests for Automata State, WorkingArea, delta, advance

///|
fn status_is_running(s : Status) -> Bool {
  match s {
    Running => true
    _ => false
  }
}

///|
fn status_is_failed(s : Status) -> Bool {
  match s {
    Failed => true
    _ => false
  }
}

///|
fn status_is_match(s : Status) -> Bool {
  match s {
    Match(_, _) => true
    _ => false
  }
}

///|
test "State::create and dummy" {
  let ids = Ids::create()
  let expr = Expr::cst(ids, Cset::single(97))
  let cat = Category::from_char('a')
  let s = State::create(cat, expr)
  assert_eq(s.idx, Idx::initial())

  let d = State::dummy()
  assert_eq(d.idx, Idx::unknown())
  assert_eq(d.hash, -1)
}

///|
test "State::equal - self equality" {
  let ids = Ids::create()
  let expr = Expr::cst(ids, Cset::single(97))
  let cat = Category::from_char('a')
  let s1 = State::create(cat, expr)
  assert_eq(State::equal(s1, s1), true)
}

///|
test "delta: regex 'a' with matching char" {
  let ids = Ids::create()
  let expr = Expr::cst(ids, Cset::single(97))
  let cat = Category::from_char('a')
  let wa = WorkingArea::create()
  let s0 = State::create(cat, expr)
  let s1 = delta(wa, cat, 97, s0)
  let st = State::status(s1)
  assert_eq(status_is_running(st), true)
}

///|
test "delta: regex 'a' with non-matching char" {
  let ids = Ids::create()
  let expr = Expr::cst(ids, Cset::single(97))
  let cat = Category::from_char('a')
  let wa = WorkingArea::create()
  let s0 = State::create(cat, expr)
  let s1 = delta(wa, cat, 98, s0)
  let st = State::status(s1)
  assert_eq(status_is_failed(st), true)
}

///|
test "advance: regex 'a' after matching delta" {
  let ids = Ids::create()
  let expr = Expr::cst(ids, Cset::single(97))
  let cat = Category::from_char('a')
  let wa = WorkingArea::create()
  let s0 = State::create(cat, expr)
  let s1 = delta(wa, cat, 97, s0)
  let s2 = advance(wa, s1)
  let st = State::status(s2)
  assert_eq(status_is_match(st), true)
}

///|
test "delta: regex 'a*' with matching char stays running" {
  let ids = Ids::create()
  let a_cset = Cset::single(97)
  let a_expr = Expr::cst(ids, a_cset)
  let star_expr = Expr::rep(ids, RepKind::greedy(), Sem::longest(), a_expr)
  let cat = Category::from_char('a')
  let wa = WorkingArea::create()
  let s0 = State::create(cat, star_expr)
  let s1 = delta(wa, cat, 97, s0)
  let st = State::status(s1)
  assert_eq(status_is_running(st), true)
}

///|
test "advance: regex 'a*' after non-matching char gives match" {
  let ids = Ids::create()
  let a_cset = Cset::single(97)
  let a_expr = Expr::cst(ids, a_cset)
  let star_expr = Expr::rep(ids, RepKind::greedy(), Sem::longest(), a_expr)
  let cat = Category::from_char('a')
  let wa = WorkingArea::create()
  let s0 = State::create(cat, star_expr)
  let s1 = delta(wa, cat, 98, s0)
  let s2 = advance(wa, s1)
  let st = State::status(s2)
  assert_eq(status_is_match(st), true)
}

///|
test "WorkingArea::free_index returns 0 for empty desc" {
  let wa = WorkingArea::create()
  let idx = WorkingArea::free_index(wa, Desc::empty())
  assert_eq(idx, 0)
}

///|
test "delta: regex 'ab' (sequence) with 'a' then 'b'" {
  let ids = Ids::create()
  let a_expr = Expr::cst(ids, Cset::single(97))
  let b_expr = Expr::cst(ids, Cset::single(98))
  let ab_expr = Expr::seq(ids, Sem::first(), a_expr, b_expr)
  let cat = Category::from_char('a')
  let wa = WorkingArea::create()
  let s0 = State::create(cat, ab_expr)
  let s1 = delta(wa, cat, 97, s0)
  let st1 = State::status(s1)
  assert_eq(status_is_running(st1), true)
  let s2 = delta(wa, cat, 98, s1)
  let st2 = State::status(s2)
  assert_eq(status_is_running(st2), true)
  let s3 = advance(wa, s2)
  let st3 = State::status(s3)
  assert_eq(status_is_match(st3), true)
}

///|
test "delta: regex 'a|b' (alternative) with 'a'" {
  let ids = Ids::create()
  let a_expr = Expr::cst(ids, Cset::single(97))
  let b_expr = Expr::cst(ids, Cset::single(98))
  let alt_expr = Expr::alt(ids, [a_expr, b_expr])
  let cat = Category::from_char('a')
  let wa = WorkingArea::create()
  let s0 = State::create(cat, alt_expr)
  let s1 = delta(wa, cat, 97, s0)
  let s2 = advance(wa, s1)
  let st = State::status(s2)
  assert_eq(status_is_match(st), true)
}

///|
test "delta: regex 'a|b' (alternative) with 'b'" {
  let ids = Ids::create()
  let a_expr = Expr::cst(ids, Cset::single(97))
  let b_expr = Expr::cst(ids, Cset::single(98))
  let alt_expr = Expr::alt(ids, [a_expr, b_expr])
  let cat = Category::from_char('a')
  let wa = WorkingArea::create()
  let s0 = State::create(cat, alt_expr)
  let s1 = delta(wa, cat, 98, s0)
  let s2 = advance(wa, s1)
  let st = State::status(s2)
  assert_eq(status_is_match(st), true)
}

///|
test "delta: regex 'a|b' (alternative) with 'c' fails" {
  let ids = Ids::create()
  let a_expr = Expr::cst(ids, Cset::single(97))
  let b_expr = Expr::cst(ids, Cset::single(98))
  let alt_expr = Expr::alt(ids, [a_expr, b_expr])
  let cat = Category::from_char('a')
  let wa = WorkingArea::create()
  let s0 = State::create(cat, alt_expr)
  let s1 = delta(wa, cat, 99, s0)
  let st = State::status(s1)
  assert_eq(status_is_failed(st), true)
}

///|
test "delta: regex eps matches immediately" {
  let ids = Ids::create()
  let eps_expr = Expr::eps(ids)
  let cat = Category::from_char('a')
  let wa = WorkingArea::create()
  let s0 = State::create(cat, eps_expr)
  let s1 = advance(wa, s0)
  let st = State::status(s1)
  assert_eq(status_is_match(st), true)
}

///|
test "expr rename Cst preserves cset with new id" {
  let ids1 = Ids::create()
  let e = Expr::cst(ids1, Cset::single(97))
  let ids2 = Ids::create()
  let e2 = Expr::rename(ids2, e)
  match e2 {
    Cst(_, s) => {
      assert_eq(s, Cset::single(97))
      assert_eq(Expr::id(e2), 1)
    }
    _ => assert_true(false)
  }
}

///|
test "expr rename Seq recursively renames children" {
  let ids1 = Ids::create()
  let a = Expr::cst(ids1, Cset::single(97))
  let b = Expr::cst(ids1, Cset::single(98))
  let seq = Expr::seq(ids1, Sem::longest(), a, b)
  let ids2 = Ids::create()
  let seq2 = Expr::rename(ids2, seq)
  match seq2 {
    Seq(_, k, y, z) => {
      assert_eq(k, Sem::longest())
      assert_eq(Expr::id(seq2), 1)
      match y {
        Cst(_, s1) => assert_eq(s1, Cset::single(97))
        _ => assert_true(false)
      }
      match z {
        Cst(_, s2) => assert_eq(s2, Cset::single(98))
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}

///|
test "expr rename Alt recursively renames all children" {
  let ids1 = Ids::create()
  let a = Expr::cst(ids1, Cset::single(97))
  let b = Expr::cst(ids1, Cset::single(98))
  let c = Expr::cst(ids1, Cset::single(99))
  let alt = Expr::alt(ids1, [a, b, c])
  let ids2 = Ids::create()
  let alt2 = Expr::rename(ids2, alt)
  match alt2 {
    Alt(_, l) => {
      assert_eq(l.length(), 3)
      match l[0] {
        Cst(_, s) => assert_eq(s, Cset::single(97))
        _ => assert_true(false)
      }
      match l[1] {
        Cst(_, s) => assert_eq(s, Cset::single(98))
        _ => assert_true(false)
      }
      match l[2] {
        Cst(_, s) => assert_eq(s, Cset::single(99))
        _ => assert_true(false)
      }
      assert_eq(Expr::id(alt2), 4)
    }
    _ => assert_true(false)
  }
}

///|
test "expr rename Rep recursively renames child" {
  let ids1 = Ids::create()
  let a = Expr::cst(ids1, Cset::single(97))
  let rep = Expr::rep(ids1, RepKind::greedy(), Sem::longest(), a)
  let ids2 = Ids::create()
  let rep2 = Expr::rename(ids2, rep)
  match rep2 {
    Rep(_, g, k, y) => {
      assert_eq(g, RepKind::greedy())
      assert_eq(k, Sem::longest())
      match y {
        Cst(_, s) => assert_eq(s, Cset::single(97))
        _ => assert_true(false)
      }
      assert_eq(Expr::id(rep2), 1)
    }
    _ => assert_true(false)
  }
}
