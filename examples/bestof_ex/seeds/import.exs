# seeds/import.exs
# Import seed data using NexBase

Nex.Env.init()
NexBase.init(url: Nex.Env.get(:database_url), ssl: true, start: true)

IO.puts("🚀 Importing seed data...")
IO.puts("----------------------------------------")

try do
  tags = [
    {"Web Framework", "web-framework"},
    {"Database", "database"},
    {"Real-time", "realtime"},
    {"GraphQL", "graphql"},
    {"Background Job", "background-job"},
    {"Testing", "testing"},
    {"Authentication", "auth"},
    {"HTTP Client", "http-client"},
    {"Deployment", "deployment"},
    {"Monitoring", "monitoring"},
    {"CLI", "cli"},
    {"Parsing", "parsing"},
    {"Crypto", "crypto"},
    {"DevTools", "devtools"},
    {"Machine Learning", "ml"}
  ]

  projects = [
    %{name: "Phoenix", description: "Productive. Reliable. Fast. A web framework that does not compromise on speed and maintainability.", repo_url: "https://github.com/phoenixframework/phoenix", homepage_url: "https://www.phoenixframework.org", stars: 22000},
    %{name: "Ecto", description: "A toolkit for data mapping and language integrated query for Elixir.", repo_url: "https://github.com/elixir-ecto/ecto", homepage_url: "https://hexdocs.pm/ecto", stars: 7500},
    %{name: "LiveView", description: "Rich, real-time user experiences with server-rendered HTML.", repo_url: "https://github.com/phoenixframework/phoenix_live_view", homepage_url: "https://hexdocs.pm/phoenix_live_view", stars: 6500},
    %{name: "Absinthe", description: "The GraphQL toolkit for Elixir.", repo_url: "https://github.com/absinthe-graphql/absinthe", homepage_url: "https://absinthe-graphql.org", stars: 4200},
    %{name: "Nerves", description: "Craft and deploy bulletproof embedded software in Elixir.", repo_url: "https://github.com/nerves-project/nerves", homepage_url: "https://nerves-project.org", stars: 2300},
    %{name: "Nx", description: "Multi-dimensional tensors Elixir lib with multi-staged compilation (CPU/GPU).", repo_url: "https://github.com/elixir-nx/nx", homepage_url: "https://hexdocs.pm/nx", stars: 2600},
    %{name: "Broadway", description: "Concurrent and multi-stage data ingestion and data processing with Elixir.", repo_url: "https://github.com/dashbitco/broadway", homepage_url: "https://hexdocs.pm/broadway", stars: 2800},
    %{name: "Oban", description: "Robust job processing in Elixir, backed by modern PostgreSQL and SQLite3.", repo_url: "https://github.com/sorentwo/oban", homepage_url: "https://hexdocs.pm/oban", stars: 3100},
    %{name: "Ash", description: "A declarative, resource-oriented application framework for Elixir.", repo_url: "https://github.com/ash-project/ash", homepage_url: "https://ash-hq.org", stars: 1600},
    %{name: "Livebook", description: "Automate code & data workflows with interactive Elixir notebooks.", repo_url: "https://github.com/livebook-dev/livebook", homepage_url: "https://livebook.dev", stars: 5000},
    %{name: "Tesla", description: "The flexible HTTP client library for Elixir, with support for middleware.", repo_url: "https://github.com/elixir-tesla/tesla", homepage_url: "https://hexdocs.pm/tesla", stars: 2000},
    %{name: "ExUnit", description: "Unit testing framework shipped with Elixir.", repo_url: "https://github.com/elixir-lang/elixir", homepage_url: "https://hexdocs.pm/ex_unit", stars: 24000},
    %{name: "Credo", description: "A static code analysis tool for the Elixir language.", repo_url: "https://github.com/rrrene/credo", homepage_url: "https://hexdocs.pm/credo", stars: 4900},
    %{name: "Dialyxir", description: "Mix tasks to simplify use of Dialyzer in Elixir projects.", repo_url: "https://github.com/jeremyjh/dialyxir", homepage_url: "https://hexdocs.pm/dialyxir", stars: 1700},
    %{name: "ExMachina", description: "Create test data for Elixir applications.", repo_url: "https://github.com/beam-community/ex_machina", homepage_url: "https://hexdocs.pm/ex_machina", stars: 1900},
    %{name: "Guardian", description: "An authentication library for use with Elixir applications.", repo_url: "https://github.com/ueberauth/guardian", homepage_url: "https://hexdocs.pm/guardian", stars: 3400},
    %{name: "Pow", description: "Robust, modular, and extendable user authentication system for Phoenix.", repo_url: "https://github.com/pow-auth/pow", homepage_url: "https://hexdocs.pm/pow", stars: 1600},
    %{name: "Swoosh", description: "Compose, deliver and test your emails easily in Elixir.", repo_url: "https://github.com/swoosh/swoosh", homepage_url: "https://hexdocs.pm/swoosh", stars: 1500},
    %{name: "Finch", description: "An HTTP client with a focus on performance, built on top of Mint and NimblePool.", repo_url: "https://github.com/sneako/finch", homepage_url: "https://hexdocs.pm/finch", stars: 1300},
    %{name: "Req", description: "Batteries-included HTTP client for Elixir.", repo_url: "https://github.com/wojtekmach/req", homepage_url: "https://hexdocs.pm/req", stars: 1000},
    %{name: "Bandit", description: "A pure Elixir HTTP server for Plug & WebSocket applications.", repo_url: "https://github.com/mtrudel/bandit", homepage_url: "https://hexdocs.pm/bandit", stars: 1700},
    %{name: "Fly.io", description: "Elixir clustering and deployment tools for Fly.io.", repo_url: "https://github.com/superfly/fly_postgres_elixir", homepage_url: "https://fly.io/docs/elixir", stars: 500},
    %{name: "Bumblebee", description: "Pre-trained Neural Network models in Axon for text, image, and audio.", repo_url: "https://github.com/elixir-nx/bumblebee", homepage_url: "https://hexdocs.pm/bumblebee", stars: 1300},
    %{name: "Commanded", description: "Use Commanded to build your own Elixir applications following the CQRS/ES pattern.", repo_url: "https://github.com/commanded/commanded", homepage_url: "https://hexdocs.pm/commanded", stars: 1800},
    %{name: "Membrane", description: "Multimedia processing framework for Elixir.", repo_url: "https://github.com/membraneframework/membrane_core", homepage_url: "https://membrane.stream", stars: 1100}
  ]

  project_tags = [
    {"Phoenix", "web-framework"},
    {"Phoenix", "realtime"},
    {"Ecto", "database"},
    {"LiveView", "web-framework"},
    {"LiveView", "realtime"},
    {"Absinthe", "graphql"},
    {"Absinthe", "web-framework"},
    {"Nerves", "deployment"},
    {"Nx", "ml"},
    {"Broadway", "background-job"},
    {"Oban", "background-job"},
    {"Ash", "web-framework"},
    {"Livebook", "devtools"},
    {"Livebook", "ml"},
    {"Tesla", "http-client"},
    {"ExUnit", "testing"},
    {"Credo", "devtools"},
    {"Credo", "testing"},
    {"Dialyxir", "devtools"},
    {"ExMachina", "testing"},
    {"Guardian", "auth"},
    {"Pow", "auth"},
    {"Swoosh", "http-client"},
    {"Finch", "http-client"},
    {"Req", "http-client"},
    {"Bandit", "web-framework"},
    {"Bandit", "deployment"},
    {"Bumblebee", "ml"},
    {"Commanded", "database"},
    {"Membrane", "realtime"}
  ]

  # 1) Insert tags
  Enum.each(tags, fn {name, slug} ->
    NexBase.from("tags") |> NexBase.insert(%{name: name, slug: slug}) |> NexBase.run()
    IO.puts("  ✓ Tag: #{name}")
  end)

  # 2) Insert projects
  Enum.each(projects, fn p ->
    NexBase.from("projects") |> NexBase.insert(p) |> NexBase.run()
    IO.puts("  ✓ Project: #{p.name}")
  end)

  # 3) Link project_tags
  Enum.each(project_tags, fn {project_name, tag_slug} ->
    with {:ok, [%{id: pid}]} <- NexBase.from("projects") |> NexBase.eq(:name, project_name) |> NexBase.select([:id]) |> NexBase.run(),
         {:ok, [%{id: tid}]} <- NexBase.from("tags") |> NexBase.eq(:slug, tag_slug) |> NexBase.select([:id]) |> NexBase.run() do
      NexBase.from("project_tags") |> NexBase.insert(%{project_id: pid, tag_id: tid}) |> NexBase.run()
      IO.puts("  ✓ #{project_name} → #{tag_slug}")
    else
      _ -> IO.puts("  ✗ Failed: #{project_name} → #{tag_slug}")
    end
  end)

  # 4) Generate today's stats
  today = Date.to_iso8601(Date.utc_today())
  {:ok, all} = NexBase.from("projects") |> NexBase.select([:id, :stars]) |> NexBase.run()

  Enum.each(all, fn %{id: id, stars: stars} ->
    NexBase.from("project_stats") |> NexBase.insert(%{project_id: id, stars: stars, recorded_at: today}) |> NexBase.run()
  end)

  IO.puts("----------------------------------------")
  IO.puts("✅ Seed completed! (#{length(projects)} projects, #{length(tags)} tags)")

rescue
  e ->
    IO.puts("✗ Error: #{inspect(e)}")
    System.halt(1)
end
