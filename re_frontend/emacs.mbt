// Emacs — Emacs-style regex parser (port of lib/emacs.ml)

///|
let emacs_pipe : Bytes = @base.sb("\\|")

///|
let emacs_close_group : Bytes = @base.sb("\\)")

///|
#derive(Default)
pub struct Emacs {}

///|
fn emacs_by_code(f : (Int32, Int32) -> Int32, c : Char, c2 : Char) -> Char {
  let ci = c.to_int()
  let c2i = c2.to_int()
  f(ci, c2i).unsafe_to_char()
}

///|
fn emacs_regexp(buf : @base.ParseBuffer, emacs_only : Bool) -> @ast.Ast raise {
  emacs_regexp_(buf, [emacs_branch(buf, emacs_only)], emacs_only)
}

///|
fn emacs_regexp_(
  buf : @base.ParseBuffer,
  left : Array[@ast.Ast],
  emacs_only : Bool,
) -> @ast.Ast raise {
  if @base.ParseBuffer::accept_s(buf, emacs_pipe) {
    left.push(emacs_branch(buf, emacs_only))
    emacs_regexp_(buf, left, emacs_only)
  } else {
    @ast.Ast::alt(left)
  }
}

///|
fn emacs_branch(buf : @base.ParseBuffer, emacs_only : Bool) -> @ast.Ast raise {
  emacs_branch_(buf, [], emacs_only)
}

///|
fn emacs_branch_(
  buf : @base.ParseBuffer,
  left : Array[@ast.Ast],
  emacs_only : Bool,
) -> @ast.Ast raise {
  if @base.ParseBuffer::eos(buf) ||
    @base.ParseBuffer::peek2(buf, '\\', '|') ||
    @base.ParseBuffer::peek2(buf, '\\', ')') {
    @ast.Ast::seq(left)
  } else {
    left.push(emacs_piece(buf, emacs_only))
    emacs_branch_(buf, left, emacs_only)
  }
}

///|
fn emacs_piece(buf : @base.ParseBuffer, emacs_only : Bool) -> @ast.Ast raise {
  let r = emacs_atom(buf, emacs_only)
  if @base.ParseBuffer::accept(buf, '*') {
    @ast.Ast::rep(r)
  } else if @base.ParseBuffer::accept(buf, '+') {
    @ast.Ast::rep1(r)
  } else if @base.ParseBuffer::accept(buf, '?') {
    @ast.Ast::opt(r)
  } else {
    r
  }
}

///|
fn emacs_atom(buf : @base.ParseBuffer, emacs_only : Bool) -> @ast.Ast raise {
  if @base.ParseBuffer::accept(buf, '.') {
    @compile.Re::notnl()
  } else if @base.ParseBuffer::accept(buf, '^') {
    @ast.Ast::bol()
  } else if @base.ParseBuffer::accept(buf, '$') {
    @ast.Ast::eol()
  } else if @base.ParseBuffer::accept(buf, '[') {
    if @base.ParseBuffer::accept(buf, '^') {
      @ast.Ast::compl(emacs_bracket(buf, []))
    } else {
      @ast.Ast::alt(emacs_bracket(buf, []))
    }
  } else if @base.ParseBuffer::accept(buf, '\\') {
    if @base.ParseBuffer::accept(buf, '(') {
      let r = emacs_regexp(buf, emacs_only)
      if !@base.ParseBuffer::accept_s(buf, emacs_close_group) {
        fail("Emacs parse error")
      }
      @ast.Ast::group(r)
    } else if emacs_only && @base.ParseBuffer::accept(buf, '`') {
      @ast.Ast::bos()
    } else if emacs_only && @base.ParseBuffer::accept(buf, '\'') {
      @ast.Ast::eos()
    } else if @base.ParseBuffer::accept(buf, '=') {
      @ast.Ast::start()
    } else if @base.ParseBuffer::accept(buf, 'b') {
      @ast.Ast::alt([@ast.Ast::bow(), @ast.Ast::eow()])
    } else if emacs_only && @base.ParseBuffer::accept(buf, 'B') {
      @ast.Ast::not_boundary()
    } else if emacs_only && @base.ParseBuffer::accept(buf, '<') {
      @ast.Ast::bow()
    } else if emacs_only && @base.ParseBuffer::accept(buf, '>') {
      @ast.Ast::eow()
    } else if @base.ParseBuffer::accept(buf, 'w') {
      @ast.Ast::alt([@compile.Re::alnum(), @ast.Ast::char('_')])
    } else if @base.ParseBuffer::accept(buf, 'W') {
      @ast.Ast::compl([@compile.Re::alnum(), @ast.Ast::char('_')])
    } else {
      if @base.ParseBuffer::eos(buf) {
        fail("Emacs parse error")
      }
      let c = @base.ParseBuffer::get(buf)
      if c == '*' ||
        c == '+' ||
        c == '?' ||
        c == '[' ||
        c == ']' ||
        c == '.' ||
        c == '^' ||
        c == '$' ||
        c == '\\' {
        @ast.Ast::char(c)
      } else if c >= '0' && c <= '9' {
        fail("Emacs not supported: backreference")
      } else if emacs_only {
        fail("Emacs parse error")
      } else {
        @ast.Ast::char(c)
      }
    }
  } else {
    if @base.ParseBuffer::eos(buf) {
      fail("Emacs parse error")
    }
    let c = @base.ParseBuffer::get(buf)
    if c == '*' || c == '+' || c == '?' || c == ')' {
      fail("Emacs parse error")
    } else {
      @ast.Ast::char(c)
    }
  }
}

///|
fn emacs_bracket(
  buf : @base.ParseBuffer,
  s : Array[@ast.Ast],
) -> Array[@ast.Ast] raise {
  if s.length() > 0 && @base.ParseBuffer::accept(buf, ']') {
    s.rev_in_place()
    s
  } else {
    let c = emacs_char(buf)
    if @base.ParseBuffer::accept(buf, '-') {
      if @base.ParseBuffer::accept(buf, ']') {
        s.push(@ast.Ast::char(c))
        s.push(@ast.Ast::char('-'))
        s.rev_in_place()
        s
      } else {
        let c2 = emacs_char(buf)
        let c2_max = emacs_by_code(Int32::max, c, c2)
        s.push(@compile.Re::rg(c, c2_max))
        emacs_bracket(buf, s)
      }
    } else {
      s.push(@ast.Ast::char(c))
      emacs_bracket(buf, s)
    }
  }
}

///|
fn emacs_char(buf : @base.ParseBuffer) -> Char raise {
  if @base.ParseBuffer::eos(buf) {
    fail("Emacs parse error")
  }
  @base.ParseBuffer::get(buf)
}

///|
pub fn Emacs::re(s : Bytes, case~ : Bool = true) -> @ast.Ast raise {
  let buf = @base.ParseBuffer::create(s)
  if @base.ParseBuffer::eos(buf) {
    fail("Emacs parse error")
  }
  let r = emacs_regexp(buf, true)
  if !@base.ParseBuffer::eos(buf) {
    fail("Emacs parse error")
  }
  if case {
    r
  } else {
    @ast.Ast::no_case(r)
  }
}

///|
pub fn Emacs::re_no_emacs(s : Bytes, case~ : Bool) -> @ast.Ast raise {
  let buf = @base.ParseBuffer::create(s)
  if @base.ParseBuffer::eos(buf) {
    fail("Emacs parse error")
  }
  let r = emacs_regexp(buf, false)
  if !@base.ParseBuffer::eos(buf) {
    fail("Emacs parse error")
  }
  if case {
    r
  } else {
    @ast.Ast::no_case(r)
  }
}

///|
pub fn Emacs::compile_pat(s : Bytes, case~ : Bool = true) -> @compile.Re raise {
  @compile.compile(Emacs::re(s, case~))
}
