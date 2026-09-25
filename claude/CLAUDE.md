# Personal Skills — reach for one without being asked

Skills live in `~/.claude/skills/` (symlinks into `~/.agents/skills` and
`~/github/ineoo/skills`), so they are available in every session and every repo. When a trigger
below matches the task at hand, **invoke the skill instead of improvising** — no need to wait for
`/the-name`. Announce which one you picked in one line, then follow it.

Precedence: a repo's own `.claude/skills/` wins over a personal skill of the same purpose; the
Constitutional Rules below win over both. If two triggers match, the narrower skill wins
(`hono-api` over `ts-feature-dev` for a route). One skill at a time.

## TypeScript / JS stack

| When | Skill |
|---|---|
| Writing or reviewing TS types, zod schemas, generics — or tempted by `any` / an unchecked `as` | `ts-typesafety` |
| Deciding how to structure new logic, or refactoring a pile of conditionals | `ts-design-patterns` |
| Adding a feature, module or use case to an existing TS app | `ts-feature-dev` |
| Creating or changing a Hono route, middleware, RPC contract, error envelope | `hono-api` |
| Touching TanStack Start routes, loaders, server functions or TanStack Query code | `tanstack-start` |
| Adding a package or a dependency, or deciding which package owns new code | `pnpm-monorepo` |
| Killing `as` casts in test fixtures | `migrate-to-shoehorn` |

## Before writing code

| When | Skill |
|---|---|
| A feature needs specifying before it is built — requirements, use case, user flow | `write-spec` |
| A plan or design needs stress-testing before commitment | `grill-me` (`grill-with-docs` when the repo has CONTEXT.md / ADRs to challenge it against) |
| A data model, state machine or UI shape is still an open question | `prototype` |
| One module's interface is worth exploring several ways | `design-an-interface` |
| A refactor needs breaking into safe incremental commits | `request-refactor-plan` |

## While building

| When | Skill |
|---|---|
| Building a feature or fixing a bug where a test can be written first | `tdd` |
| A hard bug or a performance regression — reproduce, minimise, instrument, fix | `diagnose` |
| Setting up commit-time formatting / typecheck / tests in a repo | `setup-pre-commit` |
| Writing a new skill | `write-a-skill` |

## After building

| When | Skill |
|---|---|
| Reviewing a branch, a PR, or work in progress against standards and spec | `review` |
| Auditing a codebase for improvements, or asking where the project should go next | `improve` (read-only; produces plans for others to execute) |
| Looking for architectural deepening — coupling, testability, consolidation | `improve-codebase-architecture` |
| The user is reporting bugs conversationally and wants them filed | `qa` |

## Tracker and handover

| When | Skill |
|---|---|
| Turning the conversation into a PRD | `to-prd` |
| Breaking a plan or PRD into independently-grabbable issues | `to-issues` |
| Creating, triaging or preparing an issue for an unattended agent | `triage` |
| The context is getting long and another agent must pick the work up | `handoff` |
| Jira ticket IDs handed over to port from the old backend to the new one | `jira-backport` |
| Scaffolding exercise directories in a course repo | `scaffold-exercises` |

## Only on explicit request

`teach`, `zoom-out` and `setup-matt-pocock-skills` are user-invoked only
(`disable-model-invocation`) — never trigger them yourself. `caveman` is model-invocable but is a
style choice, not a task: wait for the user to ask for it.

---


# Work context

Company-specific context and policies stay out of this public repo. They live in a local file
that `install.sh --dotfiles` creates from any `# … Company Context` section of the previous CLAUDE.md:

@~/.claude/CLAUDE.work.md
