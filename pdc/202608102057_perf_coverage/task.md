# 任务：re-mbt 性能优化 + 测试覆盖率提升

## 项目背景

- **项目**：re-mbt，ocaml-re 到 MoonBit 的正则表达式库移植
- **路径**：D:\CodeWorkspace\forMoonbit\re-mbt
- **匹配引擎**：lazy DFA + Brzozowski/Antimirov 导数（线性时间，无灾难性回溯）
- **约束**：纯 MoonBit，无 C FFI，支持 native/wasm/js 全后端
- **源码**：re/ 目录下 32 个源文件，约 160KB
- **测试**：9 个测试文件，251 个 test 块
- **Benchmark**：bench/ 目录，10 个 section，bench/run_bench.ps1 自动化脚本
- **构建命令**：moon check / moon test / moon build --target native --release
- **依赖**：moonbitlang/x@0.4.48

## 执行顺序

**先性能后覆盖率**：先做性能优化，再补充测试覆盖。

## 阶段一：性能优化（全面优化）

### 优化方向
- **算法层**：优化 cset（字符集操作）、automata（导数/状态管理）、compile（lazy DFA driver）的核心算法
- **内存层**：减少热路径上的内存分配（减少 @array/@hashmap 创建，使用可变结构）
- **数据结构层**：优化核心数据结构（bit_vector、hash_set、dense_map、cset 的内部表示和操作）

### 方法
1. 运行现有 benchmark（bench/run_bench.ps1）建立基线
2. 分析 benchmark 结果定位热点
3. 针对热点逐模块优化
4. 每次优化后重新运行 benchmark 验证改进
5. 确保 moon test 全部通过，不引入回归

### 核心模块优先级
1. `cset.mbt`（12.1KB）- 字符集操作，匹配热路径
2. `compile.mbt`（16.4KB）- lazy DFA driver，匹配引擎核心
3. `automata_state.mbt`（7.4KB）- 状态管理
4. `automata_desc.mbt`（8.2KB）- 导数表达式操作
5. `core.mbt`（3.1KB）- 高层 API
6. `hash_set.mbt`（2.3KB）- int 专用哈希集
7. `bit_vector.mbt`（1.3KB）- 位向量

### 验证标准
- moon test 全部通过
- benchmark 结果有可测量的改进
- 无新 warning 引入

## 阶段二：测试覆盖率提升

### 方法
1. 运行现有测试确认全部通过
2. 分析未覆盖的 pub API 和分支（参考 re/pkg.generated.mbti 接口）
3. 补充缺失测试，重点覆盖：
   - 核心模块的边界条件
   - 错误路径和异常处理
   - 各前端解析器的边缘 case
   - cset/automata/compile 的内部操作（通过公开 API 间接测试）

### 现状
- 已有 251 个测试
- coverage_test.mbt（103 个测试）专门补充 pub API 覆盖
- 测试层次：基础数据结构 → AST → 自动机 → 编译 → 核心 API → 各前端

### 验证标准
- moon test 全部通过
- 新增测试覆盖之前未覆盖的 API 和分支
- 无冗余/重复测试

## 约束
- 保持纯 MoonBit 实现，不引入 C FFI
- 保持与 OCaml 上游的行为一致性
- 保持 latin1 大小写处理
- 不修改 pkg.generated.mbti（由 moon info 自动生成）
- 代码命名遵循 snake_case 风格
- 每轮优化后必须运行 moon test 确保不回归
