defmodule AiSaga.Pages.Paper.Slug do
  use Nex

  def mount(%{"slug" => slug}) do
    {:ok, [paper]} = NexBase.from("papers")
    |> NexBase.eq(:slug, slug)
    |> NexBase.single()
    |> NexBase.run()

    {:ok, [paradigm]} = NexBase.from("paradigms")
    |> NexBase.eq(:id, paper["paradigm_id"])
    |> NexBase.single()
    |> NexBase.run()

    {:ok, author_links} = NexBase.from("paper_authors")
    |> NexBase.eq(:paper_id, paper["id"])
    |> NexBase.order(:author_order, :asc)
    |> NexBase.run()

    authors = Enum.map(author_links, fn link ->
      {:ok, [a]} = NexBase.from("authors")
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
    <div class="max-w-4xl mx-auto space-y-8">
      <a href="/" class="inline-flex items-center gap-2 text-sm font-mono opacity-60 hover:opacity-100">
        ← 返回首页
      </a>

      <article class="space-y-6">
        <%!-- 基本信息头部 --%>
        <header class="space-y-4 border-b-2 border-black pb-6">
          <div class="flex flex-wrap items-center gap-3">
            <a href={"/paradigm/#{@paradigm["slug"]}"} class="px-3 py-1 bg-[rgb(111,194,255)] border border-black text-sm font-mono hover:bg-blue-200">
              {@paradigm["name"]}
            </a>
            <%= if @paper["is_paradigm_shift"] == 1 do %>
              <span class="px-3 py-1 bg-[rgb(255,222,0)] border border-black text-sm font-mono font-bold">
                ⚡ 范式变迁
              </span>
            <% end %>
            <span class="text-sm font-mono opacity-60">{@paper["published_year"]}年</span>
          </div>

          <h1 class="text-4xl font-black leading-tight">{@paper["title"]}</h1>

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

        <%!-- 三个视角的内容 --%>
        <div class="space-y-8">

          <%!-- 一、历史视角：承前启后 --%>
          <%= if @paper["prev_paradigm"] do %>
            <section class="space-y-4">
              <h2 class="text-2xl font-black border-b-2 border-black pb-2">📜 一、历史视角：承前启后</h2>

              <div class="bg-white p-6 border-2 border-black md-shadow-sm prose max-w-none">
                <h3 class="text-lg font-bold mb-3">上一个范式</h3>
                <div class="markdown-content">
                  {Phoenix.HTML.raw(markdown_to_html(@paper["prev_paradigm"]))}
                </div>
              </div>
            </section>
          <% end %>

          <%= if @paper["core_contribution"] do %>
            <section class="bg-[rgb(255,222,0)] p-6 border-2 border-black md-shadow-sm">
              <h3 class="text-lg font-bold mb-3">💡 核心贡献</h3>
              <div class="markdown-content prose max-w-none">
                {Phoenix.HTML.raw(markdown_to_html(@paper["core_contribution"]))}
              </div>
            </section>
          <% end %>

          <%= if @paper["core_mechanism"] do %>
            <section class="bg-white p-6 border-2 border-black md-shadow-sm">
              <h3 class="text-lg font-bold mb-3">⚙️ 核心机制</h3>
              <div class="markdown-content prose max-w-none">
                {Phoenix.HTML.raw(markdown_to_html(@paper["core_mechanism"]))}
              </div>
            </section>
          <% end %>

          <%= if @paper["why_it_wins"] do %>
            <section class="bg-[rgb(111,194,255)] p-6 border-2 border-black md-shadow-sm">
              <h3 class="text-lg font-bold mb-3">🏆 为什么赢了</h3>
              <div class="markdown-content prose max-w-none">
                {Phoenix.HTML.raw(markdown_to_html(@paper["why_it_wins"]))}
              </div>
            </section>
          <% end %>

          <%!-- 二、范式变迁视角 --%>
          <section class="space-y-4">
            <h2 class="text-2xl font-black border-b-2 border-black pb-2">🔄 二、范式变迁视角</h2>

            <div class="grid gap-4">
              <div class="bg-white p-6 border-2 border-black">
                <h3 class="text-lg font-bold mb-3 text-red-600">⚠️ 当时面临的挑战</h3>
                <p class="opacity-80">{@paper["challenge"]}</p>
              </div>

              <div class="bg-[rgb(255,222,0)] p-6 border-2 border-black">
                <h3 class="text-lg font-bold mb-3">💡 解决方案</h3>
                <p class="opacity-90">{@paper["solution"]}</p>
              </div>

              <div class="bg-[rgb(111,194,255)] p-6 border-2 border-black">
                <h3 class="text-lg font-bold mb-3">🌊 深远影响</h3>
                <p class="opacity-90">{@paper["impact"]}</p>
              </div>
            </div>
          </section>

          <%!-- 三、人的视角 --%>
          <%= if @paper["author_destinies"] do %>
            <section class="space-y-4">
              <h2 class="text-2xl font-black border-b-2 border-black pb-2">👤 三、人的视角：作者去向</h2>

              <div class="bg-white p-6 border-2 border-black md-shadow-sm prose max-w-none">
                <div class="markdown-content">
                  {Phoenix.HTML.raw(markdown_to_html(@paper["author_destinies"]))}
                </div>
              </div>
            </section>
          <% end %>

          <%!-- 后续影响 --%>
          <%= if @paper["subsequent_impact"] do %>
            <section class="space-y-4">
              <h2 class="text-2xl font-black border-b-2 border-black pb-2">📈 后续影响</h2>

              <div class="bg-gray-50 p-6 border-2 border-black md-shadow-sm prose max-w-none">
                <div class="markdown-content">
                  {Phoenix.HTML.raw(markdown_to_html(@paper["subsequent_impact"]))}
                </div>
              </div>
            </section>
          <% end %>

          <%!-- 原始历史背景（如果没有新格式） --%>
          <%= if !@paper["prev_paradigm"] && @paper["history_context"] do %>
            <section class="bg-gray-50 p-6 border-2 border-black">
              <h2 class="text-lg font-bold mb-3">📜 历史背景</h2>
              <p class="opacity-80">{@paper["history_context"]}</p>
            </section>
          <% end %>

        </div>
      </article>
    </div>
    """
  end
end
