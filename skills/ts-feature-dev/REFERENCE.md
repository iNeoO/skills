# Architecture Reference — patterns, trade-offs, building blocks

Distilled from *Learning Domain-Driven Design* (Khononov), *Architecture Patterns with Python* (Percival & Gregory), *Fundamentals of Software Architecture* (Richards & Ford), adapted to TypeScript.

## Architectural pattern per logic pattern

| Business logic | Architecture | Why |
|---|---|---|
| Transaction script | Minimal layering (route → handler → db) | The handler already is the service layer; adding one duplicates it |
| Active record | Layered + explicit service layer | The orchestration logic controlling the records needs a home |
| Domain model | Ports & adapters (hexagonal) | Domain must not depend on infrastructure; dependencies point inward |
| Event-sourced domain model | CQRS mandatory | Events alone can't serve queries; project read models |

CQRS is also legitimate without event sourcing whenever the same data needs several persistent representations (operational DB + search index + analytics). A command may return data — as long as it comes from the strongly consistent model.

**Scope warning:** these are per-module decisions, not app-wide ones. A single app legitimately mixes a domain-model module for its core with transaction scripts for supporting endpoints. Forcing one architecture on the whole codebase creates accidental complexity.

## Layer vocabulary (equivalences you'll meet in the wild)

- Presentation = user interface = routes/handlers
- Service layer = application layer = use cases
- Business logic layer = domain layer = core
- Data access layer = infrastructure layer = adapters

Rule: layers depend downward (layered) or point inward to the domain (hexagonal). The domain layer imports **nothing** from infrastructure — it defines ports (interfaces); adapters implement them and are wired at the composition root.

## Tactical building blocks (when the domain model is warranted)

**Value object** — identified by its values, immutable, validates itself in its constructor/parse. Use for anything with rules or units: `Money`, `EmailAddress`, `TicketPriority`. Kills primitive obsession; in TS, pair with branded types (`ts-typesafety`). Money on raw `number` is a known bug factory (rounding) — always a VO or integer cents.

**Aggregate** — a consistency boundary: a hierarchy of entities + VOs that must be strongly consistent *together*.
- State changes only through its public methods (commands); outside code reads but never mutates internals.
- **One aggregate per transaction.** Needing two in one transaction means the boundary is wrong.
- Keep aggregates as small as the invariants allow. Reference other aggregates by ID only.
- Concurrent updates: version field + `WHERE version = expected` (optimistic concurrency), fail → retry.

**Domain event** — past-tense fact (`TicketEscalated`) emitted by an aggregate; other modules subscribe. Use for cross-aggregate/cross-module consistency (eventual) and side effects (email, analytics). Cons to respect: synchronous handlers hide latency in commits; chains of handlers obscure the flow; circular subscriptions loop. Keep the handler graph shallow and documented. Reliable publication alongside a DB write → outbox pattern.

**Domain service** — stateless function/object hosting logic that reads several aggregates but belongs to none. Not a loophole around one-aggregate-per-transaction.

## Repository / Unit of Work — costs and benefits (be honest)

- Repository: easy fakes for tests, domain decoupled from persistence — but it's an extra indirection, and a good ORM/query builder already decouples a lot. **Plain CRUD does not need a repository or a domain model.** Investment pays off only as domain complexity grows.
- Service layer: single place listing the use cases, testable without HTTP — but if the app is a thin web app, handlers already play this role; introduce it when orchestration starts leaking into handlers, not before.
- Unit of Work: explicit atomic blocks, safe-by-default rollback — but your ORM (Prisma `$transaction`, Drizzle `db.transaction`, Kysely) already provides it; wrap only to narrow the interface, don't reinvent.

## Modularity guardrails (any pattern)

- High cohesion inside a module, minimal knowledge between modules. Depend on interfaces at boundaries.
- A change that routinely fans out across many packages signals wrong boundaries — prefer wider modules you can split later over premature fine-grained ones (logical splits are cheap, physical splits are expensive).
- Watch afferent/efferent coupling when adding imports: a "shared" package that everything imports and that imports everything is a ball of mud in disguise.
