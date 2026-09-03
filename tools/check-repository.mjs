import { readFileSync, readdirSync } from 'node:fs';
import { extname, join } from 'node:path';

for (const name of readdirSync('src')) {
  if (!name.endsWith('.pp')) continue;
  const text = readFileSync(join('src', name), 'utf8');
  if (name !== 'oscore_port.pp' && text.includes('@oscore/')) {
    throw new Error(`${name}: only oscore_port.pp may import oscore`);
  }
  if (text.includes('@osbare/') || /\b(outb|inb|cli|sti|hlt)\s*\(/.test(text)) {
    throw new Error(`${name}: direct osbare or hardware access is forbidden`);
  }
}

const pairs = [
  'README', 'ABI', 'ARCHITECTURE', 'ROADMAP', 'CHANGELOG', 'COMPATIBILITY',
  'THIRD_PARTY',
];
for (const name of pairs) {
  readFileSync(`${name}.md`);
  readFileSync(`${name}.zh-CN.md`);
}

const textExtensions = new Set([
  '.c', '.cnf', '.h', '.md', '.pp', '.sh', '.mjs', '.toml', '.yml',
]);
function checkTextTree(directory) {
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    if (['.git', 'build', 'target'].includes(entry.name)) continue;
    const path = join(directory, entry.name);
    if (entry.isDirectory()) {
      checkTextTree(path);
      continue;
    }
    if (!textExtensions.has(extname(entry.name)) && entry.name !== 'VERSION') continue;
    const content = readFileSync(path, 'utf8');
    if (!content.endsWith('\n') || content.endsWith('\n\n')) {
      throw new Error(`${path}: expected exactly one final newline`);
    }
    if (/[ \t]+$/m.test(content)) {
      throw new Error(`${path}: trailing whitespace`);
    }
  }
}

checkTextTree('.');
if (readFileSync('VERSION', 'utf8').trim() !== '0.2.2') {
  throw new Error('VERSION must be 0.2.2');
}
console.log('PPNET REPOSITORY PASS');
