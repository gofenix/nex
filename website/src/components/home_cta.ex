defmodule NexWebsite.Components.HomeCta do
  use Nex

  def render(assigns) do
    ~H"""
    <section class="py-28 px-6 md:px-10 text-center" style="background: white; border-top: 1px solid #EBEBEB;">
      <div class="max-w-2xl mx-auto">
        <h2 class="text-4xl md:text-5xl font-extrabold mb-5" style="color: #111; letter-spacing: -0.04em;">
          Ready to ship<br/>something real?
        </h2>
        <p class="text-xl mb-10" style="color: #666;">
          Install in 30 seconds. Your first page in 2 minutes.
        </p>
        <div class="flex flex-col sm:flex-row gap-3 justify-center mb-12">
          <a href="/getting_started" class="inline-flex items-center justify-center gap-2 text-base font-semibold text-white px-8 py-3.5 rounded-full transition-all hover:opacity-90 hover:-translate-y-0.5" style="background: linear-gradient(135deg, #9B7EBD, #7B5FA8); box-shadow: 0 4px 20px rgba(123,95,168,0.35);">
            Get Started — Free
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7l5 5m0 0l-5 5m5-5H6"/></svg>
          </a>
          <a href="https://github.com/gofenix/nex" target="_blank" class="inline-flex items-center justify-center gap-2 text-base font-medium px-8 py-3.5 rounded-full transition-all hover:bg-gray-100" style="color: #444; background: #F5F5F0; border: 1px solid #E0E0E0;">
            <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24"><path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/></svg>
            Star on GitHub
          </a>
        </div>
        <div class="flex items-center justify-center gap-8 flex-wrap">
          <div class="flex items-center gap-2 text-sm" style="color: #888;">
            <svg class="w-4 h-4" style="color: #9B7EBD;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
            MIT Licensed
          </div>
          <div class="flex items-center gap-2 text-sm" style="color: #888;">
            <svg class="w-4 h-4" style="color: #9B7EBD;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
            No credit card required
          </div>
          <div class="flex items-center gap-2 text-sm" style="color: #888;">
            <svg class="w-4 h-4" style="color: #9B7EBD;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
            Production ready
          </div>
        </div>
      </div>
    </section>
    """
  end
end
