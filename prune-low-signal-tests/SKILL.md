---
name: prune-low-signal-tests
description: >-
  Audits test suites, proposes removal of low-signal tests, and drafts testing
  standards for the repo. Use when the user asks to prune tests, reduce test
  time or flakes, define testing standards, audit test quality, or remove
  redundant or smoke-only tests.
---

# Prune Low-Signal Tests + Define Testing Standards

**Goal**  
Remove tests that add cost (time, flakes, noise) without meaningful protection, then document clear rules so future tests stay high-signal.

## Before you start

1. **Discover the test stack**: test runner, config paths, how CI runs tests, and any existing testing docs.
2. **Baseline metrics** (record in your report):
   - Total test count (files and cases if the runner exposes both).
   - Wall-clock time for the full suite (same command CI uses when possible).
3. **Scope**: Confirm with the user if they want the whole repo or specific packages/apps.

Do not delete tests until the user approves the proposed deletion list—unless they explicitly asked you to apply deletions in the same session.

## 1. Review & Prune Existing Tests

Evaluate every test (or test file) against this rubric:

**Delete if the test is primarily:**
- Redundant with the type system
- Testing trivial logic or basic framework/DOM behavior
- Asserting mock call sequences that just mirror the implementation
- A pure smoke / “it renders” test
- Dependent on real or fake timers in a non-deterministic way
- A duplicate case in a table-driven suite
- A wall-clock performance assertion
- Something that has never failed in a way that indicated a real regression

**Keep (or strengthen) if the test covers:**
- Core orchestration / business-flow correctness
- Event sourcing or state-machine invariants
- Auth, permissions, and access-control boundaries
- Persistence, migrations, and data integrity
- External protocol / format parsing and translation
- Deterministic handling of races or concurrency
- Critical error paths and recovery behavior

### Process

- Prefer multiple independent reviews on borderline cases (e.g. `second-opinion` CLI review or a focused `Task` subagent with only the borderline list—do not re-debate obvious keeps/deletes).
- Apply deletions cleanly (remove unused helpers, fixtures, and exports afterward).
- Restore any high-value tests that were incorrectly flagged.
- Measure before/after: test count and wall-clock time.

### Inventory workflow

1. List test files and group by area (unit vs integration, package, feature).
2. For each file, skim name + assertions; flag against the rubric above.
3. For **borderline** items, note why it is unclear and send only those for a second pass.
4. Batch **proposed deletions** with a one-line rationale each (path + test name when applicable).
5. After approval, delete in logical commits; run the suite; fix any broken imports or shared fixtures.

### Git history (optional, high value)

When the user wants evidence for “never failed meaningfully,” use `git log` / blame on the test file or `git log -S 'test name'` sparingly on disputed cases—not on every test.

## 2. Testing Standards Going Forward

Document and enforce these rules:

- Prefer a small number of high-value integration tests over large suites of heavily mocked unit tests.
- Test doubles are allowed only at true boundaries (network, clock, filesystem, process, external services).
- Core logic should run for real whenever practical.
- Every new test must answer: “Has this failed (or could it realistically fail) in a way that indicates a real regression?”
- Avoid tests that merely restate the types or the happy-path implementation.
- Keep the suite fast and deterministic; flakiness is treated as a defect.
- When adding coverage, prefer protecting important invariants, edge cases, and cross-component behavior.

### Where to put guidelines

- If the repo already has `CONTRIBUTING.md`, `docs/testing.md`, or similar, **extend** that file.
- Otherwise add a short section to `docs/TESTING.md` or the root `README` under “Testing”—match project conventions.

Use [testing-standards-template.md](testing-standards-template.md) as the default body; trim or merge with existing docs.

## Output when running this skill

Deliver all four sections in your reply (and commit docs/deletions only when the user asks):

1. **Proposed deletions** — table or list: path, test identifier, one-line rationale.
2. **Restore or rewrite** — tests wrongly flagged, or tests to keep but strengthen (what to change).
3. **Updated testing guidelines** — short markdown section ready to commit (from template + repo-specific notes).
4. **Impact estimate** — tests removed (count), before/after timing if measured, expected CI time savings (rough % or seconds).

### Report template

```markdown
## Proposed deletions

| Path | Test / file | Rationale |
|------|-------------|-----------|
| ... | ... | ... |

## Restore or rewrite

- ...

## Testing guidelines (commit-ready)

<markdown section>

## Impact estimate

- Tests before: N (files: F)
- Tests after (if applied): N'
- Wall-clock before: Xm Ys
- Wall-clock after (if applied): ...
- Notes: ...
```

## Trigger phrases

Apply this skill when the user mentions: prune tests, test audit, low-signal tests, testing standards, reduce test time, flaky tests cleanup, or “tests that don’t catch regressions.”

## Related skills

- **second-opinion** — independent pass on borderline deletion list.
- **parallel-worker-review-loop** — split review by package when the suite is very large (one stream per package).
