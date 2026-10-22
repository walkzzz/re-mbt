// Tests for Automata State, WorkingArea, delta, advance

///|
fn status_is_running(s : @re.Status) -> Bool {
  match s {
    Running => true
    _ => false
  }
}

///|
fn status_is_failed(s : @re.Status) -> Bool {
  match s {
    Failed => true
    _ => false
  }
}

///|
fn status_is_match(s : @re.Status) -> Bool {
  match s {
    Match(_, _) => true
    _ => false
  }
}

///|
test "State::create and dummy" {
  let ids = @re.Ids::create()
  let expr = @re.Expr::cst(ids, @re.Cset::single(97))
  let cat = @re.Category::from_char('a')
  let s = @re.State::create(cat, expr)
  assert_eq(s.idx, @re.Idx::initial())

  let d = @re.State::dummy()
  assert_eq(d.idx, @re.Idx::unknown())
  assert_eq(d.hash, -1)
}

///|
test "State::equal - self equality" {
  let ids = @re.Ids::create()
  let expr = @re.Expr::cst(ids, @re.Cset::single(97))
  let cat = @re.Category::from_char('a')
  let s1 = @re.State::create(cat, expr)
  assert_eq(@re.State::equal(s1, s1), true)
}

///|
test "delta: regex 'a' with matching char" {
  let ids = @re.Ids::create()
  let expr = @re.Expr::cst(ids, @re.Cset::single(97))
  let cat = @re.Category::from_char('a')
  let wa = @re.WorkingArea::create()
  let s0 = @re.State::create(cat, expr)
  let s1 = @re.delta(wa, cat, 97, s0)
  let st = @re.State::status(s1)
  assert_eq(status_is_running(st), true)
}

///|
test "delta: regex 'a' with non-matching char" {
  let ids = @re.Ids::create()
  let expr = @re.Expr::cst(ids, @re.Cset::single(97))
  let cat = @re.Category::from_char('a')
  let wa = @re.WorkingArea::create()
  let s0 = @re.State::create(cat, expr)
  let s1 = @re.delta(wa, cat, 98, s0)
  let st = @re.State::status(s1)
  assert_eq(status_is_failed(st), true)
}

///|
test "advance: regex 'a' after matching delta" {
  let ids = @re.Ids::create()
  let expr = @re.Expr::cst(ids, @re.Cset::single(97))
  let cat = @re.Category::from_char('a')
  let wa = @re.WorkingArea::create()
  let s0 = @re.State::create(cat, expr)
  let s1 = @re.delta(wa, cat, 97, s0)
  let s2 = @re.advance(wa, s1)
  let st = @re.State::status(s2)
  assert_eq(status_is_match(st), true)
}

///|
test "delta: regex 'a*' with matching char stays running" {
  let ids = @re.Ids::create()
  let a_cset = @re.Cset::single(97)
  let a_expr = @re.Expr::cst(ids, a_cset)
  let star_expr = @re.Expr::rep(
    ids,
    @re.RepKind::greedy(),
    @re.Sem::longest(),
    a_expr,
  )
  let cat = @re.Category::from_char('a')
  let wa = @re.WorkingArea::create()
  let s0 = @re.State::create(cat, star_expr)
  let s1 = @re.delta(wa, cat, 97, s0)
  let st = @re.State::status(s1)
  assert_eq(status_is_running(st), true)
}

///|
test "advance: regex 'a*' after non-matching char gives match" {
  let ids = @re.Ids::create()
  let a_cset = @re.Cset::single(97)
  let a_expr = @re.Expr::cst(ids, a_cset)
  let star_expr = @re.Expr::rep(
    ids,
    @re.RepKind::greedy(),
    @re.Sem::longest(),
    a_expr,
  )
  let cat = @re.Category::from_char('a')
  let wa = @re.WorkingArea::create()
  let s0 = @re.State::create(cat, star_expr)
  let s1 = @re.delta(wa, cat, 98, s0)
  let s2 = @re.advance(wa, s1)
  let st = @re.State::status(s2)
  assert_eq(status_is_match(st), true)
}

///|
test "WorkingArea::free_index returns 0 for empty desc" {
  let wa = @re.WorkingArea::create()
  let idx = @re.WorkingArea::free_index(wa, @re.Desc::empty())
  assert_eq(idx, 0)
}

///|
test "delta: regex 'ab' (sequence) with 'a' then 'b'" {
  let ids = @re.Ids::create()
  let a_expr = @re.Expr::cst(ids, @re.Cset::single(97))
  let b_expr = @re.Expr::cst(ids, @re.Cset::single(98))
  let ab_expr = @re.Expr::seq(ids, @re.Sem::first(), a_expr, b_expr)
  let cat = @re.Category::from_char('a')
  let wa = @re.WorkingArea::create()
  let s0 = @re.State::create(cat, ab_expr)
  let s1 = @re.delta(wa, cat, 97, s0)
  let st1 = @re.State::status(s1)
  assert_eq(status_is_running(st1), true)
  let s2 = @re.delta(wa, cat, 98, s1)
  let st2 = @re.State::status(s2)
  assert_eq(status_is_running(st2), true)
  let s3 = @re.advance(wa, s2)
  let st3 = @re.State::status(s3)
  assert_eq(status_is_match(st3), true)
}

///|
test "delta: regex 'a|b' (alternative) with 'a'" {
  let ids = @re.Ids::create()
  let a_expr = @re.Expr::cst(ids, @re.Cset::single(97))
  let b_expr = @re.Expr::cst(ids, @re.Cset::single(98))
  let alt_expr = @re.Expr::alt(ids, [a_expr, b_expr])
  let cat = @re.Category::from_char('a')
  let wa = @re.WorkingArea::create()
  let s0 = @re.State::create(cat, alt_expr)
  let s1 = @re.delta(wa, cat, 97, s0)
  let s2 = @re.advance(wa, s1)
  let st = @re.State::status(s2)
  assert_eq(status_is_match(st), true)
}

///|
test "delta: regex 'a|b' (alternative) with 'b'" {
  let ids = @re.Ids::create()
  let a_expr = @re.Expr::cst(ids, @re.Cset::single(97))
  let b_expr = @re.Expr::cst(ids, @re.Cset::single(98))
  let alt_expr = @re.Expr::alt(ids, [a_expr, b_expr])
  let cat = @re.Category::from_char('a')
  let wa = @re.WorkingArea::create()
  let s0 = @re.State::create(cat, alt_expr)
  let s1 = @re.delta(wa, cat, 98, s0)
  let s2 = @re.advance(wa, s1)
  let st = @re.State::status(s2)
  assert_eq(status_is_match(st), true)
}

///|
test "delta: regex 'a|b' (alternative) with 'c' fails" {
  let ids = @re.Ids::create()
  let a_expr = @re.Expr::cst(ids, @re.Cset::single(97))
  let b_expr = @re.Expr::cst(ids, @re.Cset::single(98))
  let alt_expr = @re.Expr::alt(ids, [a_expr, b_expr])
  let cat = @re.Category::from_char('a')
  let wa = @re.WorkingArea::create()
  let s0 = @re.State::create(cat, alt_expr)
  let s1 = @re.delta(wa, cat, 99, s0)
  let st = @re.State::status(s1)
  assert_eq(status_is_failed(st), true)
}

///|
test "delta: regex eps matches immediately" {
  let ids = @re.Ids::create()
  let eps_expr = @re.Expr::eps(ids)
  let cat = @re.Category::from_char('a')
  let wa = @re.WorkingArea::create()
  let s0 = @re.State::create(cat, eps_expr)
  let s1 = @re.advance(wa, s0)
  let st = @re.State::status(s1)
  assert_eq(status_is_match(st), true)
}

///|
test "expr rename Cst preserves cset with new id" {
  let ids1 = @re.Ids::create()
  let e = @re.Expr::cst(ids1, @re.Cset::single(97))
  let ids2 = @re.Ids::create()
  let e2 = @re.Expr::rename(ids2, e)
  match e2 {
    Cst(_, s) => {
      assert_eq(s, @re.Cset::single(97))
      assert_eq(@re.Expr::id(e2), 1)
    }
    _ => assert_true(false)
  }
}

///|
test "expr rename Seq recursively renames children" {
  let ids1 = @re.Ids::create()
  let a = @re.Expr::cst(ids1, @re.Cset::single(97))
  let b = @re.Expr::cst(ids1, @re.Cset::single(98))
  let seq = @re.Expr::seq(ids1, @re.Sem::longest(), a, b)
  let ids2 = @re.Ids::create()
  let seq2 = @re.Expr::rename(ids2, seq)
  match seq2 {
    Seq(_, k, y, z) => {
      assert_eq(k, @re.Sem::longest())
      assert_eq(@re.Expr::id(seq2), 1)
      match y {
        Cst(_, s1) => assert_eq(s1, @re.Cset::single(97))
        _ => assert_true(false)
      }
      match z {
        Cst(_, s2) => assert_eq(s2, @re.Cset::single(98))
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}

///|
test "expr rename Alt recursively renames all children" {
  let ids1 = @re.Ids::create()
  let a = @re.Expr::cst(ids1, @re.Cset::single(97))
  let b = @re.Expr::cst(ids1, @re.Cset::single(98))
  let c = @re.Expr::cst(ids1, @re.Cset::single(99))
  let alt = @re.Expr::alt(ids1, [a, b, c])
  let ids2 = @re.Ids::create()
  let alt2 = @re.Expr::rename(ids2, alt)
  match alt2 {
    Alt(_, l) => {
      assert_eq(l.length(), 3)
      match l[0] {
        Cst(_, s) => assert_eq(s, @re.Cset::single(97))
        _ => assert_true(false)
      }
      match l[1] {
        Cst(_, s) => assert_eq(s, @re.Cset::single(98))
        _ => assert_true(false)
      }
      match l[2] {
        Cst(_, s) => assert_eq(s, @re.Cset::single(99))
        _ => assert_true(false)
      }
      assert_eq(@re.Expr::id(alt2), 4)
    }
    _ => assert_true(false)
  }
}

///|
test "expr rename Rep recursively renames child" {
  let ids1 = @re.Ids::create()
  let a = @re.Expr::cst(ids1, @re.Cset::single(97))
  let rep = @re.Expr::rep(ids1, @re.RepKind::greedy(), @re.Sem::longest(), a)
  let ids2 = @re.Ids::create()
  let rep2 = @re.Expr::rename(ids2, rep)
  match rep2 {
    Rep(_, g, k, y) => {
      assert_eq(g, @re.RepKind::greedy())
      assert_eq(k, @re.Sem::longest())
      match y {
        Cst(_, s) => assert_eq(s, @re.Cset::single(97))
        _ => assert_true(false)
      }
      assert_eq(@re.Expr::id(rep2), 1)
    }
    _ => assert_true(false)
  }
}
