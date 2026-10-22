// Core — high-level Re API (port of lib/core.ml)
// Re type is Compile.Re (already defined in compile.mbt as `Re`)

// --- Character class shortcuts (return Ast) ---

///|
pub fn Re::rg(c : Char, c2 : Char) -> @ast.Ast {
  @ast.Ast::cset(@base.Cset::cseq(c, c2))
}

///|
pub fn Re::notnl() -> @ast.Ast {
  @ast.Ast::cset(@base.Cset::notnl())
}

///|
pub fn Re::lower() -> @ast.Ast {
  @ast.Ast::cset(@base.Cset::lower())
}

///|
pub fn Re::upper() -> @ast.Ast {
  @ast.Ast::cset(@base.Cset::upper())
}

///|
pub fn Re::alpha() -> @ast.Ast {
  @ast.Ast::cset(@base.Cset::alpha())
}

///|
pub fn Re::digit() -> @ast.Ast {
  @ast.Ast::cset(@base.Cset::cdigit())
}

///|
pub fn Re::alnum() -> @ast.Ast {
  @ast.Ast::cset(@base.Cset::alnum())
}

///|
pub fn Re::wordc() -> @ast.Ast {
  @ast.Ast::cset(@base.Cset::wordc())
}

///|
pub fn Re::ascii() -> @ast.Ast {
  @ast.Ast::cset(@base.Cset::ascii())
}

///|
pub fn Re::blank() -> @ast.Ast {
  @ast.Ast::cset(@base.Cset::blank())
}

///|
pub fn Re::cntrl() -> @ast.Ast {
  @ast.Ast::cset(@base.Cset::cntrl())
}

///|
pub fn Re::graph() -> @ast.Ast {
  @ast.Ast::cset(@base.Cset::graph())
}

///|
pub fn Re::print() -> @ast.Ast {
  @ast.Ast::cset(@base.Cset::print())
}

///|
pub fn Re::punct() -> @ast.Ast {
  @ast.Ast::cset(@base.Cset::punct())
}

///|
pub fn Re::space() -> @ast.Ast {
  @ast.Ast::cset(@base.Cset::space())
}

///|
pub fn Re::xdigit() -> @ast.Ast {
  @ast.Ast::cset(@base.Cset::xdigit())
}

// --- exec_opt ---

///|
/// Search for a match of `re` in `s` starting at `pos`.
/// Returns `Some(GroupT)` if found, `None` otherwise.
pub fn exec_opt(
  re : Re,
  s : Bytes,
  pos~ : Int32 = 0,
  len~ : Int32 = -1,
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
  pos~ : Int32 = 0,
  len~ : Int32 = -1,
) -> GroupT raise {
  match match_str(groups=true, partial=false, re, s, pos~, len~) {
    MatchInfo(substr) => substr
    _ => fail("Re.exec: not found")
  }
}

// --- execp ---

///|
/// Test whether `re` matches anywhere in `s`. More efficient than `exec_opt`.
pub fn execp(
  re : Re,
  s : Bytes,
  pos~ : Int32 = 0,
  len~ : Int32 = -1,
) -> Bool raise {
  match_str_p(re, s, pos~, len~)
}

// --- exec_partial ---

///|
pub(all) enum ExecPartialResult {
  Full
  Partial
  Mismatch
} derive(Eq, Debug)

///|
pub extend ExecPartialResult with Eq::{equal, not_equal}

///|
pub extend ExecPartialResult with @moonbitlang/core/debug.Debug::{to_repr}

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
  pos~ : Int32 = 0,
  len~ : Int32 = -1,
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
  PartialD(Int32)
  MismatchD
}

///|
pub fn exec_partial_detailed(
  re : Re,
  s : Bytes,
  pos~ : Int32 = 0,
  len~ : Int32 = -1,
) -> ExecPartialDetailedResult raise {
  match match_str(groups=true, partial=true, re, s, pos~, len~) {
    MatchInfo(group) => FullD(group)
    RunningInfo(no_match_starts_before) => PartialD(no_match_starts_before)
    FailedInfo => MismatchD
  }
}

// --- Mark module ---

///|
pub fn Re::mark_test(g : GroupT, p : @base.Pmark) -> Bool {
  GroupT::pmarks(g).mem(p)
}

///|
pub fn Re::mark_all(g : GroupT) -> @base.PmarkSet {
  GroupT::pmarks(g)
}

// --- Pretty printing ---

///|
/// Pretty-print an AST (uncompiled regexp) to a string.
/// Corresponds to OCaml `Re.pp`.
pub fn Re::pp(ast : @ast.Ast) -> String {
  let repr : @debug.Repr = @ast.Ast::to_dyn(ast).to_repr()
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
