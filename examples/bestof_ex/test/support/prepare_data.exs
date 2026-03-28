Nex.Env.init()
NexBase.init(url: System.fetch_env!("DATABASE_URL"), start: true)

NexBase.query!(
  """
  CREATE TABLE IF NOT EXISTS bestofex_projects (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    full_name TEXT,
    description TEXT,
    repo_url TEXT NOT NULL UNIQUE,
    homepage_url TEXT,
    avatar_url TEXT,
    stars INTEGER DEFAULT 0,
    open_issues INTEGER DEFAULT 0,
    pushed_at TEXT,
    license TEXT,
    last_commit_at TEXT,
    added_at TEXT DEFAULT CURRENT_TIMESTAMP,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
  )
  """,
  []
)

NexBase.query!(
  """
  CREATE TABLE IF NOT EXISTS bestofex_project_stats (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id INTEGER NOT NULL,
    stars INTEGER NOT NULL,
    recorded_at TEXT NOT NULL
  )
  """,
  []
)

NexBase.query!(
  """
  CREATE TABLE IF NOT EXISTS bestofex_tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE
  )
  """,
  []
)

NexBase.query!(
  """
  CREATE TABLE IF NOT EXISTS bestofex_project_tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id INTEGER NOT NULL,
    tag_id INTEGER NOT NULL
  )
  """,
  []
)

NexBase.query!("DELETE FROM bestofex_project_tags", [])
NexBase.query!("DELETE FROM bestofex_project_stats", [])
NexBase.query!("DELETE FROM bestofex_tags", [])
NexBase.query!("DELETE FROM bestofex_projects", [])

NexBase.query!(
  """
  INSERT INTO bestofex_projects (
    name, full_name, description, repo_url, homepage_url, stars, added_at, created_at, updated_at
  ) VALUES ($1, $2, $3, $4, $5, $6, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
  """,
  [
    "Phoenix Live Dashboard",
    "phoenixframework/phoenix_live_dashboard",
    "Real-time dashboards for Phoenix applications.",
    "https://github.com/phoenixframework/phoenix_live_dashboard",
    "https://hexdocs.pm/phoenix_live_dashboard",
    12_500
  ]
)

NexBase.query!(
  """
  INSERT INTO bestofex_project_stats (project_id, stars, recorded_at)
  VALUES (1, 12400, DATE('now', '-1 day'))
  """,
  []
)

NexBase.query!(
  """
  INSERT INTO bestofex_project_stats (project_id, stars, recorded_at)
  VALUES (1, 12000, DATE('now', 'start of month'))
  """,
  []
)

NexBase.query!(
  """
  INSERT INTO bestofex_tags (name, slug)
  VALUES ($1, $2)
  """,
  ["Dashboard", "dashboard"]
)

NexBase.query!(
  """
  INSERT INTO bestofex_project_tags (project_id, tag_id)
  VALUES (1, 1)
  """,
  []
)
