defmodule NexBase.Repo do
  @moduledoc """
  Facade module for starting adapter-specific Repos in supervision trees.

  Supports both single and multi-connection usage:

      # Single connection
      NexBase.init(url: "postgres://localhost/mydb")
      children = [{NexBase.Repo, []}]

      # Multiple connections
      main = NexBase.init(url: "postgres://localhost/main")
      analytics = NexBase.init(url: "postgres://analytics/db")
      children = [{NexBase.Repo, main}, {NexBase.Repo, analytics}]
  """

  alias NexBase.Conn

  def child_spec(%Conn{} = conn) do
    %{
      id: {__MODULE__, conn.name},
      start: {__MODULE__, :start_link, [conn]},
      type: :supervisor
    }
  end

  def child_spec(opts) when is_list(opts) do
    conn = Application.get_env(:nex_base, :default_conn)
    if conn, do: child_spec(conn), else: raise("NexBase not initialized. Call NexBase.init/1 first.")
  end

  def start_link(%Conn{repo_module: repo_mod, name: name}) do
    # When name == repo_mod, this is the default single-connection mode.
    # Ecto registers the process under the module name by default.
    if name == repo_mod do
      repo_mod.start_link([])
    else
      repo_mod.start_link(name: name)
    end
  end

  def start_link(opts) when is_list(opts) do
    conn = Application.get_env(:nex_base, :default_conn)
    if conn, do: start_link(conn), else: raise("NexBase not initialized. Call NexBase.init/1 first.")
  end
end
