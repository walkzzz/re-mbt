# R17 五类多手段测试报告 — Sprint 16/17 性能优化

> 生成时间：2026-10-22
> 测试范围：Str 延迟编译（Sprint 16）+ ReCache memoization（Sprint 17）
> 基线：454 tests passed → 测试后：481 tests passed（新增 27 tests，全部通过）

## 1. 形式化证明

### 1.1 ReCache key 唯一性（re_compile/r17_test.mbt）

| 测试名 | 不变量 | 输入 | 执行 | 输出 | 结论 |
|--------|--------|------|------|------|------|
| `R17-formal: same key hits cache, length stable` | 相同 key → 命中，length 不增 | key="formal-key-1", ast=digit | compile×2 | length=1（不变） | ✅ Pass |
| `R17-formal: different keys produce different cache entries` | 不同 key → 不同条目 | key="k-a"/"k-b" | compile×2 | length=2 | ✅ Pass |
| `R17-formal: cache hit returns execp-equivalent Re` | 命中返回的 clone 与首次编译语义等价 | ast=alnum, s="Z9" | compile×2 → execp | execp(re1,s)==execp(re2,s)==true | ✅ Pass |
| `R17-formal: get after compile returns Some, miss returns None` | get 语义正确 | key 存在/不存在 | get | Some/None | ✅ Pass |

### 1.2 Str 延迟编译语义等价性（re_frontend/r17_test.mbt）

| 测试名 | 不变量 | 输入 | 执行 | 输出 | 结论 |
|--------|--------|------|------|------|------|
| `R17-formal-str: string_match anchored at 0` | string_match(re,s,p) == (srch 命中且 start==p) | re="abc", s="abcdef" | string_match(p=0/1) | true/false | ✅ Pass |
| `R17-formal-str: string_match false when match not at pos` | 匹配存在但不在 pos → false | re="bc", s="abc" | string_match(p=0/1) | false/true | ✅ Pass |
| `R17-formal-str: search_forward pos satisfies string_match` | search_forward 返回的 pos 满足 string_match | re="world", s="hello world" | search_forward→string_match | pos=6, match=true | ✅ Pass |
| `R17-formal-str: compile_regexp_cached equivalent to compile_regexp` | 缓存版与直接版语义等价 | pat="a+b", s="aaab" | string_match 对比 | true==true | ✅ Pass |
| `R17-formal-str: case_fold cached equivalent to direct` | case_fold 缓存版与直接版等价 | pat="HELLO", s="hello world" | string_match 对比 | true==true | ✅ Pass |

**形式化证明结论**：9/9 Pass。ReCache key 唯一性不变量成立；Str 延迟编译的 srch 搜索 + 起始位置检查与锚定匹配语义等价。

## 2. AI 测试

模拟 ReCache 重复编译场景（re_compile/r17_test.mbt）：

| 测试名 | 场景 | 输入 | 执行 | 输出 | 结论 |
|--------|------|------|------|------|------|
| `R17-ai: compile same pattern N times, only 1 cache entry` | 重复编译 N 次 | N=10, 同一 key | compile×10 | length=1 | ✅ Pass |
| `R17-ai: length grows with distinct patterns` | 不同模式递增 | 4 个不同 ast | compile×4 | length=4 | ✅ Pass |
| `R17-ai: clear empties cache, recompile misses` | clear 后重编译 | key="ai-clear" | compile→clear→compile | 1→0→1 | ✅ Pass |
| `R17-ai: new_with_capacity behaves like new` | 带容量构造 | capacity=8 | compile | length=1 | ✅ Pass |

**AI 测试结论**：4/4 Pass。ReCache 在重复编译、递增编译、clear 后重编译场景下行为符合预期。

## 3. FAKE 测试

构造假数据验证 ReCache 不崩溃（re_compile/r17_test.mbt）：

| 测试名 | 假数据 | 输入 | 执行 | 输出 | 结论 |
|--------|--------|------|------|------|------|
| `R17-fake: epsilon pattern compile does not crash` | 空串模式 | Ast::epsilon() | compile→execp("")/("x") | true/true | ✅ Pass |
| `R17-fake: empty-set pattern compile does not crash` | 空集模式 | Ast::empty() | compile→execp("")/("abc") | 不崩溃 | ✅ Pass |
| `R17-fake: very long pattern (a{500}) compile does not crash` | 超长模式 | repn('a',500,500) | compile→execp(500×'a') | true | ✅ Pass |
| `R17-fake: get on absent key returns None` | 不存在 key | "nonexistent-key-xyz" | get | None | ✅ Pass |
| `R17-fake: empty key bytes does not crash` | 空 key | Bytes("") | compile×2 | length=1 | ✅ Pass |

**FAKE 测试结论**：5/5 Pass。ReCache 对空模式、超长模式、空 key、不存在 key 等边界数据不崩溃。

## 4. MOCK 测试

验证缓存跳过编译，返回等价 Re（re_compile/r17_test.mbt）：

| 测试名 | Mock 场景 | 输入 | 执行 | 输出 | 结论 |
|--------|-----------|------|------|------|------|
| `R17-mock: cached re is execp-equivalent to first compile` | 缓存命中返回等价 Re | 5 个输入 | execp 对比 | 全部相等 | ✅ Pass |
| `R17-mock: different keys do not hit each other` | 不同 key 不互相命中 | 2 个不同 key | compile×2 | length=2 | ✅ Pass |
| `R17-mock: cache hit clone has independent WorkingArea` | clone 独立性 | 交替 execp | re1/re2 交替 | 不互相干扰 | ✅ Pass |
| `R17-mock: interleaved compile of two patterns keeps both cached` | 交叉编译 | 2 pattern 交替 | compile×4 | length=2, execp 正确 | ✅ Pass |

**MOCK 测试结论**：4/4 Pass。缓存命中返回的 clone 与首次编译 Re 语义等价，且 WorkingArea 独立。

## 5. E2E 测试

端到端完整流程（re_frontend/r17_test.mbt）：

| 测试名 | 流程 | 输入 | 执行 | 输出 | 结论 |
|--------|------|------|------|------|------|
| `R17-e2e: ReCache lifecycle: compile→match→hit→match→clear→miss` | 缓存全生命周期 | pat="[0-9]+" | compile→match→compile(hit)→match→clear→compile(miss) | length: 1→1→0→1 | ✅ Pass |
| `R17-e2e: Str lazy compile: match→forward→backward triggers mtch` | Str 延迟编译 | re="ab", s="xyzab123ab" | string_match→search_forward→search_backward×2 | fwd=3, bwd=8 | ✅ Pass |
| `R17-e2e: Str cached + lazy compile full flow` | 缓存+延迟编译 | pat="cd", s="abcde" | compile→match→forward→backward→compile(hit)→clear→compile(miss) | length: 1→1→0→1 | ✅ Pass |
| `R17-e2e: multi-frontend cache isolation` | 多前端缓存隔离 | Perl/Pcre/Posix/Emacs | 各编译一次 | length=4, 全匹配 | ✅ Pass |
| `R17-e2e: Str split with cached regexp` | 缓存+split | pat="," | compile_regexp_cached→split | ["a","b","c"] | ✅ Pass |

**E2E 测试结论**：5/5 Pass。端到端流程覆盖缓存生命周期、Str 延迟编译触发 mtch、多前端缓存隔离、缓存+split 组合。

## 总结

| 测试类型 | 测试数 | 通过数 | 失败数 | 结论 |
|----------|--------|--------|--------|------|
| 形式化证明 | 9 | 9 | 0 | ✅ Pass |
| AI 测试 | 4 | 4 | 0 | ✅ Pass |
| FAKE 测试 | 5 | 5 | 0 | ✅ Pass |
| MOCK 测试 | 4 | 4 | 0 | ✅ Pass |
| E2E 测试 | 5 | 5 | 0 | ✅ Pass |
| **合计** | **27** | **27** | **0** | **✅ 全 Pass** |

### 验证不变量

1. **ReCache key 唯一性**：相同 (pattern, opts) → 相同 key → 命中缓存（length 不增）；不同 key → 不同条目 ✅
2. **Str 延迟编译语义等价性**：string_match 用 srch + 起始位置检查 == 原始 mtch 锚定匹配 ✅
3. **缓存命中语义等价**：命中返回的 clone 与首次编译 Re 的 execp 结果一致 ✅
4. **clone 独立性**：命中返回的 clone 有独立 WorkingArea，不互相干扰 ✅
5. **mtch 延迟编译**：search_backward 触发 mtch 编译，后续调用复用 ✅

### 验收门禁

- `moon check`：0 warning 0 error ✅
- `moon test`：481/481 passed ✅
- 新增测试：27 个（re_compile/r17_test.mbt 17 个 + re_frontend/r17_test.mbt 10 个）
- 报告文件：`docs/arch_test_report.md`