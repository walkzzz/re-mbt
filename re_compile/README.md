# re_compile — 编译与核心执行包

> 将 AST 编译为自动机，提供匹配执行核心。

## 公共 API

| 类型 | 说明 |
|------|------|
| `Re` | 编译后的正则表达式 |
| `GroupT` | 匹配结果与分组 |
| `MatchInfo` | 匹配信息 |
| `ExecPartialResult` / `ExecPartialDetailedResult` | 部分匹配结果 |
| `CompileIdx` / `CompileState` / `StateHashTable` / `StateInfo` / `Positions` | 编译内部类型 |

| 函数 | 说明 |
|------|------|
| `compile` | 编译 AST → Re |
| `exec` / `exec_opt` / `execp` | 执行匹配 |
| `exec_partial` / `exec_partial_detailed` | 部分匹配 |
| `match_str` / `match_str_p` / `match_str_no_bounds` | 匹配字符串 |
| `mk_re` / `copy_re` | 构造/复制 Re |

## 依赖

`re_base`, `re_ast`