defmodule AiSaga.Api.GeneratePaper.Stream do
  use Nex

  alias AiSaga.{ArxivClient, HFClient, OpenAIClient, PaperGenerator}

  def get(_req) do
    Nex.stream(fn send ->
      send.(%{
        event: "message",
        data: "<div class='text-sm opacity-70'>🔍 正在从 HuggingFace 获取热门论文...</div>"
      })

      with {:ok, papers_summary} <- PaperGenerator.get_papers_summary(),
           {:ok, hf_candidates} <- HFClient.get_trending_papers(20) do
        send.(%{
          event: "message",
          data:
            "<div class='text-sm opacity-70'>📊 已获取 #{length(hf_candidates)} 篇候选论文，正在让 AI 推荐...</div>"
        })

        with {:ok, recommendation} <- OpenAIClient.recommend_paper(papers_summary, hf_candidates) do
          send.(%{
            event: "message",
            data:
              "<div class='text-sm font-bold' style='color: #4ade80;'>✨ AI 推荐: #{recommendation.title}</div>"
          })

          send.(%{
            event: "message",
            data:
              "<div class='text-sm opacity-70'>📄 正在从 arXiv 获取论文详情... (ID: #{recommendation.arxiv_id || "未获取到"})</div>"
          })

          # 验证 arXiv ID
          if is_nil(recommendation.arxiv_id) or recommendation.arxiv_id == "" do
            send.(%{
              event: "message",
              data: "<div class='text-sm' style='color: #f87171;'>❌ AI 未返回有效的 arXiv ID，请重试</div>"
            })

            send.(%{
              event: "done",
              data: Jason.encode!(%{status: "error", message: "AI 未返回有效的 arXiv ID，请重试"})
            })
          else
            with {:ok, arxiv_papers} <- ArxivClient.get_paper_by_id(recommendation.arxiv_id),
                 new_paper = List.first(arxiv_papers),
                 {:ok, hf_data} <- HFClient.get_paper_details(recommendation.arxiv_id),
                 {:ok, relevant_papers} <- PaperGenerator.get_relevant_papers(new_paper.published) do
              send.(%{
                event: "message",
                data: "<div class='text-sm opacity-70'>🤖 正在生成三视角深度分析，请耐心等待（约60秒）...</div>"
              })

              # 添加超时处理 - 55秒超时（在Bandit SSE超时之前）
              analysis_task =
                Task.async(fn ->
                  OpenAIClient.generate_analysis(relevant_papers, new_paper, hf_data)
                end)

              case Task.yield(analysis_task, 55_000) do
                {:ok, {:ok, analysis}} ->
                  with {:ok, slug} <-
                         PaperGenerator.save_paper(new_paper, analysis, recommendation) do
                    send.(%{
                      event: "message",
                      data: "<div class='text-sm font-bold' style='color: #4ade80;'>✅ 生成完成！</div>"
                    })

                    send.(%{
                      event: "message",
                      data:
                        "<div class='text-sm mt-2'><span class='font-bold'>📖 论文链接:</span> <a href='/paper/#{slug}' class='underline hover:opacity-80' style='color: #6fc2ff;'>#{new_paper.title}</a></div>"
                    })

                    send.(%{
                      event: "message",
                      data:
                        "<div class='text-sm mt-2 p-3 bg-yellow-400/20 border border-yellow-400 rounded' style='color: var(--md-white);'><span class='font-bold'>💡 推荐理由:</span> #{recommendation.reason}</div>"
                    })

                    # 发送完成事件（JSON 格式）
                    send.(%{
                      event: "done",
                      data:
                        Jason.encode!(%{status: "success", slug: slug, title: new_paper.title})
                    })
                  else
                    {:error, reason} ->
                      # 友好的错误提示
                      {display_msg, status_msg} =
                        case reason do
                          "论文已存在: " <> slug ->
                            {
                              "AI 推荐的论文已存在数据库中 - <a href='/paper/#{slug}' class='underline' style='color: #6fc2ff;'>查看论文</a>",
                              "论文已存在，请点击重试按钮让 AI 推荐另一篇论文"
                            }

                          _ ->
                            {"保存论文失败: #{inspect(reason)}", inspect(reason)}
                        end

                      send.(%{
                        event: "message",
                        data:
                          "<div class='text-sm' style='color: #f87171;'>❌ #{display_msg}</div>"
                      })

                      send.(%{
                        event: "done",
                        data: Jason.encode!(%{status: "error", message: status_msg})
                      })
                  end

                {:ok, {:error, reason}} ->
                  error_msg = "分析生成失败: #{inspect(reason)}"

                  send.(%{
                    event: "message",
                    data: "<div class='text-sm' style='color: #f87171;'>❌ #{error_msg}</div>"
                  })

                  send.(%{
                    event: "done",
                    data: Jason.encode!(%{status: "error", message: error_msg})
                  })

                nil ->
                  Task.shutdown(analysis_task, :brutal_kill)
                  error_msg = "分析生成超时：API响应超过55秒，请稍后重试"

                  send.(%{
                    event: "message",
                    data: "<div class='text-sm' style='color: #f87171;'>❌ #{error_msg}</div>"
                  })

                  send.(%{
                    event: "done",
                    data: Jason.encode!(%{status: "error", message: error_msg})
                  })
              end
            else
              {:error, reason} ->
                error_msg = "获取论文详情失败: #{inspect(reason)}"

                send.(%{
                  event: "message",
                  data: "<div class='text-sm' style='color: #f87171;'>❌ #{error_msg}</div>"
                })

                send.(%{
                  event: "done",
                  data: Jason.encode!(%{status: "error", message: error_msg})
                })
            end
          end
        else
          {:error, reason} ->
            error_msg = "AI 推荐失败: #{inspect(reason)}"

            send.(%{
              event: "message",
              data: "<div class='text-sm' style='color: #f87171;'>❌ #{error_msg}</div>"
            })

            send.(%{event: "done", data: Jason.encode!(%{status: "error", message: error_msg})})
        end
      else
        {:error, reason} ->
          error_msg = "获取数据失败: #{inspect(reason)}"

          send.(%{
            event: "message",
            data: "<div class='text-sm' style='color: #f87171;'>❌ #{error_msg}</div>"
          })

          send.(%{event: "done", data: Jason.encode!(%{status: "error", message: error_msg})})
      end
    end)
  end
end
