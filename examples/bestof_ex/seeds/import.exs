# seeds/import.exs
# Load .env file manually
env_file = ".env"
if File.exists?(env_file) do
  File.read!(env_file)
  |> String.split("\n")
  |> Enum.each(fn line ->
    line = String.trim(line)
    unless String.starts_with?(line, "#") or line == "" do
      case String.split(line, "=", parts: 2) do
        [key, value] ->
          key = String.trim(key)
          value = String.trim(value)
          System.put_env(key, value)
        _ -> :ok
      end
    end
  end)
else
  IO.puts("⚠️  .env file not found")
  System.halt(1)
end

url = System.get_env("DATABASE_URL")

if is_nil(url) or url == "" do
  IO.puts("⚠️  DATABASE_URL not set")
  System.halt(1)
end

# Parse URL into components
regex = ~r/postgresql:\/\/([^:]+):([^@]+)@([^:]+):(\d+)\/(.+)/
case Regex.run(regex, url) do
  [_, username, password, hostname, port, database] ->
    IO.puts("Connecting to #{hostname}:#{port}/#{database}")

    # Start Postgrex directly
    {:ok, conn} = Postgrex.start_link(
      hostname: hostname,
      port: String.to_integer(port),
      username: username,
      password: password,
      database: database
    )

    IO.puts("Connected!")

    # Helper functions
    insert_tag = fn name, slug ->
      Postgrex.query!(conn, "INSERT INTO tags (name, slug) VALUES ($1, $2) ON CONFLICT DO NOTHING", [name, slug])
    end

    insert_project = fn name, description, repo_url, homepage_url, stars ->
      Postgrex.query!(conn, "INSERT INTO projects (name, description, repo_url, homepage_url, stars) VALUES ($1, $2, $3, $4, $5) ON CONFLICT DO NOTHING", [name, description, repo_url, homepage_url, stars])
    end

    get_project_id = fn name ->
      case Postgrex.query!(conn, "SELECT id FROM projects WHERE name = $1", [name]).rows do
        [[id]] -> id
        _ -> nil
      end
    end

    get_tag_id = fn slug ->
      case Postgrex.query!(conn, "SELECT id FROM tags WHERE slug = $1", [slug]).rows do
        [[id]] -> id
        _ -> nil
      end
    end

    insert_project_tag = fn project_id, tag_id ->
      Postgrex.query!(conn, "INSERT INTO project_tags (project_id, tag_id) VALUES ($1, $2) ON CONFLICT DO NOTHING", [project_id, tag_id])
    end

    # 1) 导入 tags
    Enum.each(tags, fn {name, slug} ->
      insert_tag.(name, slug)
      IO.puts("Inserted tag: #{name}")
    end)

    # 2) 导入 projects
    Enum.each(projects, fn p ->
      insert_project.(p.name, p.description, p.repo_url, p.homepage_url, p.stars)
      IO.puts("Inserted project: #{p.name}")
    end)

    # 3) 导入 project_tags
    Enum.each(project_tags, fn {project_name, tag_slug} ->
      project_id = get_project_id.(project_name)
      tag_id = get_tag_id.(tag_slug)
      if project_id && tag_id do
        insert_project_tag.(project_id, tag_id)
        IO.puts("Linked #{project_name} -> #{tag_slug}")
      end
    end)

    # 4) 生成今天的 stats
    today = Date.to_iso8601(Date.utc_today())
    {:ok, all_projects} = Postgrex.query!(conn, "SELECT id, stars FROM projects", [])

    Enum.each(all_projects.rows, fn [id, stars] ->
      Postgrex.query!(conn, "INSERT INTO project_stats (project_id, stars, recorded_at) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING", [id, stars, today])
    end)

    IO.puts("Seed completed!")

    # Cleanup
    Postgrex.stop(conn)

  _ ->
    IO.puts("⚠️  Invalid DATABASE_URL format")
    System.halt(1)
end
