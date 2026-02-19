defmodule NexWebsite.Pages.Docs.Path do
  use Nex

  def mount(params) do
    path_segments = params["path"] || []
    slug = Enum.join(path_segments, "/")

    # Handle root /docs -> redirect to introduction
    slug = if slug == "", do: "intro", else: slug

    case load_doc(slug) do
      {:ok, content, title} ->
        %{
          title: "#{title} - Nex Documentation",
          doc_content: content,
          current_slug: slug,
          sidebar: get_sidebar()
        }

      {:error, _} ->
        %{
          title: "Document Not Found",
          doc_content: "<h1>Document not found</h1><p>The requested documentation could not be found.</p>",
          current_slug: slug,
          sidebar: get_sidebar()
        }
    end
  end

  def render(assigns) do
    ~H"""
    <div class="docs-layout flex min-h-screen" style="background: #FAFAF8;">
      <!-- Sidebar -->
      <aside class="docs-sidebar w-72 hidden md:flex flex-col fixed top-0 left-0 h-full z-40" style="background: #FFFFFF; border-right: 1px solid #EBEBEB;">
        <!-- Sidebar Header -->
        <div class="flex items-center gap-3 px-6 py-5" style="border-bottom: 1px solid #EBEBEB;">
          <a href="/" class="flex items-center gap-2 group">
            <div class="w-7 h-7 rounded-lg flex items-center justify-center" style="background: linear-gradient(135deg, #9B7EBD, #7B5FA8);">
              <span class="text-white font-bold text-xs">N</span>
            </div>
            <span class="font-semibold text-gray-900 group-hover:text-claude-purple transition-colors">Nex</span>
          </a>
          <span class="text-gray-300 text-sm">/</span>
          <span class="text-sm text-gray-500 font-medium">Docs</span>
        </div>

        <!-- Search hint -->
        <div class="px-4 py-3" style="border-bottom: 1px solid #F5F5F0;">
          <div class="flex items-center gap-2 px-3 py-2 rounded-lg text-sm text-gray-400 cursor-default" style="background: #F8F8F6; border: 1px solid #EBEBEB;">
            <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
            <span class="text-xs">Browse docs...</span>
          </div>
        </div>

        <!-- Nav -->
        <nav class="flex-1 overflow-y-auto px-3 py-4 space-y-6">
          <div :for={group <- @sidebar}>
            <div class="px-3 mb-2">
              <span class="text-xs font-semibold uppercase tracking-widest" style="color: #9B9B9B; letter-spacing: 0.08em;">{group.title}</span>
            </div>
            <ul class="space-y-0.5">
              <li :for={item <- group.items}>
                <a href={doc_link(item.slug)}
                   class={"docs-nav-item flex items-center gap-2.5 text-sm px-3 py-2 rounded-lg transition-all duration-150 #{if @current_slug == item.slug, do: "docs-nav-active", else: "docs-nav-default"}"}>
                  <span :if={@current_slug == item.slug} class="w-1.5 h-1.5 rounded-full flex-shrink-0" style="background: #9B7EBD;"></span>
                  <span :if={@current_slug != item.slug} class="w-1.5 h-1.5 rounded-full flex-shrink-0 opacity-0"></span>
                  {item.title}
                </a>
              </li>
            </ul>
          </div>
        </nav>

        <!-- Sidebar Footer -->
        <div class="px-4 py-4" style="border-top: 1px solid #EBEBEB;">
          <a href="https://github.com/gofenix/nex" target="_blank" class="flex items-center gap-2 text-xs text-gray-400 hover:text-gray-600 transition-colors">
            <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24"><path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/></svg>
            View on GitHub
          </a>
        </div>
      </aside>

      <!-- Main Content -->
      <main class="flex-1 md:ml-72 min-w-0">
        <!-- Top bar -->
        <div class="sticky top-0 z-30 hidden md:flex items-center justify-between px-8 py-3" style="background: rgba(250,250,248,0.95); backdrop-filter: blur(8px); border-bottom: 1px solid #EBEBEB;">
          <div class="flex items-center gap-2 text-sm text-gray-400">
            <a href="/" class="hover:text-gray-600 transition-colors">Home</a>
            <span>›</span>
            <a href="/docs" class="hover:text-gray-600 transition-colors">Docs</a>
            <span>›</span>
            <span class="text-gray-700 font-medium">{@title |> String.replace(" - Nex Documentation", "")}</span>
          </div>
          <a href="https://hex.pm/packages/nex_core" target="_blank" class="text-xs px-3 py-1.5 rounded-full font-medium transition-all" style="background: #F0EBF8; color: #7B5FA8; border: 1px solid #D4C5E8;">
            hex.pm →
          </a>
        </div>

        <!-- Mobile back -->
        <div class="md:hidden px-4 py-3" style="border-bottom: 1px solid #EBEBEB; background: white;">
          <a href="/docs" class="flex items-center gap-1.5 text-sm font-medium text-claude-purple">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/></svg>
            Back to Docs
          </a>
        </div>

        <!-- Doc Content -->
        <div class="max-w-3xl mx-auto px-6 py-10 md:px-12 md:py-14">
          <article class="docs-prose">
            {raw(@doc_content)}
          </article>

          <!-- Footer nav -->
          <div class="mt-16 pt-8 flex items-center justify-between" style="border-top: 1px solid #EBEBEB;">
            <a href="https://github.com/gofenix/nex/issues" target="_blank" class="flex items-center gap-2 text-sm text-gray-400 hover:text-gray-600 transition-colors">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/></svg>
              Edit this page
            </a>
            <a href="/docs/getting_started" class="flex items-center gap-2 text-sm font-medium text-claude-purple hover:text-claude-accent transition-colors">
              Quick Start
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
            </a>
          </div>
        </div>
      </main>
    </div>
    """
  end

  # Helpers

  defp load_doc(slug) do
    filename = slug <> ".md"
    path = Path.join([:code.priv_dir(:nex_website), "docs", filename])

    if File.exists?(path) do
      markdown = File.read!(path)
      html = Earmark.as_html!(markdown, code_class_prefix: "language-")
      title = extract_title(markdown) || slug
      {:ok, html, title}
    else
      {:error, :not_found}
    end
  end

  defp extract_title(markdown) do
    case Regex.run(~r/^#\s+(.+)$/m, markdown) do
      [_, title] -> String.trim(title)
      _ -> nil
    end
  end

  defp doc_link(slug), do: "/docs/#{slug}"

  defp get_sidebar do
    [
      %{
        title: "Getting Started",
        items: [
          %{title: "Introduction", slug: "intro"},
          %{title: "Quick Start", slug: "getting_started"},
          %{title: "Learning Path", slug: "learning_path"},
          %{title: "Vibe Coding", slug: "vibe_coding_guide"}
        ]
      },
      %{
        title: "Tutorials",
        items: [
          %{title: "01. First Page", slug: "tutorial_01_first_page"},
          %{title: "02. Actions", slug: "tutorial_02_actions"},
          %{title: "03. Forms", slug: "tutorial_03_forms"},
          %{title: "04. State", slug: "tutorial_04_state"},
          %{title: "05. Routing", slug: "tutorial_05_routing"},
          %{title: "06. Deployment", slug: "tutorial_06_deployment"}
        ]
      },
      %{
        title: "Core Concepts",
        items: [
          %{title: "Rendering Lifecycle", slug: "core_render_guide"},
          %{title: "Action Routing", slug: "core_action_guide"},
          %{title: "State Management", slug: "core_state_guide"},
          %{title: "Environment Config", slug: "core_env_guide"},
          %{title: "Declarative Interaction", slug: "core_htmx_guide"}
        ]
      },
      %{
        title: "Interactivity",
        items: [
          %{title: "Alpine.js Integration", slug: "ext_alpine_guide"},
          %{title: "Datastar Integration", slug: "ext_datastar_guide"},
          %{title: "SSE Real-Time Push", slug: "ext_sse_guide"}
        ]
      },
      %{
        title: "Advanced",
        items: [
          %{title: "Database (NexBase)", slug: "database_guide"},
          %{title: "JSON API", slug: "adv_api_guide"},
          %{title: "Components", slug: "adv_component_guide"}
        ]
      },
      %{
        title: "Architecture",
        items: [
          %{title: "Architecture Overview", slug: "arch_overview"}
        ]
      },
      %{
        title: "Reference",
        items: [
          %{title: "FAQ", slug: "reference_faq"}
        ]
      }
    ]
  end
end
