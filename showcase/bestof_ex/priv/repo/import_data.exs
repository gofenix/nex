Nex.Env.init()
NexBase.init(url: Nex.Env.get(:database_url), start: true)

IO.puts("Importing projects...")
projects = [
  %{name: "anoma", full_name: "anoma/anoma", description: "Reference implementation of Anoma", repo_url: "https://github.com/anoma/anoma", homepage_url: "https://anoma.net", avatar_url: "https://avatars.githubusercontent.com/u/87261362?v=4", stars: 34072, open_issues: 137, pushed_at: "2026-02-10T14:45:49", license: "MIT", added_at: "2026-02-08T13:57:56"},
  %{name: "elixir", full_name: "elixir-lang/elixir", description: "Elixir is a dynamic, functional language for building scalable and maintainable applications", repo_url: "https://github.com/elixir-lang/elixir", homepage_url: "https://elixir-lang.org/", avatar_url: "https://avatars.githubusercontent.com/u/1481354?v=4", stars: 26355, open_issues: 28, pushed_at: "2026-02-09T11:49:54", license: "Apache-2.0", added_at: "2026-02-08T13:57:56"},
  %{name: "analytics", full_name: "plausible/analytics", description: "Simple, open source, lightweight and privacy-friendly web analytics alternative to Google Analytics.", repo_url: "https://github.com/plausible/analytics", homepage_url: "https://plausible.io", avatar_url: "https://avatars.githubusercontent.com/u/54802774?v=4", stars: 24203, open_issues: 52, pushed_at: "2026-02-10T14:57:37", license: "AGPL-3.0", added_at: "2026-02-08T13:57:56"},
  %{name: "phoenix", full_name: "phoenixframework/phoenix", description: "Peace of mind from prototype to production", repo_url: "https://github.com/phoenixframework/phoenix", homepage_url: "https://www.phoenixframework.org", avatar_url: "https://avatars.githubusercontent.com/u/6510388?v=4", stars: 22791, open_issues: 49, pushed_at: "2026-02-04T13:25:39", license: "MIT", added_at: "2026-02-08T13:57:56"},
  %{name: "awesome-elixir", full_name: "h4cc/awesome-elixir", description: "A curated list of amazingly awesome Elixir and Erlang libraries, resources and shiny things.", repo_url: "https://github.com/h4cc/awesome-elixir", homepage_url: "https://twitter.com/AwesomeElixir", avatar_url: "https://avatars.githubusercontent.com/u/2981491?v=4", stars: 13083, open_issues: 8, pushed_at: "2025-10-12T18:06:13", license: "MIT", added_at: "2026-02-08T13:57:56"},
  %{name: "electric", full_name: "electric-sql/electric", description: "Read-path sync engine for Postgres that handles partial replication, data delivery and fan-out.", repo_url: "https://github.com/electric-sql/electric", homepage_url: "https://electric-sql.com", avatar_url: "https://avatars.githubusercontent.com/u/96433696?v=4", stars: 9868, open_issues: 237, pushed_at: "2026-02-10T15:11:13", license: "Apache-2.0", added_at: "2026-02-08T13:57:56"},
  %{name: "firezone", full_name: "firezone/firezone", description: "Enterprise-ready zero-trust access platform built on WireGuard®.", repo_url: "https://github.com/firezone/firezone", homepage_url: "https://www.firezone.dev", avatar_url: "https://avatars.githubusercontent.com/u/87211124?v=4", stars: 8393, open_issues: 475, pushed_at: "2026-02-10T13:08:25", license: "Apache-2.0", added_at: "2026-02-08T13:57:56"},
  %{name: "teslamate", full_name: "teslamate-org/teslamate", description: "A self-hosted data logger for your Tesla", repo_url: "https://github.com/teslamate-org/teslamate", homepage_url: "https://docs.teslamate.org", avatar_url: "https://avatars.githubusercontent.com/u/150616486?v=4", stars: 7620, open_issues: 61, pushed_at: "2026-02-10T14:11:35", license: "MIT", added_at: "2026-02-08T13:57:56"},
  %{name: "realtime", full_name: "supabase/realtime", description: "Broadcast, Presence, and Postgres Changes via WebSockets", repo_url: "https://github.com/supabase/realtime", homepage_url: "https://supabase.com/realtime", avatar_url: "https://avatars.githubusercontent.com/u/54469796?v=4", stars: 7483, open_issues: 56, pushed_at: "2026-02-10T13:53:23", license: "Apache-2.0", added_at: "2026-02-08T13:57:56"},
  %{name: "phoenix_live_view", full_name: "phoenixframework/phoenix_live_view", description: "Rich, real-time user experiences with server-rendered HTML", repo_url: "https://github.com/phoenixframework/phoenix_live_view", homepage_url: "https://hex.pm/packages/phoenix_live_view", avatar_url: "https://avatars.githubusercontent.com/u/6510388?v=4", stars: 6719, open_issues: 77, pushed_at: "2026-02-09T17:48:37", license: "MIT", added_at: "2026-02-08T13:57:56"},
  %{name: "ecto", full_name: "elixir-ecto/ecto", description: "A toolkit for data mapping and language integrated query.", repo_url: "https://github.com/elixir-ecto/ecto", homepage_url: "https://hexdocs.pm/ecto", avatar_url: "https://avatars.githubusercontent.com/u/19973437?v=4", stars: 6434, open_issues: 10, pushed_at: "2026-01-30T17:05:38", license: "Apache-2.0", added_at: "2026-02-08T13:57:56"},
  %{name: "papercups", full_name: "papercups-io/papercups", description: "Open-source live customer chat", repo_url: "https://github.com/papercups-io/papercups", homepage_url: "https://app.papercups.io/demo", avatar_url: "https://avatars.githubusercontent.com/u/68310464?v=4", stars: 5922, open_issues: 173, pushed_at: "2024-02-15T05:21:47", license: "MIT", added_at: "2026-02-08T13:57:57"},
  %{name: "livebook", full_name: "livebook-dev/livebook", description: "Automate code & data workflows with interactive Elixir notebooks", repo_url: "https://github.com/livebook-dev/livebook", homepage_url: "https://livebook.dev", avatar_url: "https://avatars.githubusercontent.com/u/87464290?v=4", stars: 5695, open_issues: 29, pushed_at: "2026-02-10T14:46:45", license: "Apache-2.0", added_at: "2026-02-08T13:57:57"},
  %{name: "credo", full_name: "rrrene/credo", description: "A static code analysis tool for the Elixir language with a focus on code consistency and teaching.", repo_url: "https://github.com/rrrene/credo", homepage_url: "http://credo-ci.org/", avatar_url: "https://avatars.githubusercontent.com/u/311914?v=4", stars: 5140, open_issues: 31, pushed_at: "2026-02-08T19:53:01", license: "MIT", added_at: "2026-02-08T13:57:57"}
]

Enum.each(projects, fn p ->
  {:ok, _} = NexBase.sql("""
    INSERT INTO projects (name, full_name, description, repo_url, homepage_url, avatar_url, stars, open_issues, pushed_at, license, added_at, created_at, updated_at)
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
  """, [p.name, p.full_name, p.description, p.repo_url, p.homepage_url, p.avatar_url, p.stars, p.open_issues, p.pushed_at, p.license, p.added_at, p.added_at, p.added_at])
  IO.puts("Inserted: #{p.name}")
end)

IO.puts("\nImporting tags...")
tags = [
  %{name: "Crypto", slug: "crypto"},
  %{name: "Database", slug: "database"},
  %{name: "Real-time", slug: "real-time"},
  %{name: "Web Framework", slug: "web-framework"},
  %{name: "Deployment", slug: "deployment"},
  %{name: "Monitoring", slug: "monitoring"},
  %{name: "DevTools", slug: "devtools"}
]

Enum.each(tags, fn t ->
  {:ok, _} = NexBase.sql("INSERT INTO tags (name, slug) VALUES ($1, $2)", [t.name, t.slug])
  IO.puts("Inserted: #{t.name}")
end)

IO.puts("\nImporting project_tags...")
project_tags = [
  %{project_id: 1, tag_id: 1},
  %{project_id: 6, tag_id: 2},
  %{project_id: 7, tag_id: 3},
  %{project_id: 7, tag_id: 4},
  %{project_id: 13, tag_id: 4},
  %{project_id: 13, tag_id: 3},
  %{project_id: 12, tag_id: 4},
  %{project_id: 12, tag_id: 5},
  %{project_id: 4, tag_id: 4},
  %{project_id: 4, tag_id: 3},
  %{project_id: 3, tag_id: 4},
  %{project_id: 3, tag_id: 2},
  %{project_id: 3, tag_id: 6},
  %{project_id: 14, tag_id: 7},
  %{project_id: 9, tag_id: 2},
  %{project_id: 9, tag_id: 3},
  %{project_id: 9, tag_id: 4},
  %{project_id: 8, tag_id: 5}
]

Enum.each(project_tags, fn pt ->
  {:ok, _} = NexBase.sql("INSERT INTO project_tags (project_id, tag_id) VALUES ($1, $2)", [pt.project_id, pt.tag_id])
  IO.puts("Inserted project_tag: #{pt.project_id} -> #{pt.tag_id}")
end)

IO.puts("\n✅ Import completed!")
