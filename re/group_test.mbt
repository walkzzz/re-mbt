// Tests for Group operations (group.mbt)

///|
fn bs_g(b : Bytes) -> String {
  let mut s = ""
  for i in 0..<b.length() {
    s = s + b[i].to_int().unsafe_to_char().to_string()
  }
  s
}

// === GroupT::get_opt ===

///|
test "group get_opt matched" {
  let re = @re.compile(
    @re.Ast::seq([@re.Ast::group(@re.Ast::str(sb("ab"))), @re.Ast::group(@re.Ast::str(sb("cd")))]),
  )
  match @re.exec_opt(re, sb("abcd")) {
    Some(g) => {
      assert_eq(bs_g(@re.GroupT::get_opt(g, 0).unwrap()), "abcd")
      assert_eq(bs_g(@re.GroupT::get_opt(g, 1).unwrap()), "ab")
      assert_eq(bs_g(@re.GroupT::get_opt(g, 2).unwrap()), "cd")
    }
    None => fail("should match")
  }
}

///|
test "group get_opt unmatched group" {
  let re = @re.compile(
    @re.Ast::seq([
      @re.Ast::group(@re.Ast::str(sb("a"))),
      @re.Ast::opt(@re.Ast::group(@re.Ast::str(sb("b")))),
    ]),
  )
  match @re.exec_opt(re, sb("a")) {
    Some(g) => {
      assert_eq(bs_g(@re.GroupT::get_opt(g, 0).unwrap()), "a")
      assert_eq(bs_g(@re.GroupT::get_opt(g, 1).unwrap()), "a")
      assert_eq(@re.GroupT::get_opt(g, 2), None)
    }
    None => fail("should match")
  }
}

// === GroupT::offset / offset_opt ===

///|
test "group offset basic" {
  let re = @re.compile(@re.Ast::group(@re.Ast::str(sb("hello"))))
  match @re.exec_opt(re, sb("x hello y"), pos=2) {
    Some(g) => {
      assert_eq(@re.GroupT::offset(g, 0), (2, 7))
      assert_eq(@re.GroupT::offset_opt(g, 0), Some((2, 7)))
    }
    None => fail("should match")
  }
}

///|
test "group offset_opt unmatched" {
  let re = @re.compile(
    @re.Ast::seq([
      @re.Ast::group(@re.Ast::str(sb("a"))),
      @re.Ast::opt(@re.Ast::group(@re.Ast::str(sb("b")))),
    ]),
  )
  match @re.exec_opt(re, sb("a")) {
    Some(g) => assert_eq(@re.GroupT::offset_opt(g, 2), None)
    None => fail("should match")
  }
}

///|
test "group offset raises on unmatched" {
  let re = @re.compile(
    @re.Ast::seq([
      @re.Ast::group(@re.Ast::str(sb("a"))),
      @re.Ast::opt(@re.Ast::group(@re.Ast::str(sb("b")))),
    ]),
  )
  match @re.exec_opt(re, sb("a")) {
    Some(g) =>
      try @re.GroupT::offset(g, 2) catch {
        _ => assert_eq(true, true)
      } noraise {
        _ => fail("should raise")
      }
    None => fail("should match")
  }
}

// === GroupT::start / stop / start_opt / stop_opt ===

///|
test "group start stop" {
  let re = @re.compile(
    @re.Ast::seq([@re.Ast::group(@re.Ast::str(sb("ab"))), @re.Ast::group(@re.Ast::str(sb("cd")))]),
  )
  match @re.exec_opt(re, sb("abcd")) {
    Some(g) => {
      assert_eq(@re.GroupT::start(g, 0), 0)
      assert_eq(@re.GroupT::stop(g, 0), 4)
      assert_eq(@re.GroupT::start(g, 1), 0)
      assert_eq(@re.GroupT::stop(g, 1), 2)
      assert_eq(@re.GroupT::start(g, 2), 2)
      assert_eq(@re.GroupT::stop(g, 2), 4)
    }
    None => fail("should match")
  }
}

///|
test "group start_opt stop_opt unmatched" {
  let re = @re.compile(
    @re.Ast::seq([
      @re.Ast::group(@re.Ast::str(sb("a"))),
      @re.Ast::opt(@re.Ast::group(@re.Ast::str(sb("b")))),
    ]),
  )
  match @re.exec_opt(re, sb("a")) {
    Some(g) => {
      assert_eq(@re.GroupT::start_opt(g, 2), None)
      assert_eq(@re.GroupT::stop_opt(g, 2), None)
    }
    None => fail("should match")
  }
}

///|
test "group start raises on unmatched" {
  let re = @re.compile(
    @re.Ast::seq([
      @re.Ast::group(@re.Ast::str(sb("a"))),
      @re.Ast::opt(@re.Ast::group(@re.Ast::str(sb("b")))),
    ]),
  )
  match @re.exec_opt(re, sb("a")) {
    Some(g) =>
      try @re.GroupT::start(g, 5) catch {
        _ => assert_eq(true, true)
      } noraise {
        _ => fail("should raise")
      }
    None => fail("should match")
  }
}

///|
test "group stop raises on unmatched" {
  let re = @re.compile(
    @re.Ast::seq([
      @re.Ast::group(@re.Ast::str(sb("a"))),
      @re.Ast::opt(@re.Ast::group(@re.Ast::str(sb("b")))),
    ]),
  )
  match @re.exec_opt(re, sb("a")) {
    Some(g) =>
      try @re.GroupT::stop(g, 5) catch {
        _ => assert_eq(true, true)
      } noraise {
        _ => fail("should raise")
      }
    None => fail("should match")
  }
}

// === GroupT::matched ===

///|
test "group matched" {
  let re = @re.compile(
    @re.Ast::seq([
      @re.Ast::group(@re.Ast::str(sb("a"))),
      @re.Ast::opt(@re.Ast::group(@re.Ast::str(sb("b")))),
    ]),
  )
  match @re.exec_opt(re, sb("ab")) {
    Some(g) => {
      assert_eq(@re.GroupT::matched(g, 0), true)
      assert_eq(@re.GroupT::matched(g, 1), true)
      assert_eq(@re.GroupT::matched(g, 2), true)
    }
    None => fail("should match")
  }
  match @re.exec_opt(re, sb("a")) {
    Some(g) => {
      assert_eq(@re.GroupT::matched(g, 0), true)
      assert_eq(@re.GroupT::matched(g, 1), true)
      assert_eq(@re.GroupT::matched(g, 2), false)
    }
    None => fail("should match")
  }
}

// === GroupT::nb_groups ===

///|
test "group nb_groups" {
  let re1 = @re.compile(@re.Ast::str(sb("abc")))
  match @re.exec_opt(re1, sb("abc")) {
    Some(g) => assert_eq(@re.GroupT::nb_groups(g), 1)
    None => fail("should match")
  }
  let re2 = @re.compile(
    @re.Ast::seq([
      @re.Ast::group(@re.Ast::str(sb("a"))),
      @re.Ast::group(@re.Ast::str(sb("b"))),
      @re.Ast::group(@re.Ast::str(sb("c"))),
    ]),
  )
  match @re.exec_opt(re2, sb("abc")) {
    Some(g) => assert_eq(@re.GroupT::nb_groups(g), 4)
    None => fail("should match")
  }
}

// === GroupT::start_offset / stop_offset ===

///|
test "group start_offset stop_offset" {
  let re = @re.compile(
    @re.Ast::seq([@re.Ast::group(@re.Ast::str(sb("ab"))), @re.Ast::group(@re.Ast::str(sb("cd")))]),
  )
  match @re.exec_opt(re, sb("abcd")) {
    Some(g) => {
      assert_eq(@re.GroupT::start_offset(g, 0), 0)
      assert_eq(@re.GroupT::stop_offset(g, 0), 4)
      assert_eq(@re.GroupT::start_offset(g, 1), 0)
      assert_eq(@re.GroupT::stop_offset(g, 1), 2)
      assert_eq(@re.GroupT::start_offset(g, 2), 2)
      assert_eq(@re.GroupT::stop_offset(g, 2), 4)
    }
    None => fail("should match")
  }
}

///|
test "group start_offset unmatched returns -1" {
  let re = @re.compile(
    @re.Ast::seq([
      @re.Ast::group(@re.Ast::str(sb("a"))),
      @re.Ast::opt(@re.Ast::group(@re.Ast::str(sb("b")))),
    ]),
  )
  match @re.exec_opt(re, sb("a")) {
    Some(g) => {
      assert_eq(@re.GroupT::start_offset(g, 2), -1)
      assert_eq(@re.GroupT::stop_offset(g, 2), -1)
    }
    None => fail("should match")
  }
}

// === GroupT::all ===

///|
test "group all" {
  let re = @re.compile(
    @re.Ast::seq([@re.Ast::group(@re.Ast::str(sb("ab"))), @re.Ast::group(@re.Ast::str(sb("cd")))]),
  )
  match @re.exec_opt(re, sb("abcd")) {
    Some(g) => {
      let all = @re.GroupT::all(g)
      assert_eq(all.length(), 3)
      assert_eq(bs_g(all[0]), "abcd")
      assert_eq(bs_g(all[1]), "ab")
      assert_eq(bs_g(all[2]), "cd")
    }
    None => fail("should match")
  }
}

///|
test "group all with unmatched" {
  let re = @re.compile(
    @re.Ast::seq([
      @re.Ast::group(@re.Ast::str(sb("a"))),
      @re.Ast::opt(@re.Ast::group(@re.Ast::str(sb("b")))),
    ]),
  )
  match @re.exec_opt(re, sb("a")) {
    Some(g) => {
      let all = @re.GroupT::all(g)
      assert_eq(all.length(), 3)
      assert_eq(bs_g(all[0]), "a")
      assert_eq(bs_g(all[1]), "a")
      assert_eq(bs_g(all[2]), "")
    }
    None => fail("should match")
  }
}

// === GroupT::all_offset ===

///|
test "group all_offset" {
  let re = @re.compile(
    @re.Ast::seq([@re.Ast::group(@re.Ast::str(sb("ab"))), @re.Ast::group(@re.Ast::str(sb("cd")))]),
  )
  match @re.exec_opt(re, sb("abcd")) {
    Some(g) => {
      let offs = @re.GroupT::all_offset(g)
      assert_eq(offs.length(), 3)
      assert_eq(offs[0], (0, 4))
      assert_eq(offs[1], (0, 2))
      assert_eq(offs[2], (2, 4))
    }
    None => fail("should match")
  }
}

///|
test "group all_offset with unmatched" {
  let re = @re.compile(
    @re.Ast::seq([
      @re.Ast::group(@re.Ast::str(sb("a"))),
      @re.Ast::opt(@re.Ast::group(@re.Ast::str(sb("b")))),
    ]),
  )
  match @re.exec_opt(re, sb("a")) {
    Some(g) => {
      let offs = @re.GroupT::all_offset(g)
      assert_eq(offs.length(), 3)
      assert_eq(offs[0], (0, 1))
      assert_eq(offs[1], (0, 1))
      assert_eq(offs[2], (-1, -1))
    }
    None => fail("should match")
  }
}

// === GroupT::pmarks ===

///|
test "group pmarks" {
  let re = @re.compile(@re.Ast::str(sb("abc")))
  match @re.exec_opt(re, sb("abc")) {
    Some(g) => {
      let pm = @re.GroupT::pmarks(g)
      ignore(pm)
    }
    None => fail("should match")
  }
}
