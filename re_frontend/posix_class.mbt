// Posix_class — POSIX character classes (port of lib/posix_class.ml)

///|
#warnings("-struct_never_constructed")
priv struct PosixClass {}

///|
fn PosixClass::of_name(name : String) -> @ast.Ast raise {
  match name {
    "alpha" => @compile.Re::alpha()
    "alnum" => @compile.Re::alnum()
    "ascii" => @compile.Re::ascii()
    "blank" => @compile.Re::blank()
    "cntrl" => @compile.Re::cntrl()
    "digit" => @compile.Re::digit()
    "lower" => @compile.Re::lower()
    "print" => @compile.Re::print()
    "space" => @compile.Re::space()
    "upper" => @compile.Re::upper()
    "word" => @compile.Re::wordc()
    "punct" => @compile.Re::punct()
    "graph" => @compile.Re::graph()
    "xdigit" => @compile.Re::xdigit()
    _ => fail("Invalid posix class: " + name)
  }
}

///|
#warnings("-unused_value")
fn PosixClass::names() -> Array[String] {
  [
    "alpha", "alnum", "ascii", "blank", "cntrl", "digit", "lower", "print", "space",
    "upper", "word", "punct", "graph", "xdigit",
  ]
}

// Precomputed Bytes versions of names and closing bracket

///|
let posix_class_names_bytes : Array[(String, Bytes)] = [
  ("alpha", @base.sb("alpha")),
  ("alnum", @base.sb("alnum")),
  ("ascii", @base.sb("ascii")),
  ("blank", @base.sb("blank")),
  ("cntrl", @base.sb("cntrl")),
  ("digit", @base.sb("digit")),
  ("lower", @base.sb("lower")),
  ("print", @base.sb("print")),
  ("space", @base.sb("space")),
  ("upper", @base.sb("upper")),
  ("word", @base.sb("word")),
  ("punct", @base.sb("punct")),
  ("graph", @base.sb("graph")),
  ("xdigit", @base.sb("xdigit")),
]

///|
let posix_class_close : Bytes = @base.sb(":]")

///|
fn PosixClass::parse(buf : @base.ParseBuffer) -> @ast.Ast? raise {
  if !@base.ParseBuffer::accept(buf, ':') {
    None
  } else {
    let compl = @base.ParseBuffer::accept(buf, '^')
    let mut cls : String? = None
    for entry in posix_class_names_bytes {
      if cls is None {
        let (name, name_bytes) = entry
        if @base.ParseBuffer::accept_s(buf, name_bytes) {
          cls = Some(name)
        }
      }
    }
    match cls {
      None => fail("Parse error in posix class")
      Some(name) => {
        if !@base.ParseBuffer::accept_s(buf, posix_class_close) {
          fail("Parse error in posix class")
        }
        let posix_class = PosixClass::of_name(name)
        if compl {
          Some(@ast.Ast::compl([posix_class]))
        } else {
          Some(posix_class)
        }
      }
    }
  }
}
