# 执行报告（v11）

## 概述
执行 coverage_gap_analysis.md §4 优先级 P4，向 `re/coverage_test.mbt` 末尾追加 3 个 test 块，覆盖 `Pcre::exec`、`Pcre::get_named_substring`、`Pcre::get_named_substring_opt` 三个 Pcre 高级 API 的 raise 路径与命名 group 边界条件。测试全部通过（268/268），无新 warning。

## 产出清单
| 操作 | 文件路径 | 说明 |
|------|---------|------|
| 修改 | re/coverage_test.mbt | 末尾追加 3 个 test 块（1078 → 1112 行） |

## 新增 test 块清单

| 块号 | 名称 | 覆盖 API | 覆盖分支 | 断言数 |
|------|------|---------|---------|--------|
| 1 | `pcre exec no match raise` | `Pcre::exec` | pcre.mbt:53-55 → core.mbt:112 `fail("Re.exec: not found")` | 1 |
| 2 | `pcre get_named_substring not found raise` | `Pcre::regexp` / `Pcre::exec` / `Pcre::get_named_substring` | pcre.mbt:172-180 → pcre.mbt:179 `fail("Pcre: named group not found")` | 1 |
| 3 | `pcre get_named_substring opt boundary` | `Pcre::get_named_substring` / `Pcre::get_named_substring_opt` | pcre.mbt:172-180 Some 分支 + pcre.mbt:67-84 有名分支 + pcre.mbt:67-84 无名分支（result 保持 None） | 3 |

## 各 test 块源码摘要

### 块 1 `pcre exec no match raise`
```moonbit
test "pcre exec no match raise" {
  let re = Pcre::regexp(sb_cov("abc"))
  let result = try {
    let _ = Pcre::exec(re, sb_cov("xyz"))
    false
  } catch {
    _ => true
  }
  assert_eq(result, true)
}
```
构造正则 `abc`，对不匹配输入 `xyz` 调用 `Pcre::exec`，通过 try-catch 捕获 `fail("Re.exec: not found")` 异常，断言 raise 发生。

### 块 2 `pcre get_named_substring not found raise`
```moonbit
test "pcre get_named_substring not found raise" {
  let re = Pcre::regexp(sb_cov("(?<word>[a-z]+)"))
  let g = Pcre::exec(re, sb_cov("hello"))
  let result = try {
    let _ = Pcre::get_named_substring(re, "num", g)
    false
  } catch {
    _ => true
  }
  assert_eq(result, true)
}
```
构造带 Perl 命名 group `(?<word>[a-z]+)` 的正则，匹配 `hello` 得到 GroupT，用错误 name `"num"` 调用 `Pcre::get_named_substring`，捕获 `fail("Pcre: named group not found")` 异常。

### 块 3 `pcre get_named_substring opt boundary`
```moonbit
test "pcre get_named_substring opt boundary" {
  let re = Pcre::regexp(sb_cov("(?<word>[a-z]+)"))
  let g = Pcre::exec(re, sb_cov("hello"))
  assert_eq(Pcre::get_named_substring(re, "word", g), sb_cov("hello"))
  assert_eq(Pcre::get_named_substring_opt(re, "word", g), Some(sb_cov("hello")))
  assert_eq(Pcre::get_named_substring_opt(re, "num", g), None)
}
```
三条断言分别覆盖：`get_named_substring` 命中返回 `Bytes`、`get_named_substring_opt` 命中返回 `Some(Bytes)`、`get_named_substring_opt` 未命中返回 `None`。

## 执行过程

### 决策依据
1. **API 签名确认**：阅读 pcre.mbt:53-55（`Pcre::exec`）、pcre.mbt:67-84（`get_named_substring_opt`）、pcre.mbt:172-180（`get_named_substring`）、core.mbt:104-114（`exec`），确认 raise 路径与任务上下文一致。
2. **Perl 命名 group 语法确认**：阅读 perl.mbt:185-191，确认 `(?<name>...)` 经 `ParseBuffer::accept(buf, '<')` → `perl_name` → `Ast::group(name=Some(name), r)` 路径解析。
3. **辅助函数复用**：沿用 coverage_test.mbt:4 `sb_cov` 构造 Bytes 输入，与既有 Pcre 测试（:870 `pcre groups and alternation`）风格一致。
4. **try-catch 模式**：参考 coverage_test.mbt:890-897 `str search_forward not found` 的既有 raise 捕获模式，保证与代码库约定一致。
5. **snake_case 命名**：test 块名称使用空格分隔小写单词（与既有 `pcre groups and alternation` 等一致），代码内无新标识符引入。

### 验证结果
- **moon test**：`Total tests: 268, passed: 268, failed: 0.`（265 + 3 = 268，全绿）
- **moon check**：`Finished. moon: ran 1 task, now up to date (26 warnings, 0 errors)`（与 baseline 26 warnings 一致，无新 warning）
- **行数**：coverage_test.mbt 1078 → 1112 行（+34 行，含注释和空行；与预期"约 1115"吻合）

## 与 coverage_gap_analysis.md P4 的对应关系

| P4 要求 | 本轮实现 | 状态 |
|---------|---------|------|
| 块 1 `pcre exec no match raise`：覆盖 `Pcre::exec` raise 路径（core.mbt:112） | 块 1，try-catch 捕获 `fail("Re.exec: not found")` | ✅ |
| 块 2 `pcre get_named_substring not found raise`：覆盖 pcre.mbt:179 raise | 块 2，错误 name `"num"` 触发 `fail("Pcre: named group not found")` | ✅ |
| 块 3 `pcre get_named_substring opt boundary`：覆盖 pcre.mbt:172-180 Some 分支 + pcre.mbt:67-84 有名/无名分支 | 块 3，三条 assert_eq 分别覆盖三个分支 | ✅ |
| Perl 命名 group 语法 `(?<name>...)` | 块 2/3 使用 `(?<word>[a-z]+)` | ✅ |
| 验证 268/268 全绿 | moon test 268 passed | ✅ |
| 验证 26 warnings 基线 | moon check 26 warnings 0 errors | ✅ |
| 纯 MoonBit 无 C FFI | 仅追加测试，无 FFI | ✅ |
| 不修改源码 / pkg.generated.mbti | 仅修改 coverage_test.mbt | ✅ |

## 偏差说明
无。严格按 task_v11.md 块 1/2/3 规格实现，3 块均按指定模式（try-catch + assert_eq / 直接 assert_eq）编写，覆盖指定分支，验证结果符合预期（268/268 全绿，26 warnings 基线）。
