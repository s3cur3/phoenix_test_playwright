---
# ptp-8u64
title: Re-apply upstream skip tags for known local incompatibilities
status: completed
type: task
priority: normal
created_at: 2026-03-06T07:25:59Z
updated_at: 2026-03-06T07:31:40Z
---

Context
- Upstream test refresh removed local skip tags that previously captured known Playwright-driver incompatibilities.
- Latest baseline run: 336 tests, 123 failures.
- 59 failing tests match tests that were explicitly skipped in previous local test files.

Scope
- Restore skip coverage in:
  - test/phoenix_test/upstream/assertions_test.exs
  - test/phoenix_test/upstream/live_test.exs
  - test/phoenix_test/upstream/static_test.exs

Todo
- [x] Re-add removed @tag skip/@describetag skip entries from pre-refresh baseline.
- [x] Re-run upstream suite and verify these failures are suppressed.
- [x] Call out any skips that are no longer needed.

## Summary of Changes
- Restored local skip coverage in upstream test copies using the pre-refresh baseline as source.
- Re-ran upstream suite with `mise x nodejs@24.13.0 -- mix test test/phoenix_test/upstream --seed 0`.
- Result improved from `123 failures` to `7 failures`, with `60 skipped`.
- Skip inventory now aligns with prior local compatibility policy; remaining failures are active (non-skipped) behavior/message gaps.
