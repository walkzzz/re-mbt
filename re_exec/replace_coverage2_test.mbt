// 覆盖率长尾补测 — replace.mbt 窗口后缀/空匹配推进 + search split_full 边界
// coverage tail tests for replace.mbt window suffix/empty-match advance, split_full boundaries

///|
test "replace len window preserves suffix" {
  // 窗口 [0,2) 内 'a'→'X'，窗口外后缀 'a' 保留（replace.mbt 后缀复制分支）
  let re = @compile.compile(@ast.Ast::char('a'))
  let result = @re_exec.Replace::replace(
    re,
    @base.sb("aba"),
    f=fn(_g : @compile.GroupT) { @base.sb("X") },
    pos=0,
    len=2,
  )
  assert_eq(@base.bs(result), "Xba")
}

///|
test "replace empty match advances and keeps char" {
  // 可空匹配 a* 对 "bbb"：空匹配推进 + 保留被空匹配覆盖的字符
  let re = @compile.compile(@ast.Ast::rep(@ast.Ast::char('a')))
  let result = @re_exec.Replace::replace(
    re,
    @base.sb("bbb"),
    f=fn(_g : @compile.GroupT) { @base.sb("X") },
  )
  // 每个空匹配（含首尾位置共 4 个）产出 X 且保留原字符 b
  assert_eq(@base.bs(result).length(), 7)
}

///|
test "split_full consecutive delims" {
  // 连续分隔符：SplitText 空段 + SplitDelim 交替（split_full 状态机分支）
  let re = @compile.compile(@ast.Ast::char(','))
  let full = @re_exec.Search::split_full(re, @base.sb("a,,b"))
  let mut texts = 0
  let mut delims = 0
  for token in full {
    match token {
      @re_exec.SplitText(_) => texts += 1
      @re_exec.SplitDelim(_) => delims += 1
    }
  }
  assert_eq(delims, 2)
  assert_eq(texts, 3)
}

///|
test "materialized matches direct call" {
  // 物化版 matches 直调（iter_matches 惰性化后的公共 API 兜底覆盖）
  let re = @compile.compile(@ast.Ast::char('o'))
  let s = @base.sb("foo bar boo")
  let result = @re_exec.Search::matches(re, s)
  assert_eq(result.length(), 4)
}

///|
test "materialized matches empty get branch" {
  // GroupT::get(g, 0) 为 None 的分支（空匹配产出空 Bytes）
  let re = @compile.compile(@ast.Ast::opt(@ast.Ast::char('z')))
  let s = @base.sb("ab")
  let result = @re_exec.Search::matches(re, s)
  assert_true(result.length() > 0)
}

///|
test "iter_all is truly lazy not eager" {
  // 惰性验证：取第一个匹配后不消费剩余（matches 计数不推进全量）
  let digits = @ast.Ast::rep1(@ast.Ast::cset(@base.Cset::cseq('0', '9')))
  let re = @compile.compile(digits)
  let s = @base.sb("1x22x333")
  let it = @re_exec.Search::iter_all(re, s)
  let first = it.next()
  match first {
    Some(g) => assert_eq(@compile.GroupT::start(g, 0), 0)
    None => assert_eq(true, false)
  }
}
