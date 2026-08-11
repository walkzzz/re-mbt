// Emacs — Emacs-style regex parser (port of lib/emacs.ml)

///|
let emacs_pipe : Bytes = sb("|")

///|
let emacs_close_group : Bytes = sb("\\)")

///|
#warnings("-struct_never_constructed")
pub struct Emacs {}

///|
fn emacs_by_code(f : (Int, Int) -> Int, c : Char, c2 : Char) -> Char {
  let ci = c.to_int()
  let c2i = c2.to_int()
  f(ci, c2i).unsafe_to_char()
}

///|
fn emacs_regexp(buf : ParseBuffer, emacs_only : Bool) -> Ast raise {
  emacs_regexp_(buf, [emacs_branch(buf, emacs_only)], emacs_only)
}

///|
fn emacs_regexp_(
  buf : ParseBuffer,
  left : Array[Ast],
  emacs_only : Bool,
) -> Ast raise {
  if ParseBuffer::accept_s(buf, emacs_pipe) {
    left.push(emacs_branch(buf, emacs_only))
    emacs_regexp_(buf, left, emacs_only)
  } else {
    Ast::alt(left)
  }
}

///|
fn emacs_branch(buf : ParseBuffer, emacs_only : Bool) -> Ast raise {
  emacs_branch_(buf, [], emacs_only)
}

///|
fn emacs_branch_(
  buf : ParseBuffer,
  left : Array[Ast],
  emacs_only : Bool,
) -> Ast raise {
  if ParseBuffer::eos(buf) ||
    ParseBuffer::peek2(buf, '\\', '|') ||
    ParseBuffer::peek2(buf, '\\', ')') {
    Ast::seq(left)
  } else {
    left.push(emacs_piece(buf, emacs_only))
    emacs_branch_(buf, left, emacs_only)
  }
}

///|
fn emacs_piece(buf : ParseBuffer, emacs_only : Bool) -> Ast raise {
  let r = emacs_atom(buf, emacs_only)
  if ParseBuffer::accept(buf, '*') {
    Ast::rep(r)
  } else if ParseBuffer::accept(buf, '+') {
    Ast::rep1(r)
  } else if ParseBuffer::accept(buf, '?') {
    Ast::opt(r)
  } else {
    r
  }
}

///|
fn emacs_atom(buf : ParseBuffer, emacs_only : Bool) -> Ast raise {
  if ParseBuffer::accept(buf, '.') {
    Re::notnl()
  } else if ParseBuffer::accept(buf, '^') {
    Ast::bol()
  } else if ParseBuffer::accept(buf, '$') {
    Ast::eol()
  } else if ParseBuffer::accept(buf, '[') {
    if ParseBuffer::accept(buf, '^') {
      Ast::compl(emacs_bracket(buf, []))
    } else {
      Ast::alt(emacs_bracket(buf, []))
    }
  } else if ParseBuffer::accept(buf, '\\') {
    if ParseBuffer::accept(buf, '(') {
      let r = emacs_regexp(buf, emacs_only)
      if !ParseBuffer::accept_s(buf, emacs_close_group) {
        fail("Emacs parse error")
      }
      Ast::group(r)
    } else if emacs_only && ParseBuffer::accept(buf, '`') {
      Ast::bos()
    } else if emacs_only && ParseBuffer::accept(buf, '\'') {
      Ast::eos()
    } else if ParseBuffer::accept(buf, '=') {
      Ast::start()
    } else if ParseBuffer::accept(buf, 'b') {
      Ast::alt([Ast::bow(), Ast::eow()])
    } else if emacs_only && ParseBuffer::accept(buf, 'B') {
      Ast::not_boundary()
    } else if emacs_only && ParseBuffer::accept(buf, '<') {
      Ast::bow()
    } else if emacs_only && ParseBuffer::accept(buf, '>') {
      Ast::eow()
    } else if ParseBuffer::accept(buf, 'w') {
      Ast::alt([Re::alnum(), Ast::char('_')])
    } else if ParseBuffer::accept(buf, 'W') {
      Ast::compl([Re::alnum(), Ast::char('_')])
    } else {
      if ParseBuffer::eos(buf) {
        fail("Emacs parse error")
      }
      let c = ParseBuffer::get(buf)
      if c == '*' ||
        c == '+' ||
        c == '?' ||
        c == '[' ||
        c == ']' ||
        c == '.' ||
        c == '^' ||
        c == '$' ||
        c == '\\' {
        Ast::char(c)
      } else if c >= '0' && c <= '9' {
        fail("Emacs not supported: backreference")
      } else if emacs_only {
        fail("Emacs parse error")
      } else {
        Ast::char(c)
      }
    }
  } else {
    if ParseBuffer::eos(buf) {
      fail("Emacs parse error")
    }
    let c = ParseBuffer::get(buf)
    if c == '*' || c == '+' || c == '?' {
      fail("Emacs parse error")
    } else {
      Ast::char(c)
    }
  }
}

///|
fn emacs_bracket(buf : ParseBuffer, s : Array[Ast]) -> Array[Ast] raise {
  if s.length() > 0 && ParseBuffer::accept(buf, ']') {
    s.rev_in_place()
    s
  } else {
    let c = emacs_char(buf)
    if ParseBuffer::accept(buf, '-') {
      if ParseBuffer::accept(buf, ']') {
        s.push(Ast::char(c))
        s.push(Ast::char('-'))
        s.rev_in_place()
        s
      } else {
        let c2 = emacs_char(buf)
        let c2_max = emacs_by_code(Int::max, c, c2)
        s.push(Re::rg(c, c2_max))
        emacs_bracket(buf, s)
      }
    } else {
      s.push(Ast::char(c))
      emacs_bracket(buf, s)
    }
  }
}

///|
fn emacs_char(buf : ParseBuffer) -> Char raise {
  if ParseBuffer::eos(buf) {
    fail("Emacs parse error")
  }
  ParseBuffer::get(buf)
}

///|
pub fn Emacs::re(s : Bytes, case? : Bool = true) -> Ast raise {
  let buf = ParseBuffer::create(s)
  let r = emacs_regexp(buf, true)
  if !ParseBuffer::eos(buf) {
    fail("Emacs parse error")
  }
  if case {
    r
  } else {
    Ast::no_case(r)
  }
}

///|
pub fn Emacs::re_no_emacs(s : Bytes, case~ : Bool) -> Ast raise {
  let buf = ParseBuffer::create(s)
  let r = emacs_regexp(buf, false)
  if !ParseBuffer::eos(buf) {
    fail("Emacs parse error")
  }
  if case {
    r
  } else {
    Ast::no_case(r)
  }
}

///|
pub fn Emacs::compile_pat(s : Bytes, case? : Bool = true) -> Re raise {
  compile(Emacs::re(s, case~))
}
