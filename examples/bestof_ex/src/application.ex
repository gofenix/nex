defmodule BestofEx.Application do
  @moduledoc """
  The BestofEx application.

  ## What Nex Framework Already Does

  When you run `mix nex.dev` or `mix nex.start`, the framework automatically:

  1. **Starts your application** - `Application.ensure_all_started(:bestof_ex)`
  2. **Starts framework dependencies**:
     - :bandit (HTTP server)
     - :phoenix_html (HEEx templates)
     - :phoenix_live_view (LiveView components)
     - :file_system (hot reload file watcher, dev only)
  3. **Starts Nex.Supervisor** - Framework-level processes:
     - Phoenix.PubSub - Hot reload WebSocket communication
     - Nex.Store - Page-level state storage
     - Nex.Reloader - File watcher (dev only)
  4. **Starts Bandit web server** - Listens on configured port

  ## What This Module Is For

  This is YOUR application's supervision tree.
  Most simple apps don't need any supervised processes here.

  ## When to Add Children

  Add supervised processes only when you need:
  - **Database connections** - `{BestofEx.Repo, []}`
  - **HTTP clients** - `{Finch, name: BestofEx.Finch}` (for calling external APIs)
  - **Background workers** - `{BestofEx.Worker, arg}`
  - **Custom GenServers/Agents** - Your own stateful processes

  ## Example: Adding an HTTP Client

      children = [
        {Finch, name: BestofEx.Finch}
      ]

  Then add to mix.exs:

      {:finch, "~> 0.18"}
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {BestofEx.Repo, []}
    ]

    opts = [strategy: :one_for_one, name: BestofEx.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
