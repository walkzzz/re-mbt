// Pcre — PCRE-compatible API (port of lib/pcre.ml)

///|
#warnings("-struct_never_constructed")
pub struct Pcre {}

///|
pub enum PcreFlag {
  Caseless
  MultilineP
  AnchoredP
  DotallP
}

///|
pub fn PcreFlag::caseless() -> PcreFlag {
  Caseless
}

///|
pub fn PcreFlag::multiline_p() -> PcreFlag {
  MultilineP
}

///|
pub fn PcreFlag::anchored_p() -> PcreFlag {
  AnchoredP
}

///|
pub fn PcreFlag::dotall_p() -> PcreFlag {
  DotallP
}

///|
pub enum PcreSplitResult {
  PcreText(Bytes)
  PcreDelim(Bytes)
  PcreGroup(Int, Bytes)
  PcreNoGroup
}

///|
fn pcre_flags_to_opts(flags : Array[PcreFlag]) -> Array[PerlOpt] {
  let opts : Array[PerlOpt] = []
  for f in flags {
    match f {
      Caseless => opts.push(Caseless)
      MultilineP => opts.push(Multiline)
      AnchoredP => opts.push(Anchored)
      DotallP => opts.push(Dotall)
    }
  }
  opts
}

///|
pub fn Pcre::re(pat : Bytes, flags? : Array[PcreFlag] = []) -> Ast raise {
  Perl::re(pat, opts=pcre_flags_to_opts(flags))
}

///|
pub fn Pcre::regexp(pat : Bytes, flags? : Array[PcreFlag] = []) -> Re raise {
  compile(Pcre::re(pat, flags~))
}

///|
pub fn Pcre::extract(rex : Re, s : Bytes) -> Array[Bytes] raise {
  let g = exec(rex, s)
  GroupT::all(g)
}

///|
pub fn Pcre::exec(rex : Re, s : Bytes, pos? : Int = 0) -> GroupT raise {
  exec(rex, s, pos~)
}

///|
pub fn Pcre::names(rex : Re) -> Array[String] {
  let result : Array[String] = []
  for p in rex.group_names {
    result.push(p.0)
  }
  result
}

///|
pub fn Pcre::get_named_substring_opt(
  rex : Re,
  name : String,
  s : GroupT,
) -> Bytes? {
  let mut result : Bytes? = None
  for p in rex.group_names {
    if result is None {
      if p.0 == name {
        match GroupT::get_opt(s, p.1) {
          Some(_) as r => result = r
          None => ()
        }
      }
    }
  }
  result
}

///|
pub fn Pcre::get_substring_ofs(s : GroupT, i : Int) -> (Int, Int) raise {
  GroupT::offset(s, i)
}

///|
pub fn Pcre::pmatch(rex : Re, s : Bytes) -> Bool raise {
  execp(rex, s)
}

///|
pub fn Pcre::quote(s : Bytes) -> Bytes {
  let buf : Array[Byte] = []
  for i in 0..<s.length() {
    let c = s[i].to_int()
    if c == 92 ||
      c == 94 ||
      c == 36 ||
      c == 46 ||
      c == 91 ||
      c == 124 ||
      c == 40 ||
      c == 41 ||
      c == 63 ||
      c == 42 ||
      c == 43 ||
      c == 123 {
      buf.push((92).to_byte())
    }
    buf.push(s[i])
  }
  Bytes::from_array(buf)
}

///|
pub fn Pcre::split(rex : Re, s : Bytes) -> Array[Bytes] raise {
  let result : Array[Bytes] = []
  let parts = Search::split(rex, s)
  for p in parts {
    if p.length() > 0 {
      result.push(p)
    }
  }
  result
}

///|
pub fn Pcre::full_split(
  rex : Re,
  s : Bytes,
  max? : Int = 0,
) -> Array[PcreSplitResult] raise {
  if s.length() == 0 {
    []
  } else if max == 1 {
    [PcreText(s)]
  } else {
    let results = Search::split_full(rex, s)
    let output : Array[PcreSplitResult] = []
    for token in results {
      match token {
        SplitText(text) => output.push(PcreText(text))
        SplitDelim(d) => {
          let matches = GroupT::all_offset(d)
          let delim = GroupT::get(d, 0).unwrap()
          output.push(PcreDelim(delim))
          for i in 1..<matches.length() {
            if matches[i] == (-1, -1) {
              output.push(PcreNoGroup)
            } else {
              output.push(PcreGroup(i, GroupT::get(d, i).unwrap()))
            }
          }
        }
      }
    }
    output
  }
}

///|
pub fn Pcre::get_substring(s : GroupT, i : Int) -> Bytes {
  GroupT::get(s, i).unwrap()
}

///|
pub fn Pcre::get_named_substring(
  rex : Re,
  name : String,
  s : GroupT,
) -> Bytes raise {
  match Pcre::get_named_substring_opt(rex, name, s) {
    Some(b) => b
    None => fail("Pcre: named group not found")
  }
}
