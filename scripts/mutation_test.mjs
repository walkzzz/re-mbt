#!/usr/bin/env node
// 变异测试 — 注入缺陷 → 跑全量测试 → KILLED/SURVIVED → 恢复 → 汇总。
// Mutation testing for re-mbt.

import { spawnSync } from 'node:child_process';
import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { join } from 'node:path';

const ROOT = fileURLToPath(new URL('..', import.meta.url));

const MUTATIONS = [
  { id: 'M01', file: 're_ast/ast_witness.mbt', old: 'Alternative(l) => if l.is_empty() { None } else { Ast::witness(l[0]) }', new: 'Alternative(l) => if l.is_empty() { Some(b"") } else { Ast::witness(l[0]) }', desc: 'empty alternative becomes matchable' },
  { id: 'M02', file: 're_ast/ast_witness.mbt', old: 'CsetOf(c) => Some(c)', new: 'CsetOf(c) => None', desc: 'cset witness becomes impossible' },
  { id: 'M03', file: 're_ast/ast_witness.mbt', old: 'Bytes::from_array([b.to_byte()])', new: 'Bytes::from_array([0])', desc: 'witness byte replaced by NUL' },
  { id: 'M04', file: 're_ast/ast_witness.mbt', old: 'NoCase(x) => witness_cset(x)', new: 'NoCase(x) => None', desc: 'no-case cast lost in witness' },
  { id: 'M05', file: 're_ast/ast_witness.mbt', old: 'Some(@base.Cset::diff(@base.Cset::cany(), @base.Cset::union_all(parts)))', new: 'Some(@base.Cset::empty())', desc: 'complement witness collapses to empty' },
  { id: 'M06', file: 're_ast/ast_witness.mbt', old: 'Some(m) => if m < 1 { 0 } else if min < 1 { 1 } else { min }', new: 'Some(m) => if m < 1 { 1 } else if min < 1 { 1 } else { min }', desc: 'repeat max=0 no longer empty' },
  { id: 'M07', file: 're_frontend/posix_class.mbt', old: "if !@base.ParseBuffer::accept(buf, ':') {", new: 'if false {', desc: 'posix class prefix check removed' },
  { id: 'M08', file: 're_frontend/posix_class.mbt', old: 'if cls is None {', new: 'if cls is Some(_) {', desc: 'posix class name scan inverted' },
  { id: 'M09', file: 're_frontend/posix_class.mbt', old: 'if !@base.ParseBuffer::accept_s(buf, posix_class_close) {', new: 'if false {', desc: 'posix class closing bracket check removed' },
  { id: 'M10', file: 're_ast/ast_witness.mbt', old: 'Intersection(l) => {', new: 'Intersection(l) => return None', desc: 'intersection witness becomes impossible' },
];

function run() {
  const r = spawnSync('moon test --target native', {
    shell: true,
    encoding: 'utf8',
    maxBuffer: 128 * 1024 * 1024,
    cwd: ROOT,
  });
  return r.status ?? 1;
}

console.log('=== baseline ===');
if (run() !== 0) {
  console.error('baseline tests are red; fix before mutation testing');
  process.exit(1);
}

let killed = 0;
let survived = 0;
let skipped = 0;
const results = [];
for (const m of MUTATIONS) {
  const p = join(ROOT, m.file);
  const original = readFileSync(p, 'utf8');
  const hits = original.split(m.old).length - 1;
  if (hits !== 1) {
    skipped++;
    results.push(`${m.id}: SKIPPED (occurrences=${hits}) — ${m.desc}`);
    continue;
  }
  writeFileSync(p, original.replace(m.old, m.new), 'utf8');
  const code = run();
  writeFileSync(p, original, 'utf8');
  if (code === 0) {
    survived++;
    results.push(`${m.id}: SURVIVED — ${m.desc}`);
  } else {
    killed++;
    results.push(`${m.id}: KILLED — ${m.desc}`);
  }
}

const finalCode = run();
for (const r of results) console.log(r);
console.log('=== mutation summary ===');
console.log(`killed=${killed} survived=${survived} skipped=${skipped} total=${MUTATIONS.length}`);
if (finalCode !== 0) {
  console.error('WARNING: baseline failing after restore — manual check needed');
  process.exit(1);
}
if (survived > 0 || skipped > 0) {
  console.error('FAIL: survived/skipped above zero');
  process.exit(1);
}
console.log('PASS: all mutations killed');