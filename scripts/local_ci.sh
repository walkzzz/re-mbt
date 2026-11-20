#!/usr/bin/env bash
# local_ci.sh — 本地 CI（与 .github/workflows/ci.yml 对齐；学 agentskills.mbt / gbz185.mbt）
# 用法：bash scripts/local_ci.sh [--quick]
#   --quick  跳过变异矩阵（慢项），其余与 CI 一致
set -u
FAIL=0
cd "$(dirname "$0")/.." || exit 1

step() { echo ""; echo "=== $1 ==="; }
run()  { echo "> $*"; "$@" || { echo "FAILED: $*"; FAIL=1; }; }

step "fmt"
run moon fmt --check

step "check --deny-warn --target all"
run moon check --deny-warn --target all

step "test 四目标（native / js / wasm / wasm-gc）"
for t in native js wasm wasm-gc; do
  run moon test --target $t
done

step "contract：mbti 漂移"
moon info >/dev/null 2>&1
git diff --exit-code --stat || { echo "FAILED: mbti drift（运行 moon info 并提交）"; FAIL=1; }

step "docs：版本/测试数/旧数字/死链/覆盖率门槛"
run node scripts/check_docs.mjs

step "coverage：core >= 95%"
run node scripts/check_coverage.mjs

step "examples：可运行示例"
run moon run examples/demo --target native

step "bench smoke"
run moon run bench/main --target native --release

if [ "${1:-}" != "--quick" ]; then
  step "mutation：10 变异点矩阵（慢，--quick 跳过）"
  run moon run scripts/mutation_test.mbtx
fi

echo ""
if [ "$FAIL" -ne 0 ]; then
  echo "LOCAL CI FAILED"
  exit 1
fi
echo "LOCAL CI OK"