defmodule NexWebsite.Components.HomeExamples do
  use Nex
  alias NexWebsite.ExamplesCatalog

  def render(assigns) do
    ~H"""
    <section class="py-24 px-6 md:px-10" style="background: white; border-top: 1px solid #EBEBEB;">
      <div class="max-w-5xl mx-auto">
        <div class="text-center mb-14">
          <p class="text-xs font-semibold uppercase tracking-widest mb-3" style="color: #9B7EBD; letter-spacing: 0.12em;">Examples</p>
          <h2 class="text-4xl font-bold mb-3" style="color: #111; letter-spacing: -0.03em;">See it in action</h2>
          <p class="text-lg" style="color: #666;">Featured examples from the Nex gallery, all owned and tested in place.</p>
        </div>

        <div class="grid md:grid-cols-3 gap-5">
          <a
            :for={example <- featured_examples()}
            href={ExamplesCatalog.github_url(example.slug)}
            target="_blank"
            class="group p-6 rounded-2xl transition-all hover:-translate-y-0.5"
            style="background: #FAFAF8; border: 1px solid #EBEBEB; text-decoration: none;"
          >
            <div class="text-2xl mb-3">{icon_for(example.slug)}</div>
            <h3 class="font-bold mb-1.5 group-hover:text-claude-purple transition-colors" style="color: #111;">{example.title}</h3>
            <p class="text-sm mb-4" style="color: #666;">{example.summary}</p>
            <div class="flex gap-2 flex-wrap">
              <span class="text-xs px-2 py-0.5 rounded-full" style="background: #F0EBF8; color: #7B5FA8;">{kind_label(example.kind)}</span>
              <span class="text-xs px-2 py-0.5 rounded-full" style="background: #F5F5F0; color: #666;">Tested</span>
            </div>
          </a>
        </div>

        <div class="mt-8 text-center">
          <a href="https://github.com/gofenix/nex/tree/main/examples" target="_blank" class="inline-flex items-center justify-center gap-2 text-sm font-semibold px-5 py-2.5 rounded-full transition-all hover:-translate-y-0.5" style="color: #7B5FA8; background: #F0EBF8; border: 1px dashed #D4C5E8; text-decoration: none;">
            Browse the full examples gallery
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 4v16m8-8H4"/></svg>
          </a>
        </div>
      </div>
    </section>
    """
  end

  defp featured_examples do
    ExamplesCatalog.featured(6)
  end

  defp kind_label(:app), do: "App"
  defp kind_label(:pattern), do: "Pattern"

  defp icon_for("agent_console"), do: "🤖"
  defp icon_for("ai_saga"), do: "🧠"
  defp icon_for("alpine_demo"), do: "🏔️"
  defp icon_for("auth_demo"), do: "🔐"
  defp icon_for("bestof_ex"), do: "⭐"
  defp icon_for("counter"), do: "🔢"
  defp icon_for("todos"), do: "✅"
  defp icon_for("websocket"), do: "🔌"
  defp icon_for(_slug), do: "🧩"
end
