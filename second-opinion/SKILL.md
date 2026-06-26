---
name: second-opinion
description: Runs a fresh second-opinion review via the Cursor CLI (`agent -p`) in a separate Auto agent session. Use when the user asks for a second opinion, independent review, another agent's take, peer review via CLI, or explicitly mentions `agent -p`.
disable-model-invocation: true
---

# Second opinion (`agent -p`)

Spawn a **separate** Cursor agent in headless print mode. The parent agent stays in chat; the CLI agent reads the repo and returns a review in stdout.

## When to use

- User asks for a **second opinion**, **independent review**, or **another agent's take**
- User mentions **`agent -p`**, **headless agent**, or **CLI agent review**
- After implementing a sensitive change (auth, provisioning, payments) and before merge

Do **not** use for: normal in-chat code review, Bugbot, or parallel `Task` subagents (see `parallel-worker-review-loop`).

## Preconditions

1. Confirm CLI exists: `which agent` (typically `~/.local/bin/agent`).
2. Run from the **target repo root** (`cd` or `--workspace <abs-path>`).
3. Default to **read-only** review: `--mode ask` (or `--plan`). Never use `--force` without a mode unless the user explicitly wants the CLI agent to edit files.

## Command pattern

Use the Shell tool with a long timeout (`block_until_ms` ≥ **120000**, prefer **180000** for broad reviews).

```bash
cd "<REPO_ROOT>" && agent -p --mode ask --force "$(cat <<'EOF'
<REVIEW PROMPT>
EOF
)" 2>&1
```

Optional flags (only when user asks):

| Flag | Use |
|------|-----|
| `--model <slug>` | Specific model for the review agent |
| `--workspace <path>` | Repo without `cd` |
| `--output-format json` | Machine-parseable output |
| `--trust` | Skip workspace trust prompt in CI-like runs |

## Review prompt template

Adapt and fill placeholders. Keep the **do not edit** guard unless the user wants implementation.

```text
Second-opinion code review only — do NOT edit files.

Repo: <REPO_ROOT>

Context:
<1–3 sentences: feature, requirements, constraints>

Key files (read them):
- <path>
- <path>

Compare with existing patterns:
- <path or area>

Deliver a concise review with:
1) Correctness vs requirements
2) Security/auth gaps
3) Failure modes and edge cases
4) UX gaps (if UI)
5) Top 3 fixes ranked by priority (suggestions only, no edits)

Be specific and cite file paths.
EOF
```

For **narrow** questions, shorten the deliverable list to what the user asked.

## Parent agent workflow

1. Gather context (requirements, changed files, open questions).
2. Run `agent -p` with the template above.
3. **Synthesize** the CLI output for the user — do not dump raw stdout unless they ask.
4. Call out **Critical** vs **Suggestion** items from the review.
5. Ask whether to implement fixes; do not auto-edit based on the second opinion alone.

## Failure handling

| Symptom | Action |
|---------|--------|
| `agent: command not found` | Tell user to install/update Cursor CLI; check `~/.local/bin` on PATH |
| Timeout | Retry with a smaller file list or narrower prompt; increase `block_until_ms` |
| Empty/minimal output | Retry with explicit “read these files first” list |
| Auth / API errors | Check `CURSOR_API_KEY` or CLI login state |

## Example (feature review)

```bash
cd "/Users/me/project" && agent -p --mode ask --force "$(cat <<'EOF'
Second-opinion code review only — do NOT edit files.

Repo: /Users/me/project

Feature: Admin creates real users (WorkOS + Convex).

Requirements:
- Required: first name, first last name, email
- Optional: second name, second last name, document
- Checkbox "allow school creation" default checked

Key files:
- packages/backend/convex/platform/platformAdminUsersNodeApi.ts
- apps/admin/features/dashboard/create-platform-user-form.tsx

Deliver: correctness, security, failure modes, UX, top 3 fixes (no edits).
EOF
)" 2>&1
```

## Anti-patterns

- Running second opinion **without** `--mode ask`/`plan` for review-only requests
- Using `agent -p` as a substitute for running tests or typecheck
- Implementing every suggestion without user confirmation
- Spawning second opinion before the first agent has a coherent diff to review
