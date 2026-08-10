// Replace — replace matched substrings (port of lib/replace.ml)

///|
pub struct Replace {}

///|
pub fn Replace::replace(
  re : Re,
  s : Bytes,
  f~ : (GroupT) -> Bytes,
  pos? : Int = 0,
  len? : Int = -1,
  all? : Bool = true,
) -> Bytes raise {
  if pos < 0 {
    fail("Re.replace: invalid pos")
  }
  let limit = if len < 0 {
    s.length()
  } else {
    if pos + len > s.length() {
      fail("Re.replace: invalid len")
    }
    pos + len
  }
  let buf : Array[Byte] = []
  let mut cur_pos = pos
  let mut on_match = false
  let mut done = false
  while !done {
    if cur_pos > limit {
      done = true
    } else {
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
          if cur_pos == p1 && p1 == p2 && on_match {
            if p2 < limit {
              buf.push(s[p2])
            }
            cur_pos = p2 + 1
            on_match = false
          } else {
            for k in cur_pos..<p1 {
              buf.push(s[k])
            }
            let replacing = f(substr)
            for k in 0..<replacing.length() {
              buf.push(replacing[k])
            }
            if all {
              if p1 == p2 {
                if p2 < limit {
                  buf.push(s[p2])
                }
                cur_pos = p2 + 1
              } else {
                cur_pos = p2
              }
              on_match = p1 != p2
            } else {
              for k in p2..<limit {
                buf.push(s[k])
              }
              done = true
            }
          }
        }
        FailedInfo => {
          for k in cur_pos..<limit {
            buf.push(s[k])
          }
          done = true
        }
        RunningInfo(_) => done = true
      }
    }
  }
  Bytes::from_array(buf)
}

///|
pub fn Replace::replace_string(
  re : Re,
  s : Bytes,
  by~ : Bytes,
  pos? : Int = 0,
  len? : Int = -1,
  all? : Bool = true,
) -> Bytes raise {
  let by_val = by
  Replace::replace(re, s, f=fn(_ : GroupT) { by_val }, pos~, len~, all~)
}
