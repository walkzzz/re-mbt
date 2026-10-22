// Posix — POSIX regex parser (port of lib/posix.ml)

///|
pub struct Posix {} derive(Default)

///|
pub enum PosixOpt {
  ICase
  NoSub
  Newline
}

///|
fn posix_regexp(buf : @base.ParseBuffer, newline : Bool) -> @ast.Ast raise {
  posix_regexp_(buf, [posix_branch(buf, newline)], newline)
}

///|
fn posix_regexp_(
  buf : @base.ParseBuffer,
  left : Array[@ast.Ast],
  newline : Bool,
) -> @ast.Ast raise {
  if @base.ParseBuffer::accept(buf, '|') {
    left.push(posix_branch(buf, newline))
    posix_regexp_(buf, left, newline)
  } else {
    @ast.Ast::alt(left)
  }
}

///|
fn posix_branch(buf : @base.ParseBuffer, newline : Bool) -> @ast.Ast raise {
  posix_branch_(buf, [], newline)
}

///|
fn posix_branch_(
  buf : @base.ParseBuffer,
  left : Array[@ast.Ast],
  newline : Bool,
) -> @ast.Ast raise {
  if @base.ParseBuffer::eos(buf) ||
    @base.ParseBuffer::peek(buf, '|') ||
    @base.ParseBuffer::peek(buf, ')') {
    @ast.Ast::seq(left)
  } else {
    left.push(posix_piece(buf, newline))
    posix_branch_(buf, left, newline)
  }
}

///|
fn posix_piece(buf : @base.ParseBuffer, newline : Bool) -> @ast.Ast raise {
  let r = posix_atom(buf, newline)
  if @base.ParseBuffer::accept(buf, '*') {
    @ast.Ast::rep(@ast.Ast::nest(r))
  } else if @base.ParseBuffer::accept(buf, '+') {
    @ast.Ast::rep1(@ast.Ast::nest(r))
  } else if @base.ParseBuffer::accept(buf, '?') {
    @ast.Ast::opt(r)
  } else if @base.ParseBuffer::accept(buf, '{') {
    match @base.ParseBuffer::integer(buf) {
      Some(i) => {
        let j = if @base.ParseBuffer::accept(buf, ',') {
          @base.ParseBuffer::integer(buf)
        } else {
          Some(i)
        }
        if !@base.ParseBuffer::accept(buf, '}') {
          fail("Posix parse error")
        }
        match j {
          Some(jv) => if jv < i { fail("Posix parse error") }
          None => ()
        }
        @ast.Ast::repn(@ast.Ast::nest(r), i, j)
      }
      None => {
        @base.ParseBuffer::unget(buf)
        r
      }
    }
  } else {
    r
  }
}

///|
fn posix_atom(buf : @base.ParseBuffer, newline : Bool) -> @ast.Ast raise {
  if @base.ParseBuffer::accept(buf, '.') {
    if newline {
      @compile.Re::notnl()
    } else {
      @ast.Ast::any()
    }
  } else if @base.ParseBuffer::accept(buf, '(') {
    let r = posix_regexp(buf, newline)
    if !@base.ParseBuffer::accept(buf, ')') {
      fail("Posix parse error")
    }
    @ast.Ast::group(r)
  } else if @base.ParseBuffer::accept(buf, '^') {
    if newline {
      @ast.Ast::bol()
    } else {
      @ast.Ast::bos()
    }
  } else if @base.ParseBuffer::accept(buf, '$') {
    if newline {
      @ast.Ast::eol()
    } else {
      @ast.Ast::eos()
    }
  } else if @base.ParseBuffer::accept(buf, '[') {
    if @base.ParseBuffer::accept(buf, '^') {
      @ast.Ast::diff(
        @ast.Ast::compl(posix_bracket(buf, [])),
        @ast.Ast::char('\n'),
      )
    } else {
      @ast.Ast::alt(posix_bracket(buf, []))
    }
  } else if @base.ParseBuffer::accept(buf, '\\') {
    if @base.ParseBuffer::eos(buf) {
      fail("Posix parse error")
    }
    let c = @base.ParseBuffer::get(buf)
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
      @ast.Ast::char(c)
    } else {
      fail("Posix parse error")
    }
  } else {
    if @base.ParseBuffer::eos(buf) {
      fail("Posix parse error")
    }
    let c = @base.ParseBuffer::get(buf)
    if c == '*' || c == '+' || c == '?' || c == '{' || c == '\\' {
      fail("Posix parse error")
    } else {
      @ast.Ast::char(c)
    }
  }
}

///|
priv enum PosixElem {
  PosixCharElem(Char)
  PosixSetElem(@ast.Ast)
}

///|
fn posix_bracket(
  buf : @base.ParseBuffer,
  s : Array[@ast.Ast],
) -> Array[@ast.Ast] raise {
  if s.length() > 0 && @base.ParseBuffer::accept(buf, ']') {
    s.rev_in_place()
    s
  } else {
    match posix_char_elem(buf) {
      PosixSetElem(st) => {
        s.push(st)
        posix_bracket(buf, s)
      }
      PosixCharElem(c) =>
        if @base.ParseBuffer::accept(buf, '-') {
          if @base.ParseBuffer::accept(buf, ']') {
            s.push(@ast.Ast::char(c))
            s.push(@ast.Ast::char('-'))
            s.rev_in_place()
            s
          } else {
            match posix_char_elem(buf) {
              PosixCharElem(c2) => {
                s.push(@compile.Re::rg(c, c2))
                posix_bracket(buf, s)
              }
              PosixSetElem(st2) => {
                s.push(@ast.Ast::char(c))
                s.push(@ast.Ast::char('-'))
                s.push(st2)
                posix_bracket(buf, s)
              }
            }
          }
        } else {
          s.push(@ast.Ast::char(c))
          posix_bracket(buf, s)
        }
    }
  }
}

///|
fn posix_char_elem(buf : @base.ParseBuffer) -> PosixElem raise {
  if @base.ParseBuffer::eos(buf) {
    fail("Posix parse error")
  }
  let c = @base.ParseBuffer::get(buf)
  if c == '[' {
    match PosixClass::parse(buf) {
      Some(set) => PosixSetElem(set)
      None =>
        if @base.ParseBuffer::accept(buf, '.') {
          if @base.ParseBuffer::eos(buf) {
            fail("Posix parse error")
          }
          let c2 = @base.ParseBuffer::get(buf)
          if !@base.ParseBuffer::accept(buf, '.') {
            fail("Posix not supported")
          }
          if !@base.ParseBuffer::accept(buf, ']') {
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
pub fn Posix::re(s : Bytes, opts~ : Array[PosixOpt] = []) -> @ast.Ast raise {
  let newline = posix_has_opt(opts, Newline)
  let buf = @base.ParseBuffer::create(s)
  let r = posix_regexp(buf, newline)
  if !@base.ParseBuffer::eos(buf) {
    fail("Posix parse error")
  }
  let r = if posix_has_opt(opts, ICase) { @ast.Ast::no_case(r) } else { r }
  if posix_has_opt(opts, NoSub) {
    @ast.Ast::no_group(r)
  } else {
    r
  }
}

///|
pub fn Posix::compile(
  s : Bytes,
  opts~ : Array[PosixOpt] = [],
) -> @compile.Re raise {
  @compile.compile(@ast.Ast::longest(Posix::re(s, opts~)))
}

///|
pub fn Posix::compile_pat(
  s : Bytes,
  opts~ : Array[PosixOpt] = [],
) -> @compile.Re raise {
  Posix::compile(s, opts~)
}
