Nex.Env.init()

IO.puts("Testing SQLite connection...")

conn = NexBase.init(url: Nex.Env.get(:database_url), pool_size: 1, start: true)

IO.puts("Creating papers table...")

NexBase.query!("""
CREATE TABLE IF NOT EXISTS papers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  abstract TEXT,
  arxiv_id TEXT UNIQUE,
  published_at TEXT,
  url TEXT,
  categories TEXT,
  authors TEXT,
  citations INTEGER DEFAULT 0,
  viewpoint TEXT,
  history_context TEXT,
  paradigm TEXT,
  author_bio TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
)
""", [])

IO.puts("Migrations completed!")
