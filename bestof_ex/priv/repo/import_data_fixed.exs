defmodule ImportData do
  # Helper to parse datetime strings
  defp parse_datetime(nil), do: nil
  defp parse_datetime(str) do
    case DateTime.from_iso8601(str) do
      {:ok, dt, _} -> DateTime.to_naive(dt)
      _ ->
        # Try adding seconds if needed
        case DateTime.from_iso8601(str <> ":00") do
          {:ok, dt, _} -> DateTime.to_naive(dt)
          _ -> nil
        end
    end
  end

  def run do
    Nex.Env.init()
    NexBase.init(url: Nex.Env.get(:database_url), start: true)

    # Projects to import (excluding the first one which is already inserted)
    projects = [
      %{name: "elixir", full_name: "elixir-lang/elixir", description: "Elixir is a dynamic, functional language for building scalable and maintainable applications", repo_url: "https://github.com/elixir-lang/elixir", homepage_url: "https://elixir-lang.org/", avatar_url: "https://avatars.githubusercontent.com/u/1481354?v=4", stars: 26355, open_issues: 28, pushed_at: parse_datetime("2026-02-09T11:49:54"), license: "Apache-2.0"},
      %{name: "analytics", full_name: "plausible/analytics", description: "Simple, open source, lightweight and privacy-friendly web analytics alternative to Google Analytics.", repo_url: "https://github.com/plausible/analytics", homepage_url: "https://plausible.io", avatar_url: "https://avatars.githubusercontent.com/u/54802774?v=4", stars: 24203, open_issues: 52, pushed_at: parse_datetime("2026-02-10T14:57:37"), license: "AGPL-3.0"},
      %{name: "phoenix", full_name: "phoenixframework/phoenix", description: "Peace of mind from prototype to production", repo_url: "https://github.com/phoenixframework/phoenix", homepage_url: "https://www.phoenixframework.org", avatar_url: "https://avatars.githubusercontent.com/u/6510388?v=4", stars: 22791, open_issues: 49, pushed_at: parse_datetime("2026-02-04T13:25:39"), license: "MIT"},
      %{name: "awesome-elixir", full_name: "h4cc/awesome-elixir", description: "A curated list of amazingly awesome Elixir and Erlang libraries, resources and shiny things.", repo_url: "https://github.com/h4cc/awesome-elixir", homepage_url: "https://twitter.com/AwesomeElixir", avatar_url: "https://avatars.githubusercontent.com/u/2981491?v=4", stars: 13083, open_issues: 8, pushed_at: parse_datetime("2025-10-12T18:06:13"), license: "MIT"},
      %{name: "electric", full_name: "electric-sql/electric", description: "Read-path sync engine for Postgres that handles partial replication, data delivery and fan-out.", repo_url: "https://github.com/electric-sql/electric", homepage_url: "https://electric-sql.com", avatar_url: "https://avatars.githubusercontent.com/u/96433696?v=4", stars: 9868, open_issues: 237, pushed_at: parse_datetime("2026-02-10T15:11:13"), license: "Apache-2.0"},
      %{name: "firezone", full_name: "firezone/firezone", description: "Enterprise-ready zero-trust access platform built on WireGuard.", repo_url: "https://github.com/firezone/firezone", homepage_url: "https://www.firezone.dev", avatar_url: "https://avatars.githubusercontent.com/u/87211124?v=4", stars: 8393, open_issues: 475, pushed_at: parse_datetime("2026-02-10T13:08:25"), license: "Apache-2.0"},
      %{name: "teslamate", full_name: "teslamate-org/teslamate", description: "A self-hosted data logger for your Tesla", repo_url: "https://github.com/teslamate-org/teslamate", homepage_url: "https://docs.teslamate.org", avatar_url: "https://avatars.githubusercontent.com/u/150616486?v=4", stars: 7620, open_issues: 61, pushed_at: parse_datetime("2026-02-10T14:11:35"), license: "MIT"},
      %{name: "realtime", full_name: "supabase/realtime", description: "Broadcast, Presence, and Postgres Changes via WebSockets", repo_url: "https://github.com/supabase/realtime", homepage_url: "https://supabase.com/realtime", avatar_url: "https://avatars.githubusercontent.com/u/54469796?v=4", stars: 7483, open_issues: 56, pushed_at: parse_datetime("2026-02-10T13:53:23"), license: "Apache-2.0"},
      %{name: "phoenix_live_view", full_name: "phoenixframework/phoenix_live_view", description: "Rich, real-time user experiences with server-rendered HTML", repo_url: "https://github.com/phoenixframework/phoenix_live_view", homepage_url: "https://hex.pm/packages/phoenix_live_view", avatar_url: "https://avatars.githubusercontent.com/u/6510388?v=4", stars: 6719, open_issues: 77, pushed_at: parse_datetime("2026-02-09T17:48:37"), license: "MIT"},
      %{name: "ecto", full_name: "elixir-ecto/ecto", description: "A toolkit for data mapping and language integrated query.", repo_url: "https://github.com/elixir-ecto/ecto", homepage_url: "https://hexdocs.pm/ecto", avatar_url: "https://avatars.githubusercontent.com/u/19973437?v=4", stars: 6434, open_issues: 10, pushed_at: parse_datetime("2026-01-30T17:05:38"), license: "Apache-2.0"},
      %{name: "papercups", full_name: "papercups-io/papercups", description: "Open-source live customer chat", repo_url: "https://github.com/papercups-io/papercups", homepage_url: "https://app.papercups.io/demo", avatar_url: "https://avatars.githubusercontent.com/u/68310464?v=4", stars: 5922, open_issues: 173, pushed_at: parse_datetime("2024-02-15T05:21:47"), license: "MIT"},
      %{name: "livebook", full_name: "livebook-dev/livebook", description: "Automate code & data workflows with interactive Elixir notebooks", repo_url: "https://github.com/livebook-dev/livebook", homepage_url: "https://livebook.dev", avatar_url: "https://avatars.githubusercontent.com/u/87464290?v=4", stars: 5695, open_issues: 29, pushed_at: parse_datetime("2026-02-10T14:46:45"), license: "Apache-2.0"},
      %{name: "credo", full_name: "rrrene/credo", description: "A static code analysis tool for the Elixir language with a focus on code consistency and teaching.", repo_url: "https://github.com/rrrene/credo", homepage_url: "http://credo-ci.org/", avatar_url: "https://avatars.githubusercontent.com/u/311914?v=4", stars: 5140, open_issues: 31, pushed_at: parse_datetime("2026-02-08T19:53:01"), license: "MIT"}
    ]

    IO.puts("Importing projects...")
    Enum.each(projects, fn p ->
      params = [p.name, p.full_name, p.description, p.repo_url, p.homepage_url, p.avatar_url, p.stars, p.open_issues, p.pushed_at, p.license]
      case NexBase.sql("""
        INSERT INTO projects (name, full_name, description, repo_url, homepage_url, avatar_url, stars, open_issues, pushed_at, license)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
        ON CONFLICT (repo_url) DO NOTHING
      """, params) do
        {:ok, _} -> IO.puts("✓ #{p.name}")
        {:error, e} -> IO.puts("✗ #{p.name}: #{inspect(e)}")
      end
    end)

    IO.puts("\nImporting project_tags...")
    project_tags = [
      {2, 1}, {6, 2}, {7, 3}, {7, 4}, {13, 4}, {13, 3}, {12, 4}, {12, 5},
      {4, 4}, {4, 3}, {3, 4}, {3, 2}, {3, 6}, {14, 7}, {9, 2}, {9, 3},
      {9, 4}, {8, 5}
    ]

    Enum.each(project_tags, fn {project_id, tag_id} ->
      case NexBase.sql("""
        INSERT INTO project_tags (project_id, tag_id)
        VALUES ($1, $2)
        ON CONFLICT (project_id, tag_id) DO NOTHING
      """, [project_id, tag_id]) do
        {:ok, _} -> IO.puts("✓ Tag #{project_id} -> #{tag_id}")
        {:error, e} -> IO.puts("✗ Tag #{project_id} -> #{tag_id}: #{inspect(e)}")
      end
    end)

    # Check final counts
    {:ok, pc} = NexBase.sql("SELECT COUNT(*) FROM projects", [])
    {:ok, tc} = NexBase.sql("SELECT COUNT(*) FROM tags", [])
    {:ok, pt} = NexBase.sql("SELECT COUNT(*) FROM project_tags", [])

    IO.puts("\nFinal counts:")
    IO.puts("Projects: #{hd(pc)["count"]}")
    IO.puts("Tags: #{hd(tc)["count"]}")
    IO.puts("Project_tags: #{hd(pt)["count"]}")

    IO.puts("\n✅ Import completed!")
  end
end

ImportData.run()
