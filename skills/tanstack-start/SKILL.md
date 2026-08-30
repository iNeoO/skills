---
name: tanstack-start
description: Patterns for TanStack Start applications — file-based routes, loaders with TanStack Query, server functions with validated input, typesafe search params and links, mutations with invalidation, and SSR/hydration pitfalls. Use when creating or modifying TanStack Start routes, loaders, server functions, or React data-fetching code, or when the user mentions TanStack Start/Router/Query.
---

# TanStack Start Patterns

Everything routes through the type graph: file routes generate types, schemas validate edges, `Link`/`navigate` are checked. If you're typing a URL string by hand, you've left the safe path.

## Routes and loaders

- File-based routes via `createFileRoute`; the generated `routeTree.gen.ts` is never edited by hand.
- Data needed to render → the **loader**, so SSR streams it and navigation preloads it. Component-level fetching is for optional/late data only.
- Standard pairing with TanStack Query — define `queryOptions` once, ensure in loader, consume with suspense:

```ts
const postQuery = (id: PostId) => queryOptions({
  queryKey: ['posts', id],
  queryFn: () => fetchPost({ data: id }),   // server function
})

export const Route = createFileRoute('/posts/$postId')({
  params: { parse: (p) => ({ postId: PostIdSchema.parse(p.postId) }) },
  loader: ({ context: { queryClient }, params }) =>
    queryClient.ensureQueryData(postQuery(params.postId)),
  component: PostPage,
})

function PostPage() {
  const { postId } = Route.useParams()
  const { data } = useSuspenseQuery(postQuery(postId))
  …
}
```

- Route-level `errorComponent` / `notFoundComponent` and `pendingComponent` instead of ad hoc if-states in the page.

## Server functions

- `createServerFn` for anything touching secrets, DB, or server-only libs. **Always validate input** — the wire is a boundary (see `ts-typesafety`):

```ts
export const createPost = createServerFn({ method: 'POST' })
  .validator(CreatePostSchema)          // older/newer versions: .inputValidator — match the repo
  .handler(async ({ data }) => {        // data: z.infer<typeof CreatePostSchema>
    return await insertPost(data)       // thin: delegate to the use case
  })
```

- Control flow: `throw redirect({ to: '/login' })`, `throw notFound()` — they propagate correctly through loaders and clients.
- Handlers stay thin and delegate to use cases (pattern choice: `ts-feature-dev`). If a separate Hono API already owns the domain, call it through the `hc` RPC client (`hono-api`) rather than duplicating logic in server functions.
- In components, wrap with `useServerFn(fn)` before passing to Query/handlers.

## Search params as first-class state

- Filters, tabs, pagination → the URL, validated: `validateSearch: SearchSchema.parse` on the route. Read with `Route.useSearch()`, update with `navigate({ search: (prev) => ({...prev, page}) })`.
- Never `useState` for state that should survive reload/sharing.

## Mutations

- Server function + `useMutation`; on success invalidate **both** caches that matter: `queryClient.invalidateQueries(...)` and `router.invalidate()` (loaders).
- Optimistic updates only where UX demands it; always with rollback in `onError`.

## Component patterns (from reactive-UI patterns)

- Hooks are the reuse unit — extract `useX()` before extracting components; render props / HOCs are legacy answers to the same problem.
- Context/provider only for genuinely cross-cutting values (theme, auth, di) — not to avoid passing two props; every consumer rerenders on change, so keep context values stable and split them.
- Colocate state at the lowest owner; lift only when two siblings need it.

## SSR & hydration pitfalls

- No `window`/`document`/`localStorage` at module scope or first render — guard in effects or `<ClientOnly>`.
- Hydration mismatch sources: `Date.now()`, `Math.random()`, locale formatting differing server/client → compute in loader or effect, use stable IDs (`useId`).
- Heavy, below-the-fold, or interaction-only components → `lazy()` + route-based splitting (automatic per route; don't hand-split prematurely).

## Checklist

- [ ] Params/search validated by schema; no `as` on route data
- [ ] Data for first paint in loaders; suspense components, no loading-boolean soup
- [ ] Server functions validate input and delegate; secrets never in client bundles
- [ ] Mutations invalidate router + query caches
- [ ] No window access during SSR/first render
