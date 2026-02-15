_ = """
 Usage: mix run priv/repo/migrations/002_add_paper_details.exs
"""

Nex.Env.init()
NexBase.init(url: Nex.Env.get(:database_url), start: true)

IO.puts("Adding paper detail fields...")

# Add new columns to papers table
NexBase.query!("""
  ALTER TABLE papers ADD COLUMN prev_paradigm TEXT
""", [])

NexBase.query!("""
  ALTER TABLE papers ADD COLUMN core_contribution TEXT
""", [])

NexBase.query!("""
  ALTER TABLE papers ADD COLUMN core_mechanism TEXT
""", [])

NexBase.query!("""
  ALTER TABLE papers ADD COLUMN why_it_wins TEXT
""", [])

NexBase.query!("""
  ALTER TABLE papers ADD COLUMN subsequent_impact TEXT
""", [])

NexBase.query!("""
  ALTER TABLE papers ADD COLUMN author_destinies TEXT
""", [])

# Add more fields to authors
NexBase.query!("""
  ALTER TABLE authors ADD COLUMN key_papers TEXT
""", [])

NexBase.query!("""
  ALTER TABLE authors ADD COLUMN career_trajectory TEXT
""", [])

NexBase.query!("""
  ALTER TABLE authors ADD COLUMN current_status TEXT
""", [])

IO.puts("Paper detail fields added!")
