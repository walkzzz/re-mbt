// 覆盖率长尾补测 — perl.mbt 错误路径与边界分支
// coverage tail tests for perl.mbt error paths and boundary branches

///|
test "perl hex code out of range 256" {
  let r = try {
    let _ = @re_frontend.Perl::compile_pat(@base.sb("\\x{100}"))
    false
  } catch {
    _ => true
  }
  assert_eq(r, true)
}

///|
test "perl non_capturing unclosed paren" {
  let r = try {
    let _ = @re_frontend.Perl::compile_pat(@base.sb("(?:abc"))
    false
  } catch {
    _ => true
  }
  assert_eq(r, true)
}

///|
test "perl named group unclosed paren" {
  let r = try {
    let _ = @re_frontend.Perl::compile_pat(@base.sb("(?<g>abc"))
    false
  } catch {
    _ => true
  }
  assert_eq(r, true)
}

///|
test "perl unknown paren construct" {
  let r = try {
    let _ = @re_frontend.Perl::compile_pat(@base.sb("(?x)abc"))
    false
  } catch {
    _ => true
  }
  assert_eq(r, true)
}

///|
test "perl oct without braces" {
  let r = try {
    let _ = @re_frontend.Perl::compile_pat(@base.sb("\\o41"))
    false
  } catch {
    _ => true
  }
  assert_eq(r, true)
}

///|
test "perl oct braces invalid digit" {
  let r = try {
    let _ = @re_frontend.Perl::compile_pat(@base.sb("\\o{8}"))
    false
  } catch {
    _ => true
  }
  assert_eq(r, true)
}

///|
test "perl octal escape missing digits" {
  let r = try {
    let _ = @re_frontend.Perl::compile_pat(@base.sb("\\1a"))
    false
  } catch {
    _ => true
  }
  assert_eq(r, true)
}

///|
test "perl quote backslash at eos" {
  let r = try {
    let _ = @re_frontend.Perl::compile_pat(@base.sb("\\Qab\\"))
    false
  } catch {
    _ => true
  }
  assert_eq(r, true)
}

///|
test "perl quote unterminated at eos" {
  let r = try {
    let _ = @re_frontend.Perl::compile_pat(@base.sb("\\Qab"))
    false
  } catch {
    _ => true
  }
  assert_eq(r, true)
}

///|
test "perl hex braces eos" {
  let r = try {
    let _ = @re_frontend.Perl::compile_pat(@base.sb("\\x{4"))
    false
  } catch {
    _ => true
  }
  assert_eq(r, true)
}

///|
test "perl hex braces invalid digit" {
  let r = try {
    let _ = @re_frontend.Perl::compile_pat(@base.sb("\\x{g}"))
    false
  } catch {
    _ => true
  }
  assert_eq(r, true)
}

///|
test "perl name first char invalid" {
  let r = try {
    let _ = @re_frontend.Perl::compile_pat(@base.sb("(?<1ab>x)"))
    false
  } catch {
    _ => true
  }
  assert_eq(r, true)
}

///|
test "perl name middle char invalid" {
  let r = try {
    let _ = @re_frontend.Perl::compile_pat(@base.sb("(?<g1!>x)"))
    false
  } catch {
    _ => true
  }
  assert_eq(r, true)
}

///|
test "perl name eos" {
  let r = try {
    let _ = @re_frontend.Perl::compile_pat(@base.sb("(?<g1"))
    false
  } catch {
    _ => true
  }
  assert_eq(r, true)
}

///|
// 注：`[=` collating 分支（perl_char_elem 494）不可靠可测——`[=b=]` 与 `a[=b=]` 均解析为
// 字面量字符类（`[` 作为类内字面量元素），嵌套 `[a[=b=]]` 触发 fail（abort 不可捕获）。
// 该分支记录为特殊路径，见门禁报告。
// note: the `[=` collating branch is not reliably testable; recorded as special path.

///|
test "perl bracket collating eos" {
  let r = try {
    let _ = @re_frontend.Perl::compile_pat(@base.sb("[.a"))
    false
  } catch {
    _ => true
  }
  assert_eq(r, true)
}

///|
test "perl bracket collating missing dots" {
  let r = try {
    let _ = @re_frontend.Perl::compile_pat(@base.sb("x[.abz"))
    false
  } catch {
    _ => true
  }
  assert_eq(r, true)
}

///|
test "perl bracket collating missing bracket" {
  let r = try {
    let _ = @re_frontend.Perl::compile_pat(@base.sb("x[.a.bz"))
    false
  } catch {
    _ => true
  }
  assert_eq(r, true)
}

///|
test "perl bracket backslash eos" {
  let r = try {
    let _ = @re_frontend.Perl::compile_pat(@base.sb("[\\"))
    false
  } catch {
    _ => true
  }
  assert_eq(r, true)
}

///|
test "perl bracket letter escape invalid" {
  let r = try {
    let _ = @re_frontend.Perl::compile_pat(@base.sb("[\\q]"))
    false
  } catch {
    _ => true
  }
  assert_eq(r, true)
}

///|
test "perl bracket digit escape unsupported" {
  let r = try {
    let _ = @re_frontend.Perl::compile_pat(@base.sb("[\\1]"))
    false
  } catch {
    _ => true
  }
  assert_eq(r, true)
}

///|
test "perl hex braces multiline valid still works" {
  let re = @re_frontend.Perl::compile_pat(@base.sb("\\x{48}\\x{69}"))
  assert_eq(@compile.execp(re, @base.sb("Hi")), true)
}
