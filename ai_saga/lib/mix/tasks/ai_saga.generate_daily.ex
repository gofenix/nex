defmodule Mix.Tasks.AiSaga.GenerateDaily do
  @moduledoc """
  每日定时生成一篇 AI 论文解读

  Usage:
    mix ai_saga.generate_daily
  """
  use Mix.Task

  require Logger

  @shortdoc "Generate one AI paper analysis daily"

  def run(_args) do
    # 启动应用（确保数据库连接等可用）
    Mix.Task.run("app.start")

    Logger.info("[DailyGeneration] Starting daily paper generation...")
    start_time = System.monotonic_time(:millisecond)

    case AiSaga.PaperGenerator.generate_and_save() do
      {:ok, result} ->
        duration = System.monotonic_time(:millisecond) - start_time
        Logger.info("[DailyGeneration] ✅ Generated: #{result.title}")
        Logger.info("[DailyGeneration] Slug: #{result.slug}")
        Logger.info("[DailyGeneration] Duration: #{duration}ms")

        IO.puts("\n=== Generation Successful ===")
        IO.puts("Title: #{result.title}")
        IO.puts("Slug: #{result.slug}")
        IO.puts("=============================\n")

      {:error, reason} ->
        Logger.error("[DailyGeneration] ❌ Failed: #{inspect(reason)}")

        IO.puts("\n=== Generation Failed ===")
        IO.puts("Error: #{inspect(reason)}")
        IO.puts("=========================\n")

        # 失败时返回非零退出码
        System.halt(1)
    end
  end
end
