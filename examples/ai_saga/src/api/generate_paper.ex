defmodule AiSaga.Api.GeneratePaper do
  use Nex

  alias AiSaga.{ArxivClient, HFClient, OpenAIClient, PaperGenerator}

  def post(_req) do
    result = generate_paper_sync()

    case result do
      {:ok, slug, title, reason} ->
        Nex.html("""
        <div id="generate-controls">
          <button class="md-btn md-btn-primary border-white">✅ Completed</button>
        </div>
        <div id="generate-status">
          <div class='text-sm font-bold' style='color: #4ade80;'>✅ Generation completed!</div>
          <div class='text-sm mt-2'><span class='font-bold'>📖 Paper link:</span> <a href='/paper/#{slug}' class='underline hover:opacity-80' style='color: #6fc2ff;'>#{title}</a></div>
          <div class='text-sm mt-2 p-3 bg-yellow-400/20 border border-yellow-400 rounded' style='color: var(--md-white);'><span class='font-bold'>💡 Recommendation reason:</span> #{reason}</div>
        </div>
        """)

      {:error, message} ->
        Nex.html("""
        <div id="generate-controls">
          <button class="md-btn border-white">❌ Generation Failed</button>
        </div>
        <div id="generate-status">
          <div class='text-sm' style='color: #f87171;'>❌ #{message}</div>
        </div>
        """)
    end
  end

  defp generate_paper_sync do
    with {:ok, papers_summary} <- PaperGenerator.get_papers_summary(),
         {:ok, hf_candidates} <- HFClient.get_trending_papers(20),
         {:ok, recommendation} <- OpenAIClient.recommend_paper(papers_summary, hf_candidates),
         {:ok, arxiv_papers} <- ArxivClient.get_paper_by_id(recommendation.arxiv_id),
         new_paper = List.first(arxiv_papers),
         {:ok, hf_data} <- HFClient.get_paper_details(recommendation.arxiv_id),
         {:ok, relevant_papers} <- PaperGenerator.get_relevant_papers(new_paper.published),
         {:ok, analysis} <- OpenAIClient.generate_analysis(relevant_papers, new_paper, hf_data),
         {:ok, slug} <- PaperGenerator.save_paper(new_paper, analysis, recommendation) do
      {:ok, slug, new_paper.title, recommendation.reason}
    else
      {:error, reason} -> {:error, inspect(reason)}
      _ -> {:error, "Unknown error"}
    end
  end
end
