# NexBase

A fluent PostgreSQL query builder for Elixir, inspired by Supabase's JavaScript client. Build type-safe database queries with a chainable, expressive API.

## Features

- 🔗 **Fluent API** - Chain methods for readable, composable queries
- 🛡️ **Type-Safe** - Leverages Ecto for safe query construction
- 📝 **PostgreSQL First** - Optimized for PostgreSQL with full feature support
- 🎯 **Simple & Minimal** - No magic, just straightforward query building
- 🚀 **Production Ready** - Built on battle-tested Ecto foundation

## Installation

Add `nex_base` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:nex_base, "~> 0.1.0"}
  ]
end
```

Then run `mix deps.get`.

## Quick Start

First, configure your Ecto repository in your application:

```elixir
# lib/my_app/repo.ex
defmodule MyApp.Repo do
  use Ecto.Repo,
    otp_app: :my_app,
    adapter: Ecto.Adapters.Postgres
end
```

Then initialize a client and use NexBase to build queries:

```elixir
# Initialize client (similar to Supabase)
client = NexBase.client(repo: MyApp.Repo)

# Simple select
{:ok, users} = client
|> NexBase.from("users")
|> NexBase.select(["id", "name", "email"])
|> NexBase.eq("active", true)
|> NexBase.run()

# With filters and ordering
{:ok, posts} = client
|> NexBase.from("posts")
|> NexBase.gt("published_at", DateTime.utc_now())
|> NexBase.order(:published_at, :desc)
|> NexBase.limit(10)
|> NexBase.run()

# Insert data
{:ok, result} = client
|> NexBase.from("users")
|> NexBase.insert(%{name: "John", email: "john@example.com"})
|> NexBase.run()

# Update with conditions
{:ok, result} = client
|> NexBase.from("posts")
|> NexBase.eq("id", 123)
|> NexBase.update(%{title: "Updated Title", updated_at: DateTime.utc_now()})
|> NexBase.run()

# Delete with conditions
{:ok, result} = client
|> NexBase.from("posts")
|> NexBase.eq("id", 123)
|> NexBase.delete()
|> NexBase.run()
```

## Supported Filters

- `eq(query, column, value)` - Equality
- `neq(query, column, value)` - Not equal
- `gt(query, column, value)` - Greater than
- `gte(query, column, value)` - Greater than or equal
- `lt(query, column, value)` - Less than
- `lte(query, column, value)` - Less than or equal
- `like(query, column, pattern)` - Pattern matching (case-sensitive)
- `ilike(query, column, pattern)` - Pattern matching (case-insensitive)
- `in(query, column, values)` - Value in list
- `is(query, column, value)` - IS NULL / IS TRUE / IS FALSE

## Documentation

Full documentation is available on [HexDocs](https://hexdocs.pm/nex_base).

