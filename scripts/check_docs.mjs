#!/usr/bin/env node
// 文档数字一致性自检 — 版本 / CHANGELOG / 测试数 / 覆盖率 / 旧数字残留 / 死链
// Docs consistency for re-mbt.

import { readFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import path from 'node:path';

const ROOT = path.resolve(import.meta.dirname, '..');

async function read(rel) {
  return readFile(path.join(ROOT, rel), 'utf8');
}

function cap(re, text, file, what) {
  const m = text.match(re);
  if (!m) throw new Error(`${what}: not found in ${file}`);
  return m[1];
}

const ASSERTIONS = [
  {
    id: 'A1',
    desc: 'moon.mod version == CHANGELOG 最新条目',
    async run() {
      const mod = cap(/^version = "([^"]+)"/m, await read('moon.mod'), 'moon.mod', 'version');
      const cl = cap(/^## \[([^\]]+)\]/m, await read('CHANGELOG.md'), 'CHANGELOG.md', 'latest');
      if (mod !== cl) throw new Error(`moon.mod=${mod} != CHANGELOG=${cl}`);
      return { version: mod };
    },
  },
  {
    id: 'A2',
    desc: 'README 测试数 == AGENTS.md 测试数',
    async run() {
      const readme = await read('README.md');
      const agents = await read('AGENTS.md');
      const a = cap(/(\d+) 个测试/, readme, 'README.md', 'readme tests');
      const b = cap(/(\d+) 测试/, agents, 'AGENTS.md', 'agents tests');
      if (a !== b) throw new Error(`README=${a} != AGENTS=${b}`);
      return { tests: a };
    },
  },
  {
    id: 'A3',
    desc: 'README 无旧测试数残留（713 / 437）',
    async run() {
      const readme = await read('README.md');
      for (const old of ['713', '437']) {
        if (readme.includes(old)) throw new Error(`README 残留旧测试数 ${old}`);
      }
      return { checked: ['713', '437'] };
    },
  },
  {
    id: 'A4',
    desc: 'README 引用的 docs/*.md 全部存在（防死链）',
    async run() {
      const readme = await read('README.md');
      const links = [...readme.matchAll(/\]\((docs\/[\w.-]+\.md)\)/g)].map((m) => m[1]);
      const missing = links.filter((f) => !existsSync(path.join(ROOT, f)));
      if (missing.length) throw new Error(`missing docs: ${missing.join(', ')}`);
      return { checked: links.length };
    },
  },
  {
    id: 'A5',
    desc: '覆盖率门槛脚本存在（95%）且 CI 引用',
    async run() {
      const cov = await read('scripts/check_coverage.mjs');
      const min = cap(/const CORE_MIN = ([\d.]+)/, cov, 'scripts/check_coverage.mjs', 'CORE_MIN');
      if (min !== '95.0') throw new Error(`CORE_MIN=${min} != 95.0`);
      const ci = await read('.github/workflows/ci.yml');
      if (!ci.includes('node scripts/check_coverage.mjs')) throw new Error('CI 未引用 check_coverage.mjs');
      return { core_min: min };
    },
  },
  {
    id: 'A6',
    desc: 'docs/assessment.md 测试数与 README 一致',
    async run() {
      const doc = await read('docs/assessment.md');
      const tests = cap(/(\d+) 测试/, doc, 'docs/assessment.md', 'assessment tests');
      const readme = cap(/(\d+) 个测试/, await read('README.md'), 'README.md', 'readme tests');
      if (tests !== readme) throw new Error(`assessment=${tests} != README=${readme}`);
      return { tests };
    },
  },
  {
    id: 'A7',
    desc: '治理文档齐备（TEST_REPORT/known-gaps/CONTRIBUTING/SECURITY/CoC）且 AGENTS 引用 mbtx 变异',
    async run() {
      const required = [
        'docs/TEST_REPORT.md',
        'docs/known-gaps.md',
        'CONTRIBUTING.md',
        'SECURITY.md',
        'CODE_OF_CONDUCT.md',
        'scripts/local_ci.sh',
        'scripts/mutation_test.mbtx',
      ];
      for (const f of required) {
        if (!existsSync(path.join(ROOT, f))) throw new Error(`missing ${f}`);
      }
      const agents = await read('AGENTS.md');
      if (!agents.includes('mutation_test.mbtx')) throw new Error('AGENTS 未引用 mutation_test.mbtx');
      return { checked: required.length };
    },
  },
];

const results = [];
for (const a of ASSERTIONS) {
  try {
    results.push({ id: a.id, desc: a.desc, ok: true, evidence: await a.run() });
  } catch (e) {
    results.push({ id: a.id, desc: a.desc, ok: false, fail: String(e.message) });
  }
}
const failed = results.filter((r) => !r.ok).length;
console.log(JSON.stringify({ schema: 'check_docs@1', total: results.length, failed, results }, null, 2));
process.exit(failed === 0 ? 0 : 1);