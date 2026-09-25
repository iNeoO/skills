---
name: audit-fix
description: Resolve npm/pnpm audit vulnerabilities safely — root-cause grouping, OSV verification of every candidate version, upgrade before override, and adversarial validation of any override. Use when the user says "fix the audit", "pnpm audit", "npm audit", "resolve vulnerabilities", "il y a des vulnérabilités", "corrige l'audit", or invokes /audit-fix.
---

# Audit Fix

Clear dependency vulnerabilities without breaking the build. The audit number is
not the goal — a green audit over a broken runtime is a worse outcome than an
honest red one.

## Core rule: escalation order

Always try these in order. Never skip ahead.

1. **Stale lockfile** — the declared range already permits the patched version.
   Costs nothing, changes no manifest.
2. **Raise the floor** on a direct dependency (patch/minor).
3. **Major bump** — requires reading breaking changes AND user confirmation.
4. **Scoped override** — last resort, and only if it survives §6.
5. **Document as accepted** — when a fix would break more than it fixes.

## 1. Map advisories to root causes

Never work advisory-by-advisory. One direct dependency usually accounts for many
advisories (`hono` alone was 14 of 61 in one app). Group by the *first two path
segments* — the workspace package and its direct dep:

```bash
pnpm audit --json 2>/dev/null | node ~/.claude/scripts/audit-fix/audit-roots.mjs
pnpm audit --json 2>/dev/null | node ~/.claude/scripts/audit-fix/audit-roots.mjs --paths
```

`--paths` also prints full dependency chains — you need those to pick a scoped
override selector in §6.

Now you have a handful of root causes, not 60 advisories.

## 2. Is it just a stale lockfile?

For each root cause, compare the **declared range** against the **patched
version**. If the range already permits the fix, the lockfile is simply stale:

```bash
git show HEAD:package.json | grep '"<pkg>"'   # ^4.12.15 already allows 4.12.32
```

Refresh only the packages that need it. Packages with no manifest entry
(pure transitives) cannot suffer manifest churn:

```bash
pnpm update -r js-yaml postcss valibot esbuild   # targeted, safe
```

> **Never run a bare `pnpm update -r`.** pnpm rewrites *every* manifest, stripping
> caret ranges to exact pins — a 900-line diff across 60+ untouched dependencies.
> After any pnpm write command, run `git diff --stat` and confirm only the files
> you intended have changed.

## 3. Vet every candidate version

Never bump to `latest` on faith. For each candidate, get the version, then ask
OSV whether that exact version is clean:

```bash
pnpm view <pkg> version
curl -s -X POST https://api.osv.dev/v1/query \
  -d '{"package":{"name":"<pkg>","ecosystem":"npm"},"version":"<version>"}'
```

`~/.claude/scripts/audit-fix/osv-check.sh <pkg>@<version> ...` batches this and
prints CLEAN or the GHSA ids; `--ranges` shows each advisory's real affected
ranges, which is how you catch the flattened-range trap below.

Two traps:

- **pnpm audit flattens multi-major ranges.** It may print `patched: >=5.0.8`
  for a package resolved at `1.1.18`. Query OSV directly to see the real
  per-major `ranges` — sometimes there is genuinely no backport and *every*
  version below the new major is affected.
- **A clean package can have a dirty tree.** OSV on the package itself says
  nothing about its transitive deps. Confirm with `pnpm audit` after installing.

## 4. Raise the floor, preserve the style

Edit the manifest to the patched version, **keeping the repo's existing range
style**. Check before editing — `grep save-exact .npmrc` and look at a manifest:

- **Ranged repo** (`^1.2.3`): raise the floor, keep the caret. This documents
  intent and stops a future resolution sliding back under the fix.
- **Pinned repo** (`1.2.3`, or `save-exact=true`): change the pin to another
  exact version. Never reintroduce a caret — the pin is the convention, and the
  manifest is meant to state exactly what was built and tested.

Only touch packages that actually carry an advisory. A 12-line diff gets
reviewed; a 900-line one gets rubber-stamped.

Also check for manifests the audit cannot see — packages excluded from the
workspace have no lockfile entry, so `pnpm audit` skips them entirely and their
declared version is the only thing pinning them. Review those by hand.

## 5. Majors need confirmation — but do the homework first

Before asking, gather the facts so the user can decide in one pass:

1. Read the breaking changes (GitHub releases API, filtered to `X.0.0` tags).
2. Check each breaking change against the actual call sites in this repo.
3. Verify the transitive chain of the new major is OSV-clean.
4. State the blast radius (dev-only vs shipped) and how it will be verified.

Then ask. "testcontainers 10→12 clears 8 advisories; both breaking changes are
already satisfied by your two call sites; dev-only" is a decidable question.
"Upgrade testcontainers?" is not.

## 6. Overrides: last resort, adversarially verified

An override forces a version its parent never declared support for. Before
adding one, all four checks must pass:

1. **Scope it.** Use pnpm's `parent>child` selector, not a bare global pin.
   Then prove the parent exists *only* in the intended subtree:
   ```bash
   grep -oE "^  '?<parent>@[0-9][^':]*" pnpm-lock.yaml | sort -u   # expect one line
   ```
2. **Read the consumer's real usage.** Find the require/import in
   `node_modules/.pnpm/<pkg>@<ver>/…` and see which API it touches.
3. **Test the new version's shape empirically**, in a scratch dir, not from
   memory:
   ```bash
   cd "$SCRATCH" && npm init -y >/dev/null && npm i <pkg>@<ver> >/dev/null
   node -e "const m=require('<pkg>'); console.log(typeof m, Object.keys(m))"
   ```
   A package rewritten in TS/ESM often turns `module.exports = fn` into
   `{ fn }` — which silently breaks every CJS caller.
4. **Run the real tooling and diff its output.** Byte-identical output is the
   proof the override held.

**Reject the override if any check fails, and record why in a comment next to
the other overrides.** A rejected override is a real deliverable: it stops the
next person from re-attempting it. Report the advisory as accepted-with-reason
rather than making the number go down.

### Peer-dependency trap

pnpm auto-installs optional peers, so packages you never import (each of a
library's alternative router/validator integrations) land in the tree with their
advisories. Do **not** reach for `auto-install-peers=false` — it also strips
peers other packages genuinely need. Diff the lockfile package list before and
after any peer-related setting change. Pinning the unused peer to a clean
version is usually the safer fix.

## 7. Verify

Run the project's own Definition of Done (check `CLAUDE.md`) — lint, full build,
tests. Dependency changes break at build and runtime, not at audit time.

Close with an honest report: fixed count, remaining count, and for each
remaining advisory the reason it was not fixed and its blast radius.
