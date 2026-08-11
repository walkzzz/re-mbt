///|
test "ColorMap empty flatten" {
  let cm = ColorMap::make()
  let (table, _bt, repr) = cm.flatten()
  assert_eq(ColorRepr::length(repr), 1)
  assert_eq(ColorTable::get(table, 0), ColorTable::get(table, 255))
}

///|
test "ColorMap single char split" {
  let cm = ColorMap::make()
  cm.split(Cset::single(65))
  let (table, _bt, repr) = cm.flatten()
  assert_eq(ColorRepr::length(repr), 2)
  assert_eq(ColorTable::get(table, 65), 1)
  assert_eq(ColorTable::get(table, 66), 0)
}

///|
test "ColorMap two chars split" {
  let cm = ColorMap::make()
  cm.split(Cset::single(65))
  cm.split(Cset::single(66))
  let (table, _bt, repr) = cm.flatten()
  assert_eq(ColorRepr::length(repr), 3)
  assert_eq(ColorTable::get(table, 65), 1)
  assert_eq(ColorTable::get(table, 66), 2)
  assert_eq(ColorTable::get(table, 67), 0)
}

///|
test "ColorMap translate_colors" {
  let cm = ColorMap::make()
  cm.split(Cset::single(65))
  let (table, bt, _repr) = cm.flatten()
  let translated = ColorTable::translate_colors(table, bt, Cset::single(65))
  assert_eq(Cset::mem(1, translated), true)
  assert_eq(Cset::mem(0, translated), false)
}

///|
test "colorize single char matches manual split" {
  let r = Ast::char('a')
  let rnc = Ast::handle_case(r, false)
  let cm1 = ColorMap::make()
  let lnl1 = Ast::colorize(cm1, rnc)
  let (t1, _bt1, rep1) = ColorMap::flatten(cm1)
  let cm2 = ColorMap::make()
  ColorMap::split(cm2, Cset::single(97))
  let (t2, _bt2, rep2) = ColorMap::flatten(cm2)
  assert_eq(ColorRepr::length(rep1), ColorRepr::length(rep2))
  assert_eq(ColorTable::get(t1, 0), ColorTable::get(t2, 0))
  assert_eq(ColorTable::get(t1, 64), ColorTable::get(t2, 64))
  assert_eq(ColorTable::get(t1, 97), ColorTable::get(t2, 97))
  assert_eq(ColorTable::get(t1, 98), ColorTable::get(t2, 98))
  assert_eq(ColorTable::get(t1, 255), ColorTable::get(t2, 255))
  assert_eq(lnl1, false)
}

///|
test "colorize str matches manual split" {
  let r = Ast::str(b"ab")
  let rnc = Ast::handle_case(r, false)
  let cm1 = ColorMap::make()
  let lnl1 = Ast::colorize(cm1, rnc)
  let (t1, _bt1, rep1) = ColorMap::flatten(cm1)
  let cm2 = ColorMap::make()
  ColorMap::split(cm2, Cset::single(97))
  ColorMap::split(cm2, Cset::single(98))
  let (t2, _bt2, rep2) = ColorMap::flatten(cm2)
  assert_eq(ColorRepr::length(rep1), ColorRepr::length(rep2))
  assert_eq(ColorTable::get(t1, 0), ColorTable::get(t2, 0))
  assert_eq(ColorTable::get(t1, 64), ColorTable::get(t2, 64))
  assert_eq(ColorTable::get(t1, 97), ColorTable::get(t2, 97))
  assert_eq(ColorTable::get(t1, 98), ColorTable::get(t2, 98))
  assert_eq(ColorTable::get(t1, 99), ColorTable::get(t2, 99))
  assert_eq(ColorTable::get(t1, 255), ColorTable::get(t2, 255))
  assert_eq(lnl1, false)
}

///|
test "colorize alternative matches manual split" {
  let r = Ast::alt([Ast::char('a'), Ast::char('b')])
  let rnc = Ast::handle_case(r, false)
  let cm1 = ColorMap::make()
  let lnl1 = Ast::colorize(cm1, rnc)
  let (t1, _bt1, rep1) = ColorMap::flatten(cm1)
  let cm2 = ColorMap::make()
  ColorMap::split(cm2, Cset::single(97))
  ColorMap::split(cm2, Cset::single(98))
  let (t2, _bt2, rep2) = ColorMap::flatten(cm2)
  assert_eq(ColorRepr::length(rep1), ColorRepr::length(rep2))
  assert_eq(ColorTable::get(t1, 0), ColorTable::get(t2, 0))
  assert_eq(ColorTable::get(t1, 64), ColorTable::get(t2, 64))
  assert_eq(ColorTable::get(t1, 97), ColorTable::get(t2, 97))
  assert_eq(ColorTable::get(t1, 98), ColorTable::get(t2, 98))
  assert_eq(ColorTable::get(t1, 99), ColorTable::get(t2, 99))
  assert_eq(ColorTable::get(t1, 255), ColorTable::get(t2, 255))
  assert_eq(lnl1, false)
}
