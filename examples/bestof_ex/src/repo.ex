defmodule BestofEx.Repo do
  use Ecto.Repo,
    otp_app: :bestof_ex,
    adapter: Ecto.Adapters.Postgres

  @doc """
  Dynamically loads the configuration from environment variables.
  """
  def init(_type, config) do
    url = System.get_env("DATABASE_URL")
    pool_size = String.to_integer(System.get_env("POOL_SIZE") || "10")

    if is_nil(url) do
      {:ok, config}
    else
      {:ok, Keyword.merge(config, url: url, pool_size: pool_size)}
    end
  end
end
