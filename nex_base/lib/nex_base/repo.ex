defmodule NexBase.Repo do
  use Ecto.Repo,
    otp_app: :nex_base,
    adapter: Ecto.Adapters.Postgres

  @doc """
  Dynamically loads configuration.

  Config is read from Application env `:nex_base, :repo_config`,
  which should be set by the caller before starting the Repo.

  ## Example

      Application.put_env(:nex_base, :repo_config, url: "postgres://...", pool_size: 5)
      NexBase.Repo.start_link([])
  """
  def init(_type, config) do
    repo_config = Application.get_env(:nex_base, :repo_config, [])
    {:ok, Keyword.merge(config, repo_config)}
  end
end
