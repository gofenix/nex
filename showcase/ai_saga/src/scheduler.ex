defmodule AiSaga.Scheduler do
  @moduledoc """
  Simple periodic scheduler for generating AI papers.
  - Every 24 hours: generate one new AI paper
  """
  use GenServer
  require Logger

  @one_day_ms 24 * 60 * 60 * 1000

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    # Schedule first generation after 5 minutes (let app boot)
    Process.send_after(self(), :generate_paper, 300_000)

    Logger.info("[Scheduler] Started — paper generation every 24h")
    {:ok, state}
  end

  @impl true
  def handle_info(:generate_paper, state) do
    Task.start(fn ->
      Logger.info("[Scheduler] Running daily paper generation...")

      case AiSaga.PaperGenerator.generate_and_save() do
        {:ok, result} ->
          Logger.info("[Scheduler] ✅ Generated: #{result.title}")
        {:error, reason} ->
          Logger.error("[Scheduler] ❌ Failed: #{inspect(reason)}")
      end
    end)

    # Schedule next generation in 24 hours
    Process.send_after(self(), :generate_paper, @one_day_ms)
    {:noreply, state}
  end
end
