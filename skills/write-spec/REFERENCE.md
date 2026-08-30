# Spec Reference — template, quality checklist, worked example

From Cockburn, *Writing Effective Use Cases* (fully dressed template, pass/fail tests, mistakes catalog).

## Fully dressed template

```markdown
# <Goal as short active verb phrase>            e.g. "Register a loss"

**Scope**: <the system treated as a black box>   **Level**: user goal | summary | subfunction
**Primary actor**: <role>
**Context of use**: <longer goal statement / when this normally happens>
**Trigger**: <the event that starts it>
**Preconditions**: <what the system GUARANTEES is already true — never re-checked below>

**Stakeholders & interests**
- <actor>: <what they want>
- <business>: <usually: gets paid / no fraud / consistent data>
- <regulator or audit>: <usually: procedure followed, trail kept>

**Minimal guarantees** (hold on ANY exit): <e.g. no partial write persists; attempt logged>
**Success guarantees**: <state of the world when the goal is delivered — covers every interest>

**Main success scenario**
1. <Actor> <verb> <object> [<prepositional phrase>]
2. System validates <rule>.
3. …                                             (3–9 steps, trigger → goal + bookkeeping)

**Extensions**
*a. <any-time condition>:
    *a1. <handling>
2a. <what the system detected>:
    2a1. <handling steps — same writing rules>
    2a2. <ends: continue | retry step 2 | alternate success | FAIL (minimal guarantees hold)>
3a. …

**Technology & data variations**
1. <step #>: <variation list — e.g. repay by check, EFTS, or purchase credit>

**Data**: <packet name> = {field, field, …} with formats/constraints
**Business rules**: <numbered, referenced from steps/extensions>
**Open issues**: <every question you could not answer — never invent the answer>
```

Casual format keeps: title, actor, level, one paragraph for the main scenario, one paragraph per notable failure, guarantees if money/compliance is involved.

## Pass/fail quality checklist (all answers must be YES)

**Frame**
- Title is an active-verb goal phrase of the primary actor, and the system can deliver it
- Scope treated as a black box; level stated and matched by the content
- Preconditions are enforced by the system and never re-checked in the body
- Primary actor has behavior and a goal that is a service promise of the system

**Guarantees**
- Stakeholders named; minimal guarantees protect every interest on failure; success guarantees satisfy every interest

**Main scenario**
- 3–9 steps, trigger to success-guarantee delivery, correct sequencing freedom noted

**Each step**
- Phrased as a sub-goal that succeeds and moves the process distinctly forward
- The acting actor is the sentence's first words; the intent (not UI movement) is described
- Information passed is named; "validates", never "checks whether"; no `if`

**Extensions**
- Every condition is detectable by the system AND requires handling
- Every "validates" in the body has its failure extension; every called sub-spec's failure is handled
- Timeouts/inaction covered; supporting-system failures covered; internal failure with visible effect covered
- Conditions with identical net effect merged; sub-failures rolled up

**Set level**
- The specs unfold as a story from summary to user goals; a context-level spec exists per primary actor
- Sponsor answers yes to: "Is this what you want?" "Can you verify it on delivery?" "Is this everything?"
- Developer answers yes to: "Can you implement this?"

## Mistakes catalog (before → after)

1. **No system** — steps only show the user acting. → Name every actor including the system: *"ATM validates PIN against the card."*
2. **No primary actor** — written from inside the system ("Collects card. Validates funds. Dispenses."). → Bird's-eye view, subject on every sentence.
3. **UI details** — "System displays login screen… user clicks OK". → *"User accesses system with ID and password. System validates user."*
4. **Too-low goal level** — 12+ micro-steps (provide name / provide address / open connection / request stock levels). → Merge same-direction data; ask "why?" to lift ("System validates with the warehouse that quantity is in stock").
5. **Purpose ≠ content** — a "Login" spec that actually specifies the whole main menu, or programming constructs (loops, if/else) in prose. → Split; one goal per spec; plain language.
6. **Precondition as wish** — "Customer has submitted at least one claim" when the system can't ensure it and the flow shouldn't require it. → Preconditions only for system-enforced state.
7. **Ellipse worship** — a diagram is a table of contents, never the spec. The spec is text.

## Worked micro-example (sea level, condensed)

```markdown
# Withdraw cash
Scope: ATM · Level: user goal · Primary actor: Account holder
Trigger: Customer inserts card.
Minimal guarantees: card returned; every attempt logged; account never debited without cash dispensed.
Success guarantees: cash dispensed, account debited same amount, receipt offered, transaction logged.

Main success scenario:
1. Customer inserts card; ATM reads bank ID, account, encrypted PIN.
2. Customer enters PIN; ATM validates it against the card.
3. Customer selects withdrawal and amount (multiple of 5).
4. ATM validates amount against balance and daily limit with the banking system.
5. ATM dispenses cash, returns card, offers receipt, logs the transaction.

Extensions:
*a. Banking network down: *a1. ATM aborts, returns card, logs outage. FAIL.
2a. PIN invalid: 2a1. ATM notifies, re-requests PIN (max 3). 2b. Three failures: ATM keeps card. FAIL.
4a. Insufficient funds or over limit: 4a1. ATM notifies, asks new amount → step 3.
5a. Cash dispenser jams: 5a1. ATM reverses the debit, notifies customer & ops, logs incident. FAIL.
5b. Customer doesn't take card (time-out): 5b1. ATM retracts card, flags account, logs event.
```
