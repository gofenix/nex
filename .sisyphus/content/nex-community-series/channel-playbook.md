# Channel Playbook

## Operating Rule
- Write the Chinese draft first.
- Get Chinese approval before any English adaptation.
- English adaptation is not a literal translation. It keeps the proof and core claim, but rewrites the opening, CTA, and comparison language for each target community.
- Never paste the same body into `Elixir Forum`, `r/elixir`, `r/htmx`, and `r/webdev`.

## Cross-Post Cadence
- Weekly cap: at most 1 primary-channel post per calendar week across `Elixir Forum`, `r/elixir`, `r/htmx`, and `r/webdev`.
- Backup post: optional 1 backup-channel post in the same week only if the channel fit is strong and the primary post lands cleanly.
- Cooldown: wait at least 72 hours between the primary post and any backup post.
- Burst limit: never post to more than 2 of these channels in a single week.
- `r/webdev` constraint: never post to `r/webdev` in the same week as another channel unless it is the planned primary slot and the format is compliant (for example, `Showoff Saturday` when linking the project).

## Elixir Forum
- Allowed Angle: library/framework introduction with concrete trade-offs, build log, release notes, docs feedback request, or example walkthrough tied to Elixir usage.
- Tone: calm, technical, discussion-first. Lead with what Nex is for, what it is not, and what you want feedback on.
- CTA: ask for feedback on trade-offs, docs clarity, and framework fit; secondary link to GitHub only after context is established.
- Do Not Post: hype-only launch copy, flamebait against Phoenix, vague "look what I built" with no Elixir-specific substance, duplicate reposts across categories.
- Moderation Risk: medium if the post reads like promotion instead of community discussion; lower if it is framed as a concrete library update or architecture discussion.
- Opening Pattern: "I have been building a small HTMX-first Elixir framework called Nex, mainly for SSR-heavy apps where I want less ceremony than a larger stack. The part I want feedback on is..."
- Title Patterns:
  - `Building Nex: an HTMX-first Elixir framework for SSR-heavy apps`
  - `Nex 0.4.0: validator, upload handling, and rate-limiting updates`
  - `Trade-offs in building a smaller Elixir web framework around HTMX`
- Comment Strategy: answer trade-off questions directly; if Phoenix comparisons appear, keep the response on fit and workflow, not superiority.
- CTA Ladder:
  - Soft ask: `Curious whether this framing makes sense to other Elixir developers.`
  - Specific ask: `Would especially love feedback on docs, examples, and where the scope still feels too broad.`
  - Star ask: `If the direction resonates, the repo is here.`
- Voice Boundary: Chinese draft can open sharper; English forum version must reduce rhetorical flourish and foreground scope boundaries.
- Sources:
  - `https://elixirforum.com/faq`
  - `https://elixirforum.com/t/how-to-post-or-use-our-wikis/352`

## r/elixir
- Allowed Angle: Elixir-native discussion around SSR, HTMX, file routing, release notes, example apps, and framework design trade-offs.
- Tone: direct, proof-led, concise. The subreddit explicitly allows external content, but punishes excessive self-promotion and blog spam.
- CTA: feedback first, repo second, stars last.
- Do Not Post: AI-slop copy, unmarked AI-generated text, repeated self-links, off-topic startup marketing, or non-English content.
- Moderation Risk: medium-high if the post is link-heavy or reads like blog spam; lower if the body contains real substance and explicit trade-offs.
- Opening Pattern: "Built a small Elixir framework for HTMX-first SSR apps because I kept wanting server-rendered workflows without dragging in SPA complexity. The interesting part is not the launch itself, but the trade-offs around..."
- Title Patterns:
  - `Built an HTMX-first Elixir framework for SSR-heavy apps`
  - `What I learned building Nex instead of reaching for a bigger Elixir stack`
  - `Nex 0.4.0 adds validation and uploads; looking for feedback on scope`
- Comment Strategy: if challenged on overlap with Phoenix, answer with `fit`, `surface area`, and `use case`; never claim replacement.
- CTA Ladder:
  - Soft ask: `Would love honest feedback from Elixir devs on where this fits and where it clearly does not.`
  - Specific ask: `If you have 5 minutes, I care most about feedback on the example path and docs clarity.`
  - Star ask: `If you want to follow the project, the repo is here.`
- Voice Boundary: strong-opinion openings are fine, but they must be backed by repo proof in the first screenful.
- Sources:
  - `https://old.reddit.com/r/elixir/about/rules`
  - `https://www.reddit.com/r/elixir/about/rules`

## r/htmx
- Allowed Angle: HTMX workflow demos, SSR examples, SSE/WebSocket usage, and practical comparisons showing where server-driven UI works well.
- Tone: demo-first and implementation-heavy. This community is smaller and more tolerant of build logs, but weak posts still die if there is no concrete proof.
- CTA: invite workflow discussion, code review, or HTMX-specific critique.
- Do Not Post: generic Elixir launch copy, framework-positioning essay with no HTMX example, or big-stack tribal arguments.
- Moderation Risk: low-medium if the post contains a concrete HTMX flow; higher if it is mostly branding.
- Opening Pattern: "The interesting Nex claim is not `new Elixir framework`; it is that a lot of common app interactions can stay server-rendered and still feel modern. Here is the smallest proof..."
- Title Patterns:
  - `Using HTMX + server rendering in Elixir without a large frontend stack`
  - `A tiny HTMX counter is still the best way to explain Nex`
  - `Nex uses file routing + HTMX + SSE; looking for critique on the workflow`
- Comment Strategy: stay close to the example, share the exact file path, and answer with code-level detail.
- CTA Ladder:
  - Soft ask: `Interested in where this HTMX flow feels clean vs awkward.`
  - Specific ask: `Would love critique on the routing/action model and whether the demo proves the point.`
  - Star ask: `If you want more examples, the repo is here.`
- Voice Boundary: keep the Chinese strong-opinion energy, but the English adaptation should pivot fast into the demo.
- Sources:
  - `https://old.reddit.com/r/htmx/about/rules`
  - `https://www.reddit.com/r/htmx/about/rules`

## r/webdev
- Allowed Angle: process write-up, architecture trade-offs, SSR/HTMX positioning, or a show-and-tell post only when it fits the subreddit timing and self-promo limits.
- Tone: practical and cross-stack. Assume readers do not care about Elixir by default; lead with the web-dev problem, not the language.
- CTA: ask for perspective on workflow, DX, or SSR trade-offs. If asking for feedback on the project itself, reserve that for `Showoff Saturday`.
- Do Not Post: commercial promotion, repo-dump launch posts, off-day feedback requests, meme framing, or vague claims without screenshots/snippets.
- Moderation Risk: high outside the right format. This subreddit explicitly limits self-promotion and feedback requests.
- Opening Pattern: "A lot of web tooling complexity comes from defaulting to a client-heavy stack too early. I have been exploring the opposite path with a small SSR-first Elixir framework, and this is the part that seems broadly relevant to web dev..."
- Title Patterns:
  - `What gets simpler when you keep more web app interactions server-rendered?`
  - `A small case study in HTMX-first SSR app design`
  - `Showoff Saturday: Nex, a small Elixir framework for HTMX-first apps`
- Comment Strategy: contextualize everything for general web developers; explain why the post matters even if the reader never uses Elixir.
- CTA Ladder:
  - Soft ask: `Curious whether this workflow feels appealing or limiting from a general web-dev perspective.`
  - Specific ask: `If you have feedback, I care most about whether the examples prove the DX claim.`
  - Star ask: `Repo link is here for anyone who wants to inspect the implementation.`
- Voice Boundary: strip out insider phrasing and most rhetorical flourish; make the post useful even without repo clicks.
- Sources:
  - `https://old.reddit.com/r/webdev/about/rules`
  - `https://old.reddit.com/r/webdev/wiki/index`

## Non-Copy-Paste Adaptation Rule
- Same core claim, different first paragraph.
- Same proof source, different proof framing.
- Same repo link, different CTA priority.
- `Elixir Forum` and `r/elixir` can foreground framework trade-offs.
- `r/htmx` must foreground the HTMX interaction proof.
- `r/webdev` must foreground the broader workflow problem and only use project feedback asks where the subreddit format allows it.

## Source Notes
- Reddit rules were pulled from direct community rule pages on old/new Reddit.
- `r/htmx` exposes little formal rule text via logged-out fetch, so use demo-first, low-promo behavior as the safe default and re-check the live sidebar before posting.
- Elixir Forum FAQ fetch was unreliable in automation. Treat `https://elixirforum.com/faq` as a mandatory manual preflight before the first live post.
