defmodule NexWebsite.Pages.Docs.Path do
  use Nex

  def mount(params) do
    # params["path"] is a list, e.g. ["zh", "guide"] or ["guide"]
    path_segments = params["path"] || []

    # Determine language and doc slug
    {lang, slug} = case path_segments do
      ["zh" | rest] -> {:zh, Enum.join(rest, "/")}
      _ -> {:en, Enum.join(path_segments, "/")}
    end

    # Handle root /docs -> redirect to introduction or first doc
    if slug == "" do
      load_doc(lang, "getting_started")
      |> case do
        {:ok, content, title} ->
          %{
            title: "#{title} - Nex Documentation",
            doc_content: content,
            current_slug: "getting_started",
            current_lang: lang,
            sidebar: get_sidebar(lang)
          }

        {:error, _} ->
          %{
            title: "Document Not Found",
            doc_content: "<h1>Document not found</h1><p>The requested documentation could not be found.</p>",
            current_slug: slug,
            current_lang: lang,
            sidebar: get_sidebar(lang)
          }
      end
    else
      case load_doc(lang, slug) do
        {:ok, content, title} ->
          %{
            title: "#{title} - Nex Documentation",
            doc_content: content,
            current_slug: slug,
            current_lang: lang,
            sidebar: get_sidebar(lang)
          }

        {:error, _} ->
          # Fallback or 404 handled by returning a 404 state
          # For simplicity here, we might just render a not found message
          %{
            title: "Document Not Found",
            doc_content: "<h1>Document not found</h1><p>The requested documentation could not be found.</p>",
            current_slug: slug,
            current_lang: lang,
            sidebar: get_sidebar(lang)
          }
      end
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
                  <a href={doc_link(@current_lang, item.slug)}
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

          <!-- Language Switcher -->
          <div class="flex justify-end mb-8 gap-2 text-sm">
            <a href={"/docs/#{@current_slug}"} class={"px-3 py-1 rounded-full #{if @current_lang == :en, do: "bg-gray-800 text-white", else: "bg-gray-100 text-gray-600 hover:bg-gray-200"}"}>English</a>
            <a href={"/docs/zh/#{@current_slug}"} class={"px-3 py-1 rounded-full #{if @current_lang == :zh, do: "bg-gray-800 text-white", else: "bg-gray-100 text-gray-600 hover:bg-gray-200"}"}>中文</a>
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

  defp load_doc(lang, slug) do
    # Map slug to filename if needed, or assume slug matches filename
    filename = slug <> ".md"

    # Construct path: priv/docs/zh/filename or priv/docs/filename
    base_path = Path.join(:code.priv_dir(:nex_website), "docs")
    path = if lang == :zh do
      Path.join([base_path, "zh", filename])
    else
      Path.join([base_path, filename])
    end

    if File.exists?(path) do
      markdown = File.read!(path)
      # Parse markdown with proper code block handling
      html = Earmark.as_html!(markdown, code_class_prefix: "language-")
      # Extract H1 title if possible, or use slug
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

  defp doc_link(:en, slug), do: "/docs/#{slug}"
  defp doc_link(:zh, slug), do: "/docs/zh/#{slug}"

  defp get_sidebar(lang) do
    # Define structure manually for now to ensure order
    # Translating titles based on lang
    [
      %{
        title: t(lang, "Getting Started"),
        items: [
          %{title: t(lang, "Introduction"), slug: "intro"},
          %{title: t(lang, "Quick Start"), slug: "getting_started"},
          %{title: t(lang, "Learning Path"), slug: "learning_path"}
        ]
      },
      %{
        title: t(lang, "Tutorials"),
        items: [
          %{title: t(lang, "01. First Page"), slug: "tutorial_01_first_page"},
          %{title: t(lang, "02. Actions"), slug: "tutorial_02_actions"},
          %{title: t(lang, "03. Forms"), slug: "tutorial_03_forms"},
          %{title: t(lang, "04. State"), slug: "tutorial_04_state"},
          %{title: t(lang, "05. Routing"), slug: "tutorial_05_routing"},
          %{title: t(lang, "06. Deployment"), slug: "tutorial_06_deployment"}
        ]
      },
      %{
        title: t(lang, "Core Concepts"),
        items: [
          %{title: t(lang, "Rendering Lifecycle"), slug: "core_render_guide"},
          %{title: t(lang, "Action Routing"), slug: "core_action_guide"},
          %{title: t(lang, "State Management"), slug: "core_state_guide"},
          %{title: t(lang, "Env Configuration"), slug: "core_env_guide"},
          %{title: t(lang, "Interaction Protocol"), slug: "core_htmx_guide"}
        ]
      },
      %{
        title: t(lang, "Interactivity"),
        items: [
          %{title: t(lang, "Alpine.js"), slug: "ext_alpine_guide"},
          %{title: t(lang, "Datastar"), slug: "ext_datastar_guide"},
          %{title: t(lang, "SSE Real-time"), slug: "ext_sse_guide"}
        ]
      },
      %{
        title: t(lang, "Advanced"),
        items: [
          %{title: t(lang, "JSON API"), slug: "adv_api_guide"},
          %{title: t(lang, "Components"), slug: "adv_component_guide"}
        ]
      },
      %{
        title: t(lang, "Architecture & AI"),
        items: [
          %{title: t(lang, "Architecture"), slug: "arch_overview"},
          %{title: t(lang, "Vibe Coding"), slug: "vibe_coding_guide"}
        ]
      },
      %{
        title: t(lang, "Reference"),
        items: [
          %{title: t(lang, "FAQ"), slug: "reference_faq"}
        ]
      }
    ]
  end

  defp t(:zh, "Getting Started"), do: "入门指南"
  defp t(:zh, "Tutorials"), do: "分步教程"
  defp t(:zh, "Core Concepts"), do: "核心概念"
  defp t(:zh, "Interactivity"), do: "扩展增强"
  defp t(:zh, "Advanced"), do: "进阶指南"
  defp t(:zh, "Architecture & AI"), do: "架构与 AI"
  defp t(:zh, "Reference"), do: "参考资料"

  defp t(:zh, "Introduction"), do: "什么是 Nex？"
  defp t(:zh, "Quick Start"), do: "快速开始"
  defp t(:zh, "Learning Path"), do: "学习路径"

  defp t(:zh, "01. First Page"), do: "01. 第一个页面"
  defp t(:zh, "02. Actions"), do: "02. 添加交互"
  defp t(:zh, "03. Forms"), do: "03. 表单处理"
  defp t(:zh, "04. State"), do: "04. 状态管理"
  defp t(:zh, "05. Routing"), do: "05. 路由系统"
  defp t(:zh, "06. Deployment"), do: "06. 部署上线"

  defp t(:zh, "Rendering Lifecycle"), do: "渲染生命周期"
  defp t(:zh, "Action Routing"), do: "Action 路由机制"
  defp t(:zh, "State Management"), do: "状态管理深入"
  defp t(:zh, "Env Configuration"), do: "环境配置"
  defp t(:zh, "Interaction Protocol"), do: "声明式交互协议"

  defp t(:zh, "Alpine.js"), do: "Alpine.js 集成"
  defp t(:zh, "Datastar"), do: "Datastar 集成"
  defp t(:zh, "SSE Real-time"), do: "SSE 实时推送"

  defp t(:zh, "JSON API"), do: "构建 JSON API"
  defp t(:zh, "Components"), do: "组件化开发"

  defp t(:zh, "Architecture"), do: "架构概览"
  defp t(:zh, "Vibe Coding"), do: "Vibe Coding 指南"
  defp t(:zh, "FAQ"), do: "常见问题 (FAQ)"

  defp t(_, key), do: key
end
