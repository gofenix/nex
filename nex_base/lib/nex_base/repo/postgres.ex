defmodule NexBase.Repo.Postgres do
  use Ecto.Repo,
    otp_app: :nex_base,
    adapter: Ecto.Adapters.Postgres

  def init(_type, config) do
    repo_config = Application.get_env(:nex_base, :repo_config, [])
    {:ok, Keyword.merge(config, repo_config)}
  end
end
