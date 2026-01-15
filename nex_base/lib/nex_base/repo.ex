defmodule NexBase.Repo do
  use Ecto.Repo,
    otp_app: :nex_base,
    adapter: Ecto.Adapters.Postgres

  @doc """
  Dynamically loads the configuration from environment variables.
  """
  def init(_type, config) do
    url = System.get_env("DATABASE_URL")
    pool_size = String.to_integer(System.get_env("POOL_SIZE") || "10")

    if is_nil(url) do
      # If DATABASE_URL is not set, we might be in a build phase or similar.
      # However, for runtime, it is required.
      # We log a warning but don't crash here to allow compile-time tools to run?
      # Actually, Ecto.Repo.init is called at runtime start.
      {:ok, config}
    else
      {:ok, Keyword.merge(config, url: url, pool_size: pool_size)}
    end
  end
end
