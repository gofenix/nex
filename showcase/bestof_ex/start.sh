#!/bin/sh
set -e

echo "==> Running database migrations..."
mix run priv/repo/migrations/001_create_tables.exs

echo "==> Starting server..."
exec mix nex.start
