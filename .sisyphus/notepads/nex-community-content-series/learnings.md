# Learnings
## 2026-03-13: Manual recovery after subagent scope creep
- Subagent output cannot be trusted by default; verify `git diff --stat` before accepting any claimed completion.
- The useful work for Wave 1 lives entirely under `.sisyphus/content/nex-community-series/`; any example app edits are out of scope.
- `old.reddit.com/.../about/rules` exposes more usable rule text than the standard Reddit rules page when logged out.
- `r/webdev` has the strictest self-promo constraints in this first wave, so any broader-reach post must be framed as workflow value first.
- `r/htmx` exposes little formal rule text, so the safe pattern is demo-first, low-branding, and proof-heavy.
- The Chinese-first workflow needs to be repeated in both strategy and channel guidance or later tasks will drift into parallel English drafting.
- The 8-week sequence works best as credibility -> tiny proof -> scope boundary -> momentum -> showcase, instead of front-loading comparisons.
- The early post files should keep `Status` explicit so later execution can separate publishable drafts from asset-blocked ones without re-reading `asset-gaps.md` every time.
- The later post files need stronger `Blocked By` language than the early ones, because showcase and broad-webdev posts are the easiest places to overclaim without visual proof.

## 2026-03-13: Tracking and Feedback Loop
- Added a lightweight Weekly Scorecard Template to metrics.md to track weekly progress without new infra.
- Rule added: objections and questions feed into future post hooks and proof selection.
- Goal: keep the loop reusable week-to-week; document learnings in the notepad.
- Created asset-gaps.md: matrix for 8 posts with columns Angle, Required Asset, Current Source, Status, Next Action.
- At least 3 posts flagged needs-asset to ensure proof gaps are surfaced early.
- Status labels chosen to reflect current repo proof risk and to drive asset collection.
- Next steps: fill actual proof artifacts and update as assets are collected.

- Scope fidelity checks should grep for channel tokens and flag any extra destination beyond the four approved channels.
- A strong package can still fail conformance on a single out-of-scope distribution target; keep channel scope hard-bounded.

## 2026-03-13: F3 manual QA
- The end-to-end series flow is mostly legible because `strategy.md` defines the handoff order and every post brief repeats `English Adaptation Trigger`, `Blocked By`, and `Status`.
- `asset-gaps.md` cleanly distinguishes `publish-now` from `needs-asset`, so blocked showcase/webdev weeks are easy to spot before drafting.

## 2026-03-13: Proof Inventory Post Map
- Add `## Post Map` in `proof-inventory.md` with `### Post 01..08` and primary proof paths with line refs.
- Notes must include `publish-now` or `needs-asset` to match `asset-gaps.md`.


## 2026-03-13: Metrics Repeat Convention
- metrics.md now includes a `## How To Use` section with explicit Week Entry Template that must be copied and appended at the end of the file for each new week.
- Key fields added: `Post Used (01-08)`, `Chinese approved: yes/no`, `English adaptation published: yes/no` to make the approval workflow executable and derive active-week selection from history.
- F4 re-review (2026-03-13): Prior defects resolved. Strategy now hard-bounds scope to four channels only; cross-post cadence now defines weekly cap, 72h cooldown, and burst limit.
- Result: APPROVE for scope fidelity and anti-spam guardrails within package scope.

## 2026-03-13: F3 re-run
- Prior F3 blockers are resolved once `strategy.md` points approval tracking and active-week selection back to explicit `metrics.md` fields.
- The newcomer path is now deterministic: choose the earliest unlogged `publish-now` week, draft Chinese first, record `Chinese approved: yes/no`, then allow English adaptation only on `yes`.
