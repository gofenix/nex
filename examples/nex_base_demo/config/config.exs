import Config

config :nex_base_demo, NexBaseDemo.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool_size: 10
