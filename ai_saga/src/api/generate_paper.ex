defmodule AiSaga.Api.GeneratePaper do
  use Nex

  def post(req) do
    # 异步启动生成任务
    Task.start(fn ->
      case AiSaga.PaperGenerator.generate_and_save() do
        {:ok, result} ->
          IO.puts("✅ 论文生成成功: #{result.title}")
          IO.puts("   URL: /paper/#{result.slug}")
          IO.puts("   推荐理由: #{result.reason}")
        
        {:error, reason} ->
          IO.puts("❌ 论文生成失败: #{reason}")
      end
    end)
    
    Nex.json(%{message: "论文生成任务已启动，请稍候...", status: "generating"})
  end
end
