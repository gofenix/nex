defmodule BestofEx.Syncer do
  @moduledoc """
  Syncs project data from GitHub into the database.
  Handles upsert of projects, auto-tagging from GitHub topics, and daily star snapshots.
  """

  require Logger

  # GitHub topics → BestofEx tag mapping
  @topic_mapping %{
    "phoenix" => "Web Framework",
    "phoenix-framework" => "Web Framework",
    "web-framework" => "Web Framework",
    "plug" => "Web Framework",
    "ecto" => "Database",
    "database" => "Database",
    "postgresql" => "Database",
    "sqlite" => "Database",
    "graphql" => "GraphQL",
    "absinthe" => "GraphQL",
    "realtime" => "Real-time",
    "websocket" => "Real-time",
    "channels" => "Real-time",
    "pubsub" => "Real-time",
    "background-jobs" => "Background Job",
    "job-queue" => "Background Job",
    "queue" => "Background Job",
    "testing" => "Testing",
    "test" => "Testing",
    "authentication" => "Authentication",
    "auth" => "Authentication",
    "authorization" => "Authentication",
    "http-client" => "HTTP Client",
    "http" => "HTTP Client",
    "deployment" => "Deployment",
    "docker" => "Deployment",
    "release" => "Deployment",
    "monitoring" => "Monitoring",
    "telemetry" => "Monitoring",
    "metrics" => "Monitoring",
    "cli" => "CLI",
    "command-line" => "CLI",
    "parsing" => "Parsing",
    "parser" => "Parsing",
    "crypto" => "Crypto",
    "cryptography" => "Crypto",
    "encryption" => "Crypto",
    "devtools" => "DevTools",
    "developer-tools" => "DevTools",
    "linter" => "DevTools",
    "formatter" => "DevTools",
    "machine-learning" => "Machine Learning",
    "ml" => "Machine Learning",
    "neural-network" => "Machine Learning",
    "deep-learning" => "Machine Learning",
    "ai" => "Machine Learning",
    "nerves" => "Embedded",
    "embedded" => "Embedded",
    "iot" => "Embedded",
    "liveview" => "Real-time",
    "live-view" => "Real-time"
  }

  @doc """
  Full sync: search GitHub for Elixir repos with stars > 10000,
  upsert all projects, auto-tag, and record today's star snapshot.
  """
  def sync_all do
    Logger.info("[Syncer] Starting full sync...")

    case BestofEx.GitHub.search_elixir_repos() do
      {:ok, repos} ->
        Logger.info("[Syncer] Found #{length(repos)} repos from GitHub")

        Enum.each(repos, fn repo ->
          upsert_project(repo)
          Process.sleep(100)
        end)

        # Auto-tag all projects
        auto_tag_all()

        # Record today's star snapshot
        record_star_snapshots()

        Logger.info("[Syncer] Full sync completed!")
        {:ok, length(repos)}

      {:error, reason} ->
        Logger.error("[Syncer] Sync failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Daily update: fetch latest stars for all existing projects and record snapshots.
  """
  def update_stars do
    Logger.info("[Syncer] Starting daily star update...")

    case NexBase.sql("SELECT id, full_name FROM projects WHERE full_name IS NOT NULL") do
      {:ok, projects} ->
        updated =
          projects
          |> Enum.reduce(0, fn project, count ->
            case BestofEx.GitHub.get_repo(project["full_name"]) do
              {:ok, repo} ->
                NexBase.from("projects")
                |> NexBase.eq(:id, project["id"])
                |> NexBase.update(%{
                  stars: repo["stars"],
                  open_issues: repo["open_issues"],
                  pushed_at: repo["pushed_at"],
                  description: repo["description"],
                  homepage_url: repo["homepage_url"]
                })
                |> NexBase.run()

                # Rate limit: wait 1.5s between requests (40/min safe for 60/h)
                Process.sleep(1500)
                count + 1

              {:error, :rate_limited} ->
                Logger.warning("[Syncer] Rate limited, stopping star update at #{count} projects")
                throw({:rate_limited, count})

              {:error, _} ->
                count
            end
          end)

        record_star_snapshots()
        Logger.info("[Syncer] Updated stars for #{updated} projects")
        {:ok, updated}

      _ ->
        {:error, :no_projects}
    end
  catch
    {:rate_limited, count} ->
      record_star_snapshots()
      Logger.info("[Syncer] Partial update: #{count} projects before rate limit")
      {:ok, count}
  end

  defp upsert_project(repo) do
    # Check if project exists by full_name
    case NexBase.from("projects") |> NexBase.eq(:full_name, repo["full_name"]) |> NexBase.run() do
      {:ok, [existing | _]} ->
        # Update existing
        NexBase.from("projects")
        |> NexBase.eq(:id, existing["id"])
        |> NexBase.update(%{
          name: repo["name"],
          description: repo["description"],
          repo_url: repo["repo_url"],
          homepage_url: repo["homepage_url"],
          stars: repo["stars"],
          avatar_url: repo["avatar_url"],
          open_issues: repo["open_issues"],
          pushed_at: repo["pushed_at"],
          license: repo["license"]
        })
        |> NexBase.run()

        Logger.debug("[Syncer] Updated: #{repo["full_name"]}")

      _ ->
        # Insert new
        NexBase.from("projects")
        |> NexBase.insert(%{
          name: repo["name"],
          full_name: repo["full_name"],
          description: repo["description"],
          repo_url: repo["repo_url"],
          homepage_url: repo["homepage_url"],
          stars: repo["stars"],
          avatar_url: repo["avatar_url"],
          open_issues: repo["open_issues"],
          pushed_at: repo["pushed_at"],
          license: repo["license"]
        })
        |> NexBase.run()

        Logger.info("[Syncer] Added: #{repo["full_name"]} (#{repo["stars"]}⭐)")
    end
  end

  defp auto_tag_all do
    Logger.info("[Syncer] Auto-tagging projects...")

    case NexBase.sql("SELECT id, full_name FROM projects WHERE full_name IS NOT NULL") do
      {:ok, projects} ->
        projects
        |> Enum.each(fn project ->
          auto_tag_project(project)
          Process.sleep(1500)
        end)

      _ ->
        :ok
    end
  end

  defp auto_tag_project(project) do
    case BestofEx.GitHub.get_repo_topics(project["full_name"]) do
      {:ok, topics} ->
        tag_names =
          topics
          |> Enum.map(fn topic -> Map.get(@topic_mapping, topic) end)
          |> Enum.reject(&is_nil/1)
          |> Enum.uniq()

        Enum.each(tag_names, fn tag_name ->
          ensure_tag_and_link(project["id"], tag_name)
        end)

      _ ->
        :ok
    end
  end

  defp ensure_tag_and_link(project_id, tag_name) do
    slug = tag_name |> String.downcase() |> String.replace(~r/[^a-z0-9]+/, "-") |> String.trim("-")

    # Ensure tag exists
    tag_id =
      case NexBase.from("tags") |> NexBase.eq(:slug, slug) |> NexBase.run() do
        {:ok, [tag | _]} ->
          tag["id"]

        _ ->
          NexBase.from("tags") |> NexBase.insert(%{name: tag_name, slug: slug}) |> NexBase.run()

          case NexBase.from("tags") |> NexBase.eq(:slug, slug) |> NexBase.run() do
            {:ok, [tag | _]} -> tag["id"]
            _ -> nil
          end
      end

    # Link project to tag (ignore duplicate)
    if tag_id do
      case NexBase.sql(
             "SELECT id FROM project_tags WHERE project_id = $1 AND tag_id = $2",
             [project_id, tag_id]
           ) do
        {:ok, []} ->
          NexBase.from("project_tags")
          |> NexBase.insert(%{project_id: project_id, tag_id: tag_id})
          |> NexBase.run()

        _ ->
          :ok
      end
    end
  end

  defp record_star_snapshots do
    today = Date.utc_today()

    case NexBase.sql("SELECT id, stars FROM projects") do
      {:ok, projects} ->
        Enum.each(projects, fn p ->
          # Upsert: insert or update today's snapshot
          case NexBase.sql(
                 "SELECT id FROM project_stats WHERE project_id = $1 AND recorded_at = $2",
                 [p["id"], today]
               ) do
            {:ok, []} ->
              NexBase.from("project_stats")
              |> NexBase.insert(%{project_id: p["id"], stars: p["stars"], recorded_at: today})
              |> NexBase.run()

            {:ok, [existing | _]} ->
              NexBase.from("project_stats")
              |> NexBase.eq(:id, existing["id"])
              |> NexBase.update(%{stars: p["stars"]})
              |> NexBase.run()
          end
        end)

      _ ->
        :ok
    end
  end
end
