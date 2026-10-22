// Perl — Perl-style regex parser (port of lib/perl.ml)

///|
#warnings("-struct_never_constructed")
pub struct Perl {}

///|
pub enum PerlOpt {
  Ungreedy
  Dotall
  DollarEndonly
  Multiline
  Anchored
  Caseless
}

///|
pub fn PerlOpt::caseless() -> PerlOpt {
  Caseless
}

///|
pub fn PerlOpt::ungreedy() -> PerlOpt {
  Ungreedy
}

///|
pub fn PerlOpt::dotall() -> PerlOpt {
  Dotall
}

///|
pub fn PerlOpt::dollar_endonly() -> PerlOpt {
  DollarEndonly
}

///|
pub fn PerlOpt::multiline() -> PerlOpt {
  Multiline
}

///|
pub fn PerlOpt::anchored() -> PerlOpt {
  Anchored
}

///|
priv enum PerlElem {
  PerlChar(Char)
  PerlSet(@ast.Ast)
}

///|
fn perl_char_of_int(x : Int32) -> Char raise {
  if x >= 0 && x <= 255 {
    x.unsafe_to_char()
  } else {
    fail("Perl parse error: invalid char code")
  }
}

///|
fn perl_acc_digits(base : Int32, digits : Array[Int32]) -> Int32 {
  let mut acc = 0
  let mut i = 1
  for d in @base.array_reverse(digits) {
    acc = acc + d * i
    i = i * base
  }
  acc
}

///|
fn perl_greedy_mod(
  buf : @base.ParseBuffer,
  ungreedy : Bool,
  r : @ast.Ast,
) -> @ast.Ast {
  let gr = @base.ParseBuffer::accept(buf, '?')
  let gr2 = if ungreedy { !gr } else { gr }
  if gr2 {
    @ast.Ast::non_greedy(r)
  } else {
    @ast.Ast::greedy(r)
  }
}

///|
fn perl_regexp(buf : @base.ParseBuffer, opts : PerlOpts) -> @ast.Ast raise {
  perl_regexp_(buf, [perl_branch(buf, opts)], opts)
}

///|
fn perl_regexp_(
  buf : @base.ParseBuffer,
  left : Array[@ast.Ast],
  opts : PerlOpts,
) -> @ast.Ast raise {
  if @base.ParseBuffer::accept(buf, '|') {
    left.push(perl_branch(buf, opts))
    perl_regexp_(buf, left, opts)
  } else {
    @ast.Ast::alt(left)
  }
}

///|
priv struct PerlOpts {
  multiline : Bool
  dollar_endonly : Bool
  dotall : Bool
  ungreedy : Bool
}

///|
fn perl_branch(buf : @base.ParseBuffer, opts : PerlOpts) -> @ast.Ast raise {
  perl_branch_(buf, [], opts)
}

///|
fn perl_branch_(
  buf : @base.ParseBuffer,
  left : Array[@ast.Ast],
  opts : PerlOpts,
) -> @ast.Ast raise {
  if @base.ParseBuffer::eos(buf) ||
    @base.ParseBuffer::peek(buf, '|') ||
    @base.ParseBuffer::peek(buf, ')') {
    @ast.Ast::seq(left)
  } else {
    left.push(perl_piece(buf, opts))
    perl_branch_(buf, left, opts)
  }
}

///|
fn perl_piece(buf : @base.ParseBuffer, opts : PerlOpts) -> @ast.Ast raise {
  let r = perl_atom(buf, opts)
  if @base.ParseBuffer::accept(buf, '*') {
    perl_greedy_mod(buf, opts.ungreedy, @ast.Ast::rep(r))
  } else if @base.ParseBuffer::accept(buf, '+') {
    perl_greedy_mod(buf, opts.ungreedy, @ast.Ast::rep1(r))
  } else if @base.ParseBuffer::accept(buf, '?') {
    perl_greedy_mod(buf, opts.ungreedy, @ast.Ast::opt(r))
  } else if @base.ParseBuffer::accept(buf, '{') {
    match @base.ParseBuffer::integer(buf) {
      Some(i) => {
        let j = if @base.ParseBuffer::accept(buf, ',') {
          @base.ParseBuffer::integer(buf)
        } else {
          Some(i)
        }
        if !@base.ParseBuffer::accept(buf, '}') {
          fail("Perl parse error")
        }
        match j {
          Some(jv) => if jv < i { fail("Perl parse error") }
          None => ()
        }
        perl_greedy_mod(buf, opts.ungreedy, @ast.Ast::repn(r, i, j))
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
fn perl_atom(buf : @base.ParseBuffer, opts : PerlOpts) -> @ast.Ast raise {
  if @base.ParseBuffer::accept(buf, '.') {
    if opts.dotall {
      @ast.Ast::any()
    } else {
      @compile.Re::notnl()
    }
  } else if @base.ParseBuffer::accept(buf, '(') {
    if @base.ParseBuffer::accept(buf, '?') {
      if @base.ParseBuffer::accept(buf, ':') {
        let r = perl_regexp(buf, opts)
        if !@base.ParseBuffer::accept(buf, ')') {
          fail("Perl parse error")
        }
        r
      } else if @base.ParseBuffer::accept(buf, '#') {
        perl_comment(buf)
      } else if @base.ParseBuffer::accept(buf, '<') {
        let name = perl_name(buf)
        let r = perl_regexp(buf, opts)
        if !@base.ParseBuffer::accept(buf, ')') {
          fail("Perl parse error")
        }
        @ast.Ast::group(name=Some(name), r)
      } else {
        fail("Perl parse error")
      }
    } else {
      let r = perl_regexp(buf, opts)
      if !@base.ParseBuffer::accept(buf, ')') {
        fail("Perl parse error")
      }
      @ast.Ast::group(r)
    }
  } else if @base.ParseBuffer::accept(buf, '^') {
    if opts.multiline {
      @ast.Ast::bol()
    } else {
      @ast.Ast::bos()
    }
  } else if @base.ParseBuffer::accept(buf, '$') {
    if opts.multiline {
      @ast.Ast::eol()
    } else if opts.dollar_endonly {
      @ast.Ast::leol()
    } else {
      @ast.Ast::eos()
    }
  } else if @base.ParseBuffer::accept(buf, '[') {
    if @base.ParseBuffer::accept(buf, '^') {
      @ast.Ast::compl(perl_bracket(buf, []))
    } else {
      @ast.Ast::alt(perl_bracket(buf, []))
    }
  } else if @base.ParseBuffer::accept(buf, '\\') {
    if @base.ParseBuffer::eos(buf) {
      fail("Perl parse error")
    }
    let c = @base.ParseBuffer::get(buf)
    if c == 'w' {
      @ast.Ast::alt([@compile.Re::alnum(), @ast.Ast::char('_')])
    } else if c == 'W' {
      @ast.Ast::compl([@compile.Re::alnum(), @ast.Ast::char('_')])
    } else if c == 's' {
      @compile.Re::space()
    } else if c == 'S' {
      @ast.Ast::compl([@compile.Re::space()])
    } else if c == 'd' {
      @compile.Re::digit()
    } else if c == 'D' {
      @ast.Ast::compl([@compile.Re::digit()])
    } else if c == 'b' {
      @ast.Ast::alt([@ast.Ast::bow(), @ast.Ast::eow()])
    } else if c == 'B' {
      @ast.Ast::not_boundary()
    } else if c == 'A' {
      @ast.Ast::bos()
    } else if c == 'Z' {
      @ast.Ast::leol()
    } else if c == 'z' {
      @ast.Ast::eos()
    } else if c == 'G' {
      @ast.Ast::start()
    } else if c == 'e' {
      @ast.Ast::char((27).unsafe_to_char())
    } else if c == 'f' {
      @ast.Ast::char((12).unsafe_to_char())
    } else if c == 'n' {
      @ast.Ast::char('\n')
    } else if c == 'r' {
      @ast.Ast::char('\r')
    } else if c == 't' {
      @ast.Ast::char('\t')
    } else if c == 'Q' {
      perl_quote(buf, [])
    } else if c == 'E' {
      fail("Perl parse error")
    } else if c == 'x' {
      perl_parse_hex(buf)
    } else if c == 'o' {
      perl_parse_oct(buf)
    } else if (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') {
      fail("Perl parse error")
    } else if c >= '0' && c <= '7' {
      perl_parse_octal_escape(buf, c)
    } else if c == '8' || c == '9' {
      fail("Perl not supported: \\8 or \\9")
    } else {
      @ast.Ast::char(c)
    }
  } else {
    if @base.ParseBuffer::eos(buf) {
      fail("Perl parse error")
    }
    let c = @base.ParseBuffer::get(buf)
    if c == '*' || c == '+' || c == '?' || c == '{' || c == '\\' {
      fail("Perl parse error")
    } else {
      @ast.Ast::char(c)
    }
  }
}

///|
fn perl_parse_hex(buf : @base.ParseBuffer) -> @ast.Ast raise {
  let digits : Array[Int32] = []
  if @base.ParseBuffer::accept(buf, '{') {
    while !@base.ParseBuffer::accept(buf, '}') {
      digits.push(perl_hexdigit(buf))
    }
    let rev = @base.array_reverse(digits)
    let code = if rev.length() == 2 {
      rev[0] * 16 + rev[1]
    } else if rev.length() == 1 {
      rev[0]
    } else {
      fail("Perl parse error")
    }
    @ast.Ast::char(perl_char_of_int(code))
  } else {
    let c1 = perl_hexdigit(buf)
    let c2 = perl_hexdigit(buf)
    let code = c1 * 16 + c2
    @ast.Ast::char(perl_char_of_int(code))
  }
}

///|
fn perl_parse_oct(buf : @base.ParseBuffer) -> @ast.Ast raise {
  if !@base.ParseBuffer::accept(buf, '{') {
    fail("Perl parse error")
  }
  let digits : Array[Int32] = []
  while !@base.ParseBuffer::accept(buf, '}') {
    match perl_maybe_octaldigit(buf) {
      Some(d) => digits.push(d)
      None => fail("Perl parse error")
    }
  }
  @ast.Ast::char(perl_char_of_int(perl_acc_digits(8, digits)))
}

///|
fn perl_parse_octal_escape(
  buf : @base.ParseBuffer,
  n1_char : Char,
) -> @ast.Ast raise {
  let n1 = n1_char.to_int() - '0'.to_int()
  match perl_maybe_octaldigit(buf) {
    Some(n2) =>
      match perl_maybe_octaldigit(buf) {
        Some(n3) => {
          let code = n1 * 64 + n2 * 8 + n3
          @ast.Ast::char(perl_char_of_int(code))
        }
        None => fail("Perl not supported: octal escape")
      }
    None => fail("Perl not supported: octal escape")
  }
}

///|
fn perl_quote(buf : @base.ParseBuffer, acc : Array[Byte]) -> @ast.Ast raise {
  if @base.ParseBuffer::accept(buf, '\\') {
    if @base.ParseBuffer::eos(buf) {
      fail("Perl parse error")
    }
    let c = @base.ParseBuffer::get(buf)
    if c == 'E' {
      @ast.Ast::str(Bytes::from_array(acc))
    } else {
      acc.push('\\'.to_int().to_byte())
      acc.push(c.to_int().to_byte())
      perl_quote(buf, acc)
    }
  } else {
    if @base.ParseBuffer::eos(buf) {
      fail("Perl parse error")
    }
    let c = @base.ParseBuffer::get(buf)
    acc.push(c.to_int().to_byte())
    perl_quote(buf, acc)
  }
}

///|
fn perl_hexdigit(buf : @base.ParseBuffer) -> Int32 raise {
  if @base.ParseBuffer::eos(buf) {
    fail("Perl parse error")
  }
  let d = @base.ParseBuffer::get(buf)
  if d >= '0' && d <= '9' {
    d.to_int() - '0'.to_int()
  } else if d >= 'a' && d <= 'f' {
    d.to_int() - 'a'.to_int() + 10
  } else if d >= 'A' && d <= 'F' {
    d.to_int() - 'A'.to_int() + 10
  } else {
    fail("Perl parse error")
  }
}

///|
fn perl_maybe_octaldigit(buf : @base.ParseBuffer) -> Int32? {
  if @base.ParseBuffer::eos(buf) {
    None
  } else {
    let d = @base.ParseBuffer::get(buf)
    if d >= '0' && d <= '7' {
      Some(d.to_int() - '0'.to_int())
    } else {
      @base.ParseBuffer::unget(buf)
      None
    }
  }
}

///|
fn perl_name(buf : @base.ParseBuffer) -> String raise {
  if @base.ParseBuffer::eos(buf) {
    fail("Perl parse error")
  }
  let c = @base.ParseBuffer::get(buf)
  if c == '_' || (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') {
    perl_name_(buf, [c])
  } else {
    fail("Perl parse error")
  }
}

///|
fn perl_name_(buf : @base.ParseBuffer, acc : Array[Char]) -> String raise {
  if @base.ParseBuffer::eos(buf) {
    fail("Perl parse error")
  }
  let c = @base.ParseBuffer::get(buf)
  if c == '_' ||
    (c >= 'a' && c <= 'z') ||
    (c >= 'A' && c <= 'Z') ||
    (c >= '0' && c <= '9') {
    acc.push(c)
    perl_name_(buf, acc)
  } else if c == '>' {
    let mut s = ""
    for ch in acc {
      s = s + ch.to_string()
    }
    s
  } else {
    fail("Perl parse error")
  }
}

///|
fn perl_bracket(
  buf : @base.ParseBuffer,
  s : Array[@ast.Ast],
) -> Array[@ast.Ast] raise {
  if s.length() > 0 && @base.ParseBuffer::accept(buf, ']') {
    s.rev_in_place()
    s
  } else {
    match perl_char_elem(buf) {
      PerlSet(st) => {
        s.push(st)
        perl_bracket(buf, s)
      }
      PerlChar(c) =>
        if @base.ParseBuffer::accept(buf, '-') {
          if @base.ParseBuffer::accept(buf, ']') {
            s.push(@ast.Ast::char(c))
            s.push(@ast.Ast::char('-'))
            s.rev_in_place()
            s
          } else {
            match perl_char_elem(buf) {
              PerlChar(c2) => {
                s.push(@compile.Re::rg(c, c2))
                perl_bracket(buf, s)
              }
              PerlSet(st2) => {
                s.push(@ast.Ast::char(c))
                s.push(@ast.Ast::char('-'))
                s.push(st2)
                perl_bracket(buf, s)
              }
            }
          }
        } else {
          s.push(@ast.Ast::char(c))
          perl_bracket(buf, s)
        }
    }
  }
}

///|
fn perl_char_elem(buf : @base.ParseBuffer) -> PerlElem raise {
  if @base.ParseBuffer::eos(buf) {
    fail("Perl parse error")
  }
  let c = @base.ParseBuffer::get(buf)
  if c == '[' {
    if @base.ParseBuffer::accept(buf, '=') {
      fail("Perl not supported: [=...=]")
    }
    match PosixClass::parse(buf) {
      Some(set) => PerlSet(set)
      None =>
        if @base.ParseBuffer::accept(buf, '.') {
          if @base.ParseBuffer::eos(buf) {
            fail("Perl parse error")
          }
          let c2 = @base.ParseBuffer::get(buf)
          if !@base.ParseBuffer::accept(buf, '.') {
            fail("Perl not supported: collating element")
          }
          if !@base.ParseBuffer::accept(buf, ']') {
            fail("Perl parse error")
          }
          PerlChar(c2)
        } else {
          PerlChar(c)
        }
    }
  } else if c == '\\' {
    if @base.ParseBuffer::eos(buf) {
      fail("Perl parse error")
    }
    let c2 = @base.ParseBuffer::get(buf)
    if c2 == 'b' {
      PerlChar((8).unsafe_to_char())
    } else if c2 == 'n' {
      PerlChar('\n')
    } else if c2 == 'r' {
      PerlChar('\r')
    } else if c2 == 't' {
      PerlChar('\t')
    } else if c2 == 'w' {
      PerlSet(@ast.Ast::alt([@compile.Re::alnum(), @ast.Ast::char('_')]))
    } else if c2 == 'W' {
      PerlSet(@ast.Ast::alt([@compile.Re::alnum(), @ast.Ast::char('_')]))
    } else if c2 == 's' {
      PerlSet(@compile.Re::space())
    } else if c2 == 'S' {
      PerlSet(@ast.Ast::compl([@compile.Re::space()]))
    } else if c2 == 'd' {
      PerlSet(@compile.Re::digit())
    } else if c2 == 'D' {
      PerlSet(@ast.Ast::compl([@compile.Re::digit()]))
    } else if (c2 >= 'a' && c2 <= 'z') || (c2 >= 'A' && c2 <= 'Z') {
      fail("Perl parse error")
    } else if c2 >= '0' && c2 <= '9' {
      fail("Perl not supported: \\d in bracket")
    } else {
      PerlChar(c2)
    }
  } else {
    PerlChar(c)
  }
}

///|
fn perl_comment(buf : @base.ParseBuffer) -> @ast.Ast raise {
  if @base.ParseBuffer::eos(buf) {
    fail("Perl parse error")
  }
  if @base.ParseBuffer::accept(buf, ')') {
    @ast.Ast::epsilon()
  } else {
    @base.ParseBuffer::junk(buf)
    perl_comment(buf)
  }
}

///|
fn perl_has_opt(opts : Array[PerlOpt], target : PerlOpt) -> Bool {
  let mut found = false
  for opt in opts {
    if !found {
      match (opt, target) {
        (Ungreedy, Ungreedy) => found = true
        (Dotall, Dotall) => found = true
        (DollarEndonly, DollarEndonly) => found = true
        (Multiline, Multiline) => found = true
        (Anchored, Anchored) => found = true
        (Caseless, Caseless) => found = true
        _ => ()
      }
    }
  }
  found
}

///|
pub fn Perl::re(s : Bytes, opts~ : Array[PerlOpt] = []) -> @ast.Ast raise {
  let opts_rec : PerlOpts = {
    multiline: perl_has_opt(opts, Multiline),
    dollar_endonly: perl_has_opt(opts, DollarEndonly),
    dotall: perl_has_opt(opts, Dotall),
    ungreedy: perl_has_opt(opts, Ungreedy),
  }
  let buf = @base.ParseBuffer::create(s)
  let r = perl_regexp(buf, opts_rec)
  if !@base.ParseBuffer::eos(buf) {
    fail("Perl parse error")
  }
  let r = if perl_has_opt(opts, Anchored) {
    @ast.Ast::seq([@ast.Ast::start(), r])
  } else {
    r
  }
  if perl_has_opt(opts, Caseless) {
    @ast.Ast::no_case(r)
  } else {
    r
  }
}

///|
pub fn Perl::compile_pat(
  s : Bytes,
  opts~ : Array[PerlOpt] = [],
) -> @compile.Re raise {
  @compile.compile(Perl::re(s, opts~))
}
