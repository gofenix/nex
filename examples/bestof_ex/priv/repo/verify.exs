Nex.Env.init()
NexBase.init(url: Nex.Env.get(:database_url), ssl: true, prepare: :unnamed, pool_size: 2, start: true)

# Verify counts
{:ok, rows} = NexBase.sql("SELECT COUNT(*) FROM bestofex_projects", [])
IO.puts("Projects: #{hd(rows)["count"]}")

{:ok, rows} = NexBase.sql("SELECT COUNT(*) FROM bestofex_project_stats", [])
IO.puts("Stats: #{hd(rows)["count"]}")

{:ok, rows} = NexBase.sql("SELECT COUNT(*) FROM bestofex_tags", [])
IO.puts("Tags: #{hd(rows)["count"]}")

# Verify INSERT returns {:ok, []}
today = Date.utc_today()
result = NexBase.sql("""
  INSERT INTO bestofex_project_stats (project_id, stars, recorded_at)
  SELECT id, stars, $1
  FROM bestofex_projects
  ON CONFLICT (project_id, recorded_at)
  DO UPDATE SET stars = EXCLUDED.stars
""", [today])
IO.inspect(result, label: "star snapshot upsert")

# Verify homepage query works
{:ok, rows} = NexBase.sql("""
  SELECT p.id, p.name, p.stars,
         COALESCE(p.stars - ps.stars, 0) AS star_delta
  FROM bestofex_projects p
  LEFT JOIN bestofex_project_stats ps
    ON ps.project_id = p.id
    AND ps.recorded_at = CURRENT_DATE - INTERVAL '1 day'
  ORDER BY p.stars DESC
  LIMIT 5
""", [])
IO.puts("\nTop 5 projects:")
Enum.each(rows, fn r ->
  IO.puts("  #{r["name"]}: #{r["stars"]} stars (+#{r["star_delta"]})")
end)

IO.puts("\n✅ All checks passed!")
