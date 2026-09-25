#!/usr/bin/env node
// Group `pnpm audit --json` advisories by ROOT cause — the workspace package and
// its direct dependency — instead of listing them one by one. One direct dep
// usually accounts for many advisories, so this is the list you actually work from.
//
//   pnpm audit --json 2>/dev/null | node audit-roots.mjs
//   pnpm audit --json 2>/dev/null | node audit-roots.mjs --paths
//
// --paths also prints the full dependency chain for each advisory, which you need
// when choosing a scoped `parent>child` override selector.

const showPaths = process.argv.includes("--paths");
const ORDER = { critical: 0, high: 1, moderate: 2, low: 3 };

const raw = await new Promise((resolve, reject) => {
  let d = "";
  process.stdin.on("data", (c) => (d += c));
  process.stdin.on("end", () => resolve(d));
  process.stdin.on("error", reject);
});

let audit;
try {
  audit = JSON.parse(raw);
} catch {
  console.error("Could not parse stdin as JSON. Pipe `pnpm audit --json` into this script.");
  process.exit(2);
}

const advisories = Object.values(audit.advisories ?? {});
if (!advisories.length) {
  console.log("No advisories. Audit is clean.");
  process.exit(0);
}

const roots = new Map();
for (const adv of advisories) {
  const paths = [...new Set((adv.findings ?? []).flatMap((f) => f.paths ?? []))];
  for (const path of paths) {
    const root = path.split(">").slice(0, 2).join(">");
    if (!roots.has(root)) roots.set(root, []);
    roots.get(root).push({
      sev: adv.severity,
      mod: adv.module_name,
      patched: adv.patched_versions,
      ghsa: adv.github_advisory_id,
      path,
    });
  }
}

// Worst severity first, then most advisories — that ordering is the work queue.
const worst = (list) => Math.min(...list.map((e) => ORDER[e.sev] ?? 9));
const sorted = [...roots.entries()].sort(
  (a, b) => worst(a[1]) - worst(b[1]) || b[1].length - a[1].length,
);

const counts = { critical: 0, high: 0, moderate: 0, low: 0 };
for (const adv of advisories) counts[adv.severity] = (counts[adv.severity] ?? 0) + 1;

for (const [root, entries] of sorted) {
  console.log(`\n${root}`);
  const seen = new Set();
  for (const e of entries.sort((x, y) => ORDER[x.sev] - ORDER[y.sev])) {
    const key = `${e.sev}|${e.mod}|${e.patched}`;
    if (seen.has(key)) continue;
    seen.add(key);
    console.log(`   [${e.sev.padEnd(8)}] ${e.mod} → need ${e.patched}  ${e.ghsa ?? ""}`);
    if (showPaths) {
      for (const p of [...new Set(entries.filter((x) => x.mod === e.mod).map((x) => x.path))]) {
        console.log(`        ${p}`);
      }
    }
  }
}

// pnpm audit's headline counts one entry per (advisory, path) pair, so it reads
// higher than the unique-advisory count. Print both so the two never look at odds.
const pathCount = [...roots.values()].reduce((n, entries) => n + entries.length, 0);
const s = (n) => (n === 1 ? "" : "s");

console.log(
  `\n${advisories.length} unique advisor${advisories.length === 1 ? "y" : "ies"} ` +
    `(${pathCount} finding path${s(pathCount)}, which is what pnpm audit counts) ` +
    `across ${roots.size} root cause${s(roots.size)} — ` +
    `${counts.critical} critical | ${counts.high} high | ${counts.moderate} moderate | ${counts.low} low`,
);
