name = "walkzzz/re-mbt"

version = "0.2.1"

description = "A port of ocaml-re — the pure OCaml regular expression library — to idiomatic MoonBit. Linear-time matching via lazy DFA with Brzozowski/Antimirov derivatives. Frontends: Perl, PCRE, POSIX, Emacs, Glob, Str."

readme = "README.md"

license = "LGPL-2.1-or-later"

repository = "https://github.com/walkzzz/re-mbt"

keywords = [ "regex", "regexp", "regular-expression", "ocaml-re", "port" ]

preferred_target = "wasm"

supported_targets = "+wasm+wasm-gc+js+native"

import {
  "moonbitlang/x@0.4.48",
}
