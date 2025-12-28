defmodule Nex.Reloader do
  @moduledoc """
  Hot code reloading for Nex development.

  Watches `src/` directory for file changes and automatically recompiles.
  **Only enabled in :dev environment** - completely disabled in :prod and :test.
  """

  use GenServer
  require Logger

  @watch_dirs ["src/", "lib/"]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Check if hot reload is enabled (only in dev environment)"
  def enabled? do
    Application.get_env(:nex_core, :env, :prod) == :dev
  end

  @doc "Get the timestamp of the last successful reload"
  def last_reload_time do
    GenServer.call(__MODULE__, :last_reload_time)
  catch
    :exit, _ -> 0
  end

  @impl true
  def init(_opts) do
    # Only enable hot reload in dev environment
    if enabled?() do
      init_watcher()
    else
      Logger.debug("[Nex.Reloader] Hot reload disabled (not in dev environment)")
      {:ok, %{watcher: nil, last_reload: 0}}
    end
  end

  defp init_watcher do
    existing_dirs = Enum.filter(@watch_dirs, &File.dir?/1)

    case Application.ensure_loaded(:file_system) do
      :ok when existing_dirs != [] ->
        {:ok, watcher_pid} = FileSystem.start_link(dirs: existing_dirs)
        FileSystem.subscribe(watcher_pid)
        Logger.info("[Nex.Reloader] Watching for file changes in #{inspect(existing_dirs)}")
        {:ok, %{watcher: watcher_pid, last_reload: 0}}

      :ok ->
        Logger.warning("[Nex.Reloader] No watch directories found")
        {:ok, %{watcher: nil, last_reload: 0}}

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

      # Clear route cache so new routes are discovered
      Nex.RouteDiscovery.clear_cache()

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
