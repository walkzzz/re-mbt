// Search — find all matches, split (port of lib/search.ml)
// Eager evaluation: returns Array[T]

///|
#warnings("-struct_never_constructed")
pub struct Search {}

///|
pub enum SplitToken {
  SplitText(Bytes)
  SplitDelim(GroupT)
}

///|
fn bytes_sub(s : Bytes, start : Int, len : Int) -> Bytes {
  let buf : Array[Byte] = []
  for k in 0..<len {
    buf.push(s[start + k])
  }
  Bytes::from_array(buf)
}

// --- Search::all ---

///|
pub fn Search::all(
  re : Re,
  s : Bytes,
  pos? : Int = 0,
  len? : Int = -1,
) -> Array[GroupT] raise {
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
  let result : Array[GroupT] = []
  let mut cur_pos = pos
  let mut on_match = false
  while cur_pos <= limit {
    match
      match_str(
        groups=true,
        partial=false,
        re,
        s,
        pos=cur_pos,
        len=limit - cur_pos,
      ) {
      MatchInfo(substr) => {
        let p1 = GroupT::start_offset(substr, 0)
        let p2 = GroupT::stop_offset(substr, 0)
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
  re : Re,
  s : Bytes,
  pos? : Int = 0,
  len? : Int = -1,
) -> Array[Bytes] raise {
  let groups = Search::all(re, s, pos~, len~)
  let result : Array[Bytes] = []
  for g in groups {
    match GroupT::get(g, 0) {
      Some(b) => result.push(b)
      None => result.push(Bytes::from_array([]))
    }
  }
  result
}

// --- Search::split_full ---

///|
pub fn Search::split_full(
  re : Re,
  s : Bytes,
  pos? : Int = 0,
  len? : Int = -1,
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
          match_str(
            groups=true,
            partial=false,
            re,
            s,
            pos=cur_pos,
            len=limit - cur_pos,
          ) {
          MatchInfo(substr) => {
            let p1 = GroupT::start_offset(substr, 0)
            let p2 = GroupT::stop_offset(substr, 0)
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
  re : Re,
  s : Bytes,
  pos? : Int = 0,
  len? : Int = -1,
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
  re : Re,
  s : Bytes,
  pos? : Int = 0,
  len? : Int = -1,
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
