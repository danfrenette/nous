import { parseHTML } from 'linkedom';
import { Defuddle } from 'defuddle/node';

// Retained extraction must never reacquire content, including site-specific APIs.
globalThis.fetch = async () => { throw new Error('Network disabled during extraction'); };
console.log = console.warn = console.error = () => {};

try {
  if (Number(process.versions.node.split('.')[0]) < 22) throw new Error('Node.js 22+ required');
  process.stdin.setEncoding('utf8');
  let input = '';
  for await (const chunk of process.stdin) input += chunk;
  const { html, url, selector } = JSON.parse(input);
  const { document } = parseHTML(html);
  const result = await Defuddle(document, url, {
    separateMarkdown: true,
    useAsync: false,
    contentSelector: selector || undefined,
  });
  process.stdout.write(JSON.stringify({
    title: result.title || '',
    content: result.content,
    markdown: result.contentMarkdown,
  }));
} catch {
  process.stderr.write('Defuddle extraction failed\n');
  process.exitCode = 1;
}
