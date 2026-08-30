---
name: pnpm-monorepo
description: Conventions for pnpm workspace monorepos in TypeScript — package layout, dependency direction rules, workspace/catalog protocols, shared tsconfig, and where a new feature's code belongs. Use when creating or modifying packages, adding dependencies, wiring tsconfig/build in a pnpm workspace, or deciding which package should own new code.
---

# pnpm Monorepo Conventions

First rule: read `pnpm-workspace.yaml` and 2–3 existing packages; mirror what's there. The defaults below apply to gaps, not to overriding a working convention.

## Layout and ownership

```
apps/        # deployables: web (TanStack Start), api (Hono), workers
packages/    # shared code: domain logic, schemas, ui, config, db client
  <name>/src/index.ts   # single public entry; deep imports forbidden
tooling/     # eslint-config, tsconfig, scripts (optional)
```

Where does new code go?
- Used by one app → **inside that app**, next to its feature. Don't create a package for a single consumer (premature abstraction — extract on second consumer).
- Contract shared between api and web (schemas, DTO types, branded IDs) → `packages/schemas` (or the repo's equivalent). This is where zod schemas live so both sides derive types from one source.
- Pure domain logic shared → `packages/domain-<context>`; UI primitives → `packages/ui`.

## Dependency direction (enforced, not hoped)

- `apps/*` → `packages/*`. **Never** package → app, never app → app.
- Packages form a DAG: no cycles, ever. `domain` doesn't import `db`; `db` may import `domain` types. Infrastructure depends on domain, not the reverse (see `ts-feature-dev` REFERENCE).
- Check with `pnpm ls --depth -1 -r` mentally, enforce with dependency-cruiser or eslint boundaries rules if configured; `knip` for dead exports.

## Manifests

- Internal deps: `"@acme/schemas": "workspace:*"` — the `workspace:` protocol only, never a version range for internal packages.
- Shared third-party versions: `catalog:` (pnpm ≥ 9.5) — define once in `pnpm-workspace.yaml` `catalogs:`, reference as `"zod": "catalog:"`. One version of zod/react/typescript across the repo; drift breaks type identity (two zod instances = incompatible `ZodType`s). `syncpack` if no catalog.
- Every package: `"type": "module"`, `exports` map (not `main`) pointing at source or dist per repo build strategy, `sideEffects: false` when true.
- Internal-packages pattern (common with bundled apps): `exports` points at `./src/index.ts` and the consuming app's bundler compiles it — zero build step for packages. If the repo builds packages (tsup/tsc), keep that instead.

## TypeScript wiring

- `tooling/tsconfig/base.json` holds the strict flags (see `ts-typesafety`); every package extends it and only sets `include`, `outDir`, and quirks.
- `"moduleResolution": "bundler"` + `"module": "esnext"` for bundled code; `nodenext` for packages run directly by node.
- Cross-package types resolve via the `exports` field — avoid `paths` aliases for workspace packages (they lie to non-TS tooling); `paths` is fine app-internally (`~/*` → `./src/*`).
- Project references + `tsc -b` if the repo already uses them; don't retrofit them casually.

## Scripts and CI

- Root scripts fan out: `pnpm -r --parallel run dev`, filtered runs `pnpm --filter @acme/api... build` (`...` = with dependencies).
- Task runner (turbo/nx) if present: declare task inputs/outputs honestly or caching corrupts builds.
- A feature touching `packages/x` must pass `pnpm --filter ...@acme/x test` (the package **and its dependents**) before it's done.
- Versioning/publishing: changesets if configured; internal-only repos usually skip versioning entirely (`workspace:*` + `private: true`).

## Red flags

- A `packages/utils` or `packages/shared` grab-bag absorbing everything → split by domain or dissolve.
- Two versions of the same lib in the lockfile for packages that exchange types.
- An app importing another app's internals "just this once".
- `file:` or relative `../../` imports crossing package boundaries.
