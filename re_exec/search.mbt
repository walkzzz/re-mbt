// Search — find all matches, split (port of lib/search.ml)
// Eager evaluation: returns Array[T]

///|
#warnings("-struct_never_constructed")
pub struct Search {}

///|
pub enum SplitToken {
  SplitText(Bytes)
  SplitDelim(@compile.GroupT)
}

///|
fn bytes_sub(s : Bytes, start : Int32, len : Int32) -> Bytes {
  let buf : Array[Byte] = []
  for k in 0..<len {
    buf.push(s[start + k])
  }
  Bytes::from_array(buf)
}

// --- Search::all ---

///|
pub fn Search::all(
  re : @compile.Re,
  s : Bytes,
  pos~ : Int32 = 0,
  len~ : Int32 = -1,
) -> Array[@compile.GroupT] raise {
  if pos < 0 {
    fail("Re.all: invalid pos")
  }
  let limit = if len < 0 {
    s.length()
  } else {
    if pos + len > s.length() {
      fail("Re.all: invalid len")
    }
    pos + len
  }
  let result : Array[@compile.GroupT] = []
  let mut cur_pos = pos
  let mut on_match = false
  while cur_pos <= limit {
    match
      @compile.match_str(
        groups=true,
        partial=false,
        re,
        s,
        pos=cur_pos,
        len=limit - cur_pos,
      ) {
      @compile.MatchInfo(substr) => {
        let p1 = @compile.GroupT::start_offset(substr, 0)
        let p2 = @compile.GroupT::stop_offset(substr, 0)
        if on_match && p1 == cur_pos && p1 == p2 {
          cur_pos = cur_pos + 1
          on_match = false
        } else {
          result.push(substr)
          cur_pos = if p1 == p2 { p2 + 1 } else { p2 }
          on_match = p1 != p2
        }
      }
      _ => break
    }
  }
  result
}

// --- Search::matches ---

///|
pub fn Search::matches(
  re : @compile.Re,
  s : Bytes,
  pos~ : Int32 = 0,
  len~ : Int32 = -1,
) -> Array[Bytes] raise {
  let groups = Search::all(re, s, pos~, len~)
  let result : Array[Bytes] = []
  for g in groups {
    match @compile.GroupT::get(g, 0) {
      Some(b) => result.push(b)
      None => result.push(Bytes::from_array([]))
    }
  }
  result
}

// --- Search::split_full ---

///|
pub fn Search::split_full(
  re : @compile.Re,
  s : Bytes,
  pos~ : Int32 = 0,
  len~ : Int32 = -1,
) -> Array[SplitToken] raise {
  if pos < 0 {
    fail("Re.split: invalid pos")
  }
  let limit = if len < 0 {
    s.length()
  } else {
    if pos + len > s.length() {
      fail("Re.split: invalid len")
    }
    pos + len
  }
  let pos0 = pos
  let result : Array[SplitToken] = []
  let mut i = pos
  let mut cur_pos = pos
  let mut state : SplitToken? = None
  while true {
    match state {
      Some(token) => {
        result.push(token)
        state = None
      }
      None => {
        if cur_pos > limit {
          break
        }
        match
          @compile.match_str(
            groups=true,
            partial=false,
            re,
            s,
            pos=cur_pos,
            len=limit - cur_pos,
          ) {
          @compile.MatchInfo(substr) => {
            let p1 = @compile.GroupT::start_offset(substr, 0)
            let p2 = @compile.GroupT::stop_offset(substr, 0)
            let new_pos = if p1 == p2 { p2 + 1 } else { p2 }
            let old_i = i
            i = p2
            cur_pos = new_pos
            if old_i == p1 && p1 == p2 && p1 > pos0 {
              // Skip empty match right after a delimiter
            } else if p1 > pos0 {
              let text = bytes_sub(s, old_i, p1 - old_i)
              result.push(SplitText(text))
              state = Some(SplitDelim(substr))
            } else {
              result.push(SplitDelim(substr))
            }
          }
          FailedInfo =>
            if i < limit {
              let text = bytes_sub(s, i, limit - i)
              result.push(SplitText(text))
              break
            } else {
              break
            }
          RunningInfo(_) => break
        }
      }
    }
  }
  result
}

// --- Search::split ---

///|
pub fn Search::split(
  re : @compile.Re,
  s : Bytes,
  pos~ : Int32 = 0,
  len~ : Int32 = -1,
) -> Array[Bytes] raise {
  let full = Search::split_full(re, s, pos~, len~)
  let result : Array[Bytes] = []
  for token in full {
    match token {
      SplitText(text) => result.push(text)
      SplitDelim(_) => ()
    }
  }
  result
}

// --- Search::split_delim ---

///|
pub fn Search::split_delim(
  re : @compile.Re,
  s : Bytes,
  pos~ : Int32 = 0,
  len~ : Int32 = -1,
) -> Array[Bytes] raise {
  let full = Search::split_full(re, s, pos~, len~)
  let result : Array[Bytes] = []
  let mut delim = true
  let empty = Bytes::from_array([])
  for token in full {
    match token {
      SplitDelim(_) => {
        if delim {
          result.push(empty)
        }
        delim = true
      }
      SplitText(text) => {
        result.push(text)
        delim = false
      }
    }
  }
  if delim {
    result.push(empty)
  }
  result
}

// --- Search::iter_* — Seq 版 API（对齐上游 ocaml-re Re.Seq.*） ---
// Seq-style API (aligning upstream ocaml-re Re.Seq.*); current implementation
// materializes the results (Array-backed Iter), lazy streaming is a later concern.

///|
/// Search::all 的 Seq 版入口 | Seq-style entry of Search::all
pub fn Search::iter_all(
  re : @compile.Re,
  s : Bytes,
  pos~ : Int32 = 0,
  len~ : Int32 = -1,
) -> Iter[@compile.GroupT] raise {
  Search::all(re, s, pos~, len~).iter()
}

///|
/// 全部匹配子串的 Seq 版 | Seq-style matches
pub fn Search::iter_matches(
  re : @compile.Re,
  s : Bytes,
  pos~ : Int32 = 0,
  len~ : Int32 = -1,
) -> Iter[Bytes] raise {
  Search::matches(re, s, pos~, len~).iter()
}

///|
/// 按模式分割（丢弃分隔符）的 Seq 版 | Seq-style split
pub fn Search::iter_split(
  re : @compile.Re,
  s : Bytes,
  pos~ : Int32 = 0,
  len~ : Int32 = -1,
) -> Iter[Bytes] raise {
  Search::split(re, s, pos~, len~).iter()
}
