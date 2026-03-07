defmodule AiSaga.Pages.Paper.Slug do
  use Nex

  def mount(%{"slug" => slug}) do
    {:ok, [paper]} =
      NexBase.from("aisaga_papers")
      |> NexBase.eq(:slug, slug)
      |> NexBase.single()
      |> NexBase.run()

    {:ok, [paradigm]} =
      NexBase.from("aisaga_paradigms")
      |> NexBase.eq(:id, paper["paradigm_id"])
      |> NexBase.single()
      |> NexBase.run()

    {:ok, author_links} =
      NexBase.from("aisaga_paper_authors")
      |> NexBase.eq(:paper_id, paper["id"])
      |> NexBase.order(:author_order, :asc)
      |> NexBase.run()

    author_ids = Enum.map(author_links, & &1["author_id"])

    authors =
      if length(author_ids) > 0 do
        {:ok, all_authors} =
          NexBase.from("aisaga_authors")
          |> NexBase.in_list(:id, author_ids)
          |> NexBase.run()

        # Keep authors in the order defined by author_links.
        Enum.map(author_ids, fn id ->
          Enum.find(all_authors, fn a -> a["id"] == id end)
        end)
        |> Enum.filter(& &1)
      else
        []
      end

    %{
      title: paper["title"],
      paper: paper,
      paradigm: paradigm,
      authors: authors
    }
  end

  # Convert Markdown to HTML.
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
        ← Back to Papers
      </a>

      <article class="space-y-6">
        <%!-- Header --%>
        <header class="space-y-4 border-b-2 border-black pb-6">
          <div class="flex flex-wrap items-center gap-3">
            <a href={"/paradigm/#{@paradigm["slug"]}"} class="badge badge-blue">
              {@paradigm["name"]}
            </a>
            <span :if={@paper["is_paradigm_shift"] == 1} class="badge badge-yellow">
              ⚡ Paradigm shift
            </span>
            <span class="year-tag">{@paper["published_year"]}</span>
          </div>

          <h1 class="text-3xl md:text-4xl font-black leading-tight">{@paper["title"]}</h1>

          <div class="flex flex-wrap gap-2">
            <a :for={author <- @authors} href={"/author/#{author["slug"]}"} class="text-sm border-b border-black hover:bg-gray-100">{author["name"]}</a>
          </div>

          <div class="flex items-center gap-4 text-sm font-mono opacity-60">
            <span :if={@paper["arxiv_id"]}>arXiv:{@paper["arxiv_id"]}</span>
            <span :if={@paper["arxiv_id"]}>•</span>
            <span>{@paper["citations"]} citations</span>
            <span>•</span>
            <a href={@paper["url"]} target="_blank" class="hover:underline">Read original →</a>
          </div>
        </header>

        <%!-- Abstract --%>
        <div class="prose max-w-none bg-gray-50 p-6 border-2 border-black">
          <p class="text-lg leading-relaxed">{@paper["abstract"]}</p>
        </div>

        <%!-- Anchor navigation --%>
        <nav class="sticky top-0 z-10 card p-3 flex flex-wrap gap-2">
          <a :if={@paper["prev_paradigm"]} href="#history" class="badge badge-yellow hover:bg-yellow-300 transition-colors">📜 Historical Lens</a>
          <a href="#paradigm-shift" class="badge badge-blue hover:bg-blue-300 transition-colors">🔄 Paradigm Shift</a>
          <a :if={@paper["author_destinies"]} href="#people" class="badge" style="background: rgba(255,160,160,0.2); border-color: var(--md-black);">👤 Human Lens</a>
          <a :if={@paper["subsequent_impact"]} href="#impact" class="badge badge-gray hover:bg-gray-200 transition-colors">📈 Subsequent Influence</a>
        </nav>

        <%!-- Three-lens content --%>
        <div class="space-y-6">

          <%!-- I. Historical lens --%>
          <section :if={@paper["prev_paradigm"]} id="history" class="space-y-4 scroll-mt-20">
              <h2 class="text-2xl font-black border-b-2 border-black pb-2">📜 Historical Lens</h2>
              <details class="bg-white border-2 border-black group" open>
                <summary class="p-4 cursor-pointer font-bold flex items-center justify-between hover:bg-gray-50">
                  <span>📖 Previous Paradigm</span>
                  <span class="text-xs opacity-60 group-open:rotate-180 transition-transform">▼</span>
                </summary>
                <div class="p-4 pt-0 prose max-w-none markdown-content border-t border-gray-200">
                  {Phoenix.HTML.raw(markdown_to_html(@paper["prev_paradigm"]))}
                </div>
              </details>
            </section>

          <%!-- Core contribution --%>
          <details :if={@paper["core_contribution"]} class="bg-[rgb(255,222,0)] border-2 border-black group" open>
              <summary class="p-4 cursor-pointer font-bold flex items-center justify-between hover:bg-yellow-300">
                <span>💡 Core Contribution</span>
                <span class="text-xs opacity-60 group-open:rotate-180 transition-transform">▼</span>
              </summary>
              <div class="p-4 pt-0 prose max-w-none markdown-content bg-white border-t-2 border-black">
                {Phoenix.HTML.raw(markdown_to_html(@paper["core_contribution"]))}
              </div>
            </details>

          <%!-- Core mechanism --%>
          <details :if={@paper["core_mechanism"]} class="bg-white border-2 border-black group" open>
              <summary class="p-4 cursor-pointer font-bold flex items-center justify-between hover:bg-gray-50">
                <span>⚙️ Core Mechanism</span>
                <span class="text-xs opacity-60 group-open:rotate-180 transition-transform">▼</span>
              </summary>
              <div class="p-4 pt-0 prose max-w-none markdown-content border-t border-gray-200">
                {Phoenix.HTML.raw(markdown_to_html(@paper["core_mechanism"]))}
              </div>
            </details>

          <%!-- Why it won --%>
          <details :if={@paper["why_it_wins"]} class="bg-[rgb(111,194,255)] border-2 border-black group" open>
              <summary class="p-4 cursor-pointer font-bold flex items-center justify-between hover:bg-blue-300">
                <span>🏆 Why It Won</span>
                <span class="text-xs opacity-60 group-open:rotate-180 transition-transform">▼</span>
              </summary>
              <div class="p-4 pt-0 prose max-w-none markdown-content bg-white border-t-2 border-black">
                {Phoenix.HTML.raw(markdown_to_html(@paper["why_it_wins"]))}
              </div>
            </details>

          <%!-- II. Paradigm shift lens --%>
          <section id="paradigm-shift" class="space-y-4 scroll-mt-20">
            <h2 class="text-2xl font-black border-b-2 border-black pb-2">🔄 Paradigm Shift Lens</h2>

            <%!-- Challenges --%>
            <details class="bg-white border-2 border-red-200 group" open>
              <summary class="p-4 cursor-pointer font-bold flex items-center justify-between hover:bg-red-50 text-red-700">
                <span>⚠️ Challenges at the Time</span>
                <span class="text-xs opacity-60 group-open:rotate-180 transition-transform">▼</span>
              </summary>
              <div class="p-4 pt-0 prose max-w-none markdown-content border-t border-red-100">
                {Phoenix.HTML.raw(markdown_to_html(@paper["challenge"]))}
              </div>
            </details>

            <%!-- Solution --%>
            <details class="bg-[rgb(255,222,0)] border-2 border-black group" open>
              <summary class="p-4 cursor-pointer font-bold flex items-center justify-between hover:bg-yellow-300">
                <span>💡 Solution</span>
                <span class="text-xs opacity-60 group-open:rotate-180 transition-transform">▼</span>
              </summary>
              <div class="p-4 pt-0 prose max-w-none markdown-content bg-white border-t-2 border-black">
                {Phoenix.HTML.raw(markdown_to_html(@paper["solution"]))}
              </div>
            </details>

            <%!-- Long-term impact --%>
            <details class="bg-[rgb(111,194,255)] border-2 border-black group" open>
              <summary class="p-4 cursor-pointer font-bold flex items-center justify-between hover:bg-blue-300">
                <span>🌊 Long-Term Impact</span>
                <span class="text-xs opacity-60 group-open:rotate-180 transition-transform">▼</span>
              </summary>
              <div class="p-4 pt-0 prose max-w-none markdown-content bg-white border-t-2 border-black">
                {Phoenix.HTML.raw(markdown_to_html(@paper["impact"]))}
              </div>
            </details>
          </section>

          <%!-- III. Human lens --%>
          <section :if={@paper["author_destinies"]} id="people" class="space-y-4 scroll-mt-20">
              <h2 class="text-2xl font-black border-b-2 border-black pb-2">👤 Human Lens: Author Trajectories</h2>
              <details class="bg-white border-2 border-black group" open>
                <summary class="p-4 cursor-pointer font-bold flex items-center justify-between hover:bg-gray-50">
                  <span>👥 Author Trajectories</span>
                  <span class="text-xs opacity-60 group-open:rotate-180 transition-transform">▼</span>
                </summary>
                <div class="p-4 pt-0 prose max-w-none markdown-content border-t border-gray-200">
                  {Phoenix.HTML.raw(markdown_to_html(@paper["author_destinies"]))}
                </div>
              </details>
            </section>

          <%!-- Subsequent influence --%>
          <section :if={@paper["subsequent_impact"]} id="impact" class="space-y-4 scroll-mt-20">
              <h2 class="text-2xl font-black border-b-2 border-black pb-2">📈 Subsequent Influence</h2>
              <details class="bg-gray-50 border-2 border-black group" open>
                <summary class="p-4 cursor-pointer font-bold flex items-center justify-between hover:bg-gray-100">
                  <span>📊 Impact on Later Research</span>
                  <span class="text-xs opacity-60 group-open:rotate-180 transition-transform">▼</span>
                </summary>
                <div class="p-4 pt-0 prose max-w-none markdown-content border-t border-gray-200">
                  {Phoenix.HTML.raw(markdown_to_html(@paper["subsequent_impact"]))}
                </div>
              </details>
            </section>

          <%!-- Fallback historical context when the new format is absent --%>
          <details :if={!@paper["prev_paradigm"] && @paper["history_context"]} class="bg-gray-50 border-2 border-black group" open>
              <summary class="p-4 cursor-pointer font-bold flex items-center justify-between hover:bg-gray-100">
                <span>📜 Historical Context</span>
                <span class="text-xs opacity-60 group-open:rotate-180 transition-transform">▼</span>
              </summary>
              <div class="p-4 pt-0 prose max-w-none markdown-content border-t border-gray-200">
                {Phoenix.HTML.raw(markdown_to_html(@paper["history_context"]))}
              </div>
            </details>

        </div>
      </article>
    </div>
    """
  end
end
