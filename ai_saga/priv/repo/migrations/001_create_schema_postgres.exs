_ = """
PostgreSQL Migration Script
Usage: mix run priv/repo/migrations/001_create_schema_postgres.exs

Prerequisites:
1. Create a free PostgreSQL database on Supabase (https://supabase.com) or Neon (https://neon.tech)
2. Copy the connection string to your .env file
3. Run this migration script
"""

Nex.Env.init()
NexBase.init(url: Nex.Env.get(:database_url), start: true)

IO.puts("Creating PostgreSQL tables...")

# Drop existing tables if they exist (for clean migration)
NexBase.query!("DROP TABLE IF EXISTS paradigm_relations CASCADE", [])
NexBase.query!("DROP TABLE IF EXISTS paper_authors CASCADE", [])
NexBase.query!("DROP TABLE IF EXISTS papers CASCADE", [])
NexBase.query!("DROP TABLE IF EXISTS authors CASCADE", [])
NexBase.query!("DROP TABLE IF EXISTS paradigms CASCADE", [])

# Create paradigms table
NexBase.query!(
  "CREATE TABLE paradigms (\n" <>
  "  id SERIAL PRIMARY KEY,\n" <>
  "  name TEXT NOT NULL UNIQUE,\n" <>
  "  slug TEXT NOT NULL UNIQUE,\n" <>
  "  description TEXT,\n" <>
  "  start_year INTEGER,\n" <>
  "  end_year INTEGER,\n" <>
  "  crisis TEXT,\n" <>
  "  revolution TEXT,\n" <>
  "  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP\n" <>
  ")",
  []
)

# Create authors table
NexBase.query!(
  "CREATE TABLE authors (\n" <>
  "  id SERIAL PRIMARY KEY,\n" <>
  "  name TEXT NOT NULL,\n" <>
  "  slug TEXT NOT NULL UNIQUE,\n" <>
  "  bio TEXT,\n" <>
  "  affiliation TEXT,\n" <>
  "  birth_year INTEGER,\n" <>
  "  first_paper_year INTEGER,\n" <>
  "  influence_score INTEGER DEFAULT 0,\n" <>
  "  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP\n" <>
  ")",
  []
)

# Create papers table with all the new perspective fields
NexBase.query!(
  "CREATE TABLE papers (\n" <>
  "  id SERIAL PRIMARY KEY,\n" <>
  "  title TEXT NOT NULL,\n" <>
  "  slug TEXT NOT NULL UNIQUE,\n" <>
  "  abstract TEXT,\n" <>
  "  arxiv_id TEXT,\n" <>
  "  published_year INTEGER NOT NULL,\n" <>
  "  published_month INTEGER,\n" <>
  "  url TEXT,\n" <>
  "  categories TEXT,\n" <>
  "  citations INTEGER DEFAULT 0,\n" <>
  "\n" <>
  "  history_context TEXT,\n" <>
  "  challenge TEXT,\n" <>
  "  solution TEXT,\n" <>
  "  impact TEXT,\n" <>
  "\n" <>
  "  prev_paradigm TEXT,\n" <>
  "  core_contribution TEXT,\n" <>
  "  core_mechanism TEXT,\n" <>
  "  why_it_wins TEXT,\n" <>
  "  subsequent_impact TEXT,\n" <>
  "  author_destinies TEXT,\n" <>
  "\n" <>
  "  paradigm_id INTEGER REFERENCES paradigms(id),\n" <>
  "  is_paradigm_shift INTEGER DEFAULT 0,\n" <>
  "  shift_trigger TEXT,\n" <>
  "  is_daily_pick INTEGER DEFAULT 0,\n" <>
  "  daily_date TEXT,\n" <>
  "  trend_value TEXT,\n" <>
  "  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,\n" <>
  "  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP\n" <>
  ")",
  []
)

# Create paper_authors junction table
NexBase.query!(
  "CREATE TABLE paper_authors (\n" <>
  "  id SERIAL PRIMARY KEY,\n" <>
  "  paper_id INTEGER NOT NULL REFERENCES papers(id),\n" <>
  "  author_id INTEGER NOT NULL REFERENCES authors(id),\n" <>
  "  author_order INTEGER DEFAULT 1\n" <>
  ")",
  []
)

# Create paradigm_relations table
NexBase.query!(
  "CREATE TABLE paradigm_relations (\n" <>
  "  id SERIAL PRIMARY KEY,\n" <>
  "  parent_id INTEGER NOT NULL REFERENCES paradigms(id),\n" <>
  "  child_id INTEGER NOT NULL REFERENCES paradigms(id),\n" <>
  "  relation_type TEXT DEFAULT 'evolution'\n" <>
  ")",
  []
)

IO.puts("PostgreSQL tables created successfully!")
IO.puts("Run: mix run priv/repo/seeds.exs to populate with data")
