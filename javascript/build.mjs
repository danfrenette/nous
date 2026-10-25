import { build } from 'esbuild';
import { readFile, readdir, writeFile } from 'node:fs/promises';

await build({
  entryPoints: ['javascript/defuddle.mjs'],
  bundle: true,
  minify: true,
  platform: 'node',
  format: 'esm',
  target: 'node22',
  outfile: 'vendor/defuddle.mjs',
  legalComments: 'linked',
});

// Include upstream license texts, which minified packages may omit from comments.
const lock = JSON.parse(await readFile('package-lock.json', 'utf8'));
const notices = [];
for (const [directory, info] of Object.entries(lock.packages)) {
  if (!directory || info.dev) continue;
  const files = (await readdir(directory)).filter(name => /^(license|licence|copying)(\.|$)/i.test(name));
  if (!files.length) throw new Error(`Missing license text: ${directory}`);
  notices.push(`${directory} (${info.version})\n${(await Promise.all(files.map(name => readFile(`${directory}/${name}`, 'utf8')))).join('\n')}`);
}
await writeFile('vendor/THIRD_PARTY_LICENSES.txt', notices.join('\n\n========================================\n\n'));
