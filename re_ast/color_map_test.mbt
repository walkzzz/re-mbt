///|
test "ColorMap empty flatten" {
  let cm = @re_ast.ColorMap::make()
  let (table, _bt, repr) = cm.flatten()
  assert_eq(@re_ast.ColorRepr::length(repr), 1)
  assert_eq(
    @re_ast.ColorTable::get(table, 0),
    @re_ast.ColorTable::get(table, 255),
  )
}

///|
test "ColorMap single char split" {
  let cm = @re_ast.ColorMap::make()
  cm.split(@base.Cset::single(65))
  let (table, _bt, repr) = cm.flatten()
  assert_eq(@re_ast.ColorRepr::length(repr), 2)
  assert_eq(@re_ast.ColorTable::get(table, 65), 1)
  assert_eq(@re_ast.ColorTable::get(table, 66), 0)
}

///|
test "ColorMap two chars split" {
  let cm = @re_ast.ColorMap::make()
  cm.split(@base.Cset::single(65))
  cm.split(@base.Cset::single(66))
  let (table, _bt, repr) = cm.flatten()
  assert_eq(@re_ast.ColorRepr::length(repr), 3)
  assert_eq(@re_ast.ColorTable::get(table, 65), 1)
  assert_eq(@re_ast.ColorTable::get(table, 66), 2)
  assert_eq(@re_ast.ColorTable::get(table, 67), 0)
}

///|
test "ColorMap translate_colors" {
  let cm = @re_ast.ColorMap::make()
  cm.split(@base.Cset::single(65))
  let (table, bt, _repr) = cm.flatten()
  let translated = @re_ast.ColorTable::translate_colors(
    table,
    bt,
    @base.Cset::single(65),
  )
  assert_eq(@base.Cset::mem(1, translated), true)
  assert_eq(@base.Cset::mem(0, translated), false)
}

///|
test "colorize single char matches manual split" {
  let r = @re_ast.Ast::char('a')
  let rnc = @re_ast.Ast::handle_case(r, false)
  let cm1 = @re_ast.ColorMap::make()
  let lnl1 = @re_ast.Ast::colorize(cm1, rnc)
  let (t1, _bt1, rep1) = @re_ast.ColorMap::flatten(cm1)
  let cm2 = @re_ast.ColorMap::make()
  @re_ast.ColorMap::split(cm2, @base.Cset::single(97))
  let (t2, _bt2, rep2) = @re_ast.ColorMap::flatten(cm2)
  assert_eq(@re_ast.ColorRepr::length(rep1), @re_ast.ColorRepr::length(rep2))
  assert_eq(@re_ast.ColorTable::get(t1, 0), @re_ast.ColorTable::get(t2, 0))
  assert_eq(@re_ast.ColorTable::get(t1, 64), @re_ast.ColorTable::get(t2, 64))
  assert_eq(@re_ast.ColorTable::get(t1, 97), @re_ast.ColorTable::get(t2, 97))
  assert_eq(@re_ast.ColorTable::get(t1, 98), @re_ast.ColorTable::get(t2, 98))
  assert_eq(@re_ast.ColorTable::get(t1, 255), @re_ast.ColorTable::get(t2, 255))
  assert_eq(lnl1, false)
}

///|
test "colorize str matches manual split" {
  let r = @re_ast.Ast::str(b"ab")
  let rnc = @re_ast.Ast::handle_case(r, false)
  let cm1 = @re_ast.ColorMap::make()
  let lnl1 = @re_ast.Ast::colorize(cm1, rnc)
  let (t1, _bt1, rep1) = @re_ast.ColorMap::flatten(cm1)
  let cm2 = @re_ast.ColorMap::make()
  @re_ast.ColorMap::split(cm2, @base.Cset::single(97))
  @re_ast.ColorMap::split(cm2, @base.Cset::single(98))
  let (t2, _bt2, rep2) = @re_ast.ColorMap::flatten(cm2)
  assert_eq(@re_ast.ColorRepr::length(rep1), @re_ast.ColorRepr::length(rep2))
  assert_eq(@re_ast.ColorTable::get(t1, 0), @re_ast.ColorTable::get(t2, 0))
  assert_eq(@re_ast.ColorTable::get(t1, 64), @re_ast.ColorTable::get(t2, 64))
  assert_eq(@re_ast.ColorTable::get(t1, 97), @re_ast.ColorTable::get(t2, 97))
  assert_eq(@re_ast.ColorTable::get(t1, 98), @re_ast.ColorTable::get(t2, 98))
  assert_eq(@re_ast.ColorTable::get(t1, 99), @re_ast.ColorTable::get(t2, 99))
  assert_eq(@re_ast.ColorTable::get(t1, 255), @re_ast.ColorTable::get(t2, 255))
  assert_eq(lnl1, false)
}

///|
test "colorize alternative matches manual split" {
  let r = @re_ast.Ast::alt([@re_ast.Ast::char('a'), @re_ast.Ast::char('b')])
  let rnc = @re_ast.Ast::handle_case(r, false)
  let cm1 = @re_ast.ColorMap::make()
  let lnl1 = @re_ast.Ast::colorize(cm1, rnc)
  let (t1, _bt1, rep1) = @re_ast.ColorMap::flatten(cm1)
  let cm2 = @re_ast.ColorMap::make()
  @re_ast.ColorMap::split(cm2, @base.Cset::single(97))
  @re_ast.ColorMap::split(cm2, @base.Cset::single(98))
  let (t2, _bt2, rep2) = @re_ast.ColorMap::flatten(cm2)
  assert_eq(@re_ast.ColorRepr::length(rep1), @re_ast.ColorRepr::length(rep2))
  assert_eq(@re_ast.ColorTable::get(t1, 0), @re_ast.ColorTable::get(t2, 0))
  assert_eq(@re_ast.ColorTable::get(t1, 64), @re_ast.ColorTable::get(t2, 64))
  assert_eq(@re_ast.ColorTable::get(t1, 97), @re_ast.ColorTable::get(t2, 97))
  assert_eq(@re_ast.ColorTable::get(t1, 98), @re_ast.ColorTable::get(t2, 98))
  assert_eq(@re_ast.ColorTable::get(t1, 99), @re_ast.ColorTable::get(t2, 99))
  assert_eq(@re_ast.ColorTable::get(t1, 255), @re_ast.ColorTable::get(t2, 255))
  assert_eq(lnl1, false)
}
