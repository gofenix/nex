# Nex Community Content Series

## TL;DR
> **Summary**: Build an 8-week, proof-led community series for Nex that turns repo artifacts into channel-specific narratives for Reddit and Elixir Forum, optimized for GitHub stars without reading as spam.
> **Deliverables**:
> - Channel rules + posting playbook
> - Repo-backed proof inventory and asset-gap matrix
> - 8-post series calendar with per-post outlines
> - Platform adaptations for `r/elixir`, `r/htmx`, `r/webdev`, and Elixir Forum
> - Metrics and feedback loop for star-oriented iteration
> **Effort**: Medium
> **Parallel**: YES - 3 waves
> **Critical Path**: 1 -> 3 -> 5 -> 7 -> 10

## Context
### Original Request
Create a series of sharable content about the Nex framework so it can keep attracting attention on Reddit and Elixir Forum.

### Interview Summary
- Primary outcome: maximize GitHub stars.
- Deliverable depth: series strategy plus per-post outlines, not full final posts.
- Audience: mixed, but each post should target one primary audience from: indie builders, Elixir veterans, AI coders.
- Reddit angle: combine build-in-public with selective contrarian framing.
- Reddit scope: `r/elixir`, `r/htmx`, and a broader developer community. Default broader community: `r/webdev`.
- Messaging must be evidence-led using repo artifacts, examples, and changelog momentum.
- Language workflow: write Chinese first, get user review/approval, then translate/adapt to English for Reddit and Elixir Forum.
- Voice reference: learn from `数字生命卡兹克` style — strong contrarian opening, candid first-person narration, dense examples, colloquial rhythm, but keep the tone evidence-backed and community-safe.

### Metis Review (gaps addressed)
- Added a named broader Reddit target instead of leaving it open-ended.
- Added proof gating so no post is treated as publish-ready without at least one hard artifact.
- Added per-channel tone and CTA rules so Reddit and Elixir Forum do not receive copy-pasted posts.
- Added asset-gap handling for missing screenshots, benchmarks, and testimonials.
- Added one-primary-audience-per-post guardrail to prevent diluted hooks.

## Work Objectives
### Core Objective
Produce a reusable community content system for Nex that can sustain attention for 8 weeks, convert curiosity into GitHub visits/stars, and avoid generic launch-post behavior.

### Deliverables
- `.sisyphus/content/nex-community-series/strategy.md`
- `.sisyphus/content/nex-community-series/channel-playbook.md`
- `.sisyphus/content/nex-community-series/proof-inventory.md`
- `.sisyphus/content/nex-community-series/asset-gaps.md`
- `.sisyphus/content/nex-community-series/calendar.md`
- `.sisyphus/content/nex-community-series/posts/01.md` through `.sisyphus/content/nex-community-series/posts/08.md`
- `.sisyphus/content/nex-community-series/metrics.md`
- Chinese-first outline workflow embedded in every post brief, with English adaptation deferred until post-approval

### Definition of Done (verifiable conditions with commands)
- All deliverable files exist under `.sisyphus/content/nex-community-series/`.
- `calendar.md` contains 8 scheduled content slots and names all four channels.
- Every post file contains: `Primary Audience`, `Core Claim`, `Primary Proof`, `Hook`, `CTA`, `Channel Adaptation`, `Chinese Draft Goal`, `Voice Notes`, `English Adaptation Trigger`, `Blocked By`.
- `channel-playbook.md` contains separate rules for `Elixir Forum`, `r/elixir`, `r/htmx`, and `r/webdev`.
- `proof-inventory.md` maps each planned post to at least one repo source file.
- `asset-gaps.md` marks each post as `publish-now` or `needs-asset`.
- `strategy.md` contains a concrete `Chinese Voice Guide` section for the target style.

### Must Have
- One primary audience per post.
- One repo-backed proof source per post minimum.
- Separate hook/title/CTA logic per channel.
- Explicit star-oriented CTA hierarchy.
- Publish-now vs blocked status for every post.
- Reuse of `LAUNCH_COPY.md`, README/docs, changelog, examples, and showcases where relevant.
- Chinese-first drafting order with explicit `Chinese Draft Goal` and `English Adaptation Trigger` fields per post.
- A reusable voice guide that captures the target Chinese style in executable terms: opening tension, spoken cadence, personal judgment, concrete proof, and non-corporate phrasing.

### Must NOT Have (guardrails, AI slop patterns, scope boundaries)
- No identical cross-posts across Reddit and Elixir Forum.
- No vague claims like "fast" or "simple" without proof references.
- No tribal anti-Phoenix framing; comparisons must be experience-led, not combative.
- No requirement for the user to manually judge quality during verification.
- No full final post drafting in this execution scope.
- No placeholder channels, metrics, or post ideas left unresolved.
- No English post adaptation before the corresponding Chinese version is approved.
- No empty hot takes, rage-bait, or pure provocation without first-hand experience and repo proof.
- No over-copying of any creator's exact phrases; extract style principles, not mimicry.

## Verification Strategy
> ZERO HUMAN INTERVENTION — all verification is agent-executed.
- Test decision: tests-after via file-content verification using `read`, `grep`, and optional non-mutating `bash` checks.
- QA policy: every task includes artifact checks plus one edge-case check.
- Evidence: `.sisyphus/evidence/task-{N}-{slug}.{ext}`

## Execution Strategy
### Parallel Execution Waves
> Target: 5-8 tasks per wave. <3 per wave (except final) = under-splitting.
> Extract shared dependencies as Wave-1 tasks for max parallelism.

Wave 1: channel constraints, proof inventory, audience/CTA model, asset-gap audit, metrics baseline
Wave 2: series architecture, platform playbooks, post outlines 1-4, post outlines 5-8
Wave 3: final assembly, internal consistency sweep

### Dependency Matrix (full, all tasks)
- 1: none
- 2: none
- 3: none
- 4: none
- 5: none
- 6: blocked by 1,2,3,4
- 7: blocked by 1,3,6
- 8: blocked by 2,4,6,7
- 9: blocked by 2,4,6,7
- 10: blocked by 5,7,8,9

### Agent Dispatch Summary (wave -> task count -> categories)
- Wave 1 -> 5 tasks -> `writing`, `quick`, `unspecified-low`
- Wave 2 -> 4 tasks -> `writing`, `deep`
- Wave 3 -> 1 task -> `writing`

## TODOs
> Implementation + Test = ONE task. Never separate.
> EVERY task MUST have: Agent Profile + Parallelization + QA Scenarios.

- [x] 1. Audit Community Constraints

  **What to do**: Create `.sisyphus/content/nex-community-series/channel-playbook.md` section 1 with rule summaries, anti-spam guidance, post-shape constraints, and acceptable CTA behavior for `Elixir Forum`, `r/elixir`, `r/htmx`, and `r/webdev`. Include source links for each community rule or FAQ reference used, plus a language workflow note explaining that channel-ready English copy is produced only after Chinese approval.
  **Must NOT do**: Do not assume one post can be reused verbatim across channels. Do not leave the broader Reddit target unnamed.

  **Recommended Agent Profile**:
  - Category: `writing` — Reason: community guidance synthesis and policy writing
  - Skills: `[]` — no extra skill needed
  - Omitted: `playwright` — no browser interaction required for the artifact itself

  **Parallelization**: Can Parallel: YES | Wave 1 | Blocks: 6,7 | Blocked By: none

  **References**:
  - Pattern: `LAUNCH_COPY.md:33` — starting point for Reddit framing that must be tightened for community fit
  - Pattern: `README.md:17` — "what Nex is / is not" boundaries to preserve in community messaging
  - External: `https://elixirforum.com/faq` — forum norms and participation guidance
  - External: web rule references collected for subreddit fit — validate before finalizing tone constraints

  **Acceptance Criteria** (agent-executable only):
  - [ ] `channel-playbook.md` contains headings for `Elixir Forum`, `r/elixir`, `r/htmx`, and `r/webdev`
  - [ ] Each channel section contains `Allowed Angle`, `Tone`, `CTA`, `Do Not Post`, and `Moderation Risk`
  - [ ] The file names a non-copy-paste adaptation rule across channels

  **QA Scenarios** (MANDATORY — task incomplete without these):
  ```text
  Scenario: Happy path
    Tool: Grep
    Steps: Search `.sisyphus/content/nex-community-series/channel-playbook.md` for the four channel headings and the strings `Allowed Angle`, `CTA`, `Moderation Risk`
    Expected: All headings and required field labels exist
    Evidence: .sisyphus/evidence/task-1-channel-rules.txt

  Scenario: Failure/edge case
    Tool: Read
    Steps: Read the channel sections and confirm none reuse identical CTA language across all four targets
    Expected: At least one channel-specific CTA difference is visible; otherwise mark task failed
    Evidence: .sisyphus/evidence/task-1-channel-rules-error.txt
  ```

  **Commit**: YES | Message: `docs(content): add channel posting rules` | Files: `.sisyphus/content/nex-community-series/channel-playbook.md`

- [x] 2. Build Repo-Backed Proof Inventory

  **What to do**: Create `.sisyphus/content/nex-community-series/proof-inventory.md` that catalogs reusable proof units from the repo: positioning claims, feature proof, examples, showcases, launch copy, and changelog momentum. Group entries by audience fit and by strength of proof.
  **Must NOT do**: Do not invent benchmark or testimonial proof that does not exist.

  **Recommended Agent Profile**:
  - Category: `writing` — Reason: structured source mapping and concise evidence extraction
  - Skills: `[]` — no extra skill needed
  - Omitted: `git-master` — no git operation required

  **Parallelization**: Can Parallel: YES | Wave 1 | Blocks: 6,8,9,10 | Blocked By: none

  **References**:
  - Pattern: `README.md:3` — core tagline and target audience claims
  - Pattern: `website/priv/docs/intro.md:3` — server-driven simplicity and Phoenix boundary
  - Pattern: `website/src/pages/features.ex:31` — AI-native, routing, SSE, security, CDN-first proof blocks
  - Pattern: `CHANGELOG.md:8` — release momentum and recent shipped features
  - Pattern: `showcase/agent_console/README.md:3` — real app proof for AI coder angle
  - Pattern: `examples/counter/README.md:3` — simple HTMX/SSR proof for indie-builder angle
  - Pattern: `LAUNCH_COPY.md:13` — reusable claim and FAQ language

  **Acceptance Criteria** (agent-executable only):
  - [ ] `proof-inventory.md` contains sections `Claims`, `Proof Units`, `Audience Fit`, `Missing Proof`
  - [ ] At least 12 proof entries exist with source file paths
  - [ ] Every entry includes `claim`, `source`, `audience`, and `reuse-note`

  **QA Scenarios** (MANDATORY — task incomplete without these):
  ```text
  Scenario: Happy path
    Tool: Grep
    Steps: Count occurrences of `source:` and verify there are at least 12 in `.sisyphus/content/nex-community-series/proof-inventory.md`
    Expected: Count >= 12
    Evidence: .sisyphus/evidence/task-2-proof-inventory.txt

  Scenario: Failure/edge case
    Tool: Read
    Steps: Inspect `Missing Proof` and ensure screenshots, benchmarks, and testimonials are explicitly marked absent or weak
    Expected: Missing proof is documented instead of silently omitted
    Evidence: .sisyphus/evidence/task-2-proof-inventory-error.txt
  ```

  **Commit**: YES | Message: `docs(content): add nex proof inventory` | Files: `.sisyphus/content/nex-community-series/proof-inventory.md`

- [x] 3. Define Audience, CTA, and KPI Model

  **What to do**: Create `strategy.md` sections for audience segmentation, post-goal hierarchy, CTA stack, KPI definitions, and a Chinese voice guide derived from the requested `数字生命卡兹克` reference. Set the star-oriented success ladder as: GitHub stars first, GitHub visits second, docs visits third, discussion depth fourth.
  **Must NOT do**: Do not optimize every post for every audience. Do not use vague KPIs like "awareness" without a measurable proxy.

  **Recommended Agent Profile**:
  - Category: `writing` — Reason: messaging architecture and measurable strategy
  - Skills: `[]` — no extra skill needed
  - Omitted: `agent-browser` — not needed

  **Parallelization**: Can Parallel: YES | Wave 1 | Blocks: 6,7 | Blocked By: none

  **References**:
  - Pattern: `README.md:19` — target user scenarios
  - Pattern: `README.md:27` — what Nex is not
  - Pattern: `website/src/components/home_hero.ex:16` — AI-era framing and shipping-speed claim
  - Pattern: `LAUNCH_COPY.md:58` — FAQ audience framing

  **Acceptance Criteria** (agent-executable only):
  - [ ] `strategy.md` contains sections `Audience Segments`, `KPI Hierarchy`, `CTA Hierarchy`, `Message Boundaries`
  - [ ] `strategy.md` contains a `Chinese Voice Guide` section
  - [ ] Each audience segment has pain points, proof preference, and best-fit channel
  - [ ] KPI order explicitly prioritizes stars above all other outcomes

  **QA Scenarios** (MANDATORY — task incomplete without these):
  ```text
  Scenario: Happy path
    Tool: Grep
    Steps: Search `.sisyphus/content/nex-community-series/strategy.md` for `GitHub stars`, `GitHub visits`, `docs visits`, `discussion depth`
    Expected: All four KPI terms are present in descending priority
    Evidence: .sisyphus/evidence/task-3-kpi-model.txt

  Scenario: Failure/edge case
    Tool: Read
    Steps: Verify no audience section claims to target all three audiences equally in one post, and the voice guide does not reduce to generic "casual tech writing"
    Expected: Each post strategy rule limits to one primary audience and at most one secondary audience; the voice guide names concrete stylistic moves and boundaries
    Evidence: .sisyphus/evidence/task-3-kpi-model-error.txt
  ```

  **Commit**: YES | Message: `docs(content): define audience and KPI model` | Files: `.sisyphus/content/nex-community-series/strategy.md`

- [x] 4. Create Asset-Gap and Publish-Readiness Matrix

  **What to do**: Create `.sisyphus/content/nex-community-series/asset-gaps.md` mapping each planned content angle to required proof assets, current repo support, and whether the angle is `publish-now` or `needs-asset`. Include screenshot, benchmark, testimonial, and code-snippet requirements.
  **Must NOT do**: Do not label a post publish-ready if it lacks any hard proof source.

  **Recommended Agent Profile**:
  - Category: `quick` — Reason: structured matrix creation from already known gaps
  - Skills: `[]` — no extra skill needed
  - Omitted: `playwright` — this task only plans assets, not captures them

  **Parallelization**: Can Parallel: YES | Wave 1 | Blocks: 6,8,9 | Blocked By: none

  **References**:
  - Pattern: `LAUNCH_COPY.md:33` — launch angles that may need stronger proof
  - Pattern: `CHANGELOG.md:10` — features that can support publish-now angles
  - Pattern: `examples/counter/README.md:25` — code-demo proof for educational posts
  - Pattern: `showcase/agent_console/README.md:5` — real app proof for richer posts

  **Acceptance Criteria** (agent-executable only):
  - [ ] `asset-gaps.md` contains columns or headings for `Angle`, `Required Asset`, `Current Source`, `Status`, `Next Action`
  - [ ] All 8 planned posts receive a readiness status
  - [ ] At least one post is explicitly marked `needs-asset` if proof is not yet strong enough

  **QA Scenarios** (MANDATORY — task incomplete without these):
  ```text
  Scenario: Happy path
    Tool: Grep
    Steps: Search `.sisyphus/content/nex-community-series/asset-gaps.md` for `publish-now` and `needs-asset`
    Expected: Both statuses appear
    Evidence: .sisyphus/evidence/task-4-asset-gaps.txt

  Scenario: Failure/edge case
    Tool: Read
    Steps: Confirm no post with `needs-asset` is simultaneously marked ready for all channels
    Expected: Blocked posts remain blocked until the named asset exists
    Evidence: .sisyphus/evidence/task-4-asset-gaps-error.txt
  ```

  **Commit**: YES | Message: `docs(content): add asset gap matrix` | Files: `.sisyphus/content/nex-community-series/asset-gaps.md`

- [x] 5. Define Tracking and Feedback Loop

  **What to do**: Create `.sisyphus/content/nex-community-series/metrics.md` with a weekly review template covering stars, source link clicks, comment themes, objections, and next-post adjustments. Include a per-channel observation grid.
  **Must NOT do**: Do not require product analytics or infra that does not already exist.

  **Recommended Agent Profile**:
  - Category: `quick` — Reason: metrics template and review cadence design
  - Skills: `[]`
  - Omitted: `git-master` — no repository history work needed

  **Parallelization**: Can Parallel: YES | Wave 1 | Blocks: 10 | Blocked By: none

  **References**:
  - Pattern: `README.md:102` — recommended learning path that can inform funnel expectations
  - Pattern: `LAUNCH_COPY.md:54` — feedback CTA structure

  **Acceptance Criteria** (agent-executable only):
  - [ ] `metrics.md` contains sections `Weekly Scorecard`, `Channel Notes`, `Objection Log`, `Adjustment Rules`
  - [ ] The scorecard tracks stars first
  - [ ] The adjustment rules mention using comment objections to tune later post hooks

  **QA Scenarios** (MANDATORY — task incomplete without these):
  ```text
  Scenario: Happy path
    Tool: Grep
    Steps: Search `.sisyphus/content/nex-community-series/metrics.md` for `stars`, `clicks`, `objections`, `adjustment`
    Expected: All four terms exist
    Evidence: .sisyphus/evidence/task-5-metrics.txt

  Scenario: Failure/edge case
    Tool: Read
    Steps: Verify the metrics plan does not require unavailable tooling beyond manual observation and link/account checks
    Expected: Metrics remain lightweight and executable
    Evidence: .sisyphus/evidence/task-5-metrics-error.txt
  ```

  **Commit**: YES | Message: `docs(content): add review metrics loop` | Files: `.sisyphus/content/nex-community-series/metrics.md`

- [x] 6. Build 8-Week Narrative Sequence

  **What to do**: Add `calendar.md` with an 8-week sequence that moves from low-friction credibility posts to sharper comparison posts and then product-shaped proof. Default cadence: 1 Chinese-first draft package per week; English adaptation for the matching Reddit/Elixir Forum targets is unlocked only after user approval of the Chinese version.
  **Must NOT do**: Do not front-load the most contrarian posts before credibility is established. Do not schedule the same angle back-to-back.

  **Recommended Agent Profile**:
  - Category: `deep` — Reason: sequencing depends on combining evidence, audience, and platform fit
  - Skills: `[]`
  - Omitted: `playwright` — not needed

  **Parallelization**: Can Parallel: NO | Wave 2 | Blocks: 7,8,9 | Blocked By: 1,2,3,4

  **References**:
  - Pattern: `README.md:104` — fastest user path into Nex, useful for sequencing education
  - Pattern: `CHANGELOG.md:8` — momentum narrative for later-series credibility posts
  - Pattern: `LAUNCH_COPY.md:25` — existing thread ideas that can seed sequence slots

  **Acceptance Criteria** (agent-executable only):
  - [ ] `calendar.md` contains 8 numbered weeks
  - [ ] Each week names Chinese draft owner artifact, primary channel, backup channel, primary audience, and proof asset
  - [ ] The first 2 weeks are education/proof heavy and not pure framework announcement posts

  **QA Scenarios** (MANDATORY — task incomplete without these):
  ```text
  Scenario: Happy path
    Tool: Grep
    Steps: Search `.sisyphus/content/nex-community-series/calendar.md` for `Week 1` through `Week 8`
    Expected: All eight week labels exist
    Evidence: .sisyphus/evidence/task-6-calendar.txt

  Scenario: Failure/edge case
    Tool: Read
    Steps: Verify no adjacent weeks target the exact same primary audience and same primary proof angle
    Expected: Sequence shows narrative progression rather than repetition
    Evidence: .sisyphus/evidence/task-6-calendar-error.txt
  ```

  **Commit**: YES | Message: `docs(content): add 8 week series calendar` | Files: `.sisyphus/content/nex-community-series/calendar.md`

- [x] 7. Write Platform Playbooks and Title Patterns

  **What to do**: Expand `channel-playbook.md` with title formulas, acceptable opening patterns, comment-handling guidance, CTA ladders for each channel, and a style adaptation rule that translates the requested Chinese strong-opinion voice into platform-safe openings. Include explicit adaptation rules for build-in-public vs contrarian angles.
  **Must NOT do**: Do not use sensationalist or "Phoenix killer" framing.

  **Recommended Agent Profile**:
  - Category: `writing` — Reason: channel-specific persuasive structure
  - Skills: `[]`
  - Omitted: `agent-browser` — not needed

  **Parallelization**: Can Parallel: NO | Wave 2 | Blocks: 8,9,10 | Blocked By: 1,3,6

  **References**:
  - Pattern: `LAUNCH_COPY.md:33` — launch copy to refine into non-spammy formulas
  - Pattern: `README.md:27` — preserve constraints around what Nex is not
  - Pattern: `website/priv/docs/intro.md:7` — philosophical framing suitable for opinionated posts

  **Acceptance Criteria** (agent-executable only):
  - [ ] `channel-playbook.md` includes sections `Title Patterns`, `Opening Pattern`, `Comment Strategy`, `CTA Ladder`
  - [ ] Each channel has at least 3 title patterns
  - [ ] The playbook distinguishes build-in-public hooks from contrarian hooks
  - [ ] The playbook contains `Voice Boundary` guidance for Chinese-first writing and later English adaptation

  **QA Scenarios** (MANDATORY — task incomplete without these):
  ```text
  Scenario: Happy path
    Tool: Grep
    Steps: Search `.sisyphus/content/nex-community-series/channel-playbook.md` for `Title Patterns` and `CTA Ladder`
    Expected: Both labels appear for each channel section
    Evidence: .sisyphus/evidence/task-7-playbook.txt

  Scenario: Failure/edge case
    Tool: Read
    Steps: Inspect title examples and reject any that position Nex as replacing Phoenix everywhere or attack another framework directly
    Expected: Comparative framing stays bounded and respectful
    Evidence: .sisyphus/evidence/task-7-playbook-error.txt
  ```

  **Commit**: YES | Message: `docs(content): expand channel playbooks` | Files: `.sisyphus/content/nex-community-series/channel-playbook.md`

- [x] 8. Draft Post Outlines 1-4

  **What to do**: Create Chinese-first post files `posts/01.md` through `posts/04.md` for the first half of the series. Use a mix of educational and build-in-public hooks. Suggested angles: why Nex exists, one-file-one-feature proof, HTMX/SSR workflow, and real example walkthrough. Each file must include the later English adaptation notes but not the final English copy, and must specify how the Chinese draft uses the target strong-opinion voice without becoming rage-bait.
  **Must NOT do**: Do not write polished final posts. Do not assign more than one primary audience per outline.

  **Recommended Agent Profile**:
  - Category: `writing` — Reason: structured post briefing and message crafting
  - Skills: `[]`
  - Omitted: `playwright` — not needed at outline stage

  **Parallelization**: Can Parallel: YES | Wave 2 | Blocks: 10 | Blocked By: 2,4,6,7

  **References**:
  - Pattern: `README.md:7` — why Nex framing
  - Pattern: `website/src/pages/features.ex:34` — AI-native and one-file message
  - Pattern: `examples/counter/README.md:23` — HTMX/SSR explainer pattern
  - Pattern: `LAUNCH_COPY.md:25` — thread idea seeds

  **Acceptance Criteria** (agent-executable only):
  - [ ] Files `01.md` through `04.md` exist
  - [ ] Each file contains `Primary Audience`, `Core Claim`, `Primary Proof`, `Hook`, `CTA`, `Channel Adaptation`, `Chinese Draft Goal`, `Voice Notes`, `English Adaptation Trigger`, `Blocked By`
  - [ ] At least one of the first four posts targets `Elixir Forum` first and at least one targets Reddit first

  **QA Scenarios** (MANDATORY — task incomplete without these):
  ```text
  Scenario: Happy path
    Tool: Grep
    Steps: Search `.sisyphus/content/nex-community-series/posts/*.md` for the required field labels and confirm 4 files exist for `01`-`04`
    Expected: All 4 files contain all required fields
    Evidence: .sisyphus/evidence/task-8-posts-1-4.txt

  Scenario: Failure/edge case
    Tool: Read
    Steps: Inspect `Blocked By` in all four files and confirm any proof-light outline is marked `needs-asset`
    Expected: No weak outline is marked publish-ready without proof
    Evidence: .sisyphus/evidence/task-8-posts-1-4-error.txt
  ```

  **Commit**: YES | Message: `docs(content): add first four post outlines` | Files: `.sisyphus/content/nex-community-series/posts/01.md`, `.sisyphus/content/nex-community-series/posts/02.md`, `.sisyphus/content/nex-community-series/posts/03.md`, `.sisyphus/content/nex-community-series/posts/04.md`

- [x] 9. Draft Post Outlines 5-8

  **What to do**: Create Chinese-first post files `posts/05.md` through `posts/08.md` for the second half of the series. Suggested angles: contrarian but bounded comparison, changelog momentum, showcase proof, and "what Nex is not" positioning for credibility. Each file must specify how the Chinese version will later adapt into English without becoming a direct translation of forum copy, while preserving the target strong-opinion energy in a community-safe way.
  **Must NOT do**: Do not escalate contrarian framing into framework-war language.

  **Recommended Agent Profile**:
  - Category: `writing` — Reason: second-half series outline design
  - Skills: `[]`
  - Omitted: `agent-browser` — not needed

  **Parallelization**: Can Parallel: YES | Wave 2 | Blocks: 10 | Blocked By: 2,4,6,7

  **References**:
  - Pattern: `README.md:17` — what Nex is and is not
  - Pattern: `CHANGELOG.md:8` — momentum and shipped features
  - Pattern: `showcase/agent_console/README.md:5` — showcase proof for advanced/product-shaped post
  - Pattern: `LAUNCH_COPY.md:48` — bounded non-Phoenix-replacement framing

  **Acceptance Criteria** (agent-executable only):
  - [ ] Files `05.md` through `08.md` exist
  - [ ] Each file contains the same required fields as task 8, including `Voice Notes`, `Chinese Draft Goal`, and `English Adaptation Trigger`
  - [ ] At least one of posts 5-8 uses changelog momentum as the primary proof

  **QA Scenarios** (MANDATORY — task incomplete without these):
  ```text
  Scenario: Happy path
    Tool: Grep
    Steps: Search post files `05`-`08` for `Primary Proof:` and ensure one references `CHANGELOG.md`
    Expected: At least one later-stage post uses shipped-feature momentum as proof
    Evidence: .sisyphus/evidence/task-9-posts-5-8.txt

  Scenario: Failure/edge case
    Tool: Read
    Steps: Inspect all four outlines and confirm the comparison angle stays framed as fit/tradeoffs rather than replacement/attack language
    Expected: No outline claims Nex should replace Phoenix everywhere
    Evidence: .sisyphus/evidence/task-9-posts-5-8-error.txt
  ```

  **Commit**: YES | Message: `docs(content): add second four post outlines` | Files: `.sisyphus/content/nex-community-series/posts/05.md`, `.sisyphus/content/nex-community-series/posts/06.md`, `.sisyphus/content/nex-community-series/posts/07.md`, `.sisyphus/content/nex-community-series/posts/08.md`

- [x] 10. Assemble Final Strategy Package

  **What to do**: Review all generated files, add cross-links between them, and finalize `strategy.md` with a concise operating model: source of truth, sequencing logic, publish-readiness gates, and weekly workflow. Ensure the package can be handed to an execution agent with zero judgment calls.
  **Must NOT do**: Do not leave unresolved placeholders or unnamed dependencies.

  **Recommended Agent Profile**:
  - Category: `writing` — Reason: synthesis, normalization, and final packaging
  - Skills: `[]`
  - Omitted: `git-master` — commit work is straightforward and optional

  **Parallelization**: Can Parallel: NO | Wave 3 | Blocks: none | Blocked By: 5,7,8,9

  **References**:
  - Pattern: `.sisyphus/content/nex-community-series/strategy.md` — central orchestration doc created earlier in execution
  - Pattern: `.sisyphus/content/nex-community-series/channel-playbook.md` — channel constraints and title patterns
  - Pattern: `.sisyphus/content/nex-community-series/proof-inventory.md` — source-of-truth proof map
  - Pattern: `.sisyphus/content/nex-community-series/calendar.md` — sequence of record

  **Acceptance Criteria** (agent-executable only):
  - [ ] `strategy.md` links all other deliverables and names them as canonical sources
  - [ ] No file in `.sisyphus/content/nex-community-series/` contains placeholders like `[TODO]`, `[subreddit]`, or `[metric]`
  - [ ] The package explicitly states what is ready to publish now vs blocked on assets

  **QA Scenarios** (MANDATORY — task incomplete without these):
  ```text
  Scenario: Happy path
    Tool: Grep
    Steps: Search `.sisyphus/content/nex-community-series/` for placeholder strings `[TODO]`, `[subreddit]`, `[metric]`
    Expected: No matches
    Evidence: .sisyphus/evidence/task-10-final-package.txt

  Scenario: Failure/edge case
    Tool: Read
    Steps: Read `strategy.md` and confirm it points to readiness statuses in `asset-gaps.md` instead of claiming all 8 posts are publish-ready
    Expected: Blocked work remains clearly separated from ready work
    Evidence: .sisyphus/evidence/task-10-final-package-error.txt
  ```

  **Commit**: YES | Message: `docs(content): finalize community series package` | Files: `.sisyphus/content/nex-community-series/strategy.md`, `.sisyphus/content/nex-community-series/channel-playbook.md`, `.sisyphus/content/nex-community-series/proof-inventory.md`, `.sisyphus/content/nex-community-series/asset-gaps.md`, `.sisyphus/content/nex-community-series/calendar.md`, `.sisyphus/content/nex-community-series/posts/01.md`, `.sisyphus/content/nex-community-series/posts/02.md`, `.sisyphus/content/nex-community-series/posts/03.md`, `.sisyphus/content/nex-community-series/posts/04.md`, `.sisyphus/content/nex-community-series/posts/05.md`, `.sisyphus/content/nex-community-series/posts/06.md`, `.sisyphus/content/nex-community-series/posts/07.md`, `.sisyphus/content/nex-community-series/posts/08.md`, `.sisyphus/content/nex-community-series/metrics.md`

## Final Verification Wave (4 parallel agents, ALL must APPROVE)
- [x] F1. Plan Compliance Audit — oracle
- [x] F2. Code Quality Review — unspecified-high
- [x] F3. Real Manual QA — unspecified-high (+ playwright if UI)
- [x] F4. Scope Fidelity Check — deep

## Commit Strategy
- `docs(content): add channel posting rules`
- `docs(content): add nex proof inventory`
- `docs(content): define audience and KPI model`
- `docs(content): add asset gap matrix`
- `docs(content): add review metrics loop`
- `docs(content): add 8 week series calendar`
- `docs(content): expand channel playbooks`
- `docs(content): add first four post outlines`
- `docs(content): add second four post outlines`
- `docs(content): finalize community series package`

## Success Criteria
- The execution package lets another agent create the entire series without making channel, tone, asset, or sequencing decisions.
- Every planned post maps to a specific repo proof source and a specific channel adaptation.
- The series contains a balanced arc: credibility -> education -> bounded contrast -> showcase/momentum.
- Star-seeking CTAs are present but remain secondary to value delivery in every community surface.
- At least one broader-reach Reddit channel is named and governed by explicit anti-spam rules.
- The workflow enforces Chinese-first review before any English adaptation work begins.
- The Chinese voice guide is specific enough that an execution agent can reproduce the intended style without copying another creator's wording.
