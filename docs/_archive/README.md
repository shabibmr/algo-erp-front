# Archived documentation

These documents are **superseded and must not be followed**. They were written for the
**offline-first** architecture, which was reversed by the online-only pivot. They are kept —
not deleted — because offline is *parked, not abandoned* (`lib/core/database/**` still exists,
unwired and excluded from analysis), so this material is the starting point if offline is ever
revived.

For the **current** state of the project, see:
- `docs/STATUS.md` — the living status board (what's shipped/deferred).
- `../../CLAUDE.md` — architecture, commands, and the backend contract.
- `docs/backend-suggestions.md` — the live `BE-NNN` log of backend gaps.

## Contents

| File | What it was | Superseded by |
|---|---|---|
| `PROMPT_EXECUTION_PLAN.md` | Original v1 build plan (offline-first, prompt-by-prompt) | `docs/BUILD_TASKS_V2.md` |
| `offline-sync-readiness.md` | Audit of backend readiness for offline sync (all gaps Missing/Inconsistent) | Parked with the offline track |
| `change-requests/` | CR-001…008 backend change requests, mostly offline-sync | `docs/backend-suggestions.md` (BE-NNN) |

**Note:** CR-007 (payment/receipt settlement allocation) was a genuinely-missing *online*
endpoint, not an offline gap. Its content was migrated to `docs/backend-suggestions.md` as
**BE-015** before archiving — refer there for the live version.
