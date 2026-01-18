-- NexBase Demo Schema
-- Run this SQL to create the tasks table

CREATE TABLE IF NOT EXISTS tasks (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  completed BOOLEAN DEFAULT FALSE,
  inserted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create an index on inserted_at for faster sorting
CREATE INDEX IF NOT EXISTS tasks_inserted_at_idx ON tasks(inserted_at DESC);
