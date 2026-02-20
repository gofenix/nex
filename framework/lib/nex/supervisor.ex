defmodule Nex.Supervisor do
  @moduledoc """
  Framework-level supervision tree responsible for managing Nex framework's core processes.

  Supervised processes:
  - `Phoenix.PubSub` - For WebSocket hot reload broadcasting
  - `Nex.Store` - Page-level state storage (page-scoped, cleared on refresh)
  - `Nex.SessionCleaner` - Session store TTL cleanup worker
  - `Nex.Reloader` - Hot reload file watcher

  These processes are completely transparent to users and automatically managed by the framework.
  If any process crashes, it will automatically restart without affecting the user application.
  """

  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # Ensure session ETS table exists before any workers start
    Nex.Session.ensure_table()

    children = [
      # PubSub for hot reload WebSocket communication
      {Phoenix.PubSub, name: Nex.PubSub},
      # Page-level state storage
      Nex.Store,
      # Session store TTL cleanup
      Nex.SessionCleaner,
      # Hot reloader (development environment only)
      Nex.Reloader
    ]

    # one_for_one: If one process crashes, only that process restarts, not others
    Supervisor.init(children, strategy: :one_for_one)
  end
end
