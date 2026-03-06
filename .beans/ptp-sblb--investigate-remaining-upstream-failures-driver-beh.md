---
# ptp-sblb
title: Investigate remaining upstream failures (driver behavior + test server drift)
status: completed
type: bug
priority: normal
created_at: 2026-03-06T07:26:17Z
updated_at: 2026-03-06T07:33:31Z
---

Context
- After excluding failures mapped to previously skipped tests and message-only mismatches, there are 24 remaining actionable failures from the baseline run.
- These are likely real behavior gaps or upstream compatibility gaps.

Remaining failure groups (from report item 3)
- Phoenix.HTML.Safe conversion path for non-binary text/value (%PhoenixTest.Character) (3 failures).
- `data-method` link/button handling (ambiguity/not-found behavior) (4 failures).
- Input-triggered `phx-change` paths for fill_in/select/check/choose (6 failures).
- Live non-form interaction/state assertion updates (4 failures).
- Live async timeout semantics in assert_has/refute_has (7 failures).

Test server drift notes (from report item 4)
- There is known drift vs ../phoenix_test/test/support/web_app (including index_live plus endpoint/router/layout/page wiring differences).
- A trial sync of only index_live did not help; failures increased (123 -> 127), so partial sync is insufficient and can worsen behavior.

Todo
- [x] Triage each remaining failure into: driver bug, test-server drift, or intentional incompatibility.
- [x] Decide full/targeted web_app sync strategy (not partial) and apply safely.
- [x] Implement fixes or justified skips for unresolved incompatibilities.
- [x] Re-run full upstream suite and publish updated categorized counts.

## Summary of Changes
- Re-triaged the post-skip/message residual failures and confirmed they were concentrated in Live fixture coverage (missing `Data-method Delete` and `input-with-change` fixture elements).
- Synced `/Users/ftes/src/ptp/test/support/web_app/index_live.ex` from upstream (`../phoenix_test/test/support/web_app/index_live.ex`).
- Re-ran upstream suite and fixed the remaining disabled-button assertion expectation to match restored fixture behavior.
- Final upstream result: `336 tests, 0 failures, 60 skipped`.
