#!/bin/sh
set -e

echo "==> Checking database..."

# Run migration if DB doesn't exist yet
if [ ! -f /data/bestof_ex.db ]; then
  echo "==> No database found, running migration..."
  mix run priv/repo/migrations/001_create_tables.exs
  echo "==> Migration complete. Importing data from GitHub..."
  mix run seeds/import.exs
  echo "==> Import complete."
else
  echo "==> Database exists, skipping migration."
fi

echo "==> Starting server..."
exec mix nex.start
