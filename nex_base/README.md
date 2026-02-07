# NexBase

A fluent, Supabase-inspired PostgreSQL query builder for Elixir. Schema-less, chainable, built on Ecto.

## Features

- **Fluent API** — Chainable query builder, reads like natural language
- **Schema-less** — Query any table by name, no Ecto schemas needed
- **Raw SQL** — `NexBase.sql/2` for JOINs and complex queries, returns `[%{"col" => val}]`
- **Built on Ecto** — Production-ready, connection pooling, type safety
- **One-line init** — `NexBase.init(url: "...")` handles all config internally

## Installation

```elixir
def deps do
  [
    {:nex_base, "~> 0.1.0"}
  ]
end
```

## Quick Start

### 1. Initialize

```elixir
# In your application.ex
def start(_type, _args) do
  NexBase.init(url: System.get_env("DATABASE_URL"), ssl: true)

  children = [{NexBase.Repo, []}]
  Supervisor.start_link(children, strategy: :one_for_one)
end
```

### 2. Query

```elixir
# Select
{:ok, users} = NexBase.from("users")
|> NexBase.eq(:active, true)
|> NexBase.order(:name, :asc)
|> NexBase.limit(10)
|> NexBase.run()

# Insert
{:ok, _} = NexBase.from("users")
|> NexBase.insert(%{name: "Alice", email: "alice@example.com"})
|> NexBase.run()

# Update
{:ok, _} = NexBase.from("users")
|> NexBase.eq(:id, 1)
|> NexBase.update(%{name: "Bob"})
|> NexBase.run()

# Delete
{:ok, _} = NexBase.from("users")
|> NexBase.eq(:id, 1)
|> NexBase.delete()
|> NexBase.run()
```

### 3. Raw SQL

For JOINs, aggregations, and complex queries:

```elixir
{:ok, rows} = NexBase.sql("""
  SELECT u.name, COUNT(p.id) as post_count
  FROM users u
  LEFT JOIN posts p ON p.user_id = u.id
  WHERE u.active = $1
  GROUP BY u.id
  ORDER BY post_count DESC
""", [true])

# Returns: [%{"name" => "Alice", "post_count" => 42}, ...]
```

## API Reference

### Initialization

| Function | Description |
|----------|-------------|
| `NexBase.init(opts)` | Configure database connection |

**Options for `init/1`:**
- `:url` — Database URL (or falls back to `DATABASE_URL` env var)
- `:ssl` — Enable SSL with `verify: :verify_none` for cloud databases (default: `false`)
- `:pool_size` — Connection pool size (default: `10`)
- `:start` — Start the Repo in-process, for scripts (default: `false`)

### Query Builder

| Function | Description | Example |
|----------|-------------|---------|
| `from(table)` | Start a query | `NexBase.from("users")` |
| `select(q, cols)` | Select columns | `\|> NexBase.select([:id, :name])` |
| `eq(q, col, val)` | Equal | `\|> NexBase.eq(:status, "active")` |
| `neq(q, col, val)` | Not equal | `\|> NexBase.neq(:role, "admin")` |
| `gt(q, col, val)` | Greater than | `\|> NexBase.gt(:age, 18)` |
| `gte(q, col, val)` | Greater or equal | `\|> NexBase.gte(:score, 90)` |
| `lt(q, col, val)` | Less than | `\|> NexBase.lt(:price, 100)` |
| `lte(q, col, val)` | Less or equal | `\|> NexBase.lte(:qty, 50)` |
| `like(q, col, pat)` | LIKE (case-sensitive) | `\|> NexBase.like(:name, "%john%")` |
| `ilike(q, col, pat)` | ILIKE (case-insensitive) | `\|> NexBase.ilike(:email, "%@gmail%")` |
| `in_list(q, col, vals)` | IN list | `\|> NexBase.in_list(:id, [1, 2, 3])` |
| `is(q, col, val)` | IS NULL / IS TRUE | `\|> NexBase.is(:deleted_at, nil)` |
| `order(q, col, dir)` | ORDER BY | `\|> NexBase.order(:created_at, :desc)` |
| `limit(q, n)` | LIMIT | `\|> NexBase.limit(10)` |
| `offset(q, n)` | OFFSET | `\|> NexBase.offset(20)` |
| `range(q, from, to)` | Supabase-style range | `\|> NexBase.range(0, 9)` |
| `single(q)` | Limit to 1 result | `\|> NexBase.single()` |

### Mutations

| Function | Description | Example |
|----------|-------------|---------|
| `insert(q, data)` | Insert row(s) | `\|> NexBase.insert(%{name: "Alice"})` |
| `update(q, data)` | Update matching rows | `\|> NexBase.update(%{name: "Bob"})` |
| `delete(q)` | Delete matching rows | `\|> NexBase.delete()` |
| `upsert(q, data)` | Insert or replace | `\|> NexBase.upsert(%{id: 1, name: "Alice"})` |

### Execution

| Function | Description |
|----------|-------------|
| `run(q)` | Execute query, returns `{:ok, result}` or `{:error, reason}` |
| `sql(sql, params)` | Raw SQL, returns `{:ok, [%{"col" => val}]}` |
| `query(sql, params)` | Raw SQL, returns raw Postgrex result |
| `query!(sql, params)` | Raw SQL, raises on error |
| `rpc(func, params)` | Call a stored procedure |

## Usage in Scripts

For seeds, migrations, or one-off scripts, use `start: true`:

```elixir
NexBase.init(url: System.get_env("DATABASE_URL"), ssl: true, start: true)

NexBase.from("tags")
|> NexBase.insert(%{name: "Web", slug: "web"})
|> NexBase.run()
```

## Error Handling

All operations return `{:ok, result}` or `{:error, reason}`:

```elixir
case NexBase.from("users") |> NexBase.eq(:id, 123) |> NexBase.run() do
  {:ok, [user]} -> user
  {:ok, []} -> nil
  {:error, reason} -> Logger.error("Query failed: #{inspect(reason)}")
end
```

## Supabase Comparison

| Operation | Supabase JS | NexBase |
|-----------|-------------|---------|
| Init | `createClient(url, key)` | `NexBase.init(url: "...")` |
| From | `supabase.from('table')` | `NexBase.from("table")` |
| Filter | `.eq('col', val)` | `\|> NexBase.eq(:col, val)` |
| Order | `.order('col')` | `\|> NexBase.order(:col, :desc)` |
| Insert | `.insert({...})` | `\|> NexBase.insert(%{...})` |
| Execute | `await ...` | `\|> NexBase.run()` |
| Raw SQL | `supabase.rpc(...)` | `NexBase.sql("...", [])` |

## License

MIT

