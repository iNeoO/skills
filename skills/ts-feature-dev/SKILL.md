---
name: ts-feature-dev
description: Disciplined workflow for implementing a feature in an existing TypeScript codebase (pnpm monorepo, Hono API, TanStack Start frontend). Picks the right design pattern by business-logic complexity, enforces vertical-slice implementation and matching test strategy. Use when asked to add, build, or implement a feature, endpoint, route, module, or use case in an existing TS app.
---

# TypeScript Feature Development

The goal: every feature lands with the **simplest pattern that fits its complexity**, follows the repo's existing conventions, and is typesafe end to end.

## Phase 0 — Explore before writing (non-negotiable)

1. Find 2–3 existing features closest to the one requested (`grep`/glob for similar routes, services, schemas).
2. Note: folder layout, naming, validation library, error-handling convention, test style, which package owns what.
3. **Existing repo conventions beat this skill's defaults.** Mirror them. Only deviate if they violate type safety or correctness, and say so explicitly.
4. In a monorepo, decide which package the feature belongs to *before* coding (see `pnpm-monorepo` skill).

## Phase 1 — Classify the business logic (decision tree)

Ask in order (from Khononov's *Learning DDD* heuristics):

1. **Money movements, legal audit trail, or deep behavior analysis required?**
   → Event-sourced model + CQRS. Rare — flag to the user before committing to it.
2. **Complex rules, invariants, state transitions?** (the spec reads like interdependent rules, not CRUD)
   → **Domain model**: aggregates + value objects, logic in the domain, infrastructure behind ports. Test strategy: mostly unit tests on the domain.
3. **Simple logic but complex data structures?**
   → **Active record / ORM entities** + a thin service layer that orchestrates them. Test strategy: mostly integration tests.
4. **Otherwise (validate input, CRUD, ETL-ish)** →
   → **Transaction script**: the handler *is* the use case. No repository, no domain layer, no ceremony. Test strategy: mostly endpoint/E2E tests.

A rules-heavy feature forced into CRUD corrupts state; a CRUD feature forced into DDD is accidental complexity. Both are bugs. Architecture details and trade-off tables: see [REFERENCE.md](REFERENCE.md).

## Phase 2 — Design the vertical slice

Every feature is a full slice: **entry point → validation → use case → data → response**, plus its tests. Never a horizontal layer "for later".

- **Parse, don't validate** at every boundary (HTTP body/params/query, env vars, external API responses) with the repo's schema lib (usually zod). Inside the boundary, code trusts the types. See `ts-typesafety`.
- One handler = one use case. Handlers stay thin: parse → call use case → map result to response.
- Transactional behavior: an operation either fully succeeds or fully fails. Multiple writes → one transaction. Write + publish/notify → outbox or accept and document the risk. Retryable operations must be idempotent (optimistic concurrency / expected-version).
- Cross-aggregate or cross-module reactions → domain events, not direct calls (see REFERENCE.md).

## Phase 3 — Implement

- Composition over inheritance. Plain functions and interfaces over classes; classes only for genuine state + invariants (aggregates, value objects).
- **No new abstraction until the second concrete use** (YAGNI). Duplication you see twice is a signal, not yet a rule (DRY). Balance: an abstraction must hide complexity without leaking it or inventing new concepts.
- Pattern choice (Strategy vs conditionals, Factory, events…): see `ts-design-patterns`.
- API surface: see `hono-api`. Frontend slice: see `tanstack-start`.
- Errors: use the repo's established channel (exceptions + central handler, or Result union) — never introduce a second competing convention in one codebase.

## Phase 4 — Tests matched to the pattern

| Logic pattern | Dominant tests |
|---|---|
| Domain model | Unit tests on aggregates/VOs (pyramid) |
| Active record + service | Integration tests through the service (diamond) |
| Transaction script | Endpoint/E2E tests on the handler (reversed pyramid) |

Always: at least one test for the unhappy path (invalid input, not-found, conflict) per endpoint.

## Phase 5 — Self-review checklist

- [ ] Feature mirrors existing conventions (naming, layout, error shape)
- [ ] All external input parsed at the boundary; zero `any`, zero unchecked `as`
- [ ] Simplest pattern that fits — no speculative abstraction, no dead code
- [ ] Writes are atomic; retried operations idempotent
- [ ] Breaking API change? If unavoidable, flag it (see `hono-api` versioning)
- [ ] Tests cover happy + unhappy paths at the right level
- [ ] `tsc --noEmit`, lint, and the touched package's tests pass
