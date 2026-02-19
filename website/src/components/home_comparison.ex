defmodule NexWebsite.Components.HomeComparison do
  use Nex

  def render(assigns) do
    ~H"""
    <section class="py-24 px-6 md:px-10" style="background: #FAFAF8; border-top: 1px solid #EBEBEB;">
      <div class="max-w-5xl mx-auto">
        <div class="text-center mb-14">
          <p class="text-xs font-semibold uppercase tracking-widest mb-3" style="color: #9B7EBD; letter-spacing: 0.12em;">Comparison</p>
          <h2 class="text-4xl font-bold mb-3" style="color: #111; letter-spacing: -0.03em;">Why not Phoenix or Rails?</h2>
          <p class="text-lg" style="color: #666;">Nex is not a replacement — it's a focused tool for a specific job</p>
        </div>

        <div class="grid md:grid-cols-3 gap-5">
          <div class="p-7 rounded-2xl" style="background: white; border: 1px solid #EBEBEB;">
            <h3 class="font-bold mb-3 text-lg" style="color: #111;">vs Phoenix</h3>
            <p class="text-sm leading-relaxed mb-4" style="color: #555;">Phoenix is powerful and battle-tested. Nex is for when you want server-side rendering without LiveView's complexity. No channels, no PubSub, no Contexts — just pages and actions.</p>
            <p class="text-xs font-semibold" style="color: #9B7EBD;">Best for: Rapid prototypes, indie projects, AI-assisted development</p>
          </div>
          <div class="p-7 rounded-2xl" style="background: white; border: 1px solid #EBEBEB;">
            <h3 class="font-bold mb-3 text-lg" style="color: #111;">vs React / Next.js</h3>
            <p class="text-sm leading-relaxed mb-4" style="color: #555;">Frontend frameworks require JavaScript expertise, build tooling, and client-side state management. Nex uses HTMX for interactivity — no virtual DOM, no hydration, no bundle size.</p>
            <p class="text-xs font-semibold" style="color: #9B7EBD;">Best for: Server-rendered apps, zero-JS philosophy, Elixir teams</p>
          </div>
          <div class="p-7 rounded-2xl" style="background: white; border: 1px solid #EBEBEB;">
            <h3 class="font-bold mb-3 text-lg" style="color: #111;">vs Rails</h3>
            <p class="text-sm leading-relaxed mb-4" style="color: #555;">Rails is full-featured but opinionated and heavy. Nex is minimal by design — no ORM, no asset pipeline, no generators. You bring what you need, nothing more.</p>
            <p class="text-xs font-semibold" style="color: #9B7EBD;">Best for: Elixir ecosystem, concurrency, long-running connections</p>
          </div>
        </div>
      </div>
    </section>
    """
  end
end
