---
name: browser-drive
description: Drive a visible Chromium on the user's machine through the Chrome DevTools Protocol with playwright-core — the user logs in themselves, then the agent fills forms and edits pages on their behalf (LinkedIn, EPSO, Indy, any authenticated site). Use when the user asks to "ouvre une page que je peux voir", "je te log et tu fais les modifs", to fill or edit a website on their account, or mentions playwright, chromium, CDP or piloting the browser. Do not use the plugin's Playwright MCP for this — it is headless in Docker and the user cannot log in.
---

# Browser drive (visible Chromium + CDP)

The plugin's `mcp-server-playwright` runs `--headless` inside Docker: no window, no way for
the user to type a password. For anything behind a login, launch a real Chromium with a
debug port and a dedicated profile, let the user sign in, then drive that tab.

## Quick start

```bash
# 1. Launch (profile is reused: sessions survive restarts). One profile per site.
~/.agents/skills/browser-drive/scripts/launch.sh linkedin https://www.linkedin.com/login

# 2. Tell the user to log in in that window (2FA included). Never take credentials in chat.

# 3. Install the driver once per session, in the scratchpad (never in the project)
cd "$SCRATCHPAD" && npm init -y >/dev/null && npm i playwright-core >/dev/null
cp ~/.agents/skills/browser-drive/scripts/run.mjs .

# 4. Drive: one small script per action, `p` = target tab, `ctx` = context, `fs` available
node run.mjs 'return { url: p.url(), title: await p.title() }'
node run.mjs 'await p.goto("https://…"); return await p.evaluate(() => document.body.innerText.slice(0,500))'
```

`run.mjs` picks the tab whose URL contains `TAB` (env var, default `linkedin.com`) or falls
back to the first tab. Set `TAB=` per call when several sites are open.

## Workflow

1. **Launch and hand over**: launch, ask the user to log in, wait for "c'est bon". Don't poll.
2. **Reduce blast radius first**: on LinkedIn switch off "Partager les mises à jour du profil"
   (`/mypreferences/d/settings/notify-network-for-updates`) before touching any section.
3. **Read before write**: dump the form's inputs (`aria-label`, `labels[0]`, `value`) and the
   dialog's buttons before acting. Selectors guessed from memory fail half the time.
4. **One section per script, wait ≥ 3 s after each navigation**: sites like LinkedIn run an
   anti-bot script (`li.protechts.net … uc=scraping`). Pace like a human, don't parallelise tabs.
5. **Verify on the public page** after each save, and report what is live, not what was sent.
6. **Long loops go in a file** (`node loop.mjs`, timeout up to 600 000 ms) with a per-item
   try/catch and a JSON log; a thrown error mid-loop loses everything otherwise.

## Gotchas that cost time

- **Tab order shifts** after redirects/upsell pages. Select tabs by URL every call, or pin
  `const [P, S] = ctx.pages()` once and re-navigate both explicitly.
- **`locator.click` timeouts** on inputs under a dropdown overlay: focus via `evaluate` and
  use `page.keyboard.type`; pick typeahead options by exact text, else keep free text.
- **Lazy lists** (LinkedIn skills) only load on real `mouse.wheel` over `main`, after
  `mouse.move` onto it; `scrollTo`/`scrollTop` do nothing. Loop until the count is stable ×3.
- **Edit modals open only from the link click**, not from their `/edit/forms/<id>/` URL.
- **`page.screenshot` can hang** on heavy pages; read `innerText` instead.
- **Auto-mode classifier**: batch deletions and bulk external writes get denied even with the
  user's verbal OK. Ask the user to leave auto mode (Shift+Tab) so each command is approved by
  them; never split the batch to slip under it.
- **Chromium closed by mistake**: rerun `launch.sh` with the same profile, the session is kept.

## Site notes

See [LINKEDIN.md](LINKEDIN.md) for the LinkedIn profile editing map (URLs, limits, selectors).
