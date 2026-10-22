///|
pub using @base {
  type BitVector,
  type CSetMap,
  type Category,
  type Cset,
  type CsetC,
  type DenseMap,
  type Dyn,
  type HashSet,
  type Ids,
  type Idx,
  type Mark,
  type MarkInfos,
  type MarkOffset,
  type ParseBuffer,
  type Pmark,
  type PmarkSet,
  type RepKind,
  type Sem,
  bs,
  hash_combine,
  sb,
}

///|
pub using @ast {
  type Ast,
  type AstCset,
  type AstGen,
  type AstNoCase,
  type BoundaryTable,
  type ColorMap,
  type ColorRepr,
  type ColorTable,
  type Desc,
  type ET,
  type Expr,
  type Marks,
  type State,
  type Status,
  type WorkingArea,
  advance,
  delta,
}

///|
pub using @compile {
  type CompileIdx,
  type CompileState,
  type ExecPartialDetailedResult,
  type ExecPartialResult,
  type GroupT,
  type MatchInfo,
  type Positions,
  type Re,
  type StateHashTable,
  type StateInfo,
  compile,
  copy_re,
  exec,
  exec_opt,
  exec_partial,
  exec_partial_detailed,
  execp,
  match_str,
  match_str_no_bounds,
  match_str_p,
  mk_re,
}

///|
pub using @exec {
  type CsetView,
  type Replace,
  type Search,
  type SplitToken,
  type View,
  type ViewRange,
  type ViewT,
}

///|
pub using @frontend {
  type Emacs,
  type Glob,
  type Pcre,
  type PcreFlag,
  type PcreSplitResult,
  type Perl,
  type PerlOpt,
  type Posix,
  type PosixOpt,
  type Str,
  type StrSplitResult,
}
