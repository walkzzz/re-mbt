#!/usr/bin/env node
// 覆盖率门槛 — 解析 full_summary，排除 bench，对库代码设硬门槛。
// Coverage gate: parse full_summary, exclude bench, enforce library threshold.
//
// 用法：node scripts/check_coverage.mjs [--skip-test]
// 门槛：core >= 95%

import { spawnSync } from 'node:child_process';
import { writeFileSync, readFileSync, unlinkSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { join } from 'node:path';

const ROOT = fileURLToPath(new URL('..', import.meta.url));
const SUMMARY = join(ROOT, 'cov_summary.txt');
const CORE_MIN = 95.0;

function run(cmd) {
  const r = spawnSync(cmd, {
    shell: true,
    encoding: 'utf8',
    maxBuffer: 128 * 1024 * 1024,
    cwd: ROOT,
  });
  if (r.status !== 0) {
    console.error(`命令失败: ${cmd}\n${r.stderr ?? ''}`);
    process.exit(1);
  }
  return r.stdout ?? '';
}

if (!process.argv.includes('--skip-test')) {
  console.log('[1/2] moon test --enable-coverage --target native');
  run('moon test --enable-coverage --target native');
}

console.log('[2/2] moon coverage report -f full_summary');
writeFileSync(SUMMARY, run('moon coverage report -f full_summary'), 'utf8');

let core = 0;
let total = 0;
const rows = [];
for (const line of readFileSync(SUMMARY, 'utf8').split(/\r?\n/)) {
  const m = line.match(/^(.+\.mbt): (\d+)\/(\d+)$/);
  if (!m) continue;
  const low = m[1].toLowerCase();
  if (low.includes('bench') || low.includes('examples') || low.includes('playground')) continue;
  const c = Number(m[2]);
  const t = Number(m[3]);
  if (t === 0) continue;
  core += c;
  total += t;
  const pct = (c * 100) / t;
  if (pct < 97) rows.push(`${m[1]} ${c}/${t} ${pct.toFixed(1)}%`);
}

const pct = total === 0 ? 100 : (core * 100) / total;
for (const r of rows) console.log('  ' + r);
console.log(`core: ${core}/${total} = ${pct.toFixed(1)}% (threshold ${CORE_MIN}%)`);

if (existsSync(SUMMARY)) unlinkSync(SUMMARY);

if (pct < CORE_MIN) {
  console.error('FAIL: core coverage below threshold');
  process.exit(1);
}
console.log('PASS: coverage gate satisfied');