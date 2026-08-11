// compile_internal_test.mbt — direct tests for CompileIdx (9 pub fn) and StateHashTable (3 pub fn)
// Covers coverage_gap_analysis.md §4 priority P15 (compile internal state management).

///|
fn sb_ci(s : String) -> Bytes {
  let arr : Array[Byte] = []
  for c in s {
    arr.push(c.to_int().to_byte())
  }
  Bytes::from_array(arr)
}

// === CompileIdx constants ===

///|
test "compile_idx constants" {
  // CompileIdx::unknown() == -2
  assert_eq(CompileIdx::unknown(), -2)
  // CompileIdx::break_value() == -3
  assert_eq(CompileIdx::break_value(), -3)
}

// === CompileIdx three state predicates: is_idx / is_break / is_unknown ===

///|
test "compile_idx three state predicates" {
  // is_idx(t) = t >= 0
  assert_eq(CompileIdx::is_idx(0), true)
  assert_eq(CompileIdx::is_idx(1), true)
  assert_eq(CompileIdx::is_idx(-1), false)
  assert_eq(CompileIdx::is_idx(CompileIdx::unknown()), false)
  assert_eq(CompileIdx::is_idx(CompileIdx::break_value()), false)

  // is_break(x) = x <= break_value() (x <= -3)
  assert_eq(CompileIdx::is_break(CompileIdx::break_value()), true)
  assert_eq(CompileIdx::is_break(CompileIdx::make_break(5)), true)
  assert_eq(CompileIdx::is_break(0), false)
  assert_eq(CompileIdx::is_break(CompileIdx::unknown()), false)

  // is_unknown(x) = x == unknown() (x == -2)
  assert_eq(CompileIdx::is_unknown(CompileIdx::unknown()), true)
  assert_eq(CompileIdx::is_unknown(0), false)
  assert_eq(CompileIdx::is_unknown(CompileIdx::break_value()), false)
}

// === CompileIdx conversion functions: of_idx / idx / make_break / break_idx ===

///|
test "compile idx conversion functions" {
  // of_idx / idx are identity
  assert_eq(CompileIdx::of_idx(42), 42)
  assert_eq(CompileIdx::idx(42), 42)

  // make_break(idx) = -5 - idx
  assert_eq(CompileIdx::make_break(3), -8) // -5-3 = -8
  assert_eq(CompileIdx::make_break(0), -5) // -5-0 = -5

  // break_idx round-trip: break_idx(make_break(k)) == k
  assert_eq(CompileIdx::break_idx(CompileIdx::make_break(3)), 3)
  assert_eq(CompileIdx::break_idx(CompileIdx::make_break(10)), 10)
  // break_idx(-5) == 0 (boundary: make_break(0) == -5)
  assert_eq(CompileIdx::break_idx(-5), 0)
}

// === StateHashTable::create + find on empty table ===

///|
test "state hash table create and find empty" {
  // capacity=4: empty table find returns None
  let tbl4 = StateHashTable::create(4)
  match StateHashTable::find(tbl4, State::dummy()) {
    Some(_) => fail("expected None, got Some")
    None => ()
  }

  // capacity=1 boundary
  let tbl1 = StateHashTable::create(1)
  match StateHashTable::find(tbl1, State::dummy()) {
    Some(_) => fail("expected None, got Some")
    None => ()
  }

  // capacity=0 boundary: clamped to 1
  let tbl0 = StateHashTable::create(0)
  match StateHashTable::find(tbl0, State::dummy()) {
    Some(_) => fail("expected None, got Some")
    None => ()
  }
}

// === StateHashTable::add + find hit ===
// CompileState's fields are not pub(all), so struct literal construction is not
// available from test files. We obtain a CompileState by compiling a regex,
// triggering a match (which populates re.initial_states via find_initial_state),
// then extracting a CompileState from re.initial_states (same-package field access).

///|
test "state hash table add and find hit" {
  let re = compile(Ast::char('a'))
  // Trigger match to populate re.initial_states and re.states
  let s = sb_ci("a")
  let _ = match_str_p(re, s, pos=0, len=1)
  // re.initial_states is now non-empty
  assert_true(re.initial_states.length() > 0)
  let (_, cs0) = re.initial_states[0]
  // Create a fresh table and add cs0 with State::dummy() as key
  let tbl = StateHashTable::create(4)
  let key = State::dummy()
  StateHashTable::add(tbl, key, cs0)
  // find returns Some(cs'); verify it's the same CompileState by checking info.idx
  match StateHashTable::find(tbl, key) {
    Some(cs_found) =>
      assert_eq(
        CompileState::get_info(cs_found).idx,
        CompileState::get_info(cs0).idx,
      )
    None => fail("expected Some, got None")
  }
}

// === StateHashTable::find miss with different State ===

///|
test "state hash table find miss different state" {
  let re = compile(Ast::char('a'))
  // Trigger match to populate re.initial_states
  let s = sb_ci("a")
  let _ = match_str_p(re, s, pos=0, len=1)
  assert_true(re.initial_states.length() > 0)
  let (_, cs0) = re.initial_states[0]

  let tbl = StateHashTable::create(4)
  let dummy_key = State::dummy()
  StateHashTable::add(tbl, dummy_key, cs0)

  // other_key differs from dummy by idx (1 vs -1)
  let other_key = State::mk(1, Category::dummy(), [])
  // find on non-added key returns None
  match StateHashTable::find(tbl, other_key) {
    Some(_) => fail("expected None for other_key, got Some")
    None => ()
  }

  // add other_key with cs0; find on dummy_key still returns cs0
  StateHashTable::add(tbl, other_key, cs0)
  // dummy_key lookup still hits cs0 (State::equal distinguishes by idx)
  match StateHashTable::find(tbl, dummy_key) {
    Some(cs_found) =>
      assert_eq(
        CompileState::get_info(cs_found).idx,
        CompileState::get_info(cs0).idx,
      )
    None => fail("expected Some for dummy_key, got None")
  }
  // other_key lookup also hits cs0
  match StateHashTable::find(tbl, other_key) {
    Some(cs_found) =>
      assert_eq(
        CompileState::get_info(cs_found).idx,
        CompileState::get_info(cs0).idx,
      )
    None => fail("expected Some for other_key, got None")
  }
}
