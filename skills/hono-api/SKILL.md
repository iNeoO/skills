---
name: hono-api
description: Patterns for building typesafe Hono APIs — chained routes for RPC inference, zod validation at the boundary, consistent error envelopes, REST conventions (pagination, versioning, status codes), middleware, and testing. Use when creating or modifying Hono routes, endpoints, middleware, or API contracts, or when the user mentions Hono, hc client, or REST API design.
---

# Hono API Patterns

## App composition and RPC type inference

- One sub-app per resource/feature, composed at the root. **Chain route definitions** — RPC inference only sees chained routes:

```ts
// features/books/routes.ts
export const booksRoutes = new Hono<AppEnv>()
  .get('/', zValidator('query', ListBooksQuery), (c) => {/*…*/})
  .post('/', zValidator('json', CreateBookBody), async (c) => {
    const body = c.req.valid('json')          // typed by the schema
    const book = await createBook(deps(c), body)
    return c.json(toBookDto(book), 201)
  })

// app.ts
const app = new Hono<AppEnv>().route('/books', booksRoutes)
export type AppType = typeof app              // consumed by hc<AppType>()
```

- Handlers **inline** after the path (official guidance: path params and validators can't infer through detached controllers). If extraction is unavoidable, `createFactory().createHandlers(...)` from `hono/factory` — never a loose `(c: Context) => …` function.
- Handler stays thin: `c.req.valid(...)` → call use case → map to DTO + status. Business logic lives in the use case (see `ts-feature-dev`), not in the handler.
- Type the env once: `type AppEnv = { Variables: { user: User; db: Db }, Bindings: {...} }` and use `Hono<AppEnv>` everywhere; `c.set`/`c.get`/`c.var` are then typed.

## Validation at every edge

- `@hono/zod-validator` on **each** of `json`, `param`, `query` used by the route. Schemas live with the feature (or in `packages/schemas` when the frontend consumes them — see `pnpm-monorepo`); types derive via `z.infer`, never duplicated (see `ts-typesafety`).
- Response DTOs are explicit mappings from domain objects — never `c.json(dbRow)`: it leaks columns and freezes your schema to the DB shape.

## Errors: one envelope, one handler

- Throw `HTTPException(status, { message })` (or the repo's typed error classes) from handlers/use cases; convert **once** in `app.onError`:

```ts
app.onError((err, c) => {
  if (err instanceof HTTPException) return err.getResponse()
  logger.error(err)                                   // full detail server-side
  return c.json({ error: { code: 'internal', message: 'Internal error' } }, 500)
})
```

- Accurate status codes — clients build logic on them: 400 validation, 401/403 auth, 404, 409 conflict/version, 422 semantic, 500. Never a 200 carrying an error body.
- Never leak stack traces or internals to consumers; detail goes to logs.
- `app.notFound` for a consistent 404 shape.

## REST conventions (evolution-proof)

- Collections return an **object**, not a bare array: `{ items: [...], nextCursor?: string }` — pagination can then be added without a breaking change. Prefer cursor over offset.
- No PII in URLs (paths and query strings get cached/logged) → opaque IDs.
- Compatibility: adding optional fields = safe; renaming/removing/retyping = **breaking** → new major version (`/v2`) or explicit user sign-off. When an OpenAPI spec exists, diff it in CI (oasdiff).
- Consistent naming across the API (one data dictionary: `createdAt` everywhere, not `created_at` here and there).
- Need a published spec? `@hono/zod-openapi` (`createRoute` + `OpenAPIHono`) — schemas stay the single source of truth.

## Middleware

- Order matters: requestId/logger → CORS → auth → rate limit → routes. Scope middleware to the sub-app that needs it, not globally by reflex.
- Custom middleware via `createMiddleware<AppEnv>` to keep `c.var` typed.
- CoR-style: each middleware does one thing and calls `await next()`.

## Testing

- Endpoint tests without a server: `await app.request('/books', { method: 'POST', body })` or the typed `testClient(app)` from `hono/testing`; assert status **and** body shape.
- Inject fakes through the deps/env, not by module-mocking internals (ports & adapters pays off here).
- Minimum per endpoint: happy path + invalid input (400) + not-found/conflict path.
