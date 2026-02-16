defmodule AiSaga.Pages.Paper.Slug do
  use Nex

  def mount(%{"slug" => slug}) do
    {:ok, [paper]} =
      NexBase.from("papers")
      |> NexBase.eq(:slug, slug)
      |> NexBase.single()
      |> NexBase.run()

    {:ok, [paradigm]} =
      NexBase.from("paradigms")
      |> NexBase.eq(:id, paper["paradigm_id"])
      |> NexBase.single()
      |> NexBase.run()

    {:ok, author_links} =
      NexBase.from("paper_authors")
      |> NexBase.eq(:paper_id, paper["id"])
      |> NexBase.order(:author_order, :asc)
      |> NexBase.run()

    authors =
      Enum.map(author_links, fn link ->
        {:ok, [a]} =
          NexBase.from("authors")
          |> NexBase.eq(:id, link["author_id"])
          |> NexBase.single()
          |> NexBase.run()

        a
      end)

    %{
      title: paper["title"],
      paper: paper,
      paradigm: paradigm,
      authors: authors
    }
  end

  # 将Markdown转换为HTML
  defp markdown_to_html(nil), do: ""

  defp markdown_to_html(text) do
    case Earmark.as_html(text, gfm: true, breaks: true) do
      {:ok, html, _} -> html
      _ -> text
    end
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto">
      <a href="/paper" class="back-link mb-6 inline-block">
        ← 返回论文列表
      </a>

      <article class="space-y-6">
        <%!-- 基本信息头部 --%>
        <header class="space-y-4 border-b-2 border-black pb-6">
          <div class="flex flex-wrap items-center gap-3">
            <a href={"/paradigm/#{@paradigm["slug"]}"} class="badge badge-blue">
              {@paradigm["name"]}
            </a>
            <%= if @paper["is_paradigm_shift"] == 1 do %>
              <span class="badge badge-yellow">
                ⚡ 范式变迁
              </span>
            <% end %>
            <span class="year-tag">{@paper["published_year"]}年</span>
          </div>

          <h1 class="text-3xl md:text-4xl font-black leading-tight">{@paper["title"]}</h1>

          <div class="flex flex-wrap gap-2">
            <%= for author <- @authors do %>
              <a href={"/author/#{author["slug"]}"} class="text-sm border-b border-black hover:bg-gray-100">{author["name"]}</a>
            <% end %>
          </div>

          <div class="flex items-center gap-4 text-sm font-mono opacity-60">
            <%= if @paper["arxiv_id"] do %>
              <span>arXiv:{@paper["arxiv_id"]}</span>
              <span>•</span>
            <% end %>
            <span>{@paper["citations"]} citations</span>
            <span>•</span>
            <a href={@paper["url"]} target="_blank" class="hover:underline">查看原文 →</a>
          </div>
        </header>

        <%!-- 摘要 --%>
        <div class="prose max-w-none bg-gray-50 p-6 border-2 border-black">
          <p class="text-lg leading-relaxed">{@paper["abstract"]}</p>
        </div>

        <%!-- 锚点导航 --%>
        <nav class="sticky top-0 z-10 card p-3 flex flex-wrap gap-2">
          <%= if @paper["prev_paradigm"] do %>
            <a href="#history" class="badge badge-yellow hover:bg-yellow-300 transition-colors">📜 历史视角</a>
          <% end %>
          <a href="#paradigm-shift" class="badge badge-blue hover:bg-blue-300 transition-colors">🔄 范式变迁</a>
          <%= if @paper["author_destinies"] do %>
            <a href="#people" class="badge" style="background: rgba(255,160,160,0.2); border-color: var(--md-black);">👤 人物视角</a>
          <% end %>
          <%= if @paper["subsequent_impact"] do %>
            <a href="#impact" class="badge badge-gray hover:bg-gray-200 transition-colors">📈 后续影响</a>
          <% end %>
        </nav>

        <%!-- 三个视角的内容 --%>
        <div class="space-y-6">

          <%!-- 一、历史视角：承前启后 --%>
          <%= if @paper["prev_paradigm"] do %>
            <section id="history" class="space-y-4 scroll-mt-20">
              <h2 class="text-2xl font-black border-b-2 border-black pb-2">📜 历史视角：承前启后</h2>

              <%!-- 上一个范式 --%>
              <details class="bg-white border-2 border-black group" open>
                <summary class="p-4 cursor-pointer font-bold flex items-center justify-between hover:bg-gray-50">
                  <span>📖 上一个范式</span>
                  <span class="text-xs opacity-60 group-open:rotate-180 transition-transform">▼</span>
                </summary>
                <div class="p-4 pt-0 prose max-w-none markdown-content border-t border-gray-200">
                  {Phoenix.HTML.raw(markdown_to_html(@paper["prev_paradigm"]))}
                </div>
              </details>
            </section>
          <% end %>

          <%!-- 核心贡献 --%>
          <%= if @paper["core_contribution"] do %>
            <details class="bg-[rgb(255,222,0)] border-2 border-black group" open>
              <summary class="p-4 cursor-pointer font-bold flex items-center justify-between hover:bg-yellow-300">
                <span>💡 核心贡献</span>
                <span class="text-xs opacity-60 group-open:rotate-180 transition-transform">▼</span>
              </summary>
              <div class="p-4 pt-0 prose max-w-none markdown-content bg-white border-t-2 border-black">
                {Phoenix.HTML.raw(markdown_to_html(@paper["core_contribution"]))}
              </div>
            </details>
          <% end %>

          <%!-- 核心机制 --%>
          <%= if @paper["core_mechanism"] do %>
            <details class="bg-white border-2 border-black group" open>
              <summary class="p-4 cursor-pointer font-bold flex items-center justify-between hover:bg-gray-50">
                <span>⚙️ 核心机制</span>
                <span class="text-xs opacity-60 group-open:rotate-180 transition-transform">▼</span>
              </summary>
              <div class="p-4 pt-0 prose max-w-none markdown-content border-t border-gray-200">
                {Phoenix.HTML.raw(markdown_to_html(@paper["core_mechanism"]))}
              </div>
            </details>
          <% end %>

          <%!-- 为什么赢了 --%>
          <%= if @paper["why_it_wins"] do %>
            <details class="bg-[rgb(111,194,255)] border-2 border-black group" open>
              <summary class="p-4 cursor-pointer font-bold flex items-center justify-between hover:bg-blue-300">
                <span>🏆 为什么赢了</span>
                <span class="text-xs opacity-60 group-open:rotate-180 transition-transform">▼</span>
              </summary>
              <div class="p-4 pt-0 prose max-w-none markdown-content bg-white border-t-2 border-black">
                {Phoenix.HTML.raw(markdown_to_html(@paper["why_it_wins"]))}
              </div>
            </details>
          <% end %>

          <%!-- 二、范式变迁视角 --%>
          <section id="paradigm-shift" class="space-y-4 scroll-mt-20">
            <h2 class="text-2xl font-black border-b-2 border-black pb-2">🔄 范式变迁视角</h2>

            <%!-- 挑战 --%>
            <details class="bg-white border-2 border-red-200 group" open>
              <summary class="p-4 cursor-pointer font-bold flex items-center justify-between hover:bg-red-50 text-red-700">
                <span>⚠️ 当时面临的挑战</span>
                <span class="text-xs opacity-60 group-open:rotate-180 transition-transform">▼</span>
              </summary>
              <div class="p-4 pt-0 prose max-w-none markdown-content border-t border-red-100">
                {Phoenix.HTML.raw(markdown_to_html(@paper["challenge"]))}
              </div>
            </details>

            <%!-- 解决方案 --%>
            <details class="bg-[rgb(255,222,0)] border-2 border-black group" open>
              <summary class="p-4 cursor-pointer font-bold flex items-center justify-between hover:bg-yellow-300">
                <span>💡 解决方案</span>
                <span class="text-xs opacity-60 group-open:rotate-180 transition-transform">▼</span>
              </summary>
              <div class="p-4 pt-0 prose max-w-none markdown-content bg-white border-t-2 border-black">
                {Phoenix.HTML.raw(markdown_to_html(@paper["solution"]))}
              </div>
            </details>

            <%!-- 深远影响 --%>
            <details class="bg-[rgb(111,194,255)] border-2 border-black group" open>
              <summary class="p-4 cursor-pointer font-bold flex items-center justify-between hover:bg-blue-300">
                <span>🌊 深远影响</span>
                <span class="text-xs opacity-60 group-open:rotate-180 transition-transform">▼</span>
              </summary>
              <div class="p-4 pt-0 prose max-w-none markdown-content bg-white border-t-2 border-black">
                {Phoenix.HTML.raw(markdown_to_html(@paper["impact"]))}
              </div>
            </details>
          </section>

          <%!-- 三、人的视角 --%>
          <%= if @paper["author_destinies"] do %>
            <section id="people" class="space-y-4 scroll-mt-20">
              <h2 class="text-2xl font-black border-b-2 border-black pb-2">👤 人的视角：作者去向</h2>

              <details class="bg-white border-2 border-black group" open>
                <summary class="p-4 cursor-pointer font-bold flex items-center justify-between hover:bg-gray-50">
                  <span>👥 作者后续发展</span>
                  <span class="text-xs opacity-60 group-open:rotate-180 transition-transform">▼</span>
                </summary>
                <div class="p-4 pt-0 prose max-w-none markdown-content border-t border-gray-200">
                  {Phoenix.HTML.raw(markdown_to_html(@paper["author_destinies"]))}
                </div>
              </details>
            </section>
          <% end %>

          <%!-- 后续影响 --%>
          <%= if @paper["subsequent_impact"] do %>
            <section id="impact" class="space-y-4 scroll-mt-20">
              <h2 class="text-2xl font-black border-b-2 border-black pb-2">📈 后续影响</h2>

              <details class="bg-gray-50 border-2 border-black group" open>
                <summary class="p-4 cursor-pointer font-bold flex items-center justify-between hover:bg-gray-100">
                  <span>📊 对后续研究的影响</span>
                  <span class="text-xs opacity-60 group-open:rotate-180 transition-transform">▼</span>
                </summary>
                <div class="p-4 pt-0 prose max-w-none markdown-content border-t border-gray-200">
                  {Phoenix.HTML.raw(markdown_to_html(@paper["subsequent_impact"]))}
                </div>
              </details>
            </section>
          <% end %>

          <%!-- 原始历史背景（如果没有新格式） --%>
          <%= if !@paper["prev_paradigm"] && @paper["history_context"] do %>
            <details class="bg-gray-50 border-2 border-black group" open>
              <summary class="p-4 cursor-pointer font-bold flex items-center justify-between hover:bg-gray-100">
                <span>📜 历史背景</span>
                <span class="text-xs opacity-60 group-open:rotate-180 transition-transform">▼</span>
              </summary>
              <div class="p-4 pt-0 prose max-w-none markdown-content border-t border-gray-200">
                {Phoenix.HTML.raw(markdown_to_html(@paper["history_context"]))}
              </div>
            </details>
          <% end %>

        </div>
      </article>
    </div>
    """
  end
end
