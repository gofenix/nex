defmodule NexBase.Repo do
  @moduledoc """
  Facade module that delegates to the active adapter-specific Repo.

  The actual Repo module is determined by the adapter chosen during
  `NexBase.init/1` (auto-detected from the URL scheme).

  - `postgres://` → `NexBase.Repo.Postgres`
  - `sqlite://`   → `NexBase.Repo.SQLite`

  Users should use `NexBase.Repo` in their supervision tree:

      children = [{NexBase.Repo, []}]

  This module forwards `start_link/1`, `child_spec/1`, and common Repo
  functions to the underlying adapter Repo.
  """

  @doc "Returns the currently active Repo module based on adapter config."
  def repo do
    case Application.get_env(:nex_base, :adapter, :postgres) do
      :postgres -> NexBase.Repo.Postgres
      :sqlite -> NexBase.Repo.SQLite
    end
  end

  def child_spec(opts) do
    repo().child_spec(opts)
  end

  def start_link(opts \\ []) do
    repo().start_link(opts)
  end

  # Delegate common Ecto.Repo functions
  def all(queryable, opts \\ []), do: repo().all(queryable, opts)
  def one(queryable, opts \\ []), do: repo().one(queryable, opts)
  def one!(queryable, opts \\ []), do: repo().one!(queryable, opts)
  def insert_all(source, entries, opts \\ []), do: repo().insert_all(source, entries, opts)
  def update_all(queryable, updates, opts \\ []), do: repo().update_all(queryable, updates, opts)
  def delete_all(queryable, opts \\ []), do: repo().delete_all(queryable, opts)
end
