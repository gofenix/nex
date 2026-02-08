if Code.ensure_loaded?(Ecto.Adapters.SQLite3) do
  defmodule NexBase.Repo.SQLite do
    use Ecto.Repo,
      otp_app: :nex_base,
      adapter: Ecto.Adapters.SQLite3

    def init(_type, config) do
      repo_config = Application.get_env(:nex_base, :repo_config, [])
      {:ok, Keyword.merge(config, repo_config)}
    end
  end
end
