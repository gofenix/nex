defmodule BestofEx.Scheduler do
  @moduledoc """
  Simple periodic scheduler for syncing GitHub data.
  - Every 24 hours: update star counts for all projects
  - Every 7 days: full sync to discover new projects
  """
  use GenServer
  require Logger

  @one_day_ms 24 * 60 * 60 * 1000
  @one_week_ms 7 * @one_day_ms

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    # Schedule first star update after 1 minute (let app boot)
    Process.send_after(self(), :update_stars, 60_000)
    # Schedule first full sync after 5 minutes
    Process.send_after(self(), :sync_all, 300_000)

    Logger.info("[Scheduler] Started — star update every 24h, full sync every 7d")
    {:ok, state}
  end

  @impl true
  def handle_info(:update_stars, state) do
    Task.start(fn ->
      Logger.info("[Scheduler] Running daily star update...")
      BestofEx.Syncer.update_stars()
    end)

    Process.send_after(self(), :update_stars, @one_day_ms)
    {:noreply, state}
  end

  @impl true
  def handle_info(:sync_all, state) do
    Task.start(fn ->
      Logger.info("[Scheduler] Running weekly full sync...")
      BestofEx.Syncer.sync_all()
    end)

    Process.send_after(self(), :sync_all, @one_week_ms)
    {:noreply, state}
  end
end
