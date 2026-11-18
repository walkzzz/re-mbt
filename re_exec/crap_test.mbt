// crap_test.mbt — CRAP coverage tests for re_exec
// Covers view.mbt, search.mbt, replace.mbt

// === View coverage (View::view CRAP ~64, view_set CRAP ~15) ===

///|
test "view NoCase" {
  let r = @ast.Ast::no_case(@ast.Ast::char('a'))
  let _ = @re_exec.View::view(r)
}

///|
test "view_set Intersection Complement Difference" {
  let r1 = @ast.Ast::inter([@ast.Ast::char('a'), @ast.Ast::char('b')])
  let _ = @re_exec.View::view(r1)
  let r2 = @ast.Ast::compl([@ast.Ast::char('a')])
  let _ = @re_exec.View::view(r2)
  let r3 = @ast.Ast::diff(@ast.Ast::char('a'), @ast.Ast::char('b'))
  let _ = @re_exec.View::view(r3)
}

///|
test "View::view BegOfWord LastEndOfLine SemGreedy Pmark" {
  let _ = @re_exec.View::view(@ast.Ast::bow())
  let _ = @re_exec.View::view(@ast.Ast::leol())
  let _ = @re_exec.View::view(@ast.Ast::greedy(@ast.Ast::char('a')))
  let (pm, marked) = @ast.Ast::mark(@ast.Ast::char('a'))
  let _ = @re_exec.View::view(marked)
  ignore(pm)
}

// === Search::all coverage (CRAP ~10) ===

///|
test "Search::all invalid len" {
  let re = @compile.compile(@ast.Ast::str(@base.sb("a")))
  let r1 = try {
    let _ = @re_exec.Search::all(re, @base.sb("abc"), pos=0, len=100)
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
}

///|
test "Search::all empty match skip" {
  let re = @compile.compile(@ast.Ast::rep(@ast.Ast::char('a')))
  let results = @re_exec.Search::all(re, @base.sb("aa"))
  assert_eq(results.length() >= 1, true)
}

// === Search::split_full coverage (CRAP ~18) ===

///|
test "Search::split_full invalid len" {
  let re = @compile.compile(@ast.Ast::str(@base.sb(",")))
  let r1 = try {
    let _ = @re_exec.Search::split_full(re, @base.sb("a,b"), pos=0, len=100)
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
}

///|
test "Search::split_full empty match" {
  let re = @compile.compile(@ast.Ast::rep(@ast.Ast::char('a')))
  let results = @re_exec.Search::split_full(re, @base.sb("aaa"))
  assert_eq(results.length() >= 1, true)
}

///|
test "Search::matches None case" {
  let re = @compile.compile(@ast.Ast::rep(@ast.Ast::char('a')))
  let results = @re_exec.Search::matches(re, @base.sb("aaa"))
  assert_eq(results.length() >= 1, true)
}

// === Replace::replace coverage (CRAP ~23) ===

///|
test "Replace::replace invalid pos" {
  let re = @compile.compile(@ast.Ast::str(@base.sb("a")))
  let r1 = try {
    let _ = @re_exec.Replace::replace(
      re,
      @base.sb("abc"),
      f=fn(g : @compile.GroupT) { @compile.GroupT::get(g, 0).unwrap() },
      pos=-1,
    )
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
}

///|
test "Replace::replace invalid len" {
  let re = @compile.compile(@ast.Ast::str(@base.sb("a")))
  let r1 = try {
    let _ = @re_exec.Replace::replace(
      re,
      @base.sb("abc"),
      f=fn(g : @compile.GroupT) { @compile.GroupT::get(g, 0).unwrap() },
      len=100,
    )
    false
  } catch {
    _ => true
  }
  assert_eq(r1, true)
}

///|
test "Replace::replace empty match all" {
  let re = @compile.compile(@ast.Ast::rep(@ast.Ast::char('a')))
  let result = @re_exec.Replace::replace(
    re,
    @base.sb("aaa"),
    f=fn(g : @compile.GroupT) { @compile.GroupT::get(g, 0).unwrap() },
    all=true,
  )
  assert_eq(@base.bs(result).length() > 0, true)
}

///|
test "Replace::replace no match" {
  let re = @compile.compile(@ast.Ast::str(@base.sb("xyz")))
  let result = @re_exec.Replace::replace(re, @base.sb("abc"), f=fn(
    g : @compile.GroupT,
  ) {
    @compile.GroupT::get(g, 0).unwrap()
  })
  assert_eq(@base.bs(result), "abc")
}

///|
test "Replace::replace with pos and len" {
  let re = @compile.compile(@ast.Ast::str(@base.sb("a")))
  let result = @re_exec.Replace::replace(
    re,
    @base.sb("aaa"),
    f=fn(_g : @compile.GroupT) { @base.sb("X") },
    pos=1,
    len=2,
  )
  assert_eq(@base.bs(result), "aXX")
}
