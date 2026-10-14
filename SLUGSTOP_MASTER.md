# SlugStop — master prompt

## What it is (plain)

SlugStop is a small guard on your PC for **Cursor Agent**. It does **not** change the model menu when you switch chats. When you hit **Send**, it checks whether the model you picked is one you allow. If not, the message does not go out and Cursor shows a short note. Rules live in a local config file. No SlugStop server—only Cursor’s documented **user hooks** in `%USERPROFILE%\.cursor`.

**Tech one-liner:** Send-time slug gate on `beforeSubmitPrompt` / `subagentStart` using hook JSON `model`, `model_id`, and `subagent_model`.

**Docs:** https://cursor.com/docs/hooks

---

## Build boundary

- **SlugStop only.** Do not modify CriticalRange Species Guard or unrelated repos in this workspace.
- **Windows first:** PowerShell hook script; no npm, Python, or cloud service.
- **Do not run `install.ps1` or commit** unless the user explicitly asks (user may want `:) ` command blocks only).

---

## Non-goals

| Out of scope | Why |
|--------------|-----|
| Fix model picker on tab switch | No public API; hooks run at send/subagent |
| Tab inline completions | v1 is Agent only |
| Hard-pin model in Cursor Settings | User sets **Default model → Last used** manually |
| Vendor names in product/branding | Block slugs in **config** only (e.g. `"grok"`) |
| Cloud agents via `~/.cursor` | Cloud uses project `.cursor/hooks.json`; user hooks are local IDE |

---

## Repository layout

```
slugstop/
  SLUGSTOP_MASTER.md      ← this file
  README.md               ← install, config, test (human-facing)
  install.ps1             → copies into %USERPROFILE%\.cursor
  hooks.json              ← hook registration (paths relative to ~/.cursor)
  hooks/
    slugstop.ps1          ← single handler for all events
    slugstop.config.json
    logs/                 ← created at runtime; gitignore
  .gitignore
```

**Install target**

```
%USERPROFILE%\.cursor\
  hooks.json
  hooks\slugstop.ps1
  hooks\slugstop.config.json
```

Cursor runs user hooks with **cwd = `~/.cursor`**. Use `./hooks/slugstop.ps1` in `hooks.json`.

---

## Hook events (v0.1)

| Event | When | stdout JSON |
|-------|------|-------------|
| `beforeSubmitPrompt` | User hits Send | `{ "continue": true \| false, "user_message"?: string }` |
| `subagentStart` | Task subagent spawns | `{ "permission": "allow" \| "deny", "user_message"?: string }` |
| `sessionStart` | New Agent chat | `{ "additional_context"?: string }` — informational only |

Common input fields: `hook_event_name`, `model`, `model_id`, `model_params`, `workspace_roots`, `conversation_id`, …  
Extra: `prompt` (+ `attachments`) on submit; `subagent_model`, `subagent_type`, `task` on subagent.

On hook script failure: default **fail-open** unless hook entry sets `"failClosed": true`.

---

## Config (`hooks/slugstop.config.json`)

```json
{
  "allowed_patterns": ["composer", "claude-", "gpt-", "gemini-", "inherit"],
  "blocked_patterns": ["grok"],
  "bypass_prefix": "[slug:any]",
  "deny_submit_message": "SlugStop: this model isn't on your allow list. Switch the picker or start with [slug:any] on its own line.",
  "deny_subagent_message": "SlugStop: subagent model blocked. Change parent chat model or edit slugstop.config.json.",
  "session_context": "SlugStop: blocked model slugs can't send unless the prompt starts with [slug:any].",
  "audit_log": true
}
```

**Matching (implement exactly)**

1. Haystack = lowercase(`model` + space + `model_id` + space + optional `subagent_model`).
2. Any **blocked_patterns** substring in haystack → **deny**.
3. Else if **allowed_patterns** is non-empty → **allow** only if any allowed substring matches; else **deny**.
4. Else if **allowed_patterns** is empty → **allow** unless blocked.

**Bypass (submit only)**

- Environment: `SLUGSTOP_OFF=1` → allow.
- Prompt: line-start match on `bypass_prefix` (regex-escape the prefix) → allow. Do not strip prefix in v0.1.

**Audit:** if `audit_log`, append ISO lines to `hooks/logs/slugstop.log`.

---

## `hooks.json`

```json
{
  "version": 1,
  "hooks": {
    "beforeSubmitPrompt": [
      {
        "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"./hooks/slugstop.ps1\"",
        "timeout": 8
      }
    ],
    "subagentStart": [
      {
        "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"./hooks/slugstop.ps1\"",
        "timeout": 8
      }
    ],
    "sessionStart": [
      {
        "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"./hooks/slugstop.ps1\"",
        "timeout": 5
      }
    ]
  }
}
```

---

## `slugstop.ps1` contract

1. Read full stdin JSON; empty → allow (`{"continue":true}` or `{}`).
2. Load `$PSScriptRoot\slugstop.config.json` (UTF-8).
3. Switch on `hook_event_name`; emit **one line** JSON; exit `0`.
4. No external modules; `ConvertFrom-Json` / `ConvertTo-Json -Compress`.
5. User-facing deny text from config only—not hard-coded vendor names in code.

Keep script **≤ ~100 lines**.

---

## `install.ps1`

1. `$root = Join-Path $env:USERPROFILE ".cursor"`.
2. Ensure `$root\hooks` exists.
3. Copy `hooks\slugstop.ps1` → `$root\hooks\`. Copy `slugstop.config.json` only if missing (never clobber user edits). Copy repo `hooks.json` → `$root\hooks.json`; if one already exists, write `hooks.json.bak-<timestamp>` first.
4. Print config path; remind: reload Cursor / new Agent chat. If backup had non-SlugStop hooks, merge those entries into the new `hooks.json` instead of deleting the backup.

**Uninstall:** remove `$root\hooks.json`, `$root\hooks\slugstop.ps1`, `$root\hooks\slugstop.config.json`, optional `hooks\logs\`.

---

## Manual acceptance test

1. Install; open Agent; pick a blocked slug in the picker.
2. Send `hello` → blocked + `deny_submit_message`.
3. Send with first line `[slug:any]` → allowed.
4. Pick Composer (or other allowed slug) → send allowed.
5. Confirm log lines if audit enabled.

---

## GitHub description (≤350 chars)

Cursor hook that checks your model when you hit Send—not the dropdown. If it’s not on your allow list, the prompt doesn’t go out and you get a nudge to switch or override. Small local install (`~/.cursor`), your rules in config. No cloud service: a stop sign for mistaken model sends.

---

## Cursor agent — paste this to build or refresh

```
You are building SlugStop v0.1 in this workspace only.

Read SLUGSTOP_MASTER.md and implement the full tree. Windows PowerShell user hooks for Cursor (beforeSubmitPrompt, subagentStart, sessionStart). Install copies to %USERPROFILE%\.cursor.

Deliver: hooks/slugstop.ps1, hooks/slugstop.config.json, hooks.json, install.ps1, README.md, .gitignore (hooks/logs/).

Matching: blocked substring wins; then non-empty allowed_patterns requires a match; bypass via SLUGSTOP_OFF=1 or bypass_prefix on first line.

Do not install, commit, or push unless I ask. If I send ":)", give PowerShell one command per fenced block.

When done: list files, note anything untested, and give install commands only if I ask.
```

---

**SlugStop v0.1** — send gate, subagent gate, session context. **v0.2 ideas:** strip bypass prefix before model sees prompt; optional project-level `.cursor/hooks.json` template for teams.
