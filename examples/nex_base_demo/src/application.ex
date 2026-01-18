defmodule NexBaseDemo.Application do
  use Application

  @impl true
  def start(_type, _args) do
    # Load environment variables from .env file in project root
    env_file = System.get_env("ENV_FILE") || ".env"
    if File.exists?(env_file) do
      Dotenvy.source!(env_file)
    end

    # Initialize database schema
    init_database()

    children = [
      NexBase.Repo
    ]
    opts = [strategy: :one_for_one, name: NexBaseDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp init_database do
    # Create tasks table if it doesn't exist
    create_table_sql = """
    CREATE TABLE IF NOT EXISTS tasks (
      id SERIAL PRIMARY KEY,
      title TEXT NOT NULL,
      completed BOOLEAN DEFAULT FALSE,
      inserted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    )
    """

    try do
      NexBase.query!(create_table_sql, [])
      IO.puts("✓ Tasks table initialized")
    rescue
      e ->
        IO.puts("⚠ Could not initialize tasks table: #{inspect(e)}")
    end
  end
end
