///|
test "ColorMap empty flatten" {
  let cm = @re.ColorMap::make()
  let (table, _bt, repr) = cm.flatten()
  assert_eq(@re.ColorRepr::length(repr), 1)
  assert_eq(@re.ColorTable::get(table, 0), @re.ColorTable::get(table, 255))
}

///|
test "ColorMap single char split" {
  let cm = @re.ColorMap::make()
  cm.split(@re.Cset::single(65))
  let (table, _bt, repr) = cm.flatten()
  assert_eq(@re.ColorRepr::length(repr), 2)
  assert_eq(@re.ColorTable::get(table, 65), 1)
  assert_eq(@re.ColorTable::get(table, 66), 0)
}

///|
test "ColorMap two chars split" {
  let cm = @re.ColorMap::make()
  cm.split(@re.Cset::single(65))
  cm.split(@re.Cset::single(66))
  let (table, _bt, repr) = cm.flatten()
  assert_eq(@re.ColorRepr::length(repr), 3)
  assert_eq(@re.ColorTable::get(table, 65), 1)
  assert_eq(@re.ColorTable::get(table, 66), 2)
  assert_eq(@re.ColorTable::get(table, 67), 0)
}

///|
test "ColorMap translate_colors" {
  let cm = @re.ColorMap::make()
  cm.split(@re.Cset::single(65))
  let (table, bt, _repr) = cm.flatten()
  let translated = @re.ColorTable::translate_colors(table, bt, @re.Cset::single(65))
  assert_eq(@re.Cset::mem(1, translated), true)
  assert_eq(@re.Cset::mem(0, translated), false)
}

///|
test "colorize single char matches manual split" {
  let r = @re.Ast::char('a')
  let rnc = @re.Ast::handle_case(r, false)
  let cm1 = @re.ColorMap::make()
  let lnl1 = @re.Ast::colorize(cm1, rnc)
  let (t1, _bt1, rep1) = @re.ColorMap::flatten(cm1)
  let cm2 = @re.ColorMap::make()
  @re.ColorMap::split(cm2, @re.Cset::single(97))
  let (t2, _bt2, rep2) = @re.ColorMap::flatten(cm2)
  assert_eq(@re.ColorRepr::length(rep1), @re.ColorRepr::length(rep2))
  assert_eq(@re.ColorTable::get(t1, 0), @re.ColorTable::get(t2, 0))
  assert_eq(@re.ColorTable::get(t1, 64), @re.ColorTable::get(t2, 64))
  assert_eq(@re.ColorTable::get(t1, 97), @re.ColorTable::get(t2, 97))
  assert_eq(@re.ColorTable::get(t1, 98), @re.ColorTable::get(t2, 98))
  assert_eq(@re.ColorTable::get(t1, 255), @re.ColorTable::get(t2, 255))
  assert_eq(lnl1, false)
}

///|
test "colorize str matches manual split" {
  let r = @re.Ast::str(b"ab")
  let rnc = @re.Ast::handle_case(r, false)
  let cm1 = @re.ColorMap::make()
  let lnl1 = @re.Ast::colorize(cm1, rnc)
  let (t1, _bt1, rep1) = @re.ColorMap::flatten(cm1)
  let cm2 = @re.ColorMap::make()
  @re.ColorMap::split(cm2, @re.Cset::single(97))
  @re.ColorMap::split(cm2, @re.Cset::single(98))
  let (t2, _bt2, rep2) = @re.ColorMap::flatten(cm2)
  assert_eq(@re.ColorRepr::length(rep1), @re.ColorRepr::length(rep2))
  assert_eq(@re.ColorTable::get(t1, 0), @re.ColorTable::get(t2, 0))
  assert_eq(@re.ColorTable::get(t1, 64), @re.ColorTable::get(t2, 64))
  assert_eq(@re.ColorTable::get(t1, 97), @re.ColorTable::get(t2, 97))
  assert_eq(@re.ColorTable::get(t1, 98), @re.ColorTable::get(t2, 98))
  assert_eq(@re.ColorTable::get(t1, 99), @re.ColorTable::get(t2, 99))
  assert_eq(@re.ColorTable::get(t1, 255), @re.ColorTable::get(t2, 255))
  assert_eq(lnl1, false)
}

///|
test "colorize alternative matches manual split" {
  let r = @re.Ast::alt([@re.Ast::char('a'), @re.Ast::char('b')])
  let rnc = @re.Ast::handle_case(r, false)
  let cm1 = @re.ColorMap::make()
  let lnl1 = @re.Ast::colorize(cm1, rnc)
  let (t1, _bt1, rep1) = @re.ColorMap::flatten(cm1)
  let cm2 = @re.ColorMap::make()
  @re.ColorMap::split(cm2, @re.Cset::single(97))
  @re.ColorMap::split(cm2, @re.Cset::single(98))
  let (t2, _bt2, rep2) = @re.ColorMap::flatten(cm2)
  assert_eq(@re.ColorRepr::length(rep1), @re.ColorRepr::length(rep2))
  assert_eq(@re.ColorTable::get(t1, 0), @re.ColorTable::get(t2, 0))
  assert_eq(@re.ColorTable::get(t1, 64), @re.ColorTable::get(t2, 64))
  assert_eq(@re.ColorTable::get(t1, 97), @re.ColorTable::get(t2, 97))
  assert_eq(@re.ColorTable::get(t1, 98), @re.ColorTable::get(t2, 98))
  assert_eq(@re.ColorTable::get(t1, 99), @re.ColorTable::get(t2, 99))
  assert_eq(@re.ColorTable::get(t1, 255), @re.ColorTable::get(t2, 255))
  assert_eq(lnl1, false)
}
