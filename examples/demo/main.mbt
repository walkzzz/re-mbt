///|
/// re-mbt 可运行示例：Perl 捕获组 / 布尔匹配 / 大小写选项 / Glob / 错误路径。
/// Runnable demo for re-mbt: Perl groups, boolean match, caseless, glob, error path.

///|
fn main raise {
  // 1. Perl 捕获组
  let date = @re.Perl::compile_pat(@re.sb("(\\d+)-(\\d+)"))
  match @re.exec_opt(date, @re.sb("2024-12-25")) {
    Some(g) =>
      println(
        "perl match: full=" +
        @re.bs(@re.GroupT::get(g, 0).unwrap()) +
        " year=" +
        @re.bs(@re.GroupT::get(g, 1).unwrap()) +
        " month=" +
        @re.bs(@re.GroupT::get(g, 2).unwrap()),
      )
    None => println("perl match: none")
  }

  // 2. 布尔匹配与大小写选项
  let digits = @re.Perl::compile_pat(@re.sb("\\d+"))
  println("execp digits: " + @re.execp(digits, @re.sb("a1b2c3")).to_string())
  let hello = @re.Perl::compile_pat(@re.sb("hello"), opts=[
    @re.PerlOpt::caseless(),
  ])
  println("caseless HELLO: " + @re.execp(hello, @re.sb("HELLO")).to_string())

  // 3. 首个匹配的字节切片
  match @re.exec_opt(digits, @re.sb("a1b2c3")) {
    Some(g) =>
      println("first digits: " + @re.bs(@re.GroupT::get(g, 0).unwrap()))
    None => println("first digits: none")
  }

  // 4. Glob 前端
  let g = @re.Glob::compile(@re.sb("*.mbt"))
  println("glob main.mbt: " + @re.execp(g, @re.sb("main.mbt")).to_string())
  println("glob main.rs: " + @re.execp(g, @re.sb("main.rs")).to_string())

  // 5. 错误路径：不匹配返回 None，不发散
  let never = @re.Perl::compile_pat(@re.sb("^zzz$"))
  println(
    "no match: " + (@re.exec_opt(never, @re.sb("abc")) is None).to_string(),
  )
}
