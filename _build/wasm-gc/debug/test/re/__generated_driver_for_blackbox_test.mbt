// #region Define traits with default implementations

///|
/// is_being_cancelled may be unused if there's no async test
#warnings("-unused_value")
trait MoonBit_Async_Test_Driver {
  fn run_async_tests(@moonbitlang/core/prelude.Array[async () -> Unit]) -> Unit = _
  fn is_being_cancelled() -> Bool = _
}

///|
impl MoonBit_Async_Test_Driver with fn run_async_tests(_) {
  ()
}

///|
impl MoonBit_Async_Test_Driver with fn is_being_cancelled() {
  false
}

///|
trait MoonBit_Test_Driver {
  /// returns if the test is found and executed
  fn run_test(
    @moonbitlang/core/prelude.Array[async () -> Unit],
    String,
    Int,
    () -> Unit,
    (String, String, Bool) -> Unit,
    (Error) -> String,
  ) -> Bool raise MoonBitTestDriverInternalSkipTest = _
}

///|
impl MoonBit_Test_Driver with fn run_test(_, _, _, _, _, _) {
  false
}

// #endregion
// #region Define abstract types for namespace with implementation declarations

///|
priv type MoonBit_Test_Driver_Internal_No_Args

///|
impl MoonBit_Test_Driver for MoonBit_Test_Driver_Internal_No_Args

///|
priv type MoonBit_Test_Driver_Internal_With_Args

///|
impl MoonBit_Test_Driver for MoonBit_Test_Driver_Internal_With_Args

///|
priv type MoonBit_Test_Driver_Internal_Async_No_Args

///|
impl MoonBit_Test_Driver for MoonBit_Test_Driver_Internal_Async_No_Args

///|
priv type MoonBit_Test_Driver_Internal_Async_With_Args

///|
impl MoonBit_Test_Driver for MoonBit_Test_Driver_Internal_Async_With_Args

///|
priv type MoonBit_Test_Driver_Internal_With_Bench_Args

///|
impl MoonBit_Test_Driver for MoonBit_Test_Driver_Internal_With_Bench_Args

///|
priv type MoonBit_Async_Test_Driver_Impl

///|
impl MoonBit_Async_Test_Driver for MoonBit_Async_Test_Driver_Impl

///|
extend MoonBit_Test_Driver_Internal_No_Args with MoonBit_Test_Driver::{run_test}

///|
extend MoonBit_Test_Driver_Internal_With_Args with MoonBit_Test_Driver::{
  run_test,
}

///|
extend MoonBit_Test_Driver_Internal_Async_No_Args with MoonBit_Test_Driver::{
  run_test,
}

///|
extend MoonBit_Test_Driver_Internal_Async_With_Args with MoonBit_Test_Driver::{
  run_test,
}

///|
extend MoonBit_Test_Driver_Internal_With_Bench_Args with MoonBit_Test_Driver::{
  run_test,
}

///|
extend MoonBit_Async_Test_Driver_Impl with MoonBit_Async_Test_Driver::{
  run_async_tests,
  is_being_cancelled,
}

///|
// `is_being_cancelled` is only called from async-test templates. This shared
// scaffold is also generated for packages without async tests, so reference
// the method value to keep strict warning lists from treating the explicit
// extend as unused without invoking cancellation logic during initialization.
fn init {
  ignore(MoonBit_Async_Test_Driver_Impl::is_being_cancelled)
}

// #endregion

// #region Utility Types

///|
/// Maybe unused if there's no tests
#warnings("-unused_type_declaration")
priv struct MoonBitTestDriverInternalTestMap[F](
  @moonbitlang/core/prelude.Map[
    String,
    @moonbitlang/core/prelude.Map[Int, (F, ReadOnlyArray[String])],
  ]
)

///|
priv suberror MoonBitTestDriverInternalSkipTest {
  MoonBitTestDriverInternalSkipTest(name~ : String)
}

// #endregion
///|
fn moonbit_test_driver_internal_error_to_string(x : Error) -> String = "%error.to_string"

///|
#cfg(any(target="native", target="llvm"))
fn string_get(s : String, index : Int) -> Int = "%string_get"

///|
#cfg(not(target="js"))
fn moonbit_unsafe_char_from_int(x : Int) -> Char = "%identity"

///|
#cfg(any(target="native", target="llvm"))
const MOONBIT_TEST_DRIVER_INTERNAL_IS_NATIVE = true

///|
#cfg(not(any(target="native", target="llvm")))
const MOONBIT_TEST_DRIVER_INTERNAL_IS_NATIVE = false

// =========================================================
// ================== BEGIN WASM SPECIFIC ==================
// =========================================================

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn moonbit_test_driver_internal_get_file_name(
  file_name : MoonbitTestDriverInternalExternString,
) -> String {
  moonbit_test_driver_internal_string_from_extern(file_name)
}

///|
#cfg(any(target="wasm", target="wasm-gc"))
#external
type MoonbitTestDriverInternalStringReadHandle

///|
#cfg(any(target="wasm", target="wasm-gc"))
#external
type MoonbitTestDriverInternalExternString

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn moonbit_test_driver_internal_begin_read_string(
  s : MoonbitTestDriverInternalExternString,
) -> MoonbitTestDriverInternalStringReadHandle = "__moonbit_fs_unstable" "begin_read_string"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn moonbit_test_driver_internal_string_read_char(
  handle : MoonbitTestDriverInternalStringReadHandle,
) -> Int = "__moonbit_fs_unstable" "string_read_char"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn moonbit_test_driver_internal_finish_read_string(
  handle : MoonbitTestDriverInternalStringReadHandle,
) = "__moonbit_fs_unstable" "finish_read_string"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn fixedarray_to_bytes(arr : FixedArray[Byte]) -> Bytes = "%identity"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn moonbit_test_driver_internal_string_from_extern(
  e : MoonbitTestDriverInternalExternString,
) -> String {
  let buf = FixedArray::make(512, Byte::default())
  let mut len = 0
  let handle = moonbit_test_driver_internal_begin_read_string(e)
  while true {
    let ch = moonbit_test_driver_internal_string_read_char(handle)
    if ch == -1 {
      break
    } else {
      let written_bytes_len = buf.set_utf16le_char(
        len,
        moonbit_unsafe_char_from_int(ch),
      )
      len += written_bytes_len
    }
  }
  moonbit_test_driver_internal_finish_read_string(handle)
  fixedarray_to_bytes(buf).to_unchecked_string(offset=0, length=len).to_string()
}

// =========================================================
// =================== END WASM SPECIFIC ===================
// =========================================================

// =========================================================
// ============== BEGIN NATIVE/LLVM SPECIFIC ===============
// =========================================================

///|
#cfg(any(target="native", target="llvm"))
fn moonbit_test_driver_internal_native_parse_args() -> @moonbitlang/core/prelude.Array[
  (String, Int),
] {
  fn moonbit_test_driver_internal_parse_int_(s : String) -> Int {
    let mut res = 0
    let len = s.length()
    for i in 0..<len {
      res = res * 10 + (string_get(s, i) - '0')
    }
    res
  }

  fn moonbit_test_driver_internal_utf8_bytes_to_mbt_string(
    bytes : Bytes,
  ) -> String {
    let res = @moonbitlang/core/prelude.StringBuilder::new()
    let len = bytes.length()
    let mut i = 0
    while i < len {
      let mut c = bytes[i].to_int()
      if c < 0x80 {
        res.write_char(moonbit_unsafe_char_from_int(c))
        i += 1
      } else if c < 0xE0 {
        if i + 1 >= len {
          break
        }
        c = ((c & 0x1F) << 6) | (bytes[i + 1].to_int() & 0x3F)
        res.write_char(moonbit_unsafe_char_from_int(c))
        i += 2
      } else if c < 0xF0 {
        if i + 2 >= len {
          break
        }
        c = ((c & 0x0F) << 12) |
          ((bytes[i + 1].to_int() & 0x3F) << 6) |
          (bytes[i + 2].to_int() & 0x3F)
        res.write_char(moonbit_unsafe_char_from_int(c))
        i += 3
      } else {
        if i + 3 >= len {
          break
        }
        c = ((c & 0x07) << 18) |
          ((bytes[i + 1].to_int() & 0x3F) << 12) |
          ((bytes[i + 2].to_int() & 0x3F) << 6) |
          (bytes[i + 3].to_int() & 0x3F)
        c -= 0x10000
        res.write_char(moonbit_unsafe_char_from_int((c >> 10) + 0xD800))
        res.write_char(moonbit_unsafe_char_from_int((c & 0x3FF) + 0xDC00))
        i += 4
      }
    }
    res.to_string()
  }

  fn moonbit_test_driver_internal_get_cli_args_internal() -> @moonbitlang/core/prelude.Array[
    String,
  ] {
    let tmp = moonbit_test_driver_internal_get_cli_args_ffi()
    let res = @moonbitlang/core/prelude.Array::new(capacity=tmp.length())
    for i in 0..<tmp.length() {
      res.push(moonbit_test_driver_internal_utf8_bytes_to_mbt_string(tmp[i]))
    }
    res
  }

  fn moonbit_test_driver_internal_split_mbt_string(
    s : String,
    sep : Char,
  ) -> @moonbitlang/core/prelude.Array[String] {
    let res = []
    let mut i = 0
    let mut start = 0
    while i < s.length() {
      if moonbit_unsafe_char_from_int(string_get(s, i)) == sep {
        res.push(s.unsafe_substring(start~, end=i))
        start = i + 1
      }
      i += 1
    }
    if start < s.length() {
      res.push(s.unsafe_substring(start~, end=s.length()))
    }
    res
  }

  let file_and_index = []
  let cli_args = moonbit_test_driver_internal_get_cli_args_internal()
  let test_args = moonbit_test_driver_internal_split_mbt_string(
    cli_args[1],
    '/',
  )
  for arg in test_args {
    let file_and_range = moonbit_test_driver_internal_split_mbt_string(arg, ':')
    let file = file_and_range[0]
    let range = file_and_range[1]
    let start_and_end = moonbit_test_driver_internal_split_mbt_string(
      range, '-',
    )
    let start = moonbit_test_driver_internal_parse_int_(start_and_end[0])
    let end = moonbit_test_driver_internal_parse_int_(start_and_end[1])
    for i in start..<end {
      file_and_index.push((file, i))
    }
  }
  file_and_index
}

///|
#cfg(any(target="native", target="llvm"))
fn moonbit_test_driver_internal_get_cli_args_ffi() -> FixedArray[Bytes] = "$moonbit.get_cli_args"

// =========================================================
// =============== END NATIVE/LLVM SPECIFIC ================
// =========================================================

// =========================================================
// -================== BEGIN JS SPECIFIC ===================
// =========================================================

///|
#cfg(target="js")
#external
type MoonBitTestDriverInternalTestEntry

///|
#cfg(target="js")
extern "js" fn MoonBitTestDriverInternalTestEntry::filename(
  self : Self,
) -> String =
  #| (entry) => entry[0]

///|
#cfg(target="js")
extern "js" fn MoonBitTestDriverInternalTestEntry::index(self : Self) -> Int =
  #| (entry) => entry[1]

///|
/// JavaScript error captured by the generated test driver.
pub(all) suberror MoonBitTestDriverInternalJsError {
  MoonBitTestDriverInternalJsError(String)
}

///|
/// Maybe unused if there's no tests
#cfg(target="js")
#warnings("-unused_value")
fn moonbit_test_driver_internal_catch_error(
  f : () -> Unit raise,
  on_ok~ : () -> Unit,
  on_err~ : (Error) -> Unit,
) -> Unit {
  moonbit_test_driver_internal_js_catch(
    on_err=err_str => on_err(MoonBitTestDriverInternalJsError(err_str)),
    () => {
      try f() catch {
        err => on_err(err)
      } noraise {
        _ => on_ok()
      }
    },
  )
}

///|
#cfg(target="js")
extern "js" fn moonbit_test_driver_internal_js_catch(
  f : () -> Unit,
  on_err~ : (String) -> Unit,
) =
  #| (f, on_err) => {
  #|   try {
  #|     f()
  #|   } catch (err) {
  #|     const msg = err.stack.toString()
  #|     on_err(msg)
  #|   }
  #| }

///|
/// Maybe unused if there's no tests
#cfg(not(target="js"))
#warnings("-unused_value")
fn moonbit_test_driver_internal_catch_error(
  f : () -> Unit raise,
  on_ok~ : () -> Unit,
  on_err~ : (Error) -> Unit,
) -> Unit {
  try f() catch {
    err => on_err(err)
  } noraise {
    _ => on_ok()
  }
}

// =========================================================
// -=================== END JS SPECIFIC ====================
// =========================================================
// This file is introduced when tests without args is needed

///|
let moonbit_test_driver_internal_no_args_tests : MoonBitTestDriverInternalTestMap[
  () -> Unit raise,
] = {
  "view_test.mbt": {
    0: (__test_766965775f746573742e6d6274_0, ["view char"]),
    1: (__test_766965775f746573742e6d6274_1, ["view sequence"]),
    2: (__test_766965775f746573742e6d6274_2, ["view alternative"]),
    3: (__test_766965775f746573742e6d6274_3, ["view repeat"]),
    4: (__test_766965775f746573742e6d6274_4, ["view anchors"]),
    5: (__test_766965775f746573742e6d6274_5, ["view group"]),
    6: (__test_766965775f746573742e6d6274_6, ["view named group"]),
    7: (__test_766965775f746573742e6d6274_7, ["view nest"]),
    8: (__test_766965775f746573742e6d6274_8, ["view no_group"]),
    9: (__test_766965775f746573742e6d6274_9, ["view sem"]),
    10: (__test_766965775f746573742e6d6274_10, ["cset view"]),
    11: (__test_766965775f746573742e6d6274_11, ["cset view range"]),
    12: (__test_766965775f746573742e6d6274_12, ["cset view empty"]),
    13: (__test_766965775f746573742e6d6274_13, ["cset view union"]),
  },
  "parse_buffer_test.mbt": {
    0: (__test_70617273655f6275666665725f746573742e6d6274_0, ["parse_buffer create and eos boundary"]),
    1: (__test_70617273655f6275666665725f746573742e6d6274_1, ["parse_buffer integer normal digits"]),
    2: (__test_70617273655f6275666665725f746573742e6d6274_2, ["parse_buffer integer empty returns None"]),
    3: (__test_70617273655f6275666665725f746573742e6d6274_3, ["parse_buffer integer non-digit first returns None"]),
    4: (__test_70617273655f6275666665725f746573742e6d6274_4, ["parse_buffer integer digits then non-digit stops"]),
    5: (__test_70617273655f6275666665725f746573742e6d6274_5, ["parse_buffer integer overflow raise"]),
  },
  "frontend_test.mbt": {
    0: (__test_66726f6e74656e645f746573742e6d6274_0, ["perl basic match"]),
    1: (__test_66726f6e74656e645f746573742e6d6274_1, ["perl alternation"]),
    2: (__test_66726f6e74656e645f746573742e6d6274_2, ["perl groups"]),
    3: (__test_66726f6e74656e645f746573742e6d6274_3, ["perl star"]),
    4: (__test_66726f6e74656e645f746573742e6d6274_4, ["perl plus"]),
    5: (__test_66726f6e74656e645f746573742e6d6274_5, ["perl char class"]),
    6: (__test_66726f6e74656e645f746573742e6d6274_6, ["perl char class range"]),
    7: (__test_66726f6e74656e645f746573742e6d6274_7, ["perl escaped chars"]),
    8: (__test_66726f6e74656e645f746573742e6d6274_8, ["perl digit class"]),
    9: (__test_66726f6e74656e645f746573742e6d6274_9, ["perl word boundary"]),
    10: (__test_66726f6e74656e645f746573742e6d6274_10, ["emacs basic"]),
    11: (__test_66726f6e74656e645f746573742e6d6274_11, ["emacs groups"]),
    12: (__test_66726f6e74656e645f746573742e6d6274_12, ["posix basic"]),
    13: (__test_66726f6e74656e645f746573742e6d6274_13, ["posix groups"]),
    14: (__test_66726f6e74656e645f746573742e6d6274_14, ["glob basic"]),
    15: (__test_66726f6e74656e645f746573742e6d6274_15, ["glob star match"]),
    16: (__test_66726f6e74656e645f746573742e6d6274_16, ["glob question mark"]),
    17: (__test_66726f6e74656e645f746573742e6d6274_17, ["pcre basic"]),
    18: (__test_66726f6e74656e645f746573742e6d6274_18, ["pcre extract"]),
    19: (__test_66726f6e74656e645f746573742e6d6274_19, ["str basic match"]),
    20: (__test_66726f6e74656e645f746573742e6d6274_20, ["str search"]),
    21: (__test_66726f6e74656e645f746573742e6d6274_21, ["str split"]),
    22: (__test_66726f6e74656e645f746573742e6d6274_22, ["perl non-greedy"]),
    23: (__test_66726f6e74656e645f746573742e6d6274_23, ["perl {n,m}"]),
    24: (__test_66726f6e74656e645f746573742e6d6274_24, ["perl caseless"]),
    25: (__test_66726f6e74656e645f746573742e6d6274_25, ["perl unclosed paren raise"]),
    26: (__test_66726f6e74656e645f746573742e6d6274_26, ["perl invalid escape raise"]),
    27: (__test_66726f6e74656e645f746573742e6d6274_27, ["perl unclosed bracket raise"]),
    28: (__test_66726f6e74656e645f746573742e6d6274_28, ["emacs unclosed paren raise"]),
    29: (__test_66726f6e74656e645f746573742e6d6274_29, ["emacs invalid escape raise"]),
    30: (__test_66726f6e74656e645f746573742e6d6274_30, ["pcre unclosed paren raise"]),
    31: (__test_66726f6e74656e645f746573742e6d6274_31, ["pcre invalid escape raise"]),
  },
  "desc_test.mbt": {
    0: (__test_646573635f746573742e6d6274_0, ["desc initial returns single TExp with empty marks"]),
    1: (__test_646573635f746573742e6d6274_1, ["desc status empty array returns Failed"]),
    2: (__test_646573635f746573742e6d6274_2, ["desc status TMatch head returns Match"]),
    3: (__test_646573635f746573742e6d6274_3, ["desc status TExp head returns Running"]),
    4: (__test_646573635f746573742e6d6274_4, ["desc remove_duplicates dedup same expr TExp"]),
    5: (__test_646573635f746573742e6d6274_5, ["desc remove_duplicates keeps distinct expr TExp"]),
  },
  "coverage_test.mbt": {
    0: (__test_636f7665726167655f746573742e6d6274_0, ["CsetC::null_char is -1"]),
    1: (__test_636f7665726167655f746573742e6d6274_1, ["CsetC::equal_c"]),
    2: (__test_636f7665726167655f746573742e6d6274_2, ["CsetC::to_int / of_int"]),
    3: (__test_636f7665726167655f746573742e6d6274_3, ["CsetC::to_char / of_char"]),
    4: (__test_636f7665726167655f746573742e6d6274_4, ["Cset::equal"]),
    5: (__test_636f7665726167655f746573742e6d6274_5, ["Cset::compare"]),
    6: (__test_636f7665726167655f746573742e6d6274_6, ["Cset::csingle / cadd / cseq"]),
    7: (__test_636f7665726167655f746573742e6d6274_7, ["Cset::add"]),
    8: (__test_636f7665726167655f746573742e6d6274_8, ["Cset::offset"]),
    9: (__test_636f7665726167655f746573742e6d6274_9, ["Cset::union_all"]),
    10: (__test_636f7665726167655f746573742e6d6274_10, ["Cset::intersect_all"]),
    11: (__test_636f7665726167655f746573742e6d6274_11, ["Cset::hash consistency"]),
    12: (__test_636f7665726167655f746573742e6d6274_12, ["Cset::hash differs for different sets"]),
    13: (__test_636f7665726167655f746573742e6d6274_13, ["Cset::iter"]),
    14: (__test_636f7665726167655f746573742e6d6274_14, ["Cset::pick"]),
    15: (__test_636f7665726167655f746573742e6d6274_15, ["Cset::pick empty raises"]),
    16: (__test_636f7665726167655f746573742e6d6274_16, ["Cset::union_singles_in_strictly_decreasing_order"]),
    17: (__test_636f7665726167655f746573742e6d6274_17, ["Cset::union_singles empty"]),
    18: (__test_636f7665726167655f746573742e6d6274_18, ["Cset::upper"]),
    19: (__test_636f7665726167655f746573742e6d6274_19, ["Cset::lower"]),
    20: (__test_636f7665726167655f746573742e6d6274_20, ["Cset::alpha"]),
    21: (__test_636f7665726167655f746573742e6d6274_21, ["Cset::alnum"]),
    22: (__test_636f7665726167655f746573742e6d6274_22, ["Cset::wordc"]),
    23: (__test_636f7665726167655f746573742e6d6274_23, ["Cset::xdigit"]),
    24: (__test_636f7665726167655f746573742e6d6274_24, ["Cset::space"]),
    25: (__test_636f7665726167655f746573742e6d6274_25, ["Cset::blank"]),
    26: (__test_636f7665726167655f746573742e6d6274_26, ["Cset::notnl"]),
    27: (__test_636f7665726167655f746573742e6d6274_27, ["Cset::nl"]),
    28: (__test_636f7665726167655f746573742e6d6274_28, ["Cset::ascii"]),
    29: (__test_636f7665726167655f746573742e6d6274_29, ["Cset::cntrl"]),
    30: (__test_636f7665726167655f746573742e6d6274_30, ["Cset::graph"]),
    31: (__test_636f7665726167655f746573742e6d6274_31, ["Cset::print"]),
    32: (__test_636f7665726167655f746573742e6d6274_32, ["Cset::punct"]),
    33: (__test_636f7665726167655f746573742e6d6274_33, ["Cset::case_insens"]),
    34: (__test_636f7665726167655f746573742e6d6274_34, ["CSetMap::empty / find / add"]),
    35: (__test_636f7665726167655f746573742e6d6274_35, ["Category::from_int / to_int roundtrip"]),
    36: (__test_636f7665726167655f746573742e6d6274_36, ["Category::equal"]),
    37: (__test_636f7665726167655f746573742e6d6274_37, ["Category::compare"]),
    38: (__test_636f7665726167655f746573742e6d6274_38, ["Category::add"]),
    39: (__test_636f7665726167655f746573742e6d6274_39, ["Category::dummy"]),
    40: (__test_636f7665726167655f746573742e6d6274_40, ["Category::inexistant"]),
    41: (__test_636f7665726167655f746573742e6d6274_41, ["Category::not_letter"]),
    42: (__test_636f7665726167655f746573742e6d6274_42, ["Category::lastnewline"]),
    43: (__test_636f7665726167655f746573742e6d6274_43, ["Category::search_boundary"]),
    44: (__test_636f7665726167655f746573742e6d6274_44, ["Category::from_char newline"]),
    45: (__test_636f7665726167655f746573742e6d6274_45, ["Pmark::compare"]),
    46: (__test_636f7665726167655f746573742e6d6274_46, ["Pmark::to_int"]),
    47: (__test_636f7665726167655f746573742e6d6274_47, ["PmarkSet::single"]),
    48: (__test_636f7665726167655f746573742e6d6274_48, ["PmarkSet::union"]),
    49: (__test_636f7665726167655f746573742e6d6274_49, ["PmarkSet::union dedup"]),
    50: (__test_636f7665726167655f746573742e6d6274_50, ["PmarkSet::iter"]),
    51: (__test_636f7665726167655f746573742e6d6274_51, ["PmarkSet::to_list"]),
    52: (__test_636f7665726167655f746573742e6d6274_52, ["PmarkSet::is_empty"]),
    53: (__test_636f7665726167655f746573742e6d6274_53, ["PmarkSet::equal"]),
    54: (__test_636f7665726167655f746573742e6d6274_54, ["MarkInfos::make and has"]),
    55: (__test_636f7665726167655f746573742e6d6274_55, ["MarkInfos::offset"]),
    56: (__test_636f7665726167655f746573742e6d6274_56, ["MarkInfos::start_offset / stop_offset"]),
    57: (__test_636f7665726167655f746573742e6d6274_57, ["MarkInfos::iteri"]),
    58: (__test_636f7665726167655f746573742e6d6274_58, ["MarkOffset::is_present false"]),
    59: (__test_636f7665726167655f746573742e6d6274_59, ["BitVector::set / get safe"]),
    60: (__test_636f7665726167655f746573742e6d6274_60, ["BitVector::set out of bounds raises"]),
    61: (__test_636f7665726167655f746573742e6d6274_61, ["BitVector::get out of bounds raises"]),
    62: (__test_636f7665726167655f746573742e6d6274_62, ["GroupT::get_opt matched"]),
    63: (__test_636f7665726167655f746573742e6d6274_63, ["GroupT::get_opt unmatched"]),
    64: (__test_636f7665726167655f746573742e6d6274_64, ["GroupT::offset_opt"]),
    65: (__test_636f7665726167655f746573742e6d6274_65, ["GroupT::start_opt / stop_opt"]),
    66: (__test_636f7665726167655f746573742e6d6274_66, ["GroupT::pmarks"]),
    67: (__test_636f7665726167655f746573742e6d6274_67, ["Re::rg"]),
    68: (__test_636f7665726167655f746573742e6d6274_68, ["Re::lower"]),
    69: (__test_636f7665726167655f746573742e6d6274_69, ["Re::upper"]),
    70: (__test_636f7665726167655f746573742e6d6274_70, ["Re::alnum"]),
    71: (__test_636f7665726167655f746573742e6d6274_71, ["Re::wordc"]),
    72: (__test_636f7665726167655f746573742e6d6274_72, ["Re::xdigit"]),
    73: (__test_636f7665726167655f746573742e6d6274_73, ["Re::notnl"]),
    74: (__test_636f7665726167655f746573742e6d6274_74, ["Re::ascii"]),
    75: (__test_636f7665726167655f746573742e6d6274_75, ["Re::cntrl"]),
    76: (__test_636f7665726167655f746573742e6d6274_76, ["Re::graph"]),
    77: (__test_636f7665726167655f746573742e6d6274_77, ["Re::print"]),
    78: (__test_636f7665726167655f746573742e6d6274_78, ["Re::punct"]),
    79: (__test_636f7665726167655f746573742e6d6274_79, ["exec returns group on match"]),
    80: (__test_636f7665726167655f746573742e6d6274_80, ["exec raises on no match"]),
    81: (__test_636f7665726167655f746573742e6d6274_81, ["exec_partial partial"]),
    82: (__test_636f7665726167655f746573742e6d6274_82, ["perl anchor ^"]),
    83: (__test_636f7665726167655f746573742e6d6274_83, ["perl anchor end of string"]),
    84: (__test_636f7665726167655f746573742e6d6274_84, ["perl \\s class"]),
    85: (__test_636f7665726167655f746573742e6d6274_85, ["perl \\w class"]),
    86: (__test_636f7665726167655f746573742e6d6274_86, ["perl {n} exact"]),
    87: (__test_636f7665726167655f746573742e6d6274_87, ["perl {n,} open-ended"]),
    88: (__test_636f7665726167655f746573742e6d6274_88, ["perl nested groups"]),
    89: (__test_636f7665726167655f746573742e6d6274_89, ["perl alternation with groups"]),
    90: (__test_636f7665726167655f746573742e6d6274_90, ["perl char class negation"]),
    91: (__test_636f7665726167655f746573742e6d6274_91, ["perl optional ? after group"]),
    92: (__test_636f7665726167655f746573742e6d6274_92, ["emacs char class"]),
    93: (__test_636f7665726167655f746573742e6d6274_93, ["emacs plus"]),
    94: (__test_636f7665726167655f746573742e6d6274_94, ["glob escape char"]),
    95: (__test_636f7665726167655f746573742e6d6274_95, ["pcre groups and alternation"]),
    96: (__test_636f7665726167655f746573742e6d6274_96, ["str string_match with pos"]),
    97: (__test_636f7665726167655f746573742e6d6274_97, ["str search_forward not found"]),
    98: (__test_636f7665726167655f746573742e6d6274_98, ["search matches with groups in result"]),
    99: (__test_636f7665726167655f746573742e6d6274_99, ["replace with function all=false"]),
    100: (__test_636f7665726167655f746573742e6d6274_100, ["exec_partial_detailed partial"]),
    101: (__test_636f7665726167655f746573742e6d6274_101, ["exec_partial_detailed mismatch"]),
    102: (__test_636f7665726167655f746573742e6d6274_102, ["Re::mark_test and mark_all"]),
    103: (__test_636f7665726167655f746573742e6d6274_103, ["match_str groups=true partial=false"]),
    104: (__test_636f7665726167655f746573742e6d6274_104, ["match_str groups=false partial=false"]),
    105: (__test_636f7665726167655f746573742e6d6274_105, ["match_str groups=true partial=true"]),
    106: (__test_636f7665726167655f746573742e6d6274_106, ["match_str groups=false partial=true"]),
    107: (__test_636f7665726167655f746573742e6d6274_107, ["match_str pos negative bounds raise"]),
    108: (__test_636f7665726167655f746573742e6d6274_108, ["match_str_no_bounds len below -1 no raise"]),
    109: (__test_636f7665726167655f746573742e6d6274_109, ["match_str pos+len overflow bounds raise"]),
    110: (__test_636f7665726167655f746573742e6d6274_110, ["pcre exec no match raise"]),
    111: (__test_636f7665726167655f746573742e6d6274_111, ["pcre get_named_substring not found raise"]),
    112: (__test_636f7665726167655f746573742e6d6274_112, ["pcre get_named_substring opt boundary"]),
    113: (__test_636f7665726167655f746573742e6d6274_113, ["str match_beginning no match raise"]),
    114: (__test_636f7665726167655f746573742e6d6274_114, ["str match_end no match raise"]),
    115: (__test_636f7665726167655f746573742e6d6274_115, ["str matched_string no match raise"]),
    116: (__test_636f7665726167655f746573742e6d6274_116, ["str group_beginning out of bounds raise"]),
  },
  "core_test.mbt": {
    0: (__test_636f72655f746573742e6d6274_0, ["exec_opt basic match"]),
    1: (__test_636f72655f746573742e6d6274_1, ["exec_opt no match"]),
    2: (__test_636f72655f746573742e6d6274_2, ["exec_opt with pos"]),
    3: (__test_636f72655f746573742e6d6274_3, ["execp basic"]),
    4: (__test_636f72655f746573742e6d6274_4, ["execp with pos"]),
    5: (__test_636f72655f746573742e6d6274_5, ["group get and offsets"]),
    6: (__test_636f72655f746573742e6d6274_6, ["group matched and nb_groups"]),
    7: (__test_636f72655f746573742e6d6274_7, ["group all"]),
    8: (__test_636f72655f746573742e6d6274_8, ["group all_offset"]),
    9: (__test_636f72655f746573742e6d6274_9, ["search all basic"]),
    10: (__test_636f72655f746573742e6d6274_10, ["search matches basic"]),
    11: (__test_636f72655f746573742e6d6274_11, ["search all with groups"]),
    12: (__test_636f72655f746573742e6d6274_12, ["search split basic"]),
    13: (__test_636f72655f746573742e6d6274_13, ["search split no delimiter"]),
    14: (__test_636f72655f746573742e6d6274_14, ["search split with leading/trailing delim"]),
    15: (__test_636f72655f746573742e6d6274_15, ["search split_delim with leading/trailing"]),
    16: (__test_636f72655f746573742e6d6274_16, ["search split_full basic"]),
    17: (__test_636f72655f746573742e6d6274_17, ["replace_string all"]),
    18: (__test_636f72655f746573742e6d6274_18, ["replace_string first only"]),
    19: (__test_636f72655f746573742e6d6274_19, ["replace with function"]),
    20: (__test_636f72655f746573742e6d6274_20, ["exec_partial full match"]),
    21: (__test_636f72655f746573742e6d6274_21, ["exec_partial mismatch"]),
    22: (__test_636f72655f746573742e6d6274_22, ["exec_partial_detailed full"]),
    23: (__test_636f72655f746573742e6d6274_23, ["char class digit"]),
    24: (__test_636f72655f746573742e6d6274_24, ["char class alpha"]),
    25: (__test_636f72655f746573742e6d6274_25, ["char class space"]),
    26: (__test_636f72655f746573742e6d6274_26, ["exec_opt empty string match"]),
    27: (__test_636f72655f746573742e6d6274_27, ["search matches empty pattern"]),
    28: (__test_636f72655f746573742e6d6274_28, ["replace no match"]),
  },
  "compile_test.mbt": {
    0: (__test_636f6d70696c655f746573742e6d6274_0, ["compile and match: single char 'a'"]),
    1: (__test_636f6d70696c655f746573742e6d6274_1, ["compile and match: single char 'a' no match 'b'"]),
    2: (__test_636f6d70696c655f746573742e6d6274_2, ["compile and match: 'a' in 'abc'"]),
    3: (__test_636f6d70696c655f746573742e6d6274_3, ["compile and match: 'b' in 'abc' at pos 1"]),
    4: (__test_636f6d70696c655f746573742e6d6274_4, ["compile and match: 'abc' matches 'abc'"]),
    5: (__test_636f6d70696c655f746573742e6d6274_5, ["compile and match: 'abc' no match 'abd'"]),
    6: (__test_636f6d70696c655f746573742e6d6274_6, ["compile and match: 'a*' matches 'aaa'"]),
    7: (__test_636f6d70696c655f746573742e6d6274_7, ["compile and match: 'a*' matches empty"]),
    8: (__test_636f6d70696c655f746573742e6d6274_8, ["compile and match: 'a|b' matches 'a'"]),
    9: (__test_636f6d70696c655f746573742e6d6274_9, ["compile and match: 'a|b' matches 'b'"]),
    10: (__test_636f6d70696c655f746573742e6d6274_10, ["compile and match: 'a|b' no match 'c'"]),
    11: (__test_636f6d70696c655f746573742e6d6274_11, ["compile and match: 'a+' matches 'aaa'"]),
    12: (__test_636f6d70696c655f746573742e6d6274_12, ["compile and match: 'a+' no match empty"]),
    13: (__test_636f6d70696c655f746573742e6d6274_13, ["compile and match: 'a?' matches 'a'"]),
    14: (__test_636f6d70696c655f746573742e6d6274_14, ["compile and match: 'a?' matches empty"]),
    15: (__test_636f6d70696c655f746573742e6d6274_15, ["compile and match: any matches 'x'"]),
    16: (__test_636f6d70696c655f746573742e6d6274_16, ["compile and match: 'a*b' matches 'aaab'"]),
    17: (__test_636f6d70696c655f746573742e6d6274_17, ["compile and match: 'a*b' matches 'b'"]),
    18: (__test_636f6d70696c655f746573742e6d6274_18, ["compile and match: 'a*b' no match 'aaa'"]),
    19: (__test_636f6d70696c655f746573742e6d6274_19, ["compile and match: whole_string 'abc' matches 'abc'"]),
    20: (__test_636f6d70696c655f746573742e6d6274_20, ["compile and match: whole_string 'abc' no match 'abcd'"]),
  },
  "color_map_test.mbt": {
    0: (__test_636f6c6f725f6d61705f746573742e6d6274_0, ["ColorMap empty flatten"]),
    1: (__test_636f6c6f725f6d61705f746573742e6d6274_1, ["ColorMap single char split"]),
    2: (__test_636f6c6f725f6d61705f746573742e6d6274_2, ["ColorMap two chars split"]),
    3: (__test_636f6c6f725f6d61705f746573742e6d6274_3, ["ColorMap translate_colors"]),
    4: (__test_636f6c6f725f6d61705f746573742e6d6274_4, ["colorize single char matches manual split"]),
    5: (__test_636f6c6f725f6d61705f746573742e6d6274_5, ["colorize str matches manual split"]),
    6: (__test_636f6c6f725f6d61705f746573742e6d6274_6, ["colorize alternative matches manual split"]),
  },
  "basics_test.mbt": {
    0: (__test_6261736963735f746573742e6d6274_0, ["cset empty"]),
    1: (__test_6261736963735f746573742e6d6274_1, ["cset single"]),
    2: (__test_6261736963735f746573742e6d6274_2, ["cset cany"]),
    3: (__test_6261736963735f746573742e6d6274_3, ["cset union disjoint"]),
    4: (__test_6261736963735f746573742e6d6274_4, ["cset union overlapping"]),
    5: (__test_6261736963735f746573742e6d6274_5, ["cset union adjacent"]),
    6: (__test_6261736963735f746573742e6d6274_6, ["cset inter"]),
    7: (__test_6261736963735f746573742e6d6274_7, ["cset diff"]),
    8: (__test_6261736963735f746573742e6d6274_8, ["cset cdigit"]),
    9: (__test_6261736963735f746573742e6d6274_9, ["cset set from bytes"]),
    10: (__test_6261736963735f746573742e6d6274_10, ["cset one_char"]),
    11: (__test_6261736963735f746573742e6d6274_11, ["pmark gen unique"]),
    12: (__test_6261736963735f746573742e6d6274_12, ["pmarkset mem/add"]),
    13: (__test_6261736963735f746573742e6d6274_13, ["pmarkset dedup"]),
    14: (__test_6261736963735f746573742e6d6274_14, ["category from_char"]),
    15: (__test_6261736963735f746573742e6d6274_15, ["category intersect"]),
    16: (__test_6261736963735f746573742e6d6274_16, ["bitvector basic"]),
    17: (__test_6261736963735f746573742e6d6274_17, ["hashset basic"]),
    18: (__test_6261736963735f746573742e6d6274_18, ["hashset dedup"]),
  },
  "automata_test.mbt": {
    0: (__test_6175746f6d6174615f746573742e6d6274_0, ["State::create and dummy"]),
    1: (__test_6175746f6d6174615f746573742e6d6274_1, ["State::equal - self equality"]),
    2: (__test_6175746f6d6174615f746573742e6d6274_2, ["delta: regex 'a' with matching char"]),
    3: (__test_6175746f6d6174615f746573742e6d6274_3, ["delta: regex 'a' with non-matching char"]),
    4: (__test_6175746f6d6174615f746573742e6d6274_4, ["advance: regex 'a' after matching delta"]),
    5: (__test_6175746f6d6174615f746573742e6d6274_5, ["delta: regex 'a*' with matching char stays running"]),
    6: (__test_6175746f6d6174615f746573742e6d6274_6, ["advance: regex 'a*' after non-matching char gives match"]),
    7: (__test_6175746f6d6174615f746573742e6d6274_7, ["WorkingArea::free_index returns 0 for empty desc"]),
    8: (__test_6175746f6d6174615f746573742e6d6274_8, ["delta: regex 'ab' (sequence) with 'a' then 'b'"]),
    9: (__test_6175746f6d6174615f746573742e6d6274_9, ["delta: regex 'a|b' (alternative) with 'a'"]),
    10: (__test_6175746f6d6174615f746573742e6d6274_10, ["delta: regex 'a|b' (alternative) with 'b'"]),
    11: (__test_6175746f6d6174615f746573742e6d6274_11, ["delta: regex 'a|b' (alternative) with 'c' fails"]),
    12: (__test_6175746f6d6174615f746573742e6d6274_12, ["delta: regex eps matches immediately"]),
    13: (__test_6175746f6d6174615f746573742e6d6274_13, ["expr rename Cst preserves cset with new id"]),
    14: (__test_6175746f6d6174615f746573742e6d6274_14, ["expr rename Seq recursively renames children"]),
    15: (__test_6175746f6d6174615f746573742e6d6274_15, ["expr rename Alt recursively renames all children"]),
    16: (__test_6175746f6d6174615f746573742e6d6274_16, ["expr rename Rep recursively renames child"]),
  },
  "ast_test.mbt": {
    0: (__test_6173745f746573742e6d6274_0, ["Ast::char constructs single char"]),
    1: (__test_6173745f746573742e6d6274_1, ["Ast::str constructs sequence"]),
    2: (__test_6173745f746573742e6d6274_2, ["Ast::any matches all"]),
    3: (__test_6173745f746573742e6d6274_3, ["Ast::empty is empty alt"]),
    4: (__test_6173745f746573742e6d6274_4, ["Ast::alt single element returns element"]),
    5: (__test_6173745f746573742e6d6274_5, ["Ast::alt empty returns empty"]),
    6: (__test_6173745f746573742e6d6274_6, ["Ast::alt multiple elements"]),
    7: (__test_6173745f746573742e6d6274_7, ["Ast::epsilon is empty seq"]),
    8: (__test_6173745f746573742e6d6274_8, ["Ast::repn basic"]),
    9: (__test_6173745f746573742e6d6274_9, ["Ast::repn 1,1 returns original"]),
    10: (__test_6173745f746573742e6d6274_10, ["Ast::anchored BegOfStr"]),
    11: (__test_6173745f746573742e6d6274_11, ["Ast::anchored Start"]),
    12: (__test_6173745f746573742e6d6274_12, ["Ast::anchored char is false"]),
    13: (__test_6173745f746573742e6d6274_13, ["Ast::anchored seq with bos"]),
    14: (__test_6173745f746573742e6d6274_14, ["Ast::anchored repeat with min>0"]),
    15: (__test_6173745f746573742e6d6274_15, ["Ast::anchored repeat with min=0"]),
    16: (__test_6173745f746573742e6d6274_16, ["Ast::anchored group"]),
    17: (__test_6173745f746573742e6d6274_17, ["Ast::handle_case basic"]),
    18: (__test_6173745f746573742e6d6274_18, ["Ast::case wraps with Case"]),
    19: (__test_6173745f746573742e6d6274_19, ["Ast::no_case wraps with NoCase"]),
    20: (__test_6173745f746573742e6d6274_20, ["Ast::mark returns pmark and marked ast"]),
    21: (__test_6173745f746573742e6d6274_21, ["Ast::seq single returns element"]),
    22: (__test_6173745f746573742e6d6274_22, ["Ast::seq multiple returns Sequence"]),
  },
}


///|
impl MoonBit_Test_Driver for MoonBit_Test_Driver_Internal_No_Args with fn run_test(
  _,
  filename,
  index,
  handle_start,
  handle_result,
  error_to_string,
) {
  if moonbit_test_driver_internal_no_args_tests.0.get(filename)
    is Some(index_map) &&
    index_map.get(index) is Some((f, attrs)) {
    let name = if attrs is [name, ..] { name } else { "" }
    if MOONBIT_TEST_DRIVER_INTERNAL_IS_NATIVE {
      for attr in attrs {
        if attr is [.. "panic", ..] {
          raise MoonBitTestDriverInternalSkipTest(name~)
        }
      }
    }
    handle_start()
    moonbit_test_driver_internal_catch_error(
      f,
      on_ok=() => handle_result(name, "", false),
      on_err=err => handle_result(name, error_to_string(err), false),
    )
    true
  } else {
    false
  }
}
///|
#cfg(any(target="native", target="llvm"))
#test_entry
fn main {
  let async_tests = []
  for arg in moonbit_test_driver_internal_native_parse_args() {
    moonbit_test_driver_internal_do_execute(async_tests, arg.0, arg.1)
  }
  MoonBit_Async_Test_Driver_Impl::run_async_tests(async_tests)
}

///|
#cfg(target="js")
#test_entry
fn main {
  let test_params = moonbit_test_driver_js_parse_args()
  moonbit_test_driver_internal_execute(test_params)
  moonbit_test_driver_finish()
}

///|
#cfg(any(target="wasm", target="wasm-gc"))
#test_entry
fn main {
  ()
}

///|
#cfg(target="js")
extern "js" fn moonbit_test_driver_js_parse_args() -> Array[
  MoonBitTestDriverInternalTestEntry,
] =
  #|() => {
  #|  try {
  #|    let testParams = []
  #|    // check if there is command line argument
  #|    if (process.argv.length > 2) {
  #|      const testArgs = JSON.parse(process.argv[2])
  #|      testParams = testArgs.file_and_index.flatMap(([file, ranges]) => {
  #|        let arr = []
  #|        for (let range of ranges) {
  #|          for (let i = range.start; i < range.end; i++) {
  #|            arr.push([file, i])
  #|          }
  #|        }
  #|        return arr
  #|      })
  #|      return testParams
  #|    }
  #|  } catch (error) {
  #|    console.error('failed to parse args: ', error.message)
  #|    process.exit(1)
  #|  }
  #|}

///|
/// Executes selected JavaScript tests from parsed test entries.
#cfg(target="js")
pub fn moonbit_test_driver_internal_execute(
  tests : Array[MoonBitTestDriverInternalTestEntry],
) -> Unit {
  let async_tests = []
  for i in 0..<tests.length() {
    let entry = tests[i]
    moonbit_test_driver_internal_do_execute(
      async_tests,
      entry.filename(),
      entry.index(),
    )
  }
  MoonBit_Async_Test_Driver_Impl::run_async_tests(async_tests)
}

///|
#cfg(target="wasm")
let moonbit_test_driver_internal_wasm_async_tests : Array[async () -> Unit] = []

///|
/// Executes one selected WebAssembly test and stores async work for finalization.
#cfg(target="wasm")
pub fn moonbit_test_driver_internal_execute(
  filename : MoonbitTestDriverInternalExternString,
  index : Int,
) -> Unit {
  let filename = moonbit_test_driver_internal_get_file_name(filename)
  moonbit_test_driver_internal_do_execute(
    moonbit_test_driver_internal_wasm_async_tests, filename, index,
  )
}

///|
/// Executes one selected WebAssembly GC test and drains async work immediately.
#cfg(target="wasm-gc")
pub fn moonbit_test_driver_internal_execute(
  filename : MoonbitTestDriverInternalExternString,
  index : Int,
) -> Unit {
  let filename = moonbit_test_driver_internal_get_file_name(filename)
  let async_tests = []
  moonbit_test_driver_internal_do_execute(async_tests, filename, index)
  MoonBit_Async_Test_Driver_Impl::run_async_tests(async_tests)
}

///|
/// Finishes pending WebAssembly async tests and coverage collection.
#cfg(target="wasm")
pub fn moonbit_test_driver_finish() -> Unit {
  MoonBit_Async_Test_Driver_Impl::run_async_tests(
    moonbit_test_driver_internal_wasm_async_tests,
  )
  
}

///|
/// Finishes coverage collection for backends without pending async work.
#cfg(any(target="js", target="wasm-gc"))
pub fn moonbit_test_driver_finish() -> Unit {
  
}

///|
fn moonbit_test_driver_internal_do_execute(
  async_tests : Array[async () -> Unit],
  filename : String,
  index : Int,
) -> Unit {
  // These two are internalized to avoid unused warnings

  fn handle_start() {
    let file_name = filename.escape()
    @moonbitlang/core/prelude.println("----- BEGIN MOON TEST RESULT -----")
    @moonbitlang/core/prelude.println(
      "{\"type\":\"start\",\"file\":\{file_name},\"index\":\{index}}",
    )
    @moonbitlang/core/prelude.println("----- END MOON TEST RESULT -----")
  }

  fn handle_result(_testname : String, message : String, skipped : Bool) {
    // In WASM, this function is called by the external test driver, but here
    // in native mode there's nothing that calls it, so we call it manually.
    if !skipped && MOONBIT_TEST_DRIVER_INTERNAL_IS_NATIVE {
      
    }
    let file_name = filename.escape()
    let message = message.escape()
    @moonbitlang/core/prelude.println("----- BEGIN MOON TEST RESULT -----")
    @moonbitlang/core/prelude.println(
      "{\"type\":\"result\",\"file\":\{file_name},\"index\":\{index},\"message\":\{message}}",
    )
    @moonbitlang/core/prelude.println("----- END MOON TEST RESULT -----")
  }

  fn error_to_string(err : Error) -> String {
    match err {
      @moonbitlang/core/prelude.Failure::Failure(e)
      | @moonbitlang/core/prelude.InspectError::InspectError(e)
      | @moonbitlang/core/prelude.SnapshotError::SnapshotError(e)
      | MoonBitTestDriverInternalJsError(e) => e
      e => moonbit_test_driver_internal_error_to_string(e)
    }
  }

  try {
    if !(MoonBit_Test_Driver_Internal_No_Args::run_test(
        async_tests, filename, index, handle_start, handle_result, error_to_string,
      ) ||
      MoonBit_Test_Driver_Internal_With_Args::run_test(
        async_tests, filename, index, handle_start, handle_result, error_to_string,
      ) ||
      MoonBit_Test_Driver_Internal_Async_No_Args::run_test(
        async_tests, filename, index, handle_start, handle_result, error_to_string,
      ) ||
      MoonBit_Test_Driver_Internal_Async_With_Args::run_test(
        async_tests, filename, index, handle_start, handle_result, error_to_string,
      ) ||
      MoonBit_Test_Driver_Internal_With_Bench_Args::run_test(
        async_tests, filename, index, handle_start, handle_result, error_to_string,
      )) {
      raise MoonBitTestDriverInternalSkipTest(name="")
    }
  } catch {
    err => {
      guard err is MoonBitTestDriverInternalSkipTest(name~)
      handle_result(name, "skipped test", true)
    }
  }
}
