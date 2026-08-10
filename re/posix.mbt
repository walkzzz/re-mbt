// Posix — POSIX regex parser (port of lib/posix.ml)

///|
pub struct Posix {}

///|
pub enum PosixOpt {
  ICase
  NoSub
  Newline
}

///|
fn posix_regexp(buf : ParseBuffer, newline : Bool) -> Ast raise {
  posix_regexp_(buf, [posix_branch(buf, newline)], newline)
}

///|
fn posix_regexp_(
  buf : ParseBuffer,
  left : Array[Ast],
  newline : Bool,
) -> Ast raise {
  if ParseBuffer::accept(buf, '|') {
    left.push(posix_branch(buf, newline))
    posix_regexp_(buf, left, newline)
  } else {
    Ast::alt(left)
  }
}

///|
fn posix_branch(buf : ParseBuffer, newline : Bool) -> Ast raise {
  posix_branch_(buf, [], newline)
}

///|
fn posix_branch_(
  buf : ParseBuffer,
  left : Array[Ast],
  newline : Bool,
) -> Ast raise {
  if ParseBuffer::eos(buf) ||
    ParseBuffer::peek(buf, '|') ||
    ParseBuffer::peek(buf, ')') {
    Ast::seq(left)
  } else {
    left.push(posix_piece(buf, newline))
    posix_branch_(buf, left, newline)
  }
}

///|
fn posix_piece(buf : ParseBuffer, newline : Bool) -> Ast raise {
  let r = posix_atom(buf, newline)
  if ParseBuffer::accept(buf, '*') {
    Ast::rep(Ast::nest(r))
  } else if ParseBuffer::accept(buf, '+') {
    Ast::rep1(Ast::nest(r))
  } else if ParseBuffer::accept(buf, '?') {
    Ast::opt(r)
  } else if ParseBuffer::accept(buf, '{') {
    match ParseBuffer::integer(buf) {
      Some(i) => {
        let j = if ParseBuffer::accept(buf, ',') {
          ParseBuffer::integer(buf)
        } else {
          Some(i)
        }
        if !ParseBuffer::accept(buf, '}') {
          fail("Posix parse error")
        }
        match j {
          Some(jv) => if jv < i { fail("Posix parse error") }
          None => ()
        }
        Ast::repn(Ast::nest(r), i, j)
      }
      None => {
        ParseBuffer::unget(buf)
        r
      }
    }
  } else {
    r
  }
}

///|
fn posix_atom(buf : ParseBuffer, newline : Bool) -> Ast raise {
  if ParseBuffer::accept(buf, '.') {
    if newline {
      Re::notnl()
    } else {
      Ast::any()
    }
  } else if ParseBuffer::accept(buf, '(') {
    let r = posix_regexp(buf, newline)
    if !ParseBuffer::accept(buf, ')') {
      fail("Posix parse error")
    }
    Ast::group(r)
  } else if ParseBuffer::accept(buf, '^') {
    if newline {
      Ast::bol()
    } else {
      Ast::bos()
    }
  } else if ParseBuffer::accept(buf, '$') {
    if newline {
      Ast::eol()
    } else {
      Ast::eos()
    }
  } else if ParseBuffer::accept(buf, '[') {
    if ParseBuffer::accept(buf, '^') {
      Ast::diff(Ast::compl(posix_bracket(buf, [])), Ast::char('\n'))
    } else {
      Ast::alt(posix_bracket(buf, []))
    }
  } else if ParseBuffer::accept(buf, '\\') {
    if ParseBuffer::eos(buf) {
      fail("Posix parse error")
    }
    let c = ParseBuffer::get(buf)
    if c == '|' ||
      c == '(' ||
      c == ')' ||
      c == '*' ||
      c == '+' ||
      c == '?' ||
      c == '[' ||
      c == '.' ||
      c == '^' ||
      c == '$' ||
      c == '{' ||
      c == '\\' {
      Ast::char(c)
    } else {
      fail("Posix parse error")
    }
  } else {
    if ParseBuffer::eos(buf) {
      fail("Posix parse error")
    }
    let c = ParseBuffer::get(buf)
    if c == '*' || c == '+' || c == '?' || c == '{' || c == '\\' {
      fail("Posix parse error")
    } else {
      Ast::char(c)
    }
  }
}

///|
priv enum PosixElem {
  PosixCharElem(Char)
  PosixSetElem(Ast)
}

///|
fn posix_bracket(buf : ParseBuffer, s : Array[Ast]) -> Array[Ast] raise {
  if s.length() > 0 && ParseBuffer::accept(buf, ']') {
    s.rev_in_place()
    s
  } else {
    match posix_char_elem(buf) {
      PosixSetElem(st) => {
        s.push(st)
        posix_bracket(buf, s)
      }
      PosixCharElem(c) =>
        if ParseBuffer::accept(buf, '-') {
          if ParseBuffer::accept(buf, ']') {
            s.push(Ast::char(c))
            s.push(Ast::char('-'))
            s.rev_in_place()
            s
          } else {
            match posix_char_elem(buf) {
              PosixCharElem(c2) => {
                s.push(Re::rg(c, c2))
                posix_bracket(buf, s)
              }
              PosixSetElem(st2) => {
                s.push(Ast::char(c))
                s.push(Ast::char('-'))
                s.push(st2)
                posix_bracket(buf, s)
              }
            }
          }
        } else {
          s.push(Ast::char(c))
          posix_bracket(buf, s)
        }
    }
  }
}

///|
fn posix_char_elem(buf : ParseBuffer) -> PosixElem raise {
  if ParseBuffer::eos(buf) {
    fail("Posix parse error")
  }
  let c = ParseBuffer::get(buf)
  if c == '[' {
    match PosixClass::parse(buf) {
      Some(set) => PosixSetElem(set)
      None =>
        if ParseBuffer::accept(buf, '.') {
          if ParseBuffer::eos(buf) {
            fail("Posix parse error")
          }
          let c2 = ParseBuffer::get(buf)
          if !ParseBuffer::accept(buf, '.') {
            fail("Posix not supported")
          }
          if !ParseBuffer::accept(buf, ']') {
            fail("Posix parse error")
          }
          PosixCharElem(c2)
        } else {
          PosixCharElem(c)
        }
    }
  } else {
    PosixCharElem(c)
  }
}

///|
fn posix_has_opt(opts : Array[PosixOpt], target : PosixOpt) -> Bool {
  let mut found = false
  for opt in opts {
    if !found {
      match (opt, target) {
        (ICase, ICase) => found = true
        (NoSub, NoSub) => found = true
        (Newline, Newline) => found = true
        _ => ()
      }
    }
  }
  found
}

///|
pub fn Posix::re(s : Bytes, opts? : Array[PosixOpt] = []) -> Ast raise {
  let newline = posix_has_opt(opts, Newline)
  let buf = ParseBuffer::create(s)
  let r = posix_regexp(buf, newline)
  if !ParseBuffer::eos(buf) {
    fail("Posix parse error")
  }
  let r = if posix_has_opt(opts, ICase) { Ast::no_case(r) } else { r }
  if posix_has_opt(opts, NoSub) {
    Ast::no_group(r)
  } else {
    r
  }
}

///|
pub fn Posix::compile(s : Bytes, opts? : Array[PosixOpt] = []) -> Re raise {
  compile(Ast::longest(Posix::re(s, opts~)))
}

///|
pub fn Posix::compile_pat(s : Bytes, opts? : Array[PosixOpt] = []) -> Re raise {
  Posix::compile(s, opts~)
}
