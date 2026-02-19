defmodule NexWebsite.Components.HomePhilosophy do
  use Nex

  def render(assigns) do
    ~H"""
    <section class="py-24 px-6 md:px-10" style="background: #FAFAF8; border-top: 1px solid #EBEBEB;">
      <div class="max-w-5xl mx-auto">
        <div class="grid md:grid-cols-2 gap-16 items-center">
          <div>
            <p class="text-xs font-semibold uppercase tracking-widest mb-3" style="color: #9B7EBD; letter-spacing: 0.12em;">Philosophy</p>
            <h2 class="text-3xl md:text-4xl font-bold mb-5" style="color: #111; letter-spacing: -0.03em;">One file.<br/>One feature.<br/>Complete context.</h2>
            <p class="text-base leading-relaxed mb-6" style="color: #555;">
              Traditional frameworks scatter a single feature across routes, controllers, views, and helpers. Nex keeps everything in one place — the page file is the route, the handler, and the template.
            </p>
            <ul class="space-y-3">
              <li class="flex items-start gap-3">
                <svg class="w-5 h-5 mt-0.5 flex-shrink-0" style="color: #9B7EBD;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
                <span class="text-sm" style="color: #555;">AI agents understand a feature by reading one file</span>
              </li>
              <li class="flex items-start gap-3">
                <svg class="w-5 h-5 mt-0.5 flex-shrink-0" style="color: #9B7EBD;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
                <span class="text-sm" style="color: #555;">No context switching between files during development</span>
              </li>
              <li class="flex items-start gap-3">
                <svg class="w-5 h-5 mt-0.5 flex-shrink-0" style="color: #9B7EBD;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
                <span class="text-sm" style="color: #555;">Refactoring is safe — move the file, move the route</span>
              </li>
              <li class="flex items-start gap-3">
                <svg class="w-5 h-5 mt-0.5 flex-shrink-0" style="color: #9B7EBD;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
                <span class="text-sm" style="color: #555;">New team members onboard in hours, not days</span>
              </li>
            </ul>
          </div>
          <div class="rounded-2xl overflow-hidden" style="box-shadow: 0 8px 40px rgba(0,0,0,0.12); border: 1px solid #2A2A2A;">
            {raw(@example_code)}
          </div>
        </div>
      </div>
    </section>
    """
  end
end
