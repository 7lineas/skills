---
name: parallel-worker-review-loop
description: Orchestrates parallel Cursor subagent work with a mandatory review-and-finish loop per stream until 100% complete. Use when the user enables Multitask mode, asks for multiple subagents in parallel, or says to spawn a reviewer when each agent finishes and a finisher if review finds gaps.
---

# Parallel worker → review → finish loop

Use this when work can be split into independent streams and the user wants **every stream** held to a **100% done** bar—not just "agent returned."

## When to use what

| Approach | Best for |
|----------|----------|
| **This skill** (default) | Explicit orchestration: you control decomposition, parallel launch, and per-stream review/finish loops in the parent chat |
| **Custom subagents** (`work-reviewer`, `work-finisher`) | Consistent reviewer/finisher behavior; pair with this skill |
| **`subagentStop` hooks** | Fully automatic follow-ups on every subagent exit; use only if you want hooks to drive the loop without repeating instructions |

Prefer **skill + optional subagents**. Add hooks only if you want automation even when you forget to attach the skill.

## User intent (follow literally)

When the user asks for parallel multitask work with quality gates, they usually mean:

1. Split the job into parallel streams.
2. Run one **worker** subagent per stream (Multitask / `run_in_background: true`).
3. **When a worker finishes**, spawn a **reviewer** for that stream only.
4. If the reviewer says work is **not 100% complete**, spawn a **finisher** for that stream with the reviewer's gap list.
5. After a finisher, spawn the **reviewer again** for that stream.
6. Repeat steps 4–5 for that stream until the reviewer reports **PASS (100%)**.
7. Do this for **every** stream independently; do not treat one stream's PASS as done for the whole job.

## Before launching

1. **Decompose** into 2–N independent streams. Name each `stream-<id>` (e.g. `stream-auth`, `stream-ui`).
2. Write a **acceptance checklist** per stream (concrete, verifiable bullets).
3. Copy the tracker below into your working notes and update it as notifications arrive.

```markdown
## Stream tracker
| Stream | Phase | Worker | Reviewer | Finisher | Status |
|--------|-------|--------|----------|----------|--------|
| stream-a | worker | pending | — | — | |
```

Phases: `worker` → `review` → `finish` → `review` → … → `done`

## Launch workers (parallel)

- Send **one message** with **multiple** `Task` tool calls—one per stream.
- Set `run_in_background: true` when the user is in **Multitask mode** (required there).
- Each worker prompt must include:
  - Stream id and scope boundary (what is in / out of scope)
  - The stream's acceptance checklist
  - "Stop when your checklist is satisfied; report what you changed and what you did not verify"
- Prefer `subagent_type: generalPurpose` for implementation; `explore` for read-only discovery; `shell` for git/CI only.

**Do not** spawn reviewers in the same batch as workers. Reviewers run **after** the worker for that stream completes.

## On worker completion (per notification)

When a background worker completes for `stream-X`:

1. Update tracker: phase → `review`.
2. Spawn **one** reviewer `Task` for `stream-X` only (can be foreground or background; background if many streams finish close together).
3. Reviewer prompt must include:
   - Stream id and original acceptance checklist
   - Worker summary (from completion notification)
   - Instruction to use custom subagent **`work-reviewer`** if present, else follow reviewer rules below
4. Reviewer must return structured output (see **Reviewer contract**).

## On reviewer completion

Parse the reviewer's **Verdict**:

- **`PASS`** → Mark stream `done`; update tracker. When **all** streams are `done`, give the user a short consolidated summary.
- **`INCOMPLETE`** → Update tracker: phase → `finish`. Spawn **one** finisher for that stream with the **Gaps** section verbatim.
- After finisher completes → spawn reviewer again for that stream (never skip re-review).

## Finisher contract

Finisher prompt must include:

- Stream id, acceptance checklist, and full **Gaps** from the last review
- "Implement only what is required to close these gaps; do not expand scope"
- Prefer subagent **`work-finisher`** if present

After finisher completes → always return to **review** for that stream.

## Reviewer contract

Reviewer output **must** end with:

```markdown
## Verdict
PASS | INCOMPLETE

## Gaps
<!-- If INCOMPLETE: numbered, specific, testable items. If PASS: "None." -->

## Evidence
<!-- Commands run, files checked, behaviors verified -->
```

**PASS** only if every acceptance checklist item is satisfied with evidence. "Looks good" or "mostly done" is **INCOMPLETE**.

## Safety limits

- **Per-stream cap**: After **5** review cycles for one stream, stop looping, report blockers, and ask the user how to proceed.
- **No duplicate workers**: Do not launch a second worker for the same stream unless the user asks to restart that stream.
- **Parent responsibility**: Background completion notifications are handled by the **parent** agent in this chat—do not assume subagents will chain reviewers themselves unless hooks are configured.

## Parent message to user (when all streams done)

```markdown
## Parallel work complete

| Stream | Result |
|--------|--------|
| stream-a | PASS (N review cycles) |

### Notes
- [Residual risks or manual verification the user should do]
```

## Optional: hooks for automatic chaining

If the user wants follow-ups **without** re-stating the workflow, add a project `hooks.json` `subagentStop` handler that returns `followup_message` to run the next phase. See the **create-hook** skill (`subagentStop`, `followup_message`, `loop_limit`). Skills give clearer control; hooks give more automation.

## Trigger phrases

Treat these as signals to apply this skill immediately:

- "multitask", "parallel subagents", "multiple agents in parallel"
- "when each agent finishes, spawn a reviewer"
- "if review says not done, spawn another agent to finish"
- "until everything is 100% done"

## Additional resources

- Reviewer subagent: `~/.cursor/agents/work-reviewer.md`
- Finisher subagent: `~/.cursor/agents/work-finisher.md`
