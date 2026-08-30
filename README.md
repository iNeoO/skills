# skills

Agent skills for [Claude Code](https://claude.com/claude-code), distilled from a shelf of software engineering books (Cockburn, Khononov, Percival & Gregory, Richards & Ford, Despoudis, Di Francesco…) and the official Hono / TanStack Start docs.

They encode one opinion: **every feature should land with the simplest pattern that fits its complexity, typesafe end to end, following the repo's existing conventions.**

## Skills

| Skill | Purpose |
|---|---|
| [`write-spec`](skills/write-spec/SKILL.md) | Behavioral specs, use-case style: goal levels, main success scenario, exhaustive failure extensions, per-stakeholder guarantees, pass/fail checklist |
| [`ts-feature-dev`](skills/ts-feature-dev/SKILL.md) | **Orchestrator** — workflow for implementing a feature on an existing TS app: explore conventions → classify complexity (decision tree) → vertical slice → matching test strategy |
| [`ts-typesafety`](skills/ts-typesafety/SKILL.md) | Parse-don't-validate boundaries, branded types, discriminated unions, `satisfies`, generics discipline, anti-patterns to refuse |
| [`ts-design-patterns`](skills/ts-design-patterns/SKILL.md) | GoF pattern selection table in idiomatic TS (functions & unions over class hierarchies), SOLID translated, anti-patterns |
| [`pnpm-monorepo`](skills/pnpm-monorepo/SKILL.md) | Workspace layout, dependency-direction rules (DAG), `workspace:`/`catalog:`, shared tsconfig, where new code belongs |
| [`hono-api`](skills/hono-api/SKILL.md) | Chained routes for RPC inference, zod validation at every edge, single error envelope, evolution-proof REST conventions, testing |
| [`tanstack-start`](skills/tanstack-start/SKILL.md) | File routes + loaders with TanStack Query, validated server functions, typesafe search params, mutation invalidation, SSR/hydration pitfalls |

How they fit together:

```
write-spec ──► ts-feature-dev ──┬──► ts-typesafety
   (what)        (how, which    ├──► ts-design-patterns
                  pattern)      ├──► pnpm-monorepo
                                ├──► hono-api          (backend slice)
                                └──► tanstack-start    (frontend slice)
```

## Install

```sh
git clone git@github.com:iNeoO/skills.git
cd skills
./install.sh          # symlinks each skill into ~/.claude/skills (repo stays the source of truth)
```

Options:

```sh
./install.sh --copy    # copy instead of symlink (no link back to the repo)
./install.sh --force   # replace existing skills with the same name (backs them up to *.bak)
./install.sh --target <dir>   # install somewhere else (default: ~/.claude/skills)
```

With the default symlink mode, updating is just `git pull`.

## Usage

Skills trigger automatically when the context matches their description, or explicitly:

```
/ts-feature-dev   add a "favorites" feature to the api
/write-spec       spec the CSV export flow
```

`ts-feature-dev` is the entry point for feature work — it routes to the others.

## Conventions baked in

- Existing repo conventions always beat these skills' defaults.
- Complexity classification (from *Learning DDD*): transaction script → active record → domain model → event sourcing, each with its matching architecture and test strategy.
- No speculative abstraction: extract on the second concrete use, not the first.
- All external input parsed at the boundary (zod); no `any`, no unchecked `as`.
