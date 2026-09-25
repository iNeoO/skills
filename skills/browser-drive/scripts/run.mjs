// Generic CDP driver. Usage: [TAB=<url fragment>] [PORT=9222] node run.mjs '<async body>'
// Body runs with: p (target page), ctx (browser context), fs. Return a value to print it.
import { chromium } from 'playwright-core';
import fs from 'fs';
const port = process.env.PORT ?? '9222';
const tab = process.env.TAB ?? 'linkedin.com';
const b = await chromium.connectOverCDP(`http://127.0.0.1:${port}`);
const ctx = b.contexts()[0];
const pages = ctx.pages();
const p = pages.find(x => x.url().includes(tab)) ?? pages[0];
try {
  const body = process.argv[2] ?? 'return p.url()';
  const out = await new Function('p', 'ctx', 'fs', `return (async () => { ${body} })()`)(p, ctx, fs);
  if (out !== undefined) console.log(typeof out === 'string' ? out : JSON.stringify(out, null, 2));
} catch (e) { console.error('ERR', e.message.split('\n')[0]); process.exitCode = 1; }
finally { await b.close(); }
