---
name: execute-plan-until-done
description: Executes a multi-phase plan end-to-end without stopping until every acceptance criterion is verified. Runs implement → review → finish loops per phase until reviewer PASS. Use when the user wants autonomous execution, "don't stop until done", "execute this plan end to end", "100% complete", or "perfectly done without asking me unless needed core business decisions".
---

# Execute Plan Until Done

Autonomous orchestrator for plans that may take hours. **Do not stop for optional questions.** Only escalate on true blockers (see [Escalation](#escalation)).

Composes: `parallel-worker-review-loop`, `verification`, `tasks-build`.

## User intent

When the user attaches this skill or asks for end-to-end execution without stopping:

1. Ingest the plan and produce **verifiable acceptance checklists** per phase.
2. Execute every phase until **reviewer PASS** on that phase — repeat review/finish cycles as many times as needed.
3. Run **E2E verification** if the plan requires it (or a phase checklist includes it).
4. **Do not ask** for confirmation mid-run unless a [blocker](#blocker-vs-non-blocker) applies.
5. Report only when **all phases PASS**, any plan-specified verification passes, or execution **must stop** (blocker).

## Before starting

### 1. Normalize the plan

Output a **Phase tracker** in working notes:

```markdown
## Phase tracker
| Phase | Scope | Parallel group | Worker | Review cycles | Status |
|-------|-------|----------------|--------|---------------|--------|
| phase-1 | ... | — | pending | 0 | |
```

Statuses: `pending` → `implementing` → `review` → `finish` → `review` → … → `done`

### 2. Write acceptance checklists if the plan doesn't include them

Each phase needs **concrete, testable bullets**. Bad: "Improve auth." Good: "Unauthenticated GET /dashboard redirects to /login."

Copy checklists into the tracker. Phases with **no dependency** on each other may share a `parallel group` id (e.g. `group-a`).

### 3. Checkpoint (required for 3+ phases or estimated multi-hour work)

Write or update `.cursor/plan-checkpoint.json`:

```json
{
  "planTitle": "short title",
  "startedAt": "ISO-8601",
  "updatedAt": "ISO-8601",
  "phases": [
    {
      "id": "phase-1",
      "status": "pending",
      "reviewCycles": 0,
      "acceptanceChecklist": ["...", "..."]
    }
  ],
  "blockers": []
}
```

On resume: read checkpoint first; skip phases marked `done`; continue from first non-done phase.

## Execution modes

### Sequential (default)

One phase at a time. Finish phase N (reviewer **PASS**) before starting phase N+1.

### Parallel

When phases share a `parallel group` and have no cross-dependencies:

- Launch one worker `Task` per phase in **one message** (`run_in_background: true` in Multitask mode).
- Apply per-phase review/finish loops from `parallel-worker-review-loop`.
- Do **not** declare the group done until **every** phase in the group is `done`.

For parallel details, read `~/.cursor/skills/parallel-worker-review-loop/SKILL.md`.

## Per-phase loop

For each phase (parent agent or worker):

### Implement

1. Set phase → `implementing`; update checkpoint.
2. Implement **only** that phase's scope; match project conventions.
3. Run relevant tests/checks before requesting review.
4. Set phase → `review`.

### Review

Spawn reviewer (`work-reviewer` subagent if available, else follow its contract in `~/.cursor/agents/work-reviewer.md`).

Reviewer prompt must include: phase id, acceptance checklist (verbatim), implementer summary, files/commands touched.

Parse **Verdict**:
- **PASS** → phase `done`; update checkpoint; proceed to next phase or plan completion.
- **INCOMPLETE** → increment `reviewCycles`; spawn **finisher** (`work-finisher` / `~/.cursor/agents/work-finisher.md`) with **Gaps** verbatim → return to **Review**. Repeat until **PASS**.

## Optional verification (plan-driven only)

When **all phases** are `done`:

- If the plan does **not** require E2E or full-flow verification → declare **Plan complete**.
- If the plan **does** require it (explicit section, acceptance item, or user instruction):
  1. Load `verification` skill patterns as applicable.
  2. Verify only what the plan specifies.
  3. If verification fails: treat failures as a synthetic phase with its own checklist and run the per-phase loop until **PASS**.
  4. Then declare **Plan complete**.

## Escalation

### Blocker vs non-blocker

| Blocker (stop and ask) | Non-blocker (decide and continue) |
|------------------------|-----------------------------------|
| Missing secret/credential only user can provide | Style or library choice with a reasonable default |
| Irreconcilable spec conflict | Unclear naming; follow repo conventions |
| Destructive/irreversible action needing approval | Test flakiness; retry with stable approach |
| Permission denied to required system | Two valid implementations; pick smaller diff |

**Never stop** for: "Should I continue?", progress check-ins, or preferences not in the plan.

### Escalation message format

```markdown
## Execution paused — blocker

**Phase:** phase-id
**Blocker:** one sentence
**Evidence:** commands, errors, paths
**Options:** 2–3 concrete paths forward (if any)
**Completed so far:** phases done + checkpoint path
```

## Progress updates (long runs)

Every major phase transition, briefly note in chat (unless user said "silent until done"):
- Phase completed / started
- Review cycle count if > 1
- Checkpoint updated

## Completion message

```markdown
## Plan complete

| Phase | Result |
|-------|--------|
| phase-1 | PASS (1 review cycle) |

### Verification
<!-- Include only if the plan required E2E or full-flow checks -->
- [Flows checked and outcomes, or "Not required by plan."]

### Checkpoint
- `.cursor/plan-checkpoint.json` — all phases done

### Residual risks
- [Manual follow-ups outside plan scope, if any]
```

## Trigger phrases

Apply immediately when the user give you the skill or says:
- "execute end to end", "run the plan without stopping", "don't stop until done"
- "autonomous execution", "hours-long", "perfectly done", "100% complete"
- "execute plan until done" (explicit skill name)

## Optional automation

For automatic reviewer/finish chaining on subagent exit, add `subagentStop` hooks — see `create-hook` skill. Skills give clearer control; hooks add automation when the parent forgets the playbook.

## Additional resources

- Quality gates: `~/.cursor/skills/parallel-worker-review-loop/SKILL.md`
- E2E verification (when plan requires): Vercel `verification` skill
- progress: Notion `tasks-build` skill
- Reviewer: `~/.cursor/agents/work-reviewer.md`
- Finisher: `~/.cursor/agents/work-finisher.md`
