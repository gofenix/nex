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
    <div class="flex min-h-screen bg-white">
      <!-- Sidebar -->
      <aside class="w-64 border-r border-gray-200 bg-gray-50 hidden md:block fixed h-full overflow-y-auto">
        <div class="p-6">
          <h2 class="text-xl font-bold text-gray-800 mb-6 flex items-center gap-2">
            <a href="/" class="hover:text-claude-purple">Nex</a>
            <span class="text-gray-400 text-sm font-normal">Docs</span>
          </h2>

          <nav class="space-y-8">
            <div :for={group <- @sidebar}>
              <h3 class="font-bold text-gray-900 mb-3 text-sm uppercase tracking-wider">{group.title}</h3>
              <ul class="space-y-2">
                <li :for={item <- group.items}>
                  <a href={doc_link(item.slug)}
                     class={"block text-sm px-3 py-2 rounded-md transition-colors #{if @current_slug == item.slug, do: "bg-purple-100 text-claude-purple font-medium", else: "text-gray-600 hover:text-gray-900 hover:bg-gray-100"}"}>
                    {item.title}
                  </a>
                </li>
              </ul>
            </div>
          </nav>
        </div>
      </aside>

      <!-- Main Content -->
      <main class="flex-1 md:ml-64 w-full">
        <div class="max-w-4xl mx-auto px-4 py-12 md:px-12">
          <!-- Mobile Menu Toggle (Simplified) -->
          <div class="md:hidden mb-8">
            <a href="/docs" class="text-sm font-medium text-claude-purple">← Back to Menu</a>
          </div>

          <!-- Doc Content -->
          <article class="prose prose-lg prose-purple max-w-none">
            {raw(@doc_content)}
          </article>

          <!-- Footer Navigation -->
          <div class="mt-16 pt-8 border-t border-gray-200 flex justify-between">
            <!-- Ideally calculate prev/next links here -->
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
