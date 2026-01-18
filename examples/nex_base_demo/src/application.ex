defmodule NexBaseDemo.Application do
  use Application

  @impl true
  def start(_type, _args) do
    # Load environment variables from .env file in project root FIRST
    project_root = File.cwd!()
    env_file = Path.join(project_root, System.get_env("ENV_FILE") || ".env")
    if File.exists?(env_file) do
      File.read!(env_file)
      |> String.split("\n")
      |> Enum.each(fn line ->
        line = String.trim(line)
        unless String.starts_with?(line, "#") or line == "" do
          case String.split(line, "=", parts: 2) do
            [key, value] ->
              System.put_env(String.trim(key), String.trim(value))
            _ -> :ok
          end
        end
      end)
    end

    # Don't start Repo if in script mode (SCRIPT_MODE env var set)
    children = if System.get_env("SCRIPT_MODE") == "true" do
      []
    else
      [NexBaseDemo.Repo]
    end

    opts = [strategy: :one_for_one, name: NexBaseDemo.Supervisor]

    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        # Initialize database schema AFTER Repo is started (only if not in script mode)
        unless System.get_env("SCRIPT_MODE") == "true" do
          init_database()
        end
        {:ok, pid}
      error ->
        error
    end
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
      NexBase.query!(create_table_sql, [], repo: NexBaseDemo.Repo)
      IO.puts("✓ Tasks table initialized")
    rescue
      e ->
        IO.puts("⚠ Could not initialize tasks table: #{inspect(e)}")
    end
  end
end
