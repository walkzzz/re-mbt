// Posix_class — POSIX character classes (port of lib/posix_class.ml)

///|
#warnings("-struct_never_constructed")
pub struct PosixClass {}

///|
pub fn PosixClass::of_name(name : String) -> Ast raise {
  match name {
    "alpha" => Re::alpha()
    "alnum" => Re::alnum()
    "ascii" => Re::ascii()
    "blank" => Re::blank()
    "cntrl" => Re::cntrl()
    "digit" => Re::digit()
    "lower" => Re::lower()
    "print" => Re::print()
    "space" => Re::space()
    "upper" => Re::upper()
    "word" => Re::wordc()
    "punct" => Re::punct()
    "graph" => Re::graph()
    "xdigit" => Re::xdigit()
    _ => fail("Invalid posix class: " + name)
  }
}

///|
pub fn PosixClass::names() -> Array[String] {
  [
    "alpha", "alnum", "ascii", "blank", "cntrl", "digit", "lower", "print", "space",
    "upper", "word", "punct", "graph", "xdigit",
  ]
}

// Precomputed Bytes versions of names and closing bracket

///|
let posix_class_names_bytes : Array[(String, Bytes)] = [
  ("alpha", sb("alpha")),
  ("alnum", sb("alnum")),
  ("ascii", sb("ascii")),
  ("blank", sb("blank")),
  ("cntrl", sb("cntrl")),
  ("digit", sb("digit")),
  ("lower", sb("lower")),
  ("print", sb("print")),
  ("space", sb("space")),
  ("upper", sb("upper")),
  ("word", sb("word")),
  ("punct", sb("punct")),
  ("graph", sb("graph")),
  ("xdigit", sb("xdigit")),
]

///|
let posix_class_close : Bytes = sb(":]")

///|
pub fn PosixClass::parse(buf : ParseBuffer) -> Ast? raise {
  if !ParseBuffer::accept(buf, ':') {
    None
  } else {
    let compl = ParseBuffer::accept(buf, '^')
    let mut cls : String? = None
    for entry in posix_class_names_bytes {
      if cls is None {
        let (name, name_bytes) = entry
        if ParseBuffer::accept_s(buf, name_bytes) {
          cls = Some(name)
        }
      }
    }
    match cls {
      None => fail("Parse error in posix class")
      Some(name) => {
        if !ParseBuffer::accept_s(buf, posix_class_close) {
          fail("Parse error in posix class")
        }
        let posix_class = PosixClass::of_name(name)
        if compl {
          Some(Ast::compl([posix_class]))
        } else {
          Some(posix_class)
        }
      }
    }
  }
}
