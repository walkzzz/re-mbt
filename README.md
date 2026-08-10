# re-mbt

A port of [ocaml-re](https://github.com/ocaml/ocaml-re) — the pure OCaml regular expression library — to idiomatic MoonBit.

## Status

Work in progress. Porting in behavioral slices from the bottom up:

- [x] Project skeleton (`moon.mod.json`, `re/` package)
- [x] Basic data structures: `Pmark`, `Category`, `BitVector`, `DenseMap`, `HashSet`, `Slice`, `Dyn`, `Fmt`, `Cset`
- [ ] AST and auxiliaries: `Ast`, `ColorMap`, `MarkInfos`, `PosixClass`, `ParseBuffer`
- [ ] `Automata` (Brzozowski/Antimirov derivatives)
- [ ] `Compile` (lazy DFA driver)
- [ ] `Core` / `Group` / `Replace` / `Search`
- [ ] Frontends: `Perl`, `Pcre`, `Posix`, `Emacs`, `Glob`, `Str`
- [ ] `Stream`, `View`

## Design

- **Single `re` package**, internal modules mapped 1:1 from OCaml (`cset.mbt`, `ast.mbt`, `automata.mbt`, ...).
- **Matching engine**: faithful port of the lazy DFA with Brzozowski/Antimirov derivatives (linear-time matching, no catastrophic backtracking).
- **Byte-oriented**: OCaml `string` is a byte sequence; the port uses MoonBit `Bytes` for input text, patterns, and captured substrings. `String`-typed conveniences may be layered later.
- **Pure MoonBit**, no C FFI. Targets: native, wasm, js.
- **latin1** case handling, matching upstream.

## License

Upstream is LGPL-2.1-or-later WITH OCaml-LGPL-linking-exception; this port preserves the same license.
