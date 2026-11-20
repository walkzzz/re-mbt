///|
/// 浏览器演示导出层：正则匹配（JS/WasmGC 目标）。
/// Browser demo exports: regex matching for the JS/WasmGC targets.
/// 非 raise 签名：JS 端直接得到 Bool / Int32（解析错误折叠为 false / -1）。

///|
#export_name("re_match")
pub fn re_match(pattern : String, input : String) -> Bool {
  try {
    let re = @frontend.Perl::compile_pat(@base.sb(pattern))
    @compile.execp(re, @base.sb(input))
  } catch {
    _ => false
  }
}

///|
#export_name("re_find_len")
pub fn re_find_len(pattern : String, input : String) -> Int32 {
  try {
    let re = @frontend.Perl::compile_pat(@base.sb(pattern))
    match @compile.exec_opt(re, @base.sb(input)) {
      Some(g) =>
        match @compile.GroupT::get(g, 0) {
          Some(b) => b.length()
          None => -1
        }
      None => -1
    }
  } catch {
    _ => -1
  }
}
