---
name: write-spec
description: Generate high-quality behavioral specifications (use-case style, from Cockburn's Writing Effective Use Cases) for features — goal-level calibration, main success scenario, exhaustive failure extensions, per-stakeholder guarantees, and a pass/fail quality check. Use when asked to write a spec, functional requirements, use case, user flow, or to specify a feature before implementation.
---

# Writing Effective Specs

A spec is a **contract for behavior**: it describes how the system protects every stakeholder's interests while the primary actor pursues a goal. It is prose, black-box, and UI-free. The failures are where the real requirements live — the happy path is the easy half.

## Process (breadth-first — never depth-first)

Work each pass across the *whole* feature before deepening. Precision multiplies work, so spend it late:

1. **Scope & actors** — what system is the black box? Who are the primary actors? List actor → goal pairs. In an existing codebase, read the neighboring features first: reuse their vocabulary (ubiquitous language), don't invent synonyms.
2. **Calibrate the goal level** (see below). One spec = one user goal.
3. **Stakeholders & guarantees — before the scenario.** 2–5 stakeholders (primary actor, the business, often a regulator/auditor, ops). For each: their interest, the **minimal guarantee** (what holds even on failure — almost always includes "the attempt is logged / no partial state persists") and the **success guarantee**. Ask "what would make this stakeholder unhappy at the end?" and write the negation. Writing guarantees first surfaces the validations the scenario needs.
4. **Main success scenario** — 3 to 9 steps, trigger → goal delivered + bookkeeping done.
5. **Brainstorm extension conditions exhaustively** (list first, handle later — fixing each one as you find it exhausts you before the list is complete). Then rationalize the list.
6. **Write extension handling** — this is where new business rules, actors, and even new specs are discovered; budget most of the effort here.
7. **Attach the non-behavioral sections**: data fields (precise names/formats, one level of detail down), business rules, NFR notes, open issues. The spec is the hub; these are the spokes.
8. **Run the pass/fail checklist** in [REFERENCE.md](REFERENCE.md) and deliver with open questions explicitly listed — never silently invent a business rule.

## Goal levels — one spec sits at sea level

- **User goal (sea level)** — the spec's home. Tests: one person, one sitting (2–20 min); the actor can walk away happy after; a clerk could "count" these toward their day's work. *"Buy a book"*, *"Register a loss"* — not *"Log in"* (subfunction), not *"Manage account"* (summary).
- **Summary** — groups several user goals; write a couple only as a table of contents/context for the set.
- **Subfunction** — write only if reused by several specs or too bulky inline; otherwise fold it back in.
- Wrong level is the #1 spec smell. Too low → ask **"why is the actor doing this?"** to climb; >9 steps means UI details or too-low steps: merge them.

## Writing rules for steps

- **One sentence form**: present tense, active voice, actor first — *"Clerk enters basic loss information. System assigns a claim number."* Every step is a sub-goal that **succeeds** and moves the process forward. Always clear who "has the ball".
- **Intent, not movements**: never screens, buttons, clicks, field-by-field dialogs. *"User accesses system with ID and password"* — not "System displays login screen, user types…". UI detail makes the spec long, brittle, and steals the designer's job.
- **"Validates", never "checks whether"**: no `if` in the body — the reader sees "System validates X" and knows to look for extension *"X invalid:"*. All branching lives in extensions.
- Merge all data flowing one direction into one step; name the packet (*"personal information"*) and detail its fields in the data section.
- Sequencing idioms when needed: *"Steps 3–5 can happen in any order"*, *"User repeats 3–4 until done"*, *"User has the system fetch X from system B"*.

## Extensions — where the spec earns its keep

- Brainstorm against every step: alternate success paths; invalid input; **inaction/timeout**; every "validates" failing; supporting system down/slow/garbage; internal failures with visible consequences (corrupt state, missing data); performance limits exceeded.
- A condition is **what the system detects**, past-tense fragment ending in a colon: *"Time-out waiting for PIN:"* — never *"User forgot PIN"* (undetectable). Keep only conditions the system **can detect and must handle**; merge conditions with the same net effect (*"Card unreadable or non-ATM card:"*); roll sub-failures up as one condition (*"Save fails:"*).
- Number `3a`, `3a1`; `*a` for any-time conditions; indent handling. Each fragment ends one of four ways: step repaired → continue; retry the step; alternate path to success; use case fails **with minimal guarantees intact**.
- "There are several ways to do this step" (payment by card/transfer/credit) is a **technology & data variation**, not an extension.

## Ceremony — match effort to the cost of misunderstanding

Casual format (paragraphs, main scenario + notable failures) for a co-located team feature with tight feedback; fully dressed (numbered template in REFERENCE.md) for cross-team contracts, external APIs, money, compliance. When in doubt **write less at a higher level** — a short spec gets read and provokes the questions that complete it; a 100-page low-level one shuts communication down. Stop polishing once wording changes no longer change decisions.

## Hand-off

A finished spec feeds directly into: implementation slices (`ts-feature-dev` — each extension is an unhappy-path branch the code must handle), test cases (each scenario + each extension ≈ one test), and issue breakdown. Boundary schemas (`ts-typesafety`) implement the spec's validations; the data section becomes the zod schema field list.
