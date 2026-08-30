---
name: ts-design-patterns
description: Design-pattern selection catalog for idiomatic TypeScript — when each GoF/architecture pattern earns its place, its modern TS form (functions and unions over class hierarchies), proven combinations, and the anti-patterns to avoid (class overuse, God objects, over-abstraction). Use when choosing how to structure new logic, refactoring conditionals, or when the user mentions design patterns, strategy, factory, observer, singleton, or SOLID.
---

# TypeScript Design Patterns

A pattern is a vocabulary word, not a goal. Reach for one when its *problem* is present; the modern TS form is usually a function, a union, or a plain object — not a class hierarchy. When in doubt: no pattern.

## Selection table

| You observe | Pattern | Idiomatic TS form |
|---|---|---|
| Behavior varies by a known discriminant; growing if/else | **Strategy** | `Record<Kind, (input) => Output>` map; exhaustive by construction |
| Object creation logic is complex or type chosen at runtime | **Factory** | Plain function returning a union/interface; map of constructors |
| Exactly one instance per process (config, logger, db pool) | **Singleton** | Module-level `export const` — the ESM module cache is the singleton. Beware: duplicate package versions in node_modules = duplicate "singletons". Prefer passing deps explicitly (DI) when testability matters |
| Incompatible interface between your code and a lib/legacy | **Adapter** | Function/object mapping one interface to the port your domain defines |
| Complex subsystem needs one simple entry point | **Facade** | One exported function per use case hiding the orchestration |
| Add behavior without touching the target (log, cache, retry, authz) | **Decorator/Proxy** | Higher-order function wrapping the original (`withRetry(fn)`); ES `Proxy` for property-level interception only |
| Request should traverse configurable handlers | **Chain of Responsibility** | Middleware pipeline (Hono/Express style) `(ctx, next) =>` |
| One event, many decoupled reactions | **Observer / domain events** | Typed emitter or event map `Record<EventName, Payload>`; past-tense names |
| Operations as data (queue, undo, audit) | **Command** | Discriminated union of command objects + one executor |
| Behavior depends on lifecycle state with legal transitions | **State** | Discriminated union + transition function; XState if the chart is big |
| Traverse a structure without exposing internals | **Iterator** | Generators (`function*`), `Symbol.iterator` |
| Many similar objects, memory pressure | **Flyweight** | Cache keyed by shared state (`Map`), interned values |
| Step-by-step construction, many optional parts | **Builder** | Usually **not needed**: options object + defaults + `satisfies`. Real builder only for multi-representation construction |
| Clone configured instances | **Prototype** | `structuredClone(obj)` — not JSON.parse(JSON.stringify) (loses Date/Map/Set, breaks on cycles) |

Combinations that pull weight: Strategy+Factory (pick the strategy from config), middleware(CoR)+Decorator (cross-cutting concerns), Observer+Command (event-driven writes), Facade over module boundary (public API of a package).

## SOLID, translated to TS

- **S**: a module has one reason to change — split `User` from `UserAccountService`/`EmailService`; don't grow God objects.
- **O**: extend via data, not edits — replace `if (user.isPremium())…` chains with a `Record<AccountType, Voucher>` map; new case = new entry.
- **L**: a narrower implementation must not surprise callers (no new throws, no side effects the interface doesn't imply).
- **I**: small interfaces; compose (`Reader`, `Writer`) instead of one fat `Collection` with optional methods.
- **D**: use cases receive their ports (interfaces) as parameters/constructor args; concrete adapters wired at the composition root. That's what makes fakes trivial in tests.

SOLID + DRY + KISS can't all be maximized at once; they're tools, not laws. When they conflict, prefer the simplest code that passes the tests and reads clearly.

## Anti-patterns (refuse or refactor)

- **Class overuse / jungle problem**: importing a `Jungle` to get a `Banana`. If a class has no invariants to protect, it should be an interface + functions. Composition over inheritance; inheritance deeper than one level is almost always wrong in TS.
- **Partial reuse via extends** (`ExcelToPDF extends ExcelToCSV extends CSV`): split into capability interfaces (`Reader`, `Writer`) and compose (black-box reuse).
- **God object / God service**: one class knowing everything. Symptom: its name is `Manager`, `Util`, `Helper`, `Service` with 20 methods.
- **Over-abstraction**: a wrapper introducing its own concepts and config language for a simple need — or an oversimplified one hiding levers you need. The interface must expose exactly the required levers, nothing more (balanced abstraction).
- **Under-abstraction / leaky**: callers forced to know implementation details or repeat themselves. Repetition twice = signal; abstract on the second or third concrete use, not the first.
- **Pattern cargo-culting**: Builder for a 2-field object, Repository over a single query, Observer for one subscriber. Patterns have carrying costs — indirection, naming burden, onboarding cost.

For choosing the *scale* of structure (transaction script vs domain model, layers vs hexagonal), use `ts-feature-dev` and its REFERENCE.md. For type-level techniques backing these patterns, see `ts-typesafety`.
