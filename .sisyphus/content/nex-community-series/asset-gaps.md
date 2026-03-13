| Post | Angle | Required Asset | Current Source | Status | Next Action |
|---|---|---|---|---|---|
| 01 | Why Nex exists / less ceremony for SSR | core tagline, scope boundary, one concrete repo path | `README.md`; `website/priv/docs/intro.md`; `LAUNCH_COPY.md` | publish-now | Write Chinese opener around stack complexity, then anchor it with exact README lines |
| 02 | One file = one feature | website copy, small code screenshot, LoB explanation | `website/src/pages/features.ex`; `README.md` | publish-now | Capture one clean code snippet from the website example block |
| 03 | Tiny HTMX proof | counter demo, HTMX action explanation, partial update proof | `examples/counter/README.md`; `README.md` | publish-now | Build the post around the counter flow and keep the proof extremely small |
| 04 | File routing / SSR workflow walkthrough | route mapping example, `src/pages` explanation, optional screenshot | `website/src/pages/features.ex`; `README.md` | publish-now | Show route-to-file mapping and explain why this lowers cognitive load |
| 05 | What Nex is not / bounded comparison | explicit non-Phoenix boundary, scope language, at least one concrete trade-off | `README.md`; `LAUNCH_COPY.md`; `website/priv/docs/intro.md` | publish-now | Keep the comparison on fit, not superiority |
| 06 | Changelog momentum / shipped reality | specific shipped features and dates, screenshots optional | `CHANGELOG.md` | publish-now | Cite `0.4.0`, `0.3.8`, and `0.3.7` directly instead of speaking in vague momentum language |
| 07 | Real app showcase / AI-coder angle | showcase screenshots, architecture excerpt, optional short gif | `showcase/agent_console/README.md`; `website/src/pages/features.ex` | needs-asset | Capture at least 2 screenshots from Agent Console before calling it publish-ready |
| 08 | Broader webdev workflow case study | screenshot pack, side-by-side proof, generalized framing | `README.md`; `website/priv/docs/intro.md`; `examples/counter/README.md` | needs-asset | Prepare a general-webdev framing plus one visual before adapting for `r/webdev` |

## Readiness Rule
- `publish-now` means the repo already contains enough text/code proof to support the claim without inventing evidence.
- `needs-asset` means the claim would feel under-evidenced without fresh screenshots, comparison visuals, or external proof.

## Current Gaps
- Screenshots: missing for showcase-heavy and broader webdev posts.
- Benchmarks: still absent, so never use performance as a lead claim.
- Testimonials: absent, so do not imply social proof that does not exist.
