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
