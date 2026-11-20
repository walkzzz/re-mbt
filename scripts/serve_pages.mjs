#!/usr/bin/env node
// 本地预览展示页：零依赖静态服务器（正确 MIME）。
// Local preview server for the GitHub Pages demo.

import { createServer } from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import { join, extname, normalize } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(fileURLToPath(new URL('..', import.meta.url)), 'docs');
const PORT = Number(process.argv[2] ?? 8080);

const TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.wasm': 'application/wasm',
  '.json': 'application/json; charset=utf-8',
  '.md': 'text/markdown; charset=utf-8',
};

const server = createServer(async (req, res) => {
  try {
    const urlPath = decodeURIComponent((req.url ?? '/').split('?')[0]);
    const rel = urlPath === '/' ? 'index.html' : urlPath.replace(/^\/+/, '');
    const resolved = normalize(join(ROOT, rel));
    if (!resolved.startsWith(ROOT)) {
      res.writeHead(403).end('forbidden');
      return;
    }
    const info = await stat(resolved);
    const file = info.isDirectory() ? join(resolved, 'index.html') : resolved;
    const body = await readFile(file);
    res.writeHead(200, {
      'content-type': TYPES[extname(file)] ?? 'application/octet-stream',
      'cache-control': 'no-store',
    });
    res.end(body);
  } catch {
    res.writeHead(404, { 'content-type': 'text/plain; charset=utf-8' }).end('not found');
  }
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`re-mbt demo: http://127.0.0.1:${PORT}/  (root: docs/)`);
  console.log('按 Ctrl+C 停止');
});