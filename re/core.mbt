// Core — high-level Re API (port of lib/core.ml)
// Re type is Compile.Re (already defined in compile.mbt as `Re`)

// --- Character class shortcuts (return Ast) ---

///|
pub fn Re::rg(c : Char, c2 : Char) -> Ast {
  Ast::cset(Cset::cseq(c, c2))
}

///|
pub fn Re::notnl() -> Ast {
  Ast::cset(Cset::notnl())
}

///|
pub fn Re::lower() -> Ast {
  Ast::cset(Cset::lower())
}

///|
pub fn Re::upper() -> Ast {
  Ast::cset(Cset::upper())
}

///|
pub fn Re::alpha() -> Ast {
  Ast::cset(Cset::alpha())
}

///|
pub fn Re::digit() -> Ast {
  Ast::cset(Cset::cdigit())
}

///|
pub fn Re::alnum() -> Ast {
  Ast::cset(Cset::alnum())
}

///|
pub fn Re::wordc() -> Ast {
  Ast::cset(Cset::wordc())
}

///|
pub fn Re::ascii() -> Ast {
  Ast::cset(Cset::ascii())
}

///|
pub fn Re::blank() -> Ast {
  Ast::cset(Cset::blank())
}

///|
pub fn Re::cntrl() -> Ast {
  Ast::cset(Cset::cntrl())
}

///|
pub fn Re::graph() -> Ast {
  Ast::cset(Cset::graph())
}

///|
pub fn Re::print() -> Ast {
  Ast::cset(Cset::print())
}

///|
pub fn Re::punct() -> Ast {
  Ast::cset(Cset::punct())
}

///|
pub fn Re::space() -> Ast {
  Ast::cset(Cset::space())
}

///|
pub fn Re::xdigit() -> Ast {
  Ast::cset(Cset::xdigit())
}

// --- exec_opt ---

///|
/// Search for a match of `re` in `s` starting at `pos`.
/// Returns `Some(GroupT)` if found, `None` otherwise.
pub fn exec_opt(
  re : Re,
  s : Bytes,
  pos? : Int = 0,
  len? : Int = -1,
) -> GroupT? raise {
  match match_str(groups=true, partial=false, re, s, pos~, len~) {
    MatchInfo(substr) => Some(substr)
    _ => None
  }
}

// --- exec ---

///|
/// Search for a match of `re` in `s`. Raises if no match found.
pub fn exec(
  re : Re,
  s : Bytes,
  pos? : Int = 0,
  len? : Int = -1,
) -> GroupT raise {
  match match_str(groups=true, partial=false, re, s, pos~, len~) {
    MatchInfo(substr) => substr
    _ => fail("Re.exec: not found")
  }
}

// --- execp ---

///|
/// Test whether `re` matches anywhere in `s`. More efficient than `exec_opt`.
pub fn execp(re : Re, s : Bytes, pos? : Int = 0, len? : Int = -1) -> Bool raise {
  match_str_p(re, s, pos~, len~)
}

// --- exec_partial ---

///|
pub enum ExecPartialResult {
  Full
  Partial
  Mismatch
} derive(Eq, Debug)

///|
pub fn ExecPartialResult::full() -> ExecPartialResult {
  Full
}

///|
pub fn ExecPartialResult::partial() -> ExecPartialResult {
  Partial
}

///|
pub fn ExecPartialResult::mismatch() -> ExecPartialResult {
  Mismatch
}

///|
pub fn exec_partial(
  re : Re,
  s : Bytes,
  pos? : Int = 0,
  len? : Int = -1,
) -> ExecPartialResult raise {
  match match_str(groups=false, partial=true, re, s, pos~, len~) {
    MatchInfo(_) => Full
    RunningInfo(_) => Partial
    FailedInfo => Mismatch
  }
}

// --- exec_partial_detailed ---

///|
pub enum ExecPartialDetailedResult {
  FullD(GroupT)
  PartialD(Int)
  MismatchD
}

///|
pub fn exec_partial_detailed(
  re : Re,
  s : Bytes,
  pos? : Int = 0,
  len? : Int = -1,
) -> ExecPartialDetailedResult raise {
  match match_str(groups=true, partial=true, re, s, pos~, len~) {
    MatchInfo(group) => FullD(group)
    RunningInfo(no_match_starts_before) => PartialD(no_match_starts_before)
    FailedInfo => MismatchD
  }
}

// --- Mark module ---

///|
pub fn Re::mark_test(g : GroupT, p : Pmark) -> Bool {
  GroupT::pmarks(g).mem(p)
}

///|
pub fn Re::mark_all(g : GroupT) -> PmarkSet {
  GroupT::pmarks(g)
}

// --- Pretty printing ---

///|
/// Pretty-print an AST (uncompiled regexp) to a string.
/// Corresponds to OCaml `Re.pp`.
pub fn Re::pp(ast : Ast) -> String {
  let repr : @debug.Repr = Ast::to_dyn(ast).to_repr()
  "\{repr}"
}

///|
/// Pretty-print a compiled regexp to a string.
/// Corresponds to OCaml `Re.pp_re`.
pub fn Re::pp_re(re : Re) -> String {
  let names = Re::group_names(re)
  let name_str = if names.length() == 0 {
    ""
  } else {
    let mut s = " groups:"
    for entry in names {
      let (name, idx) = entry
      s = s + " " + name + "=" + idx.to_string()
    }
    s
  }
  "Re(group_count=" + Re::group_count(re).to_string() + name_str + ")"
}
