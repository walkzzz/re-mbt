// Sectioned benchmark - uses top-level let for section selection
// Modify bench_section to run only one section (0 = all)

///|
let bench_section : Int = 0

///|
fn sb(s : String) -> Bytes {
  let arr : Array[Byte] = []
  for c in s {
    arr.push(c.to_int().to_byte())
  }
  Bytes::from_array(arr)
}

///|
fn gen_input(len : Int, ch : Char) -> Bytes {
  let arr : Array[Byte] = []
  for _ in 0..<len {
    arr.push(ch.to_int().to_byte())
  }
  Bytes::from_array(arr)
}

///|
fn gen_mixed_input(len : Int) -> Bytes {
  let arr : Array[Byte] = []
  let chars = "abcdefghij"
  for i in 0..<len {
    let ci = i % chars.length()
    arr.push(chars[ci].to_int().to_byte())
  }
  Bytes::from_array(arr)
}

///|
fn gen_email_input(count : Int) -> Bytes {
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
fn run_section(sec : Int, f : () -> Unit) -> Unit {
  if bench_section == 0 || bench_section == sec {
    f()
  }
}

///|
fn main {
  let iters = 5000
  let re_simple = try! @re.Perl::compile_pat(sb("hello"))
  let re_star = try! @re.Perl::compile_pat(sb("a*b"))
  let re_alt = try! @re.Perl::compile_pat(sb("(a|b)*c"))
  let re_email = try! @re.Perl::compile_pat(sb("[a-z]+@[a-z]+\\.[a-z]+"))
  let re_word = try! @re.Perl::compile_pat(sb("(\\w+\\s*)+"))
  let re_emacs = try! @re.Emacs::compile_pat(sb("[a-z]+"))
  let re_posix = try! @re.Posix::compile_pat(sb("(a|b)*c"))
  let re_glob = try! @re.Glob::compile(sb("*.txt"))
  let re_pcre = try! @re.Pcre::regexp(sb("[a-z]+@[a-z]+\\.[a-z]+"))
  let re_str = try! @re.Str::regexp(sb("[a-z]+"))
  let re_split = try! @re.Perl::compile_pat(sb("\\s+"))
  let re_large = try! @re.Perl::compile_pat(sb("a.*b"))
  let re_caseless = try! @re.Perl::compile_pat(sb("hello"), opts=[
    @re.PerlOpt::caseless(),
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

  // Section 1: Perl compile
  run_section(1, fn() {
    for _ in 0..<iters {
      for p in patterns {
        ignore(try! @re.Perl::compile_pat(p))
      }
    }
  })

  // Section 2: Perl match
  run_section(2, fn() {
    for _ in 0..<iters {
      ignore(try! @re.execp(re_simple, input_small))
      ignore(try! @re.execp(re_star, gen_input(50, 'a')))
      ignore(try! @re.execp(re_alt, input_medium))
      ignore(try! @re.execp(re_email, input_email))
      ignore(try! @re.execp(re_word, input_large))
    }
  })

  // Section 3: Emacs
  run_section(3, fn() {
    for _ in 0..<iters {
      ignore(try! @re.Emacs::compile_pat(sb("hello")))
      ignore(try! @re.Emacs::compile_pat(sb("a*b")))
      ignore(try! @re.Emacs::compile_pat(sb("[a-z]+")))
      ignore(try! @re.execp(re_emacs, input_medium))
    }
  })

  // Section 4: POSIX
  run_section(4, fn() {
    for _ in 0..<iters {
      ignore(try! @re.Posix::compile(sb("hello")))
      ignore(try! @re.Posix::compile(sb("a*b")))
      ignore(try! @re.Posix::compile(sb("(a|b)*c")))
      ignore(try! @re.execp(re_posix, input_medium))
    }
  })

  // Section 5: Glob
  run_section(5, fn() {
    for _ in 0..<iters {
      ignore(try! @re.Glob::compile(sb("*.txt")))
      ignore(try! @re.Glob::compile(sb("a*b")))
      ignore(try! @re.Glob::compile(sb("?.*")))
      ignore(try! @re.execp(re_glob, sb("hello.txt")))
    }
  })

  // Section 6: Pcre
  run_section(6, fn() {
    for _ in 0..<iters {
      ignore(try! @re.Pcre::regexp(sb("hello")))
      ignore(try! @re.Pcre::regexp(sb("[a-z]+@[a-z]+\\.[a-z]+")))
      ignore(try! @re.Pcre::pmatch(re_pcre, input_email))
    }
  })

  // Section 7: Str
  run_section(7, fn() {
    for _ in 0..<iters {
      ignore(try! @re.Str::regexp(sb("hello")))
      ignore(try! @re.Str::regexp(sb("[a-z]+")))
      ignore(try! @re.Str::string_match(re_str, input_medium, 0))
    }
  })

  // Section 8: Search
  run_section(8, fn() {
    for _ in 0..<iters {
      ignore(try! @re.Search::all(re_word, input_large))
      ignore(try! @re.Search::matches(re_word, input_large))
    }
  })

  // Section 9: Split + Replace
  run_section(9, fn() {
    for _ in 0..<iters {
      ignore(try! @re.Search::split(re_split, split_input))
      ignore(
        try! @re.Replace::replace_string(re_split, split_input, by=sb("_")),
      )
    }
  })

  // Section 10: Large + Caseless
  run_section(10, fn() {
    for _ in 0..<iters {
      ignore(try! @re.execp(re_large, input_aaaa))
      ignore(try! @re.execp(re_caseless, sb("HELLO")))
    }
  })

  println("done")
}
