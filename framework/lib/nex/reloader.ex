defmodule Nex.Reloader do
  @moduledoc """
  Hot code reloading for Nex development.

  Watches `src/` directory for file changes and automatically recompiles.
  Browsers poll `/nex/live-reload` to detect changes and refresh.
  """

  use GenServer
  require Logger

  @watch_dirs ["src/", "lib/"]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Get the timestamp of the last successful reload"
  def last_reload_time do
    GenServer.call(__MODULE__, :last_reload_time)
  catch
    :exit, _ -> 0
  end

  @impl true
  def init(_opts) do
    case Application.ensure_loaded(:file_system) do
      :ok ->
        {:ok, watcher_pid} = FileSystem.start_link(dirs: @watch_dirs)
        FileSystem.subscribe(watcher_pid)
        Logger.info("[Nex.Reloader] Watching for file changes in #{inspect(@watch_dirs)}")
        {:ok, %{watcher: watcher_pid, last_reload: 0}}

      {:error, _} ->
        Logger.warning("[Nex.Reloader] file_system not available, hot reload disabled")
        {:ok, %{watcher: nil, last_reload: 0}}
    end
  end

  @impl true
  def handle_call(:last_reload_time, _from, state) do
    {:reply, state.last_reload, state}
  end

  @impl true
  def handle_info({:file_event, _watcher, {path, events}}, state) do
    state =
      if should_reload?(path, events) do
        reload_file(path, state)
      else
        state
      end

    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  defp should_reload?(path, events) do
    String.ends_with?(path, ".ex") and
      Enum.any?(events, &(&1 in [:modified, :created, :renamed]))
  end

  defp reload_file(path, state) do
    Logger.info("[Nex.Reloader] Recompiling: #{Path.basename(path)}")

    try do
      Code.compile_file(path)
      Logger.info("[Nex.Reloader] ✓ Reloaded successfully")

      # Broadcast reload event to all connected WebSocket clients
      Phoenix.PubSub.broadcast(Nex.PubSub, "live_reload", {:reload, path})

      # Update last_reload timestamp so browsers know to refresh
      %{state | last_reload: System.system_time(:millisecond)}
    rescue
      e ->
        Logger.error("[Nex.Reloader] ✗ Compile error: #{Exception.message(e)}")
        state
    end
  end
end
