// Replace — replace matched substrings (port of lib/replace.ml)

///|
#warnings("-struct_never_constructed")
pub struct Replace {}

///|
pub fn Replace::replace(
  re : @compile.Re,
  s : Bytes,
  f~ : (@compile.GroupT) -> Bytes,
  pos~ : Int32 = 0,
  len~ : Int32 = -1,
  all~ : Bool = true,
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
  // 窗口外文本保留：先复制前缀 [0, pos) | preserve text outside window: copy prefix first
  for k in 0..<pos {
    buf.push(s[k])
  }
  let mut cur_pos = pos
  let mut on_match = false
  let mut done = false
  while !done {
    if cur_pos > limit {
      done = true
    } else {
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
  // 复制后缀 [limit, length) | copy the suffix after the window
  for k in limit..<s.length() {
    buf.push(s[k])
  }
  Bytes::from_array(buf)
}

///|
pub fn Replace::replace_string(
  re : @compile.Re,
  s : Bytes,
  by~ : Bytes,
  pos~ : Int32 = 0,
  len~ : Int32 = -1,
  all~ : Bool = true,
) -> Bytes raise {
  let by_val = by
  Replace::replace(
    re,
    s,
    f=fn(_ : @compile.GroupT) { by_val },
    pos~,
    len~,
    all~,
  )
}
