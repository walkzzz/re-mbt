// Glob — glob pattern parser (port of lib/glob.ml)

///|
let glob_double_star_slash : Bytes = sb("**/")

///|
#warnings("-struct_never_constructed")
pub struct Glob {}

///|
priv enum GlobEnclosed {
  GlobChar(Char)
  GlobRange(Char, Char)
}

///|
priv enum GlobPiece {
  GlobExactly(Char)
  GlobAnyOf(Array[GlobEnclosed])
  GlobAnyBut(Array[GlobEnclosed])
  GlobOne
  GlobMany
  GlobManyMany(Bool)
}

///|
fn glob_enclosed_loop(
  buf : ParseBuffer,
  s : Array[GlobEnclosed],
) -> Array[GlobEnclosed] raise {
  if s.length() > 0 && ParseBuffer::accept(buf, ']') {
    s.rev_in_place()
    s
  } else {
    if !ParseBuffer::accept(buf, '\\') {
      fail("Glob parse error")
    }
    if ParseBuffer::eos(buf) {
      fail("Glob parse error")
    }
    let c = ParseBuffer::get(buf)
    if !ParseBuffer::accept(buf, '-') {
      s.push(GlobChar(c))
      glob_enclosed_loop(buf, s)
    } else if ParseBuffer::accept(buf, ']') {
      s.push(GlobChar(c))
      s.push(GlobChar('-'))
      s.rev_in_place()
      s
    } else {
      if !ParseBuffer::accept(buf, '\\') {
        fail("Glob parse error")
      }
      if ParseBuffer::eos(buf) {
        fail("Glob parse error")
      }
      let c2 = ParseBuffer::get(buf)
      s.push(GlobRange(c, c2))
      glob_enclosed_loop(buf, s)
    }
  }
}

///|
fn glob_enclosed(buf : ParseBuffer) -> Array[GlobEnclosed] raise {
  glob_enclosed_loop(buf, [])
}

///|
fn glob_piece_fn(
  buf : ParseBuffer,
  acc : Array[GlobPiece],
  double_asterisk : Bool,
) -> Array[GlobPiece] raise {
  let is_at_start = match acc.last() {
    None => true
    Some(GlobExactly('/')) => true
    _ => false
  }
  if double_asterisk &&
    is_at_start &&
    ParseBuffer::accept_s(buf, glob_double_star_slash) {
    acc.push(GlobManyMany(true))
    acc
  } else if ParseBuffer::accept(buf, '*') {
    let p = if double_asterisk && ParseBuffer::accept(buf, '*') {
      GlobManyMany(false)
    } else {
      GlobMany
    }
    acc.push(p)
    acc
  } else if ParseBuffer::accept(buf, '?') {
    acc.push(GlobOne)
    acc
  } else if !ParseBuffer::accept(buf, '[') {
    let _ = ParseBuffer::accept(buf, '\\')
    if ParseBuffer::eos(buf) {
      fail("Glob parse error")
    }
    let c = ParseBuffer::get(buf)
    acc.push(GlobExactly(c))
    acc
  } else if ParseBuffer::accept(buf, '^') || ParseBuffer::accept(buf, '!') {
    acc.push(GlobAnyBut(glob_enclosed(buf)))
    acc
  } else {
    acc.push(GlobAnyOf(glob_enclosed(buf)))
    acc
  }
}

///|
fn glob_of_string(s : Bytes, double_asterisk : Bool) -> Array[GlobPiece] raise {
  let buf = ParseBuffer::create(s)
  let mut pieces : Array[GlobPiece] = []
  while !ParseBuffer::eos(buf) {
    pieces = glob_piece_fn(buf, pieces, double_asterisk)
  }
  pieces
}

///|
priv struct GlobState {
  re_pieces : Array[Ast]
  remaining : Array[GlobPiece]
  remaining_pos : Int
  am_at_start_of_pattern : Bool
  am_at_start_of_component : Bool
  pathname : Bool
  match_backslashes : Bool
  period : Bool
}

///|
fn GlobState::create(
  period~ : Bool,
  pathname~ : Bool,
  match_backslashes~ : Bool,
  remaining : Array[GlobPiece],
) -> GlobState {
  {
    re_pieces: [],
    am_at_start_of_pattern: true,
    am_at_start_of_component: true,
    pathname,
    match_backslashes,
    period,
    remaining,
    remaining_pos: 0,
  }
}

///|
fn GlobState::explicit_period(t : GlobState) -> Bool {
  t.period &&
  (t.am_at_start_of_pattern || (t.am_at_start_of_component && t.pathname))
}

///|
fn GlobState::explicit_slash(t : GlobState) -> Bool {
  t.pathname
}

///|
fn GlobState::slashes(t : GlobState) -> Array[Char] {
  if t.match_backslashes {
    ['/', '\\']
  } else {
    ['/']
  }
}

///|
fn GlobState::append(
  t : GlobState,
  piece : Ast,
  am_at_start_of_component? : Bool = false,
) -> GlobState {
  t.re_pieces.push(piece)
  {
    re_pieces: t.re_pieces,
    remaining: t.remaining,
    remaining_pos: t.remaining_pos,
    am_at_start_of_pattern: false,
    am_at_start_of_component,
    pathname: t.pathname,
    match_backslashes: t.match_backslashes,
    period: t.period,
  }
}

///|
fn GlobState::to_re(t : GlobState) -> Ast {
  Ast::seq(t.re_pieces)
}

///|
fn GlobState::next(t : GlobState) -> (GlobPiece, GlobState)? {
  if t.remaining_pos >= t.remaining.length() {
    None
  } else {
    let piece = t.remaining[t.remaining_pos]
    Some((piece, { ..t, remaining_pos: t.remaining_pos + 1 }))
  }
}

///|
fn glob_one(
  explicit_slash~ : Bool,
  slashes~ : Array[Char],
  explicit_period~ : Bool,
) -> Ast raise {
  let chars : Array[Ast] = []
  if explicit_slash {
    for s in slashes {
      chars.push(Ast::char(s))
    }
  }
  if explicit_period {
    chars.push(Ast::char('.'))
  }
  if chars.length() == 0 {
    Ast::any()
  } else {
    Ast::compl(chars)
  }
}

///|
fn glob_enclosed_to_ast(enc : GlobEnclosed) -> Ast {
  match enc {
    GlobChar(c) => Ast::char(c)
    GlobRange(low, high) => Re::rg(low, high)
  }
}

///|
fn glob_enclosed_set(
  kind : Bool,
  set : Array[GlobEnclosed],
  explicit_slash~ : Bool,
  slashes~ : Array[Char],
  explicit_period~ : Bool,
) -> Ast raise {
  let set_asts : Array[Ast] = []
  for e in set {
    set_asts.push(glob_enclosed_to_ast(e))
  }
  let enclosure = if kind { Ast::alt(set_asts) } else { Ast::compl(set_asts) }
  Ast::inter([enclosure, glob_one(explicit_slash~, slashes~, explicit_period~)])
}

///|
fn glob_exactly(state : GlobState, c : Char) -> GlobState {
  let slashes = GlobState::slashes(state)
  let am_at_start_of_component = {
    let mut f = false
    for s in slashes {
      if !f && s == c {
        f = true
      }
    }
    f
  }
  let chars = if am_at_start_of_component { slashes } else { [c] }
  let char_asts : Array[Ast] = []
  for ch in chars {
    char_asts.push(Ast::char(ch))
  }
  GlobState::append(state, Ast::alt(char_asts), am_at_start_of_component~)
}

///|
fn glob_match_component(slashes : Array[Char], ep : Bool) -> Ast raise {
  Ast::seq([
    glob_one(explicit_slash=true, slashes~, explicit_period=ep),
    Ast::rep(glob_one(explicit_slash=true, slashes~, explicit_period=false)),
  ])
}

///|
fn glob_many_many(
  state : GlobState,
  component_with_terminator~ : Bool,
) -> GlobState raise {
  let explicit_period = state.period && state.pathname
  let slashes = GlobState::slashes(state)
  let slashes_re_asts : Array[Ast] = []
  for s in slashes {
    slashes_re_asts.push(Ast::char(s))
  }
  let slashes_re = Ast::alt(slashes_re_asts)
  let match_components = Ast::seq([
    Ast::opt(glob_match_component(slashes, explicit_period)),
    Ast::rep(
      Ast::seq([
        slashes_re,
        Ast::opt(glob_match_component(slashes, explicit_period)),
      ]),
    ),
  ])
  let result = if component_with_terminator {
    Ast::opt(Ast::seq([match_components, slashes_re]))
  } else {
    match_components
  }
  GlobState::append(state, result)
}

///|
fn glob_many(state : GlobState) -> GlobState raise {
  let explicit_slash = GlobState::explicit_slash(state)
  let explicit_period = GlobState::explicit_period(state)
  let slashes = GlobState::slashes(state)
  if !explicit_period {
    GlobState::append(
      state,
      Ast::rep(glob_one(explicit_slash~, slashes~, explicit_period~)),
    )
  } else if !explicit_slash {
    GlobState::append(
      state,
      Ast::opt(
        Ast::seq([
          glob_one(explicit_slash=false, slashes~, explicit_period~),
          Ast::rep(
            glob_one(explicit_slash=false, slashes~, explicit_period=false),
          ),
        ]),
      ),
    )
  } else {
    let not_empty = Ast::seq([
      glob_one(explicit_slash=true, slashes~, explicit_period=true),
      Ast::rep(glob_one(explicit_slash=true, slashes~, explicit_period=false)),
    ])
    let maybe_empty = Ast::opt(not_empty)
    glob_many_lookahead(state, not_empty, maybe_empty)
  }
}

///|
fn glob_many_lookahead(
  state : GlobState,
  not_empty : Ast,
  maybe_empty : Ast,
) -> GlobState raise {
  match GlobState::next(state) {
    None => GlobState::append(state, maybe_empty)
    Some((piece, state2)) =>
      match piece {
        GlobMany => glob_many_lookahead(state2, not_empty, maybe_empty)
        GlobExactly(c) => {
          let state3 = GlobState::append(
            state2,
            if c == '.' {
              not_empty
            } else {
              maybe_empty
            },
          )
          glob_exactly(state3, c)
        }
        GlobOne => GlobState::append(state2, not_empty)
        GlobAnyOf(enclosed) => {
          let slashes = GlobState::slashes(state)
          GlobState::append(
            state2,
            Ast::alt([
              glob_enclosed_set(
                true,
                enclosed,
                explicit_slash=true,
                slashes~,
                explicit_period=true,
              ),
              Ast::seq([
                not_empty,
                glob_enclosed_set(
                  true,
                  enclosed,
                  explicit_slash=true,
                  slashes~,
                  explicit_period=false,
                ),
              ]),
            ]),
          )
        }
        GlobAnyBut(enclosed) => {
          let slashes = GlobState::slashes(state)
          GlobState::append(
            state2,
            Ast::alt([
              glob_enclosed_set(
                false,
                enclosed,
                explicit_slash=true,
                slashes~,
                explicit_period=true,
              ),
              Ast::seq([
                not_empty,
                glob_enclosed_set(
                  false,
                  enclosed,
                  explicit_slash=true,
                  slashes~,
                  explicit_period=false,
                ),
              ]),
            ]),
          )
        }
        GlobManyMany(cwt) => {
          if cwt {
            fail("Glob: ** after * with terminator")
          }
          glob_many_many(state2, component_with_terminator=cwt)
        }
      }
  }
}

///|
fn glob_piece(state : GlobState, piece : GlobPiece) -> GlobState raise {
  let explicit_slash = GlobState::explicit_slash(state)
  let explicit_period = GlobState::explicit_period(state)
  let slashes = GlobState::slashes(state)
  match piece {
    GlobOne =>
      GlobState::append(
        state,
        glob_one(explicit_slash~, slashes~, explicit_period~),
      )
    GlobMany => glob_many(state)
    GlobAnyOf(enclosed) =>
      GlobState::append(
        state,
        glob_enclosed_set(
          true,
          enclosed,
          explicit_slash~,
          slashes~,
          explicit_period~,
        ),
      )
    GlobAnyBut(enclosed) =>
      GlobState::append(
        state,
        glob_enclosed_set(
          false,
          enclosed,
          explicit_slash~,
          slashes~,
          explicit_period~,
        ),
      )
    GlobExactly(c) => glob_exactly(state, c)
    GlobManyMany(cwt) => glob_many_many(state, component_with_terminator=cwt)
  }
}

///|
fn glob_to_re(
  pathname~ : Bool,
  match_backslashes~ : Bool,
  period~ : Bool,
  pieces : Array[GlobPiece],
) -> Ast raise {
  let mut state = GlobState::create(
    period~,
    pathname~,
    match_backslashes~,
    pieces,
  )
  while true {
    match GlobState::next(state) {
      None => break
      Some((p, s)) => state = glob_piece(s, p)
    }
  }
  GlobState::to_re(state)
}

///|
pub fn Glob::glob(
  s : Bytes,
  anchored? : Bool = false,
  pathname? : Bool = true,
  match_backslashes? : Bool = false,
  period? : Bool = true,
  double_asterisk? : Bool = true,
) -> Ast raise {
  let da = double_asterisk && pathname
  let re = glob_to_re(
    pathname~,
    match_backslashes~,
    period~,
    glob_of_string(s, da),
  )
  if anchored {
    Ast::whole_string(re)
  } else {
    re
  }
}

///|
pub fn Glob::compile(
  s : Bytes,
  anchored? : Bool = false,
  pathname? : Bool = true,
  match_backslashes? : Bool = false,
  period? : Bool = true,
  double_asterisk? : Bool = true,
) -> Re raise {
  compile(
    Glob::glob(
      s,
      anchored~,
      pathname~,
      match_backslashes~,
      period~,
      double_asterisk~,
    ),
  )
}
