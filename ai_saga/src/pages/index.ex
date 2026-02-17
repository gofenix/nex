defmodule AiSaga.Pages.Index do
  use Nex

  def mount(_params) do
    {:ok, paradigms} =
      NexBase.from("paradigms")
      |> NexBase.order(:start_year, :asc)
      |> NexBase.run()

    # 如果没有设置今日推荐，随机获取一篇高影响力论文
    {:ok, daily_candidates} =
      NexBase.from("papers")
      |> NexBase.eq(:is_daily_pick, 1)
      |> NexBase.single()
      |> NexBase.run()

    daily = List.first(daily_candidates || [])

    daily_pick =
      if daily do
        daily
      else
        # 随机获取一篇高影响力论文作为今日推荐
        {:ok, candidates} =
          NexBase.from("papers")
          |> NexBase.order(:citations, :desc)
          |> NexBase.limit(10)
          |> NexBase.run()

        candidates |> Enum.shuffle() |> List.first()
      end

    # 只取关键范式节点（避免过多）
    key_paradigms =
      paradigms
      |> Enum.filter(fn p ->
        p["slug"] in [
          "perceptron",
          "symbolic-ai",
          "connectionism",
          "deep-learning",
          "transformers"
        ]
      end)

    {:ok, recent} =
      NexBase.from("papers")
      |> NexBase.order(:published_year, :desc)
      |> NexBase.limit(4)
      |> NexBase.run()

    {:ok, all_papers} =
      NexBase.from("papers")
      |> NexBase.run()

    {:ok, shifts} =
      NexBase.from("papers")
      |> NexBase.eq(:is_paradigm_shift, 1)
      |> NexBase.order(:published_year, :asc)
      |> NexBase.limit(4)
      |> NexBase.run()

    %{
      title: "AiSaga - 理解AI的起点",
      paradigms: key_paradigms,
      daily: daily_pick,
      recent: recent,
      all_papers: all_papers,
      shifts: shifts
    }
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-16">
      <!-- Hero Section: 价值主张 -->
      <div class="text-center py-16">
        <div class="inline-block bg-[rgb(255,222,0)] px-4 py-1 text-sm font-bold border-2 border-black mb-6">
          🤖 AI Saga
        </div>
        <h1 class="text-4xl md:text-6xl font-black mb-6 tracking-tight leading-tight">
          用三个视角<br/>读懂AI论文
        </h1>
        <p class="text-lg opacity-60 max-w-2xl mx-auto mb-8">
          不只是读论文，而是理解论文背后的历史脉络、范式变迁与人物故事。<br/>
          从感知机到Transformer，一起探索人工智能的演进之路。
        </p>
        <div class="flex gap-4 justify-center">
          <a href="/paper" class="md-btn md-btn-primary">
            浏览论文 →
          </a>
          <a href="/paradigm" class="md-btn md-btn-secondary">
            探索范式
          </a>
        </div>
        <div class="mt-8 text-sm opacity-40">
          已收录 <%= length(@all_papers) %> 篇重要论文 · <%= length(@paradigms) %> 个研究范式
        </div>
      </div>

      <!-- 三视角理念 -->
      <section class="bg-white border-2 border-black p-8 md:p-12">
        <h2 class="text-2xl font-bold mb-8 text-center">三个维度，读懂每一篇论文</h2>
        <div class="grid md:grid-cols-3 gap-6">
          <div class="text-center p-6 bg-[rgb(255,222,0)]/10 border-2 border-black">
            <div class="text-4xl mb-4">📜</div>
            <h3 class="text-xl font-bold mb-2">历史视角</h3>
            <p class="text-sm opacity-70">
              承前启后<br/>
              上一个范式是什么？<br/>
              这篇论文的核心创新在哪里？
            </p>
          </div>
          <div class="text-center p-6 bg-[rgb(111,194,255)]/10 border-2 border-black">
            <div class="text-4xl mb-4">🔄</div>
            <h3 class="text-xl font-bold mb-2">范式变迁</h3>
            <p class="text-sm opacity-70">
              挑战与突破<br/>
              当时面临什么困境？<br/>
              如何推动领域前进？
            </p>
          </div>
          <div class="text-center p-6 bg-[rgb(255,160,160)]/10 border-2 border-black">
            <div class="text-4xl mb-4">👤</div>
            <h3 class="text-xl font-bold mb-2">人的视角</h3>
            <p class="text-sm opacity-70">
              作者与传承<br/>
              谁在推动这一切？<br/>
              他们的后续去向？
            </p>
          </div>
        </div>
      </section>

      <!-- 今日推荐 -->
      <section>
        <div class="flex items-center gap-3 mb-6">
          <span class="text-2xl">✨</span>
          <h2 class="text-2xl font-bold">今日推荐</h2>
          <%= if !@daily["is_daily_pick"] do %>
            <span class="text-xs px-2 py-1 bg-gray-100 text-gray-600">随机精选</span>
          <% end %>
        </div>
        <%= if @daily do %>
          <a href={"/paper/#{@daily["slug"]}"} class="card-yellow block p-8">
            <div class="flex items-center gap-3 mb-3">
              <span class="badge badge-black">精选</span>
              <span class="year-tag"><%= @daily["published_year"] %></span>
              <%= if @daily["is_paradigm_shift"] do %>
                <span class="badge badge-yellow">范式突破</span>
              <% end %>
            </div>
            <h3 class="text-2xl font-bold mb-3"><%= @daily["title"] %></h3>
            <p class="text-base mb-4 line-clamp-3 opacity-80"><%= @daily["abstract"] %></p>
            <div class="flex items-center justify-between">
              <span class="text-sm font-mono opacity-60">阅读全文 →</span>
              <span class="text-sm font-mono"><%= @daily["citations"] %> 引用</span>
            </div>
          </a>
        <% end %>
      </section>

      <!-- 关键范式时间线（简化版） -->
      <section>
        <div class="flex items-center justify-between mb-6">
          <h2 class="section-title !mb-0">
            <span>📅</span> 范式演进
          </h2>
          <a href="/paradigm" class="text-sm underline opacity-60 hover:opacity-100">查看全部 →</a>
        </div>
        <div class="grid md:grid-cols-5 gap-3">
          <%= for paradigm <- @paradigms do %>
            <a href={"/paradigm/#{paradigm["slug"]}"} class="card block p-4 text-center hover:bg-gray-50">
              <div class="text-2xl mb-2">
                <%= case paradigm["slug"] do %>
                  <% "perceptron" -> %> 🧠
                  <% "symbolic-ai" -> %> 🔤
                  <% "connectionism" -> %> 🔗
                  <% "deep-learning" -> %> 🎯
                  <% "transformers" -> %> ⚡
                  <% _ -> %> 📊
                <% end %>
              </div>
              <h3 class="font-bold text-sm mb-1"><%= paradigm["name"] %></h3>
              <span class="year-tag">
                <%= paradigm["start_year"] %>
              </span>
            </a>
          <% end %>
        </div>
      </section>

      <!-- 最新收录 -->
      <section>
        <div class="flex items-center justify-between mb-6">
          <h2 class="section-title !mb-0">
            <span>📝</span> 最新收录
          </h2>
          <a href="/paper" class="text-sm underline opacity-60 hover:opacity-100">查看全部 →</a>
        </div>
        <div class="grid md:grid-cols-2 gap-4">
          <%= for paper <- @recent do %>
            <a href={"/paper/#{paper["slug"]}"} class="card block p-5">
              <div class="flex items-center gap-3 mb-2">
                <span class="year-tag"><%= paper["published_year"] %></span>
                <%= if paper["is_paradigm_shift"] do %>
                  <span class="w-2 h-2 bg-[rgb(255,222,0)]"></span>
                <% end %>
              </div>
              <h3 class="font-bold mb-2 line-clamp-2"><%= paper["title"] %></h3>
              <p class="text-sm opacity-60 line-clamp-2"><%= paper["abstract"] %></p>
            </a>
          <% end %>
        </div>
      </section>

      <!-- AI生成 -->
      <section class="card-black text-white p-8" style="background: var(--md-black); color: var(--md-white);">
        <h2 class="section-title !mb-4" style="color: var(--md-white);">
          <span>🎲</span> AI自动生成论文解读
        </h2>
        <p class="text-sm opacity-70 mb-6">
          基于已有 <%= length(@all_papers) %> 篇论文的知识库，AI将从最新研究中发现价值，并生成三视角深度解读。
        </p>

        <a href="/generate" class="md-btn md-btn-primary border-white">
          开始生成 →
        </a>
      </section>

      <!-- 范式变迁时刻 -->
      <section>
        <h2 class="section-title">
          <span>🌟</span> 范式突破时刻
        </h2>
        <div class="grid md:grid-cols-2 gap-4">
          <%= for paper <- @shifts do %>
            <a href={"/paper/#{paper["slug"]}"} class="card-blue block p-5">
              <div class="flex items-center gap-2 mb-2">
                <span class="badge badge-black">范式突破</span>
                <span class="year-tag"><%= paper["published_year"] %></span>
              </div>
              <h3 class="font-bold mb-2 line-clamp-2"><%= paper["title"] %></h3>
              <p class="text-sm opacity-70 line-clamp-2"><%= paper["shift_trigger"] %></p>
            </a>
          <% end %>
        </div>
      </section>
    </div>
    """
  end
end
