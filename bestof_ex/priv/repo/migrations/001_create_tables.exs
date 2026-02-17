# Connect to database
Nex.Env.init()
NexBase.init(url: Nex.Env.get(:database_url), start: true)

# Create bestofex_projects table
NexBase.query!("""
CREATE TABLE IF NOT EXISTS bestofex_projects (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  full_name TEXT,
  description TEXT,
  repo_url TEXT NOT NULL UNIQUE,
  homepage_url TEXT,
  avatar_url TEXT,
  stars INTEGER DEFAULT 0,
  open_issues INTEGER DEFAULT 0,
  pushed_at TIMESTAMP,
  license TEXT,
  last_commit_at TIMESTAMP,
  added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
""", [])

# Create bestofex_project_stats table
NexBase.query!("""
CREATE TABLE IF NOT EXISTS bestofex_project_stats (
  id SERIAL PRIMARY KEY,
  project_id INTEGER NOT NULL REFERENCES bestofex_projects(id),
  stars INTEGER NOT NULL,
  recorded_at TIMESTAMP NOT NULL,
  UNIQUE(project_id, recorded_at)
)
""", [])

# Create bestofex_tags table
NexBase.query!("""
CREATE TABLE IF NOT EXISTS bestofex_tags (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE
)
""", [])

# Create bestofex_project_tags table
NexBase.query!("""
CREATE TABLE IF NOT EXISTS bestofex_project_tags (
  id SERIAL PRIMARY KEY,
  project_id INTEGER NOT NULL REFERENCES bestofex_projects(id),
  tag_id INTEGER NOT NULL REFERENCES bestofex_tags(id),
  UNIQUE(project_id, tag_id)
)
""", [])

# Create indexes
NexBase.query!("CREATE INDEX IF NOT EXISTS idx_bestofex_projects_stars ON bestofex_projects(stars DESC)", [])
NexBase.query!("CREATE INDEX IF NOT EXISTS idx_bestofex_projects_updated_at ON bestofex_projects(updated_at DESC)", [])
NexBase.query!("CREATE INDEX IF NOT EXISTS idx_bestofex_projects_added_at ON bestofex_projects(added_at DESC)", [])
NexBase.query!("CREATE INDEX IF NOT EXISTS idx_bestofex_project_stats_project_recorded ON bestofex_project_stats(project_id, recorded_at DESC)", [])
NexBase.query!("CREATE UNIQUE INDEX IF NOT EXISTS idx_bestofex_projects_full_name ON bestofex_projects(full_name)", [])
NexBase.query!("CREATE INDEX IF NOT EXISTS idx_bestofex_tags_slug ON bestofex_tags(slug)", [])
NexBase.query!("CREATE INDEX IF NOT EXISTS idx_bestofex_project_tags_project_id ON bestofex_project_tags(project_id)", [])
NexBase.query!("CREATE INDEX IF NOT EXISTS idx_bestofex_project_tags_tag_id ON bestofex_project_tags(tag_id)", [])

IO.puts("Migrations completed!")
