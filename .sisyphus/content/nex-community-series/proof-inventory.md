# Proof Inventory

## Claims
- Nex is the simplest way to build HTMX apps in Elixir.
- Nex is a minimalist, HTMX-first, server-rendered framework with low ceremony.
- Nex is explicitly not trying to replace Phoenix for every use case.
- Nex offers concrete shipped features, not just positioning copy.
- Nex has both tiny examples and product-shaped showcases.

## Post Map

### Post 01
- primary-proof: `README.md:3`, `README.md:9`, `website/priv/docs/intro.md:3`
- notes: publish-now per `asset-gaps.md`, keep the opener sharp but cash out fast into these exact repo lines.

### Post 02
- primary-proof: `website/src/pages/features.ex:34`, `README.md:15`, `README.md:12`
- notes: publish-now per `asset-gaps.md`, do not let the AI angle float without quoting the website copy.

### Post 03
- primary-proof: `examples/counter/README.md:3`, `examples/counter/README.md:23`, `README.md:69`
- notes: publish-now per `asset-gaps.md`, keep the proof extremely small and centered on the counter loop.

### Post 04
- primary-proof: `website/src/pages/features.ex:77`, `README.md:44`, `README.md:65`
- notes: publish-now per `asset-gaps.md`, frame as workflow case study first to fit `r/webdev` rules.

### Post 05
- primary-proof: `README.md:27`, `LAUNCH_COPY.md:48`, `website/priv/docs/intro.md:9`
- notes: publish-now per `asset-gaps.md`, repeat the scope boundary and keep the comparison on fit.

### Post 06
- primary-proof: `CHANGELOG.md:8`, `CHANGELOG.md:35`, `CHANGELOG.md:45`
- notes: publish-now per `asset-gaps.md`, cite specific shipped items instead of vague momentum language.

### Post 07
- primary-proof: `showcase/agent_console/README.md:3`, `showcase/agent_console/README.md:5`, `website/src/pages/features.ex:111`
- notes: needs-asset per `asset-gaps.md`, do not publish until at least two Agent Console screenshots exist.

### Post 08
- primary-proof: `README.md:11`, `website/priv/docs/intro.md:7`, `examples/counter/README.md:23`
- notes: needs-asset per `asset-gaps.md`, this needs minimal visuals to land with a broader `r/webdev` audience.

## Proof Units
- claim: Nex is framed around SSR without SPA complexity.
  source: `README.md:3`
  audience: indie builders, Elixir veterans
  reuse-note: strongest top-line tagline for launch, intro, and comparison posts.

- claim: Nex targets developers shipping real products without framework ceremony.
  source: `README.md:9`
  audience: indie builders
  reuse-note: use in Chinese-first opener when positioning against stack complexity.

- claim: HTMX-first is a first-class product decision, not an afterthought.
  source: `README.md:11`
  audience: HTMX-curious builders, webdev audience
  reuse-note: anchor workflow posts and HTMX-specific Reddit threads.

- claim: One `use Nex` entry point keeps the surface area small.
  source: `README.md:12`
  audience: Elixir veterans, AI coders
  reuse-note: good for DX-focused posts and AI-friendly locality framing.

- claim: File-based routing is a core differentiator.
  source: `README.md:13`
  audience: indie builders, webdev audience
  reuse-note: pair with route examples from website/features for concrete proof.

- claim: Nex is AI-friendly because UI and behavior live close together.
  source: `README.md:15`
  audience: AI coders
  reuse-note: use only with a concrete example or showcase, never as a standalone slogan.

- claim: Nex is a fit for indie products, internal tools, HTMX apps, and JSON/SSE endpoints.
  source: `README.md:19`
  audience: mixed
  reuse-note: use as scope framing when people ask who the framework is for.

- claim: Nex is not a Phoenix replacement for every use case.
  source: `README.md:27`
  audience: Elixir veterans
  reuse-note: mandatory balancing line in any contrarian or comparison post.

- claim: Nex wants to bring back the joy of server-driven web development.
  source: `website/priv/docs/intro.md:3`
  audience: indie builders, webdev audience
  reuse-note: strongest philosophical framing for a Chinese strong-opinion opener.

- claim: Nex treats HTMX as the default interaction layer because it believes SSR + declarative interactions cover most app needs.
  source: `website/priv/docs/intro.md:7`
  audience: r/htmx, r/webdev
  reuse-note: use when defending the HTMX-first bet.

- claim: Nex is a lightweight alternative to Phoenix in specific scenarios.
  source: `website/priv/docs/intro.md:9`
  audience: Elixir veterans
  reuse-note: safer comparison wording than any homemade anti-Phoenix line.

- claim: One file can represent one complete feature, which helps AI-assisted building.
  source: `website/src/pages/features.ex:34`
  audience: AI coders
  reuse-note: pair with exact wording `Locality of Behavior` for the AI-era angle.

- claim: File system to routes is visible and easy to explain.
  source: `website/src/pages/features.ex:77`
  audience: indie builders, webdev audience
  reuse-note: excellent for screenshots or code-snippet explainers.

- claim: Every module using the same `use Nex` statement reduces API sprawl.
  source: `website/src/pages/features.ex:102`
  audience: Elixir veterans, AI coders
  reuse-note: use in posts about simplicity and framework surface area.

- claim: `Nex.stream/1` gives first-class SSE support for AI chat and live progress UX.
  source: `website/src/pages/features.ex:111`
  audience: AI coders, webdev audience
  reuse-note: strongest hook for modern/AI app discussions without sounding generic.

- claim: Nex ships automatic CSRF, hot reload, and CDN-first no-build-step defaults.
  source: `website/src/pages/features.ex:123`
  audience: indie builders, webdev audience
  reuse-note: good cluster for posts about "less tooling, still usable".

- claim: The counter example proves SSR, HTMX partial updates, and state management in a tiny app.
  source: `examples/counter/README.md:3`
  audience: r/htmx, indie builders
  reuse-note: best first proof for a low-friction educational post.

- claim: The counter example explains exactly how HTMX requests and partial updates work.
  source: `examples/counter/README.md:23`
  audience: r/htmx, webdev audience
  reuse-note: strong for code-level replies in comments.

- claim: Agent Console is a real app-shaped showcase with chat, sessions, and real-time interaction.
  source: `showcase/agent_console/README.md:3`
  audience: AI coders, Elixir veterans
  reuse-note: strongest proof that Nex is not only toy examples.

- claim: Agent Console includes WebSocket messaging and streaming responses.
  source: `showcase/agent_console/README.md:5`
  audience: AI coders
  reuse-note: pair with SSE/WebSocket release notes for momentum posts.

- claim: Existing launch copy already frames Nex as HTMX-first, file-routed, intentionally small, with examples and showcases.
  source: `LAUNCH_COPY.md:13`
  audience: mixed
  reuse-note: use as raw material, not as final community copy.

- claim: Existing launch copy already contains a safe scope boundary for Phoenix comparison.
  source: `LAUNCH_COPY.md:48`
  audience: Elixir veterans
  reuse-note: preferred wording for bounded comparison posts.

- claim: Nex 0.4.0 shipped Validator and Upload support recently.
  source: `CHANGELOG.md:8`
  audience: mixed
  reuse-note: strongest momentum proof for "this project is moving" posts.

- claim: Nex already shipped WebSocket support, rate limiting, session, flash, middleware, and static-file conveniences.
  source: `CHANGELOG.md:35`
  audience: Elixir veterans, indie builders
  reuse-note: use to answer "is this only a landing page project?" objections.

- claim: The README includes an explicit example project structure tree.
  source: `README.md:44`
  audience: webdev audience, indie builders
  reuse-note: use as concrete proof that Nex documents a file-oriented SSR project layout.

- claim: The README states file-based routing comes from `src/pages/`.
  source: `README.md:65`
  audience: webdev audience, indie builders
  reuse-note: best for route-from-files walkthroughs and `r/webdev` workflow framing.

- claim: The README has a dedicated "HTMX and SSR" capabilities section.
  source: `README.md:69`
  audience: r/htmx, webdev audience
  reuse-note: use when pointing readers to the deeper capability list, not only the top tagline.

- claim: Nex 0.3.7 added Cookie, Session, Flash, and Middleware primitives.
  source: `CHANGELOG.md:45`
  audience: Elixir veterans
  reuse-note: cite as older shipped surface area proof in momentum posts.

## Audience Fit
- indie builders
  - best proof: `README.md`, `examples/counter/README.md`, `website/src/pages/features.ex`
  - what they care about: smaller stack, faster iteration, fewer moving pieces, concrete examples

- Elixir veterans
  - best proof: `README.md`, `website/priv/docs/intro.md`, `CHANGELOG.md`
  - what they care about: scope clarity, trade-offs vs Phoenix, release momentum, real capabilities

- AI coders
  - best proof: `website/src/pages/features.ex`, `showcase/agent_console/README.md`, `CHANGELOG.md`
  - what they care about: locality of behavior, SSE/WebSocket support, real app examples

## Missing Proof
- screenshots: weak
  - there is no reusable screenshot pack for examples or showcases.
- benchmarks: absent
  - there is no hard benchmark story for performance, DX speed, or LOC comparisons.
- testimonials: absent
  - there is no user quote or external adoption proof pack in the repo.
- canonical proof snippets by channel: absent
  - execution still needs a reusable snippet bank for Chinese drafts and later English adaptations.
