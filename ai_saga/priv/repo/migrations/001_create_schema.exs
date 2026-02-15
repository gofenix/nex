_ = """
 Usage: mix run priv/repo/migrations/001_create_schema.exs
"""

Nex.Env.init()
NexBase.init(url: Nex.Env.get(:database_url), start: true)

IO.puts("Creating tables...")

NexBase.query!("""
  CREATE TABLE IF NOT EXISTS paradigms (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    slug TEXT NOT NULL UNIQUE,
    description TEXT,
    start_year INTEGER,
    end_year INTEGER,
    crisis TEXT,
    revolution TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
  )
""", [])

NexBase.query!("""
  CREATE TABLE IF NOT EXISTS authors (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    bio TEXT,
    affiliation TEXT,
    birth_year INTEGER,
    first_paper_year INTEGER,
    influence_score INTEGER DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
  )
""", [])

NexBase.query!("""
  CREATE TABLE IF NOT EXISTS papers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    abstract TEXT,
    arxiv_id TEXT,
    published_year INTEGER NOT NULL,
    published_month INTEGER,
    url TEXT,
    categories TEXT,
    citations INTEGER DEFAULT 0,
    history_context TEXT,
    challenge TEXT,
    solution TEXT,
    impact TEXT,
    paradigm_id INTEGER,
    is_paradigm_shift INTEGER DEFAULT 0,
    shift_trigger TEXT,
    is_daily_pick INTEGER DEFAULT 0,
    daily_date TEXT,
    trend_value TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (paradigm_id) REFERENCES paradigms(id)
  )
""", [])

NexBase.query!("""
  CREATE TABLE IF NOT EXISTS paper_authors (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    paper_id INTEGER NOT NULL,
    author_id INTEGER NOT NULL,
    author_order INTEGER DEFAULT 1,
    FOREIGN KEY (paper_id) REFERENCES papers(id),
    FOREIGN KEY (author_id) REFERENCES authors(id)
  )
""", [])

NexBase.query!("""
  CREATE TABLE IF NOT EXISTS paradigm_relations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    parent_id INTEGER NOT NULL,
    child_id INTEGER NOT NULL,
    relation_type TEXT DEFAULT 'evolution',
    FOREIGN KEY (parent_id) REFERENCES paradigms(id),
    FOREIGN KEY (child_id) REFERENCES paradigms(id)
  )
""", [])

IO.puts("Tables created!")
