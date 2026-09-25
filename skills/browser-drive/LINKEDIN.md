# LinkedIn profile editing map (own profile, French UI)

Replace `ineoo` with the user's vanity slug. Waits: ≥ 4 s after `goto`, 5–7 s for modals.

| What | Where / how |
|---|---|
| Stop network notifications | `/mypreferences/d/settings/notify-network-for-updates` → `input[type=checkbox]` inside `div._switch…`; click its wrapper, reload, expect "Désactivé" |
| Headline | `/in/<slug>/edit/intro/` → the only `[contenteditable=true]` (max 220 chars, counter `N/220`); `Control+a`, `Delete`, `keyboard.type`, button "Enregistrer"; a Premium upsell page follows, ignore it |
| Infos (About) | `/in/<slug>/edit/forms/summary/new/` |
| Experience list | `/in/<slug>/details/experience/` → links `a[aria-label="Modifier <title> chez <company>"]`; description is a `[contenteditable=true]` with `aria-label^="Description"` |
| Education | `/in/<slug>/details/education/` → `a[aria-label="Modifier la formation <school>"]`; "Diplôme" is a typeahead input `input[aria-label="Diplôme"]` |
| Skills list | `/in/<slug>/details/skills/` — 20 items per view, lazy-loads on `mouse.wheel` over `main` only; each item has `a[aria-label="Modifier la compétence “<name>”"]` with `/forms/<id>/` |
| Delete a skill | click its edit link → button "Supprimer la compétence" → confirm button "Supprimer" |
| Add a skill | `[aria-label="Ajouter une compétence"]` → `input[aria-label="Compétence*"]`, typeahead `[role=option]`; pick the exact standardized entry when it exists (language-independent), free text otherwise. Cap: 100 skills |
| Skill order | No reorder UI: newest first. Only delete+re-add changes the order (loses endorsements) — user decision |
| Projects | `/in/<slug>/edit/forms/project/new/` → `getByLabel("Nom du projet*")`, `textarea[aria-label^=Description]` (2000 chars), selects Mois/Année ×2, select "Associé à" (experiences) |
| Open to work | `/jobs/opportunities/job-opportunities/onboarding/` opens the dialog "Modifier les préférences d’offres d’emploi": chips `button[aria-label^="Supprimer "]`, titles via `input[aria-label="Ajouter un poste"]` (max 5), location/job types are `button[role=checkbox]` |
| Connected apps card | Owner-only suggestion card, not data; dismiss button `[aria-label^="Ignorer les applications connectées"]` |

Typeahead traps: "Tech Lead" → "Chef de projet technique" (wrong), "Product Engineer" →
"Ingénieur produits" (ok), "Hono"/"Bun" have no standardized entry (keep free text).
