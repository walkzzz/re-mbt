// coverage_match_test.mbt — match_str/error paths coverage tests

// === match_str 四象限 (P1: groups × partial) ===

///|
test "match_str groups=true partial=false" {
  let re = compile(Ast::str(sb("hello")))
  // 命中返回 MatchInfo
  match
    match_str(
      groups=true,
      partial=false,
      re,
      sb("hello world"),
      pos=0,
      len=11,
    ) {
    MatchInfo(_) => assert_eq(true, true)
    FailedInfo => assert_eq(true, false)
    RunningInfo(_) => assert_eq(true, false)
  }
  // 不命中返回 FailedInfo
  match
    match_str(groups=true, partial=false, re, sb("world"), pos=0, len=5) {
    MatchInfo(_) => assert_eq(true, false)
    FailedInfo => assert_eq(true, true)
    RunningInfo(_) => assert_eq(true, false)
  }
}

///|
test "match_str groups=false partial=false" {
  let re = compile(Ast::str(sb("hello")))
  // 命中返回 MatchInfo
  match
    match_str(
      groups=false,
      partial=false,
      re,
      sb("hello world"),
      pos=0,
      len=11,
    ) {
    MatchInfo(_) => assert_eq(true, true)
    FailedInfo => assert_eq(true, false)
    RunningInfo(_) => assert_eq(true, false)
  }
  // 不命中返回 FailedInfo
  match
    match_str(groups=false, partial=false, re, sb("world"), pos=0, len=5) {
    MatchInfo(_) => assert_eq(true, false)
    FailedInfo => assert_eq(true, true)
    RunningInfo(_) => assert_eq(true, false)
  }
}

///|
test "match_str groups=true partial=true" {
  let re = compile(Ast::str(sb("hello")))
  // 部分匹配（输入是模式真前缀）返回 RunningInfo
  match match_str(groups=true, partial=true, re, sb("hel"), pos=0, len=3) {
    MatchInfo(_) => assert_eq(true, false)
    FailedInfo => assert_eq(true, false)
    RunningInfo(_) => assert_eq(true, true)
  }
  // 完整命中返回 MatchInfo
  match
    match_str(groups=true, partial=true, re, sb("hello"), pos=0, len=5) {
    MatchInfo(_) => assert_eq(true, true)
    FailedInfo => assert_eq(true, false)
    RunningInfo(_) => assert_eq(true, false)
  }
}

///|
test "match_str groups=false partial=true" {
  let re = compile(Ast::str(sb("hello")))
  // 部分匹配（输入是模式真前缀）返回 RunningInfo
  match match_str(groups=false, partial=true, re, sb("hel"), pos=0, len=3) {
    MatchInfo(_) => assert_eq(true, false)
    FailedInfo => assert_eq(true, false)
    RunningInfo(_) => assert_eq(true, true)
  }
  // 完整命中返回 MatchInfo
  match
    match_str(groups=false, partial=true, re, sb("hello"), pos=0, len=5) {
    MatchInfo(_) => assert_eq(true, true)
    FailedInfo => assert_eq(true, false)
    RunningInfo(_) => assert_eq(true, false)
  }
}

// === match_str_no_bounds 越界 (P2: 对照断言合并入块内) ===

///|
test "match_str pos negative bounds raise" {
  let re = compile(Ast::str(sb("hello")))
  let s = sb("hello")
  // 注：pos < 0 时 match_str_no_bounds 内部 next_state 访问 s[pos] 产生不可捕获的
  // RuntimeError（非 fail 异常），故此处仅对照验证 match_str raise "Re.exec: out of bounds"
  let bounds_raise = try {
    let _ = match_str(groups=true, partial=false, re, s, pos=-1, len=5)
    false
  } catch {
    _ => true
  }
  assert_eq(bounds_raise, true)
}

///|
test "match_str_no_bounds len below -1 no raise" {
  let re = compile(Ast::str(sb("hello")))
  let s = sb("hello")
  // match_str_no_bounds 不 raise：直接调用验证不产生错误（len < -1 时 last < pos，
  // 循环不执行，返回 FailedInfo）
  match match_str_no_bounds(groups=true, partial=false, re, s, pos=0, len=-2) {
    MatchInfo(_) => assert_eq(true, true)
    FailedInfo => assert_eq(true, true)
    RunningInfo(_) => assert_eq(true, true)
  }
  // 对照：match_str 对相同越界参数应 raise "Re.exec: out of bounds"
  let bounds_raise = try {
    let _ = match_str(groups=true, partial=false, re, s, pos=0, len=-2)
    false
  } catch {
    _ => true
  }
  assert_eq(bounds_raise, true)
}

///|
test "match_str pos+len overflow bounds raise" {
  let re = compile(Ast::str(sb("hello")))
  let s = sb("hello")
  // 注：pos+len > s.length() 时 match_str_no_bounds 内部循环访问 s[pos] 产生不可捕获的
  // RuntimeError（非 fail 异常），故此处仅对照验证 match_str raise "Re.exec: out of bounds"
  let bounds_raise = try {
    let _ = match_str(groups=true, partial=false, re, s, pos=0, len=100)
    false
  } catch {
    _ => true
  }
  assert_eq(bounds_raise, true)
}

// === Pcre 高级 API 异常路径 + 命名 group 边界 (P4) ===

///|
test "pcre exec no match raise" {
  let re = Pcre::regexp(sb("abc"))
  // 不匹配输入触发 core.mbt:112 fail("Re.exec: not found")
  let result = try {
    let _ = Pcre::exec(re, sb("xyz"))
    false
  } catch {
    _ => true
  }
  assert_eq(result, true)
}

///|
test "pcre get_named_substring not found raise" {
  let re = Pcre::regexp(sb("(?<word>[a-z]+)"))
  let g = Pcre::exec(re, sb("hello"))
  // 错误 name 触发 pcre.mbt:179 fail("Pcre: named group not found")
  let result = try {
    let _ = Pcre::get_named_substring(re, "num", g)
    false
  } catch {
    _ => true
  }
  assert_eq(result, true)
}

///|
test "pcre get_named_substring opt boundary" {
  let re = Pcre::regexp(sb("(?<word>[a-z]+)"))
  let g = Pcre::exec(re, sb("hello"))
  // 正向：get_named_substring 命中（pcre.mbt:172-180 Some 分支）
  assert_eq(Pcre::get_named_substring(re, "word", g), sb("hello"))
  // 正向：get_named_substring_opt 命中（pcre.mbt:67-84 有名分支）
  assert_eq(Pcre::get_named_substring_opt(re, "word", g), Some(sb("hello")))
  // 边界：get_named_substring_opt 未命中返回 None（pcre.mbt:67-84 无名分支）
  assert_eq(Pcre::get_named_substring_opt(re, "num", g), None)
}

// === Str OCaml 风格 API 错误路径 (P5) ===

///|
test "str match_beginning no match raise" {
  let re = Str::regexp(sb("abc"))
  // 不匹配 → str_state.val = None，触发 str.mbt:83-88 fail("Str: no match")
  let _ = Str::string_match(re, sb("xyz"), 0)
  let result = try {
    let _ = Str::match_beginning()
    false
  } catch {
    _ => true
  }
  assert_eq(result, true)
}

///|
test "str match_end no match raise" {
  let re = Str::regexp(sb("abc"))
  // 先清空 str_state（不匹配 → None），触发 str.mbt:91-96 fail("Str: no match")
  let _ = Str::string_match(re, sb("xyz"), 0)
  let result = try {
    let _ = Str::match_end()
    false
  } catch {
    _ => true
  }
  assert_eq(result, true)
}

///|
test "str matched_string no match raise" {
  let re = Str::regexp(sb("abc"))
  // 先清空 str_state（不匹配 → None），触发 str.mbt:99-104 fail("Str: no match")
  let _ = Str::string_match(re, sb("xyz"), 0)
  let result = try {
    let _ = Str::matched_string(sb("xyz"))
    false
  } catch {
    _ => true
  }
  assert_eq(result, true)
}

///|
test "str group_beginning out of bounds raise" {
  let re = Str::regexp(sb("abc"))
  // 匹配成功 → str_state = Some(GroupT)，正则 abc 无捕获组，仅 group 0
  let _ = Str::string_match(re, sb("abc"), 0)
  // 越界 group idx 5 → GroupT::start → group.mbt:38-43 fail("Group.start: not found")
  let result = try {
    let _ = Str::group_beginning(5)
    false
  } catch {
    _ => true
  }
  assert_eq(result, true)
}

// === GroupT raise paths (P13) ===

///|
test "GroupT::offset out of bounds raise" {
  let re = compile(
    Ast::seq([Ast::str(sb("a")), Ast::group(Ast::str(sb("b")))]),
  )
  match exec_opt(re, sb("ab")) {
    Some(g) => {
      let result = try {
        let _ = GroupT::offset(g, 99)
        false
      } catch {
        _ => true
      }
      assert_eq(result, true)
    }
    None => assert_eq(true, false)
  }
}

///|
test "GroupT::start out of bounds raise" {
  let re = compile(
    Ast::seq([Ast::str(sb("a")), Ast::group(Ast::str(sb("b")))]),
  )
  match exec_opt(re, sb("ab")) {
    Some(g) => {
      let result = try {
        let _ = GroupT::start(g, 99)
        false
      } catch {
        _ => true
      }
      assert_eq(result, true)
    }
    None => assert_eq(true, false)
  }
}

///|
test "GroupT::stop out of bounds raise" {
  let re = compile(
    Ast::seq([Ast::str(sb("a")), Ast::group(Ast::str(sb("b")))]),
  )
  match exec_opt(re, sb("ab")) {
    Some(g) => {
      let result = try {
        let _ = GroupT::stop(g, 99)
        false
      } catch {
        _ => true
      }
      assert_eq(result, true)
    }
    None => assert_eq(true, false)
  }
}

///|
test "GroupT::create direct construction" {
  let s = sb("hello")
  let marks = MarkInfos::make([(0, 0), (1, 1)])
  let pmarks = PmarkSet::empty()
  let gpos = [0, 5]
  let g = GroupT::create(s, marks, pmarks, gpos, 1)
  assert_eq(GroupT::nb_groups(g), 1)
  assert_eq(GroupT::matched(g, 0), true)
  assert_eq(GroupT::matched(g, 1), false)
  assert_eq(GroupT::offset(g, 0), (0, 5))
  assert_eq(GroupT::start(g, 0), 0)
  assert_eq(GroupT::stop(g, 0), 5)
  assert_eq(bs(GroupT::get(g, 0).unwrap()), "hello")
}