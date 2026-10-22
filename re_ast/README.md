# re_ast — AST 与自动机包

> 正则表达式抽象语法树、自动机表达式/描述/状态、颜色映射。

## 公共 API

| 类型 | 说明 |
|------|------|
| `Ast` / `AstNoCase` | 正则 AST（Cased/Uncased） |
| `AstGen[T]` / `AstCset` | 通用 AST 节点/字符集表达式 |
| `Expr` | 自动机表达式 |
| `Desc` / `Marks` / `Status` / `ET` | 自动机描述 |
| `State` / `WorkingArea` | DFA 状态/工作区 |
| `ColorMap` / `ColorTable` / `ColorRepr` / `BoundaryTable` | 颜色映射 |

| 函数 | 说明 |
|------|------|
| `advance` / `delta` | 状态转移 |

## 依赖

`re_base`