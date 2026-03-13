# Issues
## 2026-03-13: Research caveats
- `https://elixirforum.com/faq` was unreliable in automated fetch, so it is cited as a required manual preflight source instead of a fully quoted rule page.
- `r/htmx` exposes sparse logged-out rule text; safest execution rule is to treat it as demo-first and branding-light.
- Existing uncommitted changes outside `.sisyphus/` are present in the repo and must not be mixed into content-series commits.

## 2026-03-13: Potential blockers / questions
- How to consistently populate Channel Notes across weeks?
- How to quantify "Stars" meaningfully with manual observation?
- Where to store and reference the "proof selection" criteria mentioned in adjustments?
- Any additional fields to standardize in the template for consistency?

- F4 scope check (2026-03-13): REJECT due to out-of-scope channel mention `targeted AI-builder communities later`; scope is fixed to Elixir Forum, r/elixir, r/htmx, r/webdev. See `.sisyphus/content/nex-community-series/strategy.md:53`.
- Guardrail gap: no explicit anti-spam cadence/cross-post cooldown rule (e.g., avoid same-day repost across channels), which can trigger community backlash despite channel-specific copy.
- Style-risk note: `Safe Opening Templates` introduces near-ready phrasing; keep enforcement on principle-level adaptation to avoid voice mimic drift.

## 2026-03-13: F3 manual QA
- Verdict: REJECT. The workflow explains how to draft and adapt, but it never tells a newcomer where Chinese approval is recorded or how to verify the gate is cleared before English adaptation.
- Artifact gap: `strategy.md`, `calendar.md`, `channel-playbook.md`, and each `posts/*.md` brief reference approval as a gate, but no file provides a status field, approval log, or handoff step for that decision.
- Artifact gap: `calendar.md` schedules eight weeks, but it does not say how a newcomer determines the active week when joining mid-series or after a skipped week, so post selection still requires outside context.

- 2026-03-13: `strategy.md` now defines Approval Tracking, record Chinese approval per-week in `metrics.md` as `Chinese approved: yes/no`.
- 2026-03-13: `strategy.md` now defines Active Week Selection, pick the earliest unlogged `publish-now` week and skip `needs-asset` weeks.

- F4 re-review (2026-03-13): No remaining scope-fidelity defects found in `.sisyphus/content/nex-community-series/` against plan channel constraints.
