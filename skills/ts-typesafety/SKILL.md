---
name: ts-typesafety
description: Type-safety playbook for TypeScript code — parse-don't-validate boundaries, branded types, discriminated unions, const assertions, generics discipline, and the anti-patterns to refuse (any, bare Function, unchecked as). Use when writing or reviewing TypeScript types, validation, schemas, generics, or when the user mentions typesafe/type safety.
---

# TypeScript Type Safety

Types are the first test suite: make illegal states unrepresentable, then let the compiler do the reviewing.

## Boundaries: parse, don't validate

- Every external input (HTTP body/params/query/headers, env vars, DB rows from raw SQL, third-party API responses, files, messages) enters as `unknown` and is **parsed once** with a schema (zod or the repo's lib). Past that line, code trusts the types — no re-checking, no defensive `?.` chains on data already proven present.
- The schema is the single source of truth: derive the type (`z.infer<typeof Schema>`), never hand-write a duplicate interface.
- Coerce and normalize inside the schema (`z.coerce.number()`, `.trim()`, defaults) so the parsed value is *finished*, not merely legal.

## Model states as discriminated unions

```ts
type LoadState<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: AppError }
```
- No boolean soup (`isLoading` + `isError` + optional `data`): impossible combinations must not typecheck.
- Exhaustiveness: end every `switch` on the discriminant with a `default` that assigns to `never` (or use a `assertNever(x)` helper) so adding a variant breaks compilation everywhere it matters.
- Errors follow the repo's convention: exceptions with typed error classes + central handler, **or** a `Result` union `{ ok: true; value } | { ok: false; error }`. Don't mix. Don't import Go's `[value, err]` tuples.

## Branded types for identifiers and units

TS is structural; two `string` IDs are interchangeable — until a `userId` lands in a `ticketId` slot.

```ts
type Brand<T, B extends string> = T & { readonly __brand: B }
type UserId = Brand<string, 'UserId'>
const UserId = (raw: string): UserId => UserIdSchema.parse(raw) as UserId
```
Brand: IDs, money (integer cents), durations, sanitized strings. The `as` lives in exactly one constructor next to the validation — nowhere else. With zod, `z.string().uuid().brand<'UserId'>()` does both.

## Inference-first, annotations at edges

- Annotate exported/public function signatures; let locals infer. Explicit return types on public API prevent accidental widening and speed up compile.
- `as const` for literal maps and tuples; derive unions from data: `keyof typeof colors`, `(typeof STATUSES)[number]`.
- Prefer `satisfies` over `as` and over annotation when you want checking **and** narrow inference: `const config = {...} satisfies Config`.
- Record-driven logic replaces conditionals and stays exhaustive: `const discount: Record<AccountType, string> = {...}` — adding an `AccountType` member forces the map update.

## Generics discipline

- Name type params descriptively when there's more than one: `<TKey, TValue>`, `<TData, TError>` — not `<T, K>`.
- Always constrain: `<T extends { id: string }>` beats `<T>` + runtime hope. Avoid permissive defaults (`<T = {}>` erases safety).
- `NoInfer<T>` (TS 5.4+) to pin an inference site: `find<T extends string>(haystack: T[], needle: NoInfer<T>)`.
- If a generic exists for a single call site, inline it — generics are for real polymorphism.

## Refuse on sight (anti-patterns)

- `any` → `unknown` + narrowing. Implicit `any` (untyped params) counts.
- Bare `Function` / `object` / `{}` as types → precise signatures.
- `as` outside brand constructors and test fixtures; double casts `as unknown as X` are a design smell — fix the types.
- Non-null `!` in production code → narrow or handle. `noUncheckedIndexedAccess` makes indexing honest; deal with the `undefined`.
- `@ts-ignore`/`@ts-expect-error` without a linked issue comment.
- `Partial<T>`/`Required<T>` assumed deep — they're shallow, one level only.
- Enums: prefer union of literals or `as const` object; if the repo uses enums, follow the repo.
- Classes as bags of getters/setters (Java POJO style) → plain interfaces + factory functions + `Readonly<T>`; immutable update = spread + `Partial<T>` patch.

## tsconfig floor

`strict: true` plus `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`, `noFallthroughCasesInSwitch`, `verbatimModuleSyntax`, `isolatedModules`. In a monorepo these live in the shared base config (see `pnpm-monorepo`). Never weaken a flag to make a feature compile — fix the feature.
