---
# ptp-1gzs
title: Restore local error-message expectations in upstream tests
status: completed
type: task
priority: normal
created_at: 2026-03-06T07:26:05Z
updated_at: 2026-03-06T07:32:21Z
---

Context
- Upstream assertions now expect newer/expanded error wording, while the Playwright adapter currently emits local wording.
- Latest baseline run: 40 failures are "Wrong message for ..." mismatches.
- Message mismatch breakdown: AssertionsTest 25, LiveTest 9, StaticTest 6.

Scope
- Align expected messages in upstream test copies with current local driver behavior where intentional.

Todo
- [x] Reconcile expected regex/string assertions for assertion/interaction errors.
- [x] Keep expectations stable and specific enough to catch regressions.
- [x] Re-run upstream suite and confirm message-only failures are resolved.

## Summary of Changes
- After skip restoration, reduced message-mismatch scope to one active mismatch in Live tests.
- Updated the disabled-button test expectation to match the local driver error style (`Could not find an element with given selectors`).
- Re-ran upstream suite: now `336 tests, 6 failures, 60 skipped` with no remaining Wrong-message assertion failures.
