defmodule Bestofex.Application do
  @moduledoc """
  The Bestofex application.

  ## What Nex Framework Already Does

  When you run `mix nex.dev` or `mix nex.start`, the framework automatically:

  1. **Starts your application** - `Application.ensure_all_started(:bestofex)`
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
  - **Database connections** - `{Bestofex.Repo, []}`
  - **HTTP clients** - `{Finch, name: Bestofex.Finch}` (for calling external APIs)
  - **Background workers** - `{Bestofex.Worker, arg}`
  - **Custom GenServers/Agents** - Your own stateful processes

  ## Example: Adding an HTTP Client

      children = [
        {Finch, name: Bestofex.Finch}
      ]

  Then add to mix.exs:

      {:finch, "~> 0.18"}
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Add your supervised processes here
      # Examples:
      # {Finch, name: Bestofex.Finch},
      # {Bestofex.Repo, []},
      # {Bestofex.Worker, arg}
    ]

    opts = [strategy: :one_for_one, name: Bestofex.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
