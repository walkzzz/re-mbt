// Str — OCaml Str compatibility (port of lib/str.ml)

///|
pub struct Str {}

///|
struct StrRegexp {
  mtch : Re
  srch : Re
}

///|
let str_state : Ref[GroupT?] = Ref::{ val: None }

///|
pub fn Str::compile_regexp(s : Bytes, case_fold : Bool) -> StrRegexp raise {
  let re = Emacs::re_no_emacs(s, case=!case_fold)
  { mtch: compile(Ast::seq([Ast::start(), re])), srch: compile(re) }
}

///|
pub fn Str::regexp(e : Bytes) -> StrRegexp raise {
  Str::compile_regexp(e, false)
}

///|
pub fn Str::regexp_case_fold(e : Bytes) -> StrRegexp raise {
  Str::compile_regexp(e, true)
}

///|
pub fn Str::quote(s : Bytes) -> Bytes {
  let buf : Array[Byte] = []
  for i in 0..<s.length() {
    let c = s[i].to_int()
    if c == 91 ||
      c == 93 ||
      c == 42 ||
      c == 46 ||
      c == 92 ||
      c == 63 ||
      c == 43 ||
      c == 94 ||
      c == 36 {
      buf.push((92).to_byte())
    }
    buf.push(s[i])
  }
  Bytes::from_array(buf)
}

///|
pub fn Str::regexp_string(s : Bytes) -> StrRegexp raise {
  Str::compile_regexp(Str::quote(s), false)
}

///|
pub fn Str::string_match(re : StrRegexp, s : Bytes, p : Int) -> Bool raise {
  match exec_opt(re.mtch, s, pos=p) {
    Some(res) => {
      str_state.val = Some(res)
      true
    }
    None => {
      str_state.val = None
      false
    }
  }
}

///|
pub fn Str::search_forward(re : StrRegexp, s : Bytes, p : Int) -> Int raise {
  match exec_opt(re.srch, s, pos=p) {
    Some(res) => {
      str_state.val = Some(res)
      GroupT::start(res, 0)
    }
    None => fail("Str.search_forward: not found")
  }
}

///|
pub fn Str::match_beginning() -> Int raise {
  match str_state.val {
    Some(m) => GroupT::start(m, 0)
    None => fail("Str: no match")
  }
}

///|
pub fn Str::match_end() -> Int raise {
  match str_state.val {
    Some(m) => GroupT::stop(m, 0)
    None => fail("Str: no match")
  }
}

///|
pub fn Str::matched_string(_txt : Bytes) -> Bytes raise {
  match str_state.val {
    Some(m) => GroupT::get(m, 0).unwrap()
    None => fail("Str: no match")
  }
}

///|
pub fn Str::group_beginning(n : Int) -> Int raise {
  match str_state.val {
    Some(m) => GroupT::start(m, n)
    None => fail("Str: no match")
  }
}

///|
pub fn Str::group_end(n : Int) -> Int raise {
  match str_state.val {
    Some(m) => GroupT::stop(m, n)
    None => fail("Str: no match")
  }
}

///|
pub fn Str::matched_group(n : Int, _txt : Bytes) -> Bytes raise {
  match str_state.val {
    Some(m) => GroupT::get(m, n).unwrap()
    None => fail("Str: no match")
  }
}

///|
pub fn Str::string_before(s : Bytes, n : Int) -> Bytes {
  let buf : Array[Byte] = []
  for i in 0..<n {
    buf.push(s[i])
  }
  Bytes::from_array(buf)
}

///|
pub fn Str::string_after(s : Bytes, n : Int) -> Bytes {
  let buf : Array[Byte] = []
  for i in n..<s.length() {
    buf.push(s[i])
  }
  Bytes::from_array(buf)
}

///|
pub fn Str::global_replace(
  re : StrRegexp,
  _repl : Bytes,
  text : Bytes,
) -> Bytes raise {
  let result : Array[Byte] = []
  let mut start = 0
  let mut last_was_empty = false
  while true {
    let startpos = if last_was_empty { start + 1 } else { start }
    if startpos > text.length() {
      for i in start..<text.length() {
        result.push(text[i])
      }
      break
    }
    match exec_opt(re.srch, text, pos=startpos) {
      Some(m) => {
        let pos = GroupT::start(m, 0)
        let end_pos = GroupT::stop(m, 0)
        str_state.val = Some(m)
        for i in start..<pos {
          result.push(text[i])
        }
        let matched = GroupT::get(m, 0).unwrap()
        for i in 0..<matched.length() {
          result.push(matched[i])
        }
        start = end_pos
        last_was_empty = end_pos == pos
      }
      None => {
        for i in start..<text.length() {
          result.push(text[i])
        }
        break
      }
    }
  }
  Bytes::from_array(result)
}

///|
pub fn Str::replace_first(
  re : StrRegexp,
  _repl : Bytes,
  text : Bytes,
) -> Bytes raise {
  match exec_opt(re.srch, text) {
    Some(m) => {
      let pos = GroupT::start(m, 0)
      let end_pos = GroupT::stop(m, 0)
      str_state.val = Some(m)
      let result : Array[Byte] = []
      for i in 0..<pos {
        result.push(text[i])
      }
      let matched = GroupT::get(m, 0).unwrap()
      for i in 0..<matched.length() {
        result.push(matched[i])
      }
      for i in end_pos..<text.length() {
        result.push(text[i])
      }
      Bytes::from_array(result)
    }
    None => text
  }
}

///|
pub fn Str::split(re : StrRegexp, text : Bytes) -> Array[Bytes] raise {
  Str::bounded_split(re, text, 0)
}

///|
pub fn Str::bounded_split(
  re : StrRegexp,
  text : Bytes,
  num : Int,
) -> Array[Bytes] raise {
  let result : Array[Bytes] = []
  let start = if Str::string_match(re, text, 0) { Str::match_end() } else { 0 }
  let mut cur = start
  let mut n = num
  while cur < text.length() && n != 1 {
    match exec_opt(re.srch, text, pos=cur) {
      Some(m) => {
        let pos = GroupT::start(m, 0)
        let end_pos = GroupT::stop(m, 0)
        str_state.val = Some(m)
        if end_pos > cur {
          let buf : Array[Byte] = []
          for i in cur..<pos {
            buf.push(text[i])
          }
          result.push(Bytes::from_array(buf))
          cur = end_pos
          n = n - 1
        } else {
          cur = cur + 1
        }
      }
      None => break
    }
  }
  let buf : Array[Byte] = []
  for i in cur..<text.length() {
    buf.push(text[i])
  }
  result.push(Bytes::from_array(buf))
  result
}

///|
pub enum StrSplitResult {
  StrText(Bytes)
  StrDelim(Bytes)
}

///|
pub fn Str::full_split(
  re : StrRegexp,
  text : Bytes,
) -> Array[StrSplitResult] raise {
  let result : Array[StrSplitResult] = []
  let mut cur = 0
  while cur < text.length() {
    match exec_opt(re.srch, text, pos=cur) {
      Some(m) => {
        let pos = GroupT::start(m, 0)
        let end_pos = GroupT::stop(m, 0)
        str_state.val = Some(m)
        let matched = GroupT::get(m, 0).unwrap()
        if pos > cur {
          let buf : Array[Byte] = []
          for i in cur..<pos {
            buf.push(text[i])
          }
          result.push(StrText(Bytes::from_array(buf)))
        }
        result.push(StrDelim(matched))
        cur = end_pos
        if end_pos == pos {
          cur = cur + 1
        }
      }
      None => {
        let buf : Array[Byte] = []
        for i in cur..<text.length() {
          buf.push(text[i])
        }
        result.push(StrText(Bytes::from_array(buf)))
        break
      }
    }
  }
  result
}
