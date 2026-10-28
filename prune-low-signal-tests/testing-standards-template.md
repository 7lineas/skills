# Testing standards

## Principles

- Prefer a small number of high-value integration tests over large suites of heavily mocked unit tests.
- Test doubles are allowed only at true boundaries (network, clock, filesystem, process, external services).
- Core logic should run for real whenever practical.
- Every new test must answer: **Has this failed (or could it realistically fail) in a way that indicates a real regression?**
- Avoid tests that merely restate the types or the happy-path implementation.
- Keep the suite fast and deterministic; **flakiness is a defect**—fix or delete flaky tests, do not retry to green.
- When adding coverage, prefer important invariants, edge cases, and cross-component behavior.

## What we do not test

- Behavior guaranteed by the type system alone.
- Trivial logic with no business rules.
- Framework or DOM defaults (“component mounts” with no invariant).
- Mock call order that only mirrors the implementation.
- Wall-clock performance thresholds in unit tests (use dedicated benchmarks if needed).

## What we prioritize

- Core orchestration and business flows.
- Auth, permissions, and access-control boundaries.
- Persistence, migrations, and data integrity.
- External protocol / format parsing and translation.
- Deterministic concurrency or race handling.
- Critical error paths and recovery.

## Adding a new test

1. Name the regression or invariant it protects.
2. Prefer the highest level that still runs quickly and deterministically.
3. Avoid timers unless faked in a stable way; no arbitrary `setTimeout` in assertions.
4. If the test duplicates an existing case, extend the existing test instead.
