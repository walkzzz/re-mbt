// Sectioned benchmark with timing - uses top-level let for section selection
// Modify bench_section to run only one section (0 = all)
// Timing via C clock() FFI (native backend). CLOCKS_PER_SEC = 1000 on Windows.

///|
extern "c" fn clock() -> Int32 = "clock"

///|
let clocks_per_sec : Int32 = 1000

///|
let bench_section : Int32 = 0

///|
fn sb(s : String) -> Bytes {
  let arr : Array[Byte] = []
  for c in s {
    arr.push(c.to_int().to_byte())
  }
  Bytes::from_array(arr)
}

///|
fn gen_input(len : Int32, ch : Char) -> Bytes {
  let arr : Array[Byte] = []
  for _ in 0..<len {
    arr.push(ch.to_int().to_byte())
  }
  Bytes::from_array(arr)
}

///|
fn gen_mixed_input(len : Int32) -> Bytes {
  let arr : Array[Byte] = []
  let chars = "abcdefghij"
  for i in 0..<len {
    let ci = i % chars.length()
    arr.push(chars[ci].to_int().to_byte())
  }
  Bytes::from_array(arr)
}

///|
fn gen_email_input(count : Int32) -> Bytes {
  let arr : Array[Byte] = []
  let s = "user@example.com, "
  for _ in 0..<count {
    for c in s {
      arr.push(c.to_int().to_byte())
    }
  }
  Bytes::from_array(arr)
}

///|
fn[T] ignore(_ : T) -> Unit {
  ()
}

///|
fn fmt_ms(elapsed_ticks : Int32) -> String {
  let ms = elapsed_ticks * 1000 / clocks_per_sec
  ms.to_string() + " ms"
}

///|
fn run_section(sec : Int32, name : String, f : () -> Unit) -> Unit {
  if bench_section == 0 || bench_section == sec {
    let start = clock()
    f()
    let elapsed = clock() - start
    println(
      "Section " + sec.to_string() + " [" + name + "]: " + fmt_ms(elapsed),
    )
  }
}

///|
fn main {
  let iters = 5000
  let re_simple = try! @frontend.Perl::compile_pat(sb("hello"))
  let re_star = try! @frontend.Perl::compile_pat(sb("a*b"))
  let re_alt = try! @frontend.Perl::compile_pat(sb("(a|b)*c"))
  let re_email = try! @frontend.Perl::compile_pat(sb("[a-z]+@[a-z]+\\.[a-z]+"))
  let re_word = try! @frontend.Perl::compile_pat(sb("(\\w+\\s*)+"))
  let re_emacs = try! @frontend.Emacs::compile_pat(sb("[a-z]+"))
  let re_posix = try! @frontend.Posix::compile_pat(sb("(a|b)*c"))
  let re_glob = try! @frontend.Glob::compile(sb("*.txt"))
  let re_pcre = try! @frontend.Pcre::regexp(sb("[a-z]+@[a-z]+\\.[a-z]+"))
  let re_str = try! @frontend.Str::regexp(sb("[a-z]+"))
  let re_split = try! @frontend.Perl::compile_pat(sb("\\s+"))
  let re_large = try! @frontend.Perl::compile_pat(sb("a.*b"))
  let re_caseless = try! @frontend.Perl::compile_pat(sb("hello"), opts=[
    @frontend.PerlOpt::caseless(),
  ])

  let input_small = sb("hello")
  let input_medium = gen_mixed_input(100)
  let input_large = gen_mixed_input(1000)
  let input_email = gen_email_input(50)
  let split_input = sb("a b  c   d    e     f")
  let input_aaaa = gen_input(500, 'a')

  let patterns = [
    sb("hello"),
    sb("a*b"),
    sb("(a|b)*c"),
    sb("[a-z]+@[a-z]+\\.[a-z]+"),
    sb("(\\w+\\s*)+"),
    sb("a{2,5}b*c?"),
    sb("(?:ab|cd|ef)+"),
    sb("[^aeiou][aeiou][^aeiou]"),
  ]

  let total_start = clock()

  // Section 1: Perl compile
  run_section(1, "Perl compile", fn() {
    for _ in 0..<iters {
      for p in patterns {
        ignore(try! @frontend.Perl::compile_pat(p))
      }
    }
  })

  // Section 2: Perl match
  run_section(2, "Perl match", fn() {
    for _ in 0..<iters {
      ignore(try! @compile.execp(re_simple, input_small))
      ignore(try! @compile.execp(re_star, gen_input(50, 'a')))
      ignore(try! @compile.execp(re_alt, input_medium))
      ignore(try! @compile.execp(re_email, input_email))
      ignore(try! @compile.execp(re_word, input_large))
    }
  })

  // Section 3: Emacs
  run_section(3, "Emacs", fn() {
    for _ in 0..<iters {
      ignore(try! @frontend.Emacs::compile_pat(sb("hello")))
      ignore(try! @frontend.Emacs::compile_pat(sb("a*b")))
      ignore(try! @frontend.Emacs::compile_pat(sb("[a-z]+")))
      ignore(try! @compile.execp(re_emacs, input_medium))
    }
  })

  // Section 4: POSIX
  run_section(4, "POSIX", fn() {
    for _ in 0..<iters {
      ignore(try! @frontend.Posix::compile(sb("hello")))
      ignore(try! @frontend.Posix::compile(sb("a*b")))
      ignore(try! @frontend.Posix::compile(sb("(a|b)*c")))
      ignore(try! @compile.execp(re_posix, input_medium))
    }
  })

  // Section 5: Glob
  run_section(5, "Glob", fn() {
    for _ in 0..<iters {
      ignore(try! @frontend.Glob::compile(sb("*.txt")))
      ignore(try! @frontend.Glob::compile(sb("a*b")))
      ignore(try! @frontend.Glob::compile(sb("?.*")))
      ignore(try! @compile.execp(re_glob, sb("hello.txt")))
    }
  })

  // Section 6: Pcre
  run_section(6, "Pcre", fn() {
    for _ in 0..<iters {
      ignore(try! @frontend.Pcre::regexp(sb("hello")))
      ignore(try! @frontend.Pcre::regexp(sb("[a-z]+@[a-z]+\\.[a-z]+")))
      ignore(try! @frontend.Pcre::pmatch(re_pcre, input_email))
    }
  })

  // Section 7: Str
  run_section(7, "Str", fn() {
    for _ in 0..<iters {
      ignore(try! @frontend.Str::regexp(sb("hello")))
      ignore(try! @frontend.Str::regexp(sb("[a-z]+")))
      ignore(try! @frontend.Str::string_match(re_str, input_medium, 0))
    }
  })

  // Section 8: Search
  run_section(8, "Search", fn() {
    for _ in 0..<iters {
      ignore(try! @exec.Search::all(re_word, input_large))
      ignore(try! @exec.Search::matches(re_word, input_large))
    }
  })

  // Section 9: Split + Replace
  run_section(9, "Split+Replace", fn() {
    for _ in 0..<iters {
      ignore(try! @exec.Search::split(re_split, split_input))
      ignore(
        try! @exec.Replace::replace_string(re_split, split_input, by=sb("_")),
      )
    }
  })

  // Section 10: Large + Caseless
  run_section(10, "Large+Caseless", fn() {
    for _ in 0..<iters {
      ignore(try! @compile.execp(re_large, input_aaaa))
      ignore(try! @compile.execp(re_caseless, sb("HELLO")))
    }
  })

  let total_elapsed = clock() - total_start
  println("Total: " + fmt_ms(total_elapsed))
  println("done")
}
