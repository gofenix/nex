defmodule AiSaga.Api.GeneratePaper.Stream do
  use Nex

  alias AiSaga.{ArxivClient, HFClient, OpenAIClient, PaperGenerator}

  def get(_req) do
    Nex.stream(fn send ->
      send.(%{event: "message", data: "<div class='text-sm opacity-70'>🔍 正在从 HuggingFace 获取热门论文...</div>"})

      with {:ok, papers_summary} <- PaperGenerator.get_papers_summary(),
           {:ok, hf_candidates} <- HFClient.get_trending_papers(20) do
        send.(%{
          event: "message",
          data: "<div class='text-sm opacity-70'>📊 已获取 #{length(hf_candidates)} 篇候选论文，正在让 AI 推荐...</div>"
        })

        with {:ok, recommendation} <- OpenAIClient.recommend_paper(papers_summary, hf_candidates) do
          send.(%{event: "message", data: "<div class='text-sm font-bold'>✨ AI 推荐: #{recommendation.title}</div>"})
          send.(%{event: "message", data: "<div class='text-sm opacity-70'>📄 正在从 arXiv 获取论文详情...</div>"})

          with {:ok, arxiv_papers} <- ArxivClient.get_paper_by_id(recommendation.arxiv_id),
               new_paper = List.first(arxiv_papers),
               {:ok, hf_data} <- HFClient.get_paper_details(recommendation.arxiv_id),
               {:ok, relevant_papers} <- PaperGenerator.get_relevant_papers(new_paper.published) do
            send.(%{event: "message", data: "<div class='text-sm opacity-70'>🤖 正在生成三视角深度分析，请耐心等待（约60秒）...</div>"})

            # 添加超时处理 - 55秒超时（在Bandit SSE超时之前）
            analysis_task = Task.async(fn ->
              OpenAIClient.generate_analysis(relevant_papers, new_paper, hf_data)
            end)

            case Task.yield(analysis_task, 55_000) do
              {:ok, {:ok, analysis}} ->
                with {:ok, slug} <- PaperGenerator.save_paper(new_paper, analysis, recommendation) do
                  send.(%{event: "message", data: "<div class='text-sm font-bold text-green-600'>✅ 生成完成！</div>"})

                  send.(%{
                    event: "message",
                    data: "<div class='text-sm mt-2'><span class='font-bold'>📖 论文链接:</span> <a href='/paper/#{slug}' class='underline text-blue-600 hover:text-blue-800'>#{new_paper.title}</a></div>"
                  })

                  send.(%{
                    event: "message",
                    data: "<div class='text-sm mt-2 p-3 bg-yellow-50 border border-yellow-200 rounded'><span class='font-bold'>💡 推荐理由:</span> #{recommendation.reason}</div>"
                  })
                else
                  {:error, reason} ->
                    send.(%{event: "message", data: "<div class='text-sm text-red-600'>❌ 保存论文失败: #{inspect(reason)}</div>"})
                end

              {:ok, {:error, reason}} ->
                send.(%{event: "message", data: "<div class='text-sm text-red-600'>❌ 分析生成失败: #{inspect(reason)}</div>"})

              nil ->
                Task.shutdown(analysis_task, :brutal_kill)
                send.(%{event: "message", data: "<div class='text-sm text-red-600'>❌ 分析生成超时：API响应超过55秒，当前模型较慢，请稍后重试或联系管理员</div>"})
            end
          else
            {:error, reason} ->
              send.(%{event: "message", data: "<div class='text-sm text-red-600'>❌ 获取论文详情失败: #{inspect(reason)}</div>"})
          end
        else
          {:error, reason} ->
            send.(%{event: "message", data: "<div class='text-sm text-red-600'>❌ AI 推荐失败: #{inspect(reason)}</div>"})
        end
      else
        {:error, reason} ->
          send.(%{event: "message", data: "<div class='text-sm text-red-600'>❌ 获取数据失败: #{inspect(reason)}</div>"})
      end
    end)
  end
end
