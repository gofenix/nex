defmodule AiSaga.Pages.Index do
  use Nex

  def mount(_params) do
    {:ok, paradigms} =
      NexBase.from("aisaga_paradigms")
      |> NexBase.order(:start_year, :asc)
      |> NexBase.run()

    # If no daily pick is configured, choose a high-impact paper at random.
    {:ok, daily_candidates} =
      NexBase.from("aisaga_papers")
      |> NexBase.eq(:is_daily_pick, 1)
      |> NexBase.single()
      |> NexBase.run()

    daily = List.first(daily_candidates || [])

    daily_pick =
      if daily do
        daily
      else
        # Randomly select a high-impact paper as today's pick.
        {:ok, candidates} =
          NexBase.from("aisaga_papers")
          |> NexBase.order(:citations, :desc)
          |> NexBase.limit(10)
          |> NexBase.run()

        candidates |> Enum.shuffle() |> List.first()
      end

    # Keep only key paradigm milestones to avoid overcrowding.
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
      NexBase.from("aisaga_papers")
      |> NexBase.select([:title, :slug, :abstract, :published_year, :is_paradigm_shift])
      |> NexBase.order(:created_at, :desc)
      |> NexBase.limit(4)
      |> NexBase.run()

    {:ok, [%{"count" => paper_count}]} =
      NexBase.sql("SELECT COUNT(*) as count FROM aisaga_papers")

    {:ok, shifts} =
      NexBase.from("aisaga_papers")
      |> NexBase.select([:title, :slug, :published_year, :shift_trigger])
      |> NexBase.eq(:is_paradigm_shift, 1)
      |> NexBase.order(:published_year, :asc)
      |> NexBase.limit(4)
      |> NexBase.run()

    %{
      title: "AiSaga - Where AI Understanding Begins",
      paradigms: key_paradigms,
      daily: daily_pick,
      recent: recent,
      paper_count: paper_count,
      shifts: shifts
    }
  end

  defp paradigm_icon("perceptron"), do: "🧠"
  defp paradigm_icon("symbolic-ai"), do: "🔤"
  defp paradigm_icon("connectionism"), do: "🔗"
  defp paradigm_icon("deep-learning"), do: "🎯"
  defp paradigm_icon("transformers"), do: "⚡"
  defp paradigm_icon(_), do: "📊"

  def render(assigns) do
    ~H"""
    <div class="space-y-16">
      <!-- Hero Section: Value Proposition -->
      <div class="text-center py-16">
        <div class="inline-block bg-[rgb(255,222,0)] px-4 py-1 text-sm font-bold border-2 border-black mb-6">
          🤖 AI Saga
        </div>
        <h1 class="text-4xl md:text-6xl font-black mb-6 tracking-tight leading-tight">
          Understand AI Papers<br/>Through Three Lenses
        </h1>
        <p class="text-lg opacity-60 max-w-2xl mx-auto mb-8">
          Go beyond reading papers to understand the historical context, paradigm shifts, and human stories behind them.<br/>
          From the Perceptron to the Transformer, explore the evolution of artificial intelligence.
        </p>
        <div class="flex gap-4 justify-center">
          <a href="/paper" class="md-btn md-btn-primary">
            Browse Papers →
          </a>
          <a href="/paradigm" class="md-btn md-btn-secondary">
            Explore Paradigms
          </a>
        </div>
        <div class="mt-8 text-sm opacity-40">
          {@paper_count} landmark papers archived · {length(@paradigms)} research paradigms
        </div>
      </div>

      <!-- Three-lens framework -->
      <section class="bg-white border-2 border-black p-8 md:p-12">
        <h2 class="text-2xl font-bold mb-8 text-center">Three dimensions for understanding every paper</h2>
        <div class="grid md:grid-cols-3 gap-6">
          <div class="text-center p-6 bg-[rgb(255,222,0)]/10 border-2 border-black">
            <div class="text-4xl mb-4">📜</div>
            <h3 class="text-xl font-bold mb-2">Historical Lens</h3>
            <p class="text-sm opacity-70">
              What came before?<br/>
              Which paradigm did it emerge from?<br/>
              Where does its core innovation lie?
            </p>
          </div>
          <div class="text-center p-6 bg-[rgb(111,194,255)]/10 border-2 border-black">
            <div class="text-4xl mb-4">🔄</div>
            <h3 class="text-xl font-bold mb-2">Paradigm Shift</h3>
            <p class="text-sm opacity-70">
              Challenges and breakthroughs<br/>
              What problems did the field face?<br/>
              How did this work move it forward?
            </p>
          </div>
          <div class="text-center p-6 bg-[rgb(255,160,160)]/10 border-2 border-black">
            <div class="text-4xl mb-4">👤</div>
            <h3 class="text-xl font-bold mb-2">Human Lens</h3>
            <p class="text-sm opacity-70">
              Authors and legacy<br/>
              Who pushed this forward?<br/>
              Where did they go next?
            </p>
          </div>
        </div>
      </section>

      <!-- Daily recommendation -->
      <section>
        <div class="flex items-center gap-3 mb-6">
          <span class="text-2xl">✨</span>
          <h2 class="text-2xl font-bold">Today’s Pick</h2>
          <span :if={!@daily["is_daily_pick"]} class="text-xs px-2 py-1 bg-gray-100 text-gray-600">Random selection</span>
        </div>
        <a :if={@daily} href={"/paper/#{@daily["slug"]}"} class="card-yellow block p-8">
            <div class="flex items-center gap-3 mb-3">
              <span class="badge badge-black">Featured</span>
              <span class="year-tag">{@daily["published_year"]}</span>
              <span :if={@daily["is_paradigm_shift"]} class="badge badge-yellow">Paradigm shift</span>
            </div>
            <h3 class="text-2xl font-bold mb-3">{@daily["title"]}</h3>
            <p class="text-base mb-4 line-clamp-3 opacity-80">{@daily["abstract"]}</p>
            <div class="flex items-center justify-between">
              <span class="text-sm font-mono opacity-60">Read the full paper →</span>
              <span class="text-sm font-mono">{@daily["citations"]} citations</span>
            </div>
          </a>
      </section>

      <!-- Key paradigm timeline -->
      <section>
        <div class="flex items-center justify-between mb-6">
          <h2 class="section-title !mb-0">
            <span>📅</span> Paradigm Evolution
          </h2>
          <a href="/paradigm" class="text-sm underline opacity-60 hover:opacity-100">View all →</a>
        </div>
        <div class="grid md:grid-cols-5 gap-3">
          <a :for={paradigm <- @paradigms} href={"/paradigm/#{paradigm["slug"]}"} class="card block p-4 text-center hover:bg-gray-50">
              <div class="text-2xl mb-2">
                {paradigm_icon(paradigm["slug"])}
              </div>
              <h3 class="font-bold text-sm mb-1">{paradigm["name"]}</h3>
              <span class="year-tag">{paradigm["start_year"]}</span>
            </a>
        </div>
      </section>

      <!-- Latest additions -->
      <section>
        <div class="flex items-center justify-between mb-6">
          <h2 class="section-title !mb-0">
            <span>📝</span> Latest Additions
          </h2>
          <a href="/paper" class="text-sm underline opacity-60 hover:opacity-100">View all →</a>
        </div>
        <div class="grid md:grid-cols-2 gap-4">
          <a :for={paper <- @recent} href={"/paper/#{paper["slug"]}"} class="card block p-5">
              <div class="flex items-center gap-3 mb-2">
                <span class="year-tag">{paper["published_year"]}</span>
                <span :if={paper["is_paradigm_shift"]} class="w-2 h-2 bg-[rgb(255,222,0)]"></span>
              </div>
              <h3 class="font-bold mb-2 line-clamp-2">{paper["title"]}</h3>
              <p class="text-sm opacity-60 line-clamp-2">{paper["abstract"]}</p>
            </a>
        </div>
      </section>

      <!-- AI generation -->
      <section class="card-black text-white p-8" style="background: var(--md-black); color: var(--md-white);">
        <h2 class="section-title !mb-4" style="color: var(--md-white);">
          <span>🎲</span> AI-Generated Paper Analysis
        </h2>
        <p class="text-sm opacity-70 mb-6">
          Using a knowledge base of {@paper_count} existing papers, AI identifies valuable new research and generates a deep three-lens analysis.
        </p>

        <a href="/generate" class="md-btn md-btn-primary border-white">
          Start generation →
        </a>
      </section>

      <!-- Paradigm-shift moments -->
      <section>
        <h2 class="section-title">
          <span>🌟</span> Paradigm-Shift Moments
        </h2>
        <div class="grid md:grid-cols-2 gap-4">
          <a :for={paper <- @shifts} href={"/paper/#{paper["slug"]}"} class="card-blue block p-5">
              <div class="flex items-center gap-2 mb-2">
                <span class="badge badge-black">Paradigm shift</span>
                <span class="year-tag">{paper["published_year"]}</span>
              </div>
              <h3 class="font-bold mb-2 line-clamp-2">{paper["title"]}</h3>
              <p class="text-sm opacity-70 line-clamp-2">{paper["shift_trigger"]}</p>
            </a>
        </div>
      </section>
    </div>
    """
  end
end
