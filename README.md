# SlugStop

Send-time model slug gate for Cursor Agent (user hooks in `%USERPROFILE%\.cursor`). Spec: [SLUGSTOP_MASTER.md](SLUGSTOP_MASTER.md).

**Install:** `powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1`  
Backs up an existing `hooks.json` first; **replaces** it with SlugStop’s (merge from backup if you had other hooks). **Does not** overwrite an existing `slugstop.config.json`.

**Config:** `%USERPROFILE%\.cursor\hooks\slugstop.config.json` — patterns, deny messages, `[slug:any]` bypass prefix, `audit_log`.

**Cursor:** Default model → **Last used**.

| Bypass | Effect |
|--------|--------|
| Prompt line starts with `[slug:any]` | Allow that send |
| `SLUGSTOP_OFF=1` (env, restart Cursor) | Allow send only; subagents still checked |

**Test:** Blocked slug → send denied; Composer → allowed; first line `[slug:any]` → allowed. Log: `hooks\logs\slugstop.log`.

**Uninstall:** Remove `%USERPROFILE%\.cursor\hooks.json`, `hooks\slugstop.ps1`, `hooks\slugstop.config.json` (restore `hooks.json` if you had other hooks).
