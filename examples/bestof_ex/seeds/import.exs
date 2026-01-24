# seeds/import.exs
alias BestofEx.Repo

token = System.get_env("GITHUB_TOKEN") || raise "GITHUB_TOKEN not set"

# GitHub API 调用（使用 Req）
fetch_repo = fn repo_url ->
  %{"org" => org, "repo"} = Regex.named_captures(~r/https:\/\/github\.com\/(?<org>[^\/]+)\/(?<repo>[^\/]+)/, repo_url)
  url = "https://api.github.com/repos/#{org}/#{repo}"

  case Req.get!(url, headers: [{"authorization", "token #{token}"}, {"accept", "application/vnd.github.v3+json"}]) do
    %{status: 200, body: body} -> body
    _ -> nil
  end
end

# 直接在代码中定义项目列表
projects = [
  {"phoenix", "https://github.com/phoenixframework/phoenix"},
  {"ecto", "https://github.com/elixir-ecto/ecto"},
  {"live_view", "https://github.com/phoenixframework/phoenix_live_view"},
  {"absinthe", "https://github.com/absinthe-graphql/absinthe"},
  {"broadway", "https://github.com/dashbitco/broadway"},
  {"oban", "https://github.com/sorentwo/oban"}
]

tags = [
  {"Web Framework", "web-framework"},
  {"ORM", "orm"},
  {"Real-time", "realtime"},
  {"GraphQL", "graphql"},
  {"Background Job", "background-job"},
  {"Testing", "testing"}
]

project_tags = [
  {"phoenix", "web-framework"},
  {"phoenix", "realtime"},
  {"ecto", "orm"},
  {"live_view", "realtime"},
  {"absinthe", "graphql"},
  {"broadway", "background-job"},
  {"oban", "background-job"}
]

# 1) 导入 tags
Enum.each(tags, fn {name, slug} ->
  case Repo.insert("tags", %{name: name, slug: slug}, on_conflict: :nothing) do
    {:ok, _} -> IO.puts("Inserted tag: #{name}")
    {:error, _} -> IO.puts("Tag exists: #{name}")
  end
end)

# 2) 导入 projects（调用 GitHub API）
Enum.each(projects, fn {name, repo_url} ->
  case fetch_repo.(repo_url) do
    nil ->
      IO.puts("Skipping: #{repo_url}")

    repo ->
      params = %{
        name: repo["name"],
        description: repo["description"] || "",
        repo_url: repo["html_url"],
        homepage_url: repo["homepage"] || "",
        stars: repo["stargazers_count"],
        last_commit_at: parse_datetime(repo["pushed_at"])
      }

      case Repo.insert("projects", params, on_conflict: :nothing) do
        {:ok, _} -> IO.puts("Inserted project: #{params.name}")
        {:error, _} ->
          # Update existing
          IO.puts("Project exists: #{params.name}")
      end
  end
end)

# 3) 导入 project_tags
Enum.each(project_tags, fn {project_name, tag_slug} ->
  project = Repo.get_by("projects", name: project_name)
  tag = Repo.get_by("tags", slug: tag_slug)

  if project && tag do
    case Repo.insert("project_tags", %{project_id: project["id"], tag_id: tag["id"]}, on_conflict: :nothing) do
      {:ok, _} -> :ok
      {:error, _} -> :ok
    end
  end
end)

# 4) 生成今天的 stats
today = Date.utc_today()

{:ok, all_projects} = Repo.from("projects") |> Repo.run()

Enum.each(all_projects, fn project ->
  Repo.insert("project_stats", %{
    project_id: project["id"],
    stars: project["stars"],
    recorded_at: to_string(today)
  }, on_conflict: :nothing)
end)

IO.puts("Seed completed!")

defp parse_datetime(nil), do: nil
defp parse_datetime(str) do
  {:ok, datetime, _} = DateTime.from_iso8601(str)
  NaiveDateTime.truncate(datetime, :second)
end

defp to_string(%Date{} = date), do: Date.to_iso8601(date)
defp to_string(other), do: other
