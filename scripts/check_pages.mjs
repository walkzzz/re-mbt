#!/usr/bin/env node
// 展示页自检：静态资源 + JS 导出 + 匹配语义（与 native 测试一致）。
// Pages self-check for re-mbt.

import { readFileSync, existsSync, copyFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';

const ROOT = fileURLToPath(new URL('..', import.meta.url));
const JS_BUILD = join(ROOT, '_build/js/release/build/playground/playground.js');
const JS_DOCS = join(ROOT, 'docs/playground.js');

let failures = 0;
function check(name, ok, detail) {
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? `  (${detail})` : ''}`);
  if (!ok) failures++;
}

for (const f of ['docs/index.html', 'docs/app.js', 'docs/style.css']) {
  check(`asset exists: ${f}`, existsSync(join(ROOT, f)));
}
const html = readFileSync(join(ROOT, 'docs/index.html'), 'utf8');
check('index.html mentions re-mbt + MoonBit', html.includes('re-mbt') && html.includes('MoonBit'));
check('index.html loads app.js / style.css', html.includes('app.js') && html.includes('style.css'));

if (!existsSync(JS_BUILD)) {
  const r = spawnSync('moon build --target js --release playground', {
    shell: true,
    encoding: 'utf8',
    cwd: ROOT,
  });
  check('build playground js', r.status === 0, (r.stderr ?? '').slice(0, 200));
}
if (existsSync(JS_BUILD)) {
  copyFileSync(JS_BUILD, JS_DOCS);
}
check('docs/playground.js exists', existsSync(JS_DOCS));

if (!existsSync(JS_DOCS)) process.exit(1);

const mod = await import('file://' + JS_DOCS.replace(/\\/g, '/'));
for (const name of ['re_match', 're_find_len']) {
  check(`export: ${name}`, typeof mod[name] === 'function');
}
check('date pattern matches', mod.re_match('(\\d{4})-(\\d{2})-(\\d{2})', 'order-2024-12-25') === true);
check('no-match returns false', mod.re_match('^zzz$', 'abc') === false);
check('match length = 4 for a+b / aaab', mod.re_find_len('a+b', 'aaab') === 4);
check('invalid pattern folds to false', mod.re_match('(', 'x') === false);
check('invalid pattern folds to -1', mod.re_find_len('(', 'x') === -1);
check('linear-time stress does not hang', mod.re_match('(a+)+$', 'a'.repeat(200000) + '!') === false);

console.log(`\n=== pages check: ${failures === 0 ? 'PASS' : `FAIL (${failures})`} ===`);
if (failures > 0) process.exit(1);