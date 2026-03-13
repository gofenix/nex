# Strategy

## Package Map
- Canonical overview: `strategy.md`
- Channel rules and title patterns: `channel-playbook.md`
- Repo-backed proof source of truth: `proof-inventory.md`
- Publish readiness and asset blockers: `asset-gaps.md`
- Sequence of record: `calendar.md`
- Weekly review loop: `metrics.md`
- Post briefs: `posts/01.md` through `posts/08.md`

## Operating Model
- Only four channels are in scope for this series: `r/elixir`, `r/htmx`, `r/webdev`, and Elixir Forum.
- Start in `calendar.md` to select the current week and intended channel order.
- Open the matching `posts/0N.md` file to get the audience, hook, proof, and Chinese-first voice notes.
- Cross-check every claim against `proof-inventory.md` before drafting.
- Confirm whether the post is `publish-now` or `needs-asset` in `asset-gaps.md`.
- Adapt the post using the channel-specific rules in `channel-playbook.md`.
- After publishing, record outcome and objections in `metrics.md` before drafting the next post.

## Approval Tracking
- The source of truth for Chinese approval is `metrics.md`.
- For each week you execute, append a new weekly entry in `metrics.md` and include a line: `Chinese approved: yes/no`.
- English adaptation is allowed only when the latest `metrics.md` entry for that week has `Chinese approved: yes`.

## Active Week Selection
- Default order is Week 1 to Week 8, no jumping.
- The Active Week is the earliest week number in `calendar.md` that meets both conditions:
  - It is not already executed in `metrics.md` (there is no weekly entry whose `### Metadata` includes `Week number: 0N`).
  - Its matching post is `publish-now` in `asset-gaps.md`.
- If the earliest unlogged week is `needs-asset`, skip it and choose the next earliest unlogged `publish-now` week.
- In `metrics.md`, record what was executed using the template metadata fields: `Week number: (01-08)` and `Post Used: (01-08)`. Do not infer the post from the calendar after the fact.
- If you intentionally skip a week, still append a weekly entry in `metrics.md` with `Week number: 0N` filled and note the skip reason in `### Weekly Scorecard` (for example, on `Primary post:`), so the next Active Week choice stays deterministic.

## Publish-Readiness Gate
- A post can move from outline to draft only if its `Status` is `publish-now`.
- A post can move from Chinese draft to English adaptation only after Chinese approval.
- A post marked `needs-asset` stays blocked until the named screenshot, snippet, or visual proof exists.
- No post may rely on benchmarks, testimonials, or adoption proof that the repo does not actually contain.

## Weekly Workflow
1. Pick the scheduled post from `calendar.md`.
2. Draft the Chinese version using the matching post brief and `Chinese Voice Guide`.
3. Review the draft against `proof-inventory.md` and `channel-playbook.md`.
4. Approve or revise the Chinese version.
5. Only then prepare the English adaptation for the named primary channel.
6. Log results, objections, and next-proof upgrades in `metrics.md`.

## Audience Segments
### Indie Builders
- Core pain: too much stack ceremony before shipping anything useful.
- What they want from Nex: fewer layers, faster demo-to-product path, examples they can copy.
- Proof preference: tiny examples, file-based routing, HTMX partial updates, no-build-step defaults.
- Best-fit channel: Chinese drafts first, then `r/htmx` or `r/webdev` depending on the angle.
- What makes them star: they can picture using Nex this week for an internal tool, side project, or MVP.

### Elixir Veterans
- Core pain: they already know Phoenix exists, so they need a reason to care about a smaller framework.
- What they want from Nex: clear scope boundaries, honest trade-offs, and proof that the project is moving.
- Proof preference: README scope language, changelog momentum, release notes, and real examples.
- Best-fit channel: Elixir Forum and `r/elixir`.
- What makes them star: the project feels intellectually honest, opinionated in a bounded way, and worth tracking.

### AI Coders
- Core pain: many frameworks spread a single feature across too many files and abstractions.
- What they want from Nex: locality of behavior, low boilerplate, streaming-friendly primitives, and a real showcase app.
- Proof preference: `Locality of Behavior`, `one file = one complete feature`, `Nex.stream/1`, Agent Console.
- Best-fit channel: Chinese drafts first, then `r/elixir` or `r/webdev` depending on the angle.
- What makes them star: they immediately see why Nex is easier for agent-assisted iteration than a more fragmented stack.

## KPI Hierarchy
1. GitHub stars
2. GitHub visits
3. docs visits
4. discussion depth

### KPI Interpretation
- Stars are the primary signal because the user wants durable attention, not one-off comments.
- GitHub visits matter because they show whether the hook converts into inspection.
- Docs visits matter because they show whether the story moves people from curiosity to learning.
- Discussion depth matters last; high comments with no repo curiosity is not the main win condition.

## CTA Hierarchy
### Soft Ask
- Ask for reactions to the trade-off, workflow, or example proof.
- Best for first contact with a community.

### Specific Ask
- Ask for feedback on docs, examples, naming, scope boundaries, or a single architectural choice.
- Best when the body already proved there is something real to inspect.

### Star Ask
- Invite people to follow the repo if the direction resonates.
- Keep this last. It should never be the first sentence or the entire reason the post exists.

## Message Boundaries
- Never pitch Nex as a universal Phoenix replacement.
- Never claim speed, simplicity, or AI-friendliness without repo proof in the same post.
- Never optimize one post for all three audiences; every post gets one primary audience and at most one secondary audience.
- Never open with the repo link.
- Never make English adaptations more dramatic than the Chinese original.
- Never treat `needs-asset` posts as ready just because the copy sounds strong.

## Chinese Voice Guide
### What To Emulate
- Open with tension: start from a slightly uncomfortable judgment, not a bland introduction.
- Speak in first person: `我为什么会想做这个`, `我踩过什么坑`, `我为什么不想再忍这个复杂度`.
- Keep spoken cadence: short sentences, deliberate rhythm changes, and occasional sharp turns.
- Use dense examples: every strong claim should quickly land on a repo file, shipped feature, example app, or changelog entry.
- Stay concrete: if the opening says "我受不了这个复杂度了", the next paragraph should show exactly which complexity Nex is trying to cut.

### What To Avoid
- Empty hot takes with no first-hand experience.
- Rage-bait against Phoenix, LiveView, React, or SPAs.
- Borrowing another creator's exact signature phrasing.
- Corporate copy like `empowering developers` or `redefining productivity`.

### Practical Writing Formula
1. Sharp opening judgment.
2. Why this bothered me personally.
3. The smallest hard proof from the repo.
4. The scope boundary: what Nex is good at and what it is not for.
5. A discussion-first CTA.

### Safe Opening Templates
- `我越来越觉得，很多 Web 项目的复杂度，根本不是业务本身需要的，而是我们默认接受了一整套本来可以不要的前端仪式。`
- `我做 Nex，不是因为我觉得 Phoenix 不够好。恰恰相反，是因为 Phoenix 很强，所以我更清楚什么时候我其实根本不需要那么大的面。`
- `如果一个页面里的交互，最后只是改几个局部块，我现在越来越不想先把它想成一个前端工程问题。`

### Community-Safe Boundaries
- Sharp does not mean hostile.
- Contrarian does not mean contemptuous.
- First person does not mean self-indulgent; every personal stance still has to cash out into proof.
- If the post cannot survive after removing the rhetoric, the post is too weak.

### English Adaptation Note
- Keep the proof and claim, but reduce rhetorical flourish.
- Move faster to the concrete example.
- Replace implicit tone with explicit trade-off language.
- Prefer `here is where it fits` over `this is the future`.
