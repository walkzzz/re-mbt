# re_base — 基础类型包

> 字符集、字符类别、模式标记、自动机枚举、工具函数。

## 公共 API

| 类型 | 说明 |
|------|------|
| `Cset` / `CsetC` / `CSetMap` | 字符集（排序区间列表） |
| `Category` | 字符类别（位标志） |
| `Pmark` / `PmarkSet` | 模式标记标识符 |
| `Sem` / `RepKind` | 语义/重复类型枚举 |
| `Mark` / `Idx` / `Ids` | 自动机标记/索引 |
| `Dyn` | 动态值（调试用） |
| `BitVector` / `HashSet` | 位向量/哈希集合 |
| `MarkInfos` / `MarkOffset` | 标记信息 |
| `ParseBuffer` | 解析缓冲区 |
| `DenseMap` | 密集映射 |

| 函数 | 说明 |
|------|------|
| `sb` / `bs` | String↔Bytes 转换 |
| `hash_combine` | 哈希组合 |

## 依赖

无（最底层包）。