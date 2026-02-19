defmodule NexWebsite.Components.HomeHero do
  use Nex

  def render(assigns) do
    ~H"""
    <section class="relative overflow-hidden" style="background: #FAFAF8; min-height: 88vh; display: flex; align-items: center;">
      <div class="absolute inset-0 pointer-events-none" style="background-image: linear-gradient(rgba(0,0,0,0.03) 1px, transparent 1px), linear-gradient(90deg, rgba(0,0,0,0.03) 1px, transparent 1px); background-size: 40px 40px;"></div>
      <div class="absolute top-1/3 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[400px] rounded-full pointer-events-none" style="background: radial-gradient(ellipse, rgba(155,126,189,0.12) 0%, transparent 70%);"></div>

      <div class="relative max-w-5xl mx-auto px-6 md:px-10 py-24 text-center w-full">
        <a href="https://hex.pm/packages/nex_core" target="_blank" class="inline-flex items-center gap-2 text-xs font-medium px-3.5 py-1.5 rounded-full mb-8 transition-all hover:opacity-80" style="background: #F0EBF8; color: #7B5FA8; border: 1px solid #D4C5E8;">
          <span class="w-1.5 h-1.5 rounded-full bg-green-400"></span>
          v0.3 · Open Source · MIT License
        </a>

        <h1 class="text-5xl md:text-7xl font-extrabold tracking-tight mb-6 leading-[1.08]" style="color: #111; letter-spacing: -0.04em;">
          The Elixir Framework<br/>
          <span style="color: #9B7EBD;">for the AI Era.</span>
        </h1>

        <p class="text-xl md:text-2xl mb-10 max-w-2xl mx-auto leading-relaxed" style="color: #666; font-weight: 400;">
          Write a file, get a route. Write a function, get an action.<br class="hidden md:block"/>
          Ship real products in minutes, not days.
        </p>

        <div class="flex flex-col sm:flex-row gap-3 justify-center mb-16">
          <a href="/getting_started" class="inline-flex items-center justify-center gap-2 text-base font-semibold text-white px-7 py-3 rounded-full transition-all hover:opacity-90 hover:-translate-y-0.5" style="background: linear-gradient(135deg, #9B7EBD, #7B5FA8); box-shadow: 0 4px 20px rgba(123,95,168,0.35);">
            Start Building
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7l5 5m0 0l-5 5m5-5H6"/></svg>
          </a>
          <a href="/docs" class="inline-flex items-center justify-center gap-2 text-base font-medium px-7 py-3 rounded-full transition-all hover:bg-gray-100" style="color: #444; background: white; border: 1px solid #E0E0E0;">
            Read the Docs
          </a>
        </div>

        <div class="max-w-2xl mx-auto rounded-2xl overflow-hidden text-left" style="box-shadow: 0 8px 40px rgba(0,0,0,0.12); border: 1px solid #2A2A2A;">
          {raw(@example_code)}
        </div>
      </div>
    </section>
    """
  end
end
