# Database Integration (NexBase)

NexBase is Nex's companion database package. It provides a fluent query builder and raw SQL execution for PostgreSQL and SQLite — without requiring you to define a custom `Repo` module.

## 1. Installation

Add NexBase to your `mix.exs`:

```elixir
defp deps do
  [
    {:nex_core, "~> 0.3"},
    {:nex_base, "~> 0.3"}
  ]
end
```

## 2. Application Startup

Initialize NexBase in your `Application.start/2`:

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    Nex.Env.init()
    conn = NexBase.init(url: Nex.Env.get(:database_url), ssl: true)

    children = [{NexBase.Repo, conn}]
    Supervisor.start_link(children, strategy: :one_for_one, name: MyApp.Supervisor)
  end
end
```

Your `.env` file:
```bash
DATABASE_URL=postgresql://user:pass@host:5432/mydb
```

> For SQLite, use `DATABASE_URL=sqlite:data/mydb.db` — NexBase auto-detects the adapter.

## 3. Query Builder

The query builder uses a fluent pipe-based API. All queries return `{:ok, rows}` or `{:error, reason}`.

### SELECT

```elixir
# All rows
{:ok, users} = NexBase.from("users") |> NexBase.run()

# With filters
{:ok, active} = NexBase.from("users")
  |> NexBase.eq(:active, true)
  |> NexBase.order(:created_at, :desc)
  |> NexBase.limit(20)
  |> NexBase.run()

# Single row
{:ok, [user]} = NexBase.from("users")
  |> NexBase.eq(:id, id)
  |> NexBase.single()
  |> NexBase.run()

# Select specific columns (returns atom-keyed maps)
{:ok, rows} = NexBase.from("users")
  |> NexBase.select([:id, :name, :email])
  |> NexBase.run()
```

### INSERT

```elixir
{:ok, [new_user]} = NexBase.from("users")
  |> NexBase.insert(%{name: "Alice", email: "alice@example.com"})
  |> NexBase.run()
```

### UPDATE

```elixir
{:ok, [updated]} = NexBase.from("users")
  |> NexBase.eq(:id, id)
  |> NexBase.update(%{name: "Bob"})
  |> NexBase.run()
```

### DELETE

```elixir
{:ok, _} = NexBase.from("users")
  |> NexBase.eq(:id, id)
  |> NexBase.delete()
  |> NexBase.run()
```

### IN queries

```elixir
{:ok, rows} = NexBase.from("posts")
  |> NexBase.filter_in(:user_id, [1, 2, 3])
  |> NexBase.run()
```

## 4. Raw SQL

Use `NexBase.sql/2` for JOINs and complex queries. It always returns string-keyed maps.

```elixir
# Returns {:ok, [%{"col" => val, ...}]}
{:ok, rows} = NexBase.sql("""
  SELECT p.title, u.name AS author
  FROM posts p
  JOIN users u ON u.id = p.user_id
  WHERE p.published = true
  ORDER BY p.created_at DESC
  LIMIT $1
""", [10])
```

> **Always use parameterized queries** (`$1`, `$2`, ...). Never interpolate user input directly into SQL strings.

## 5. Key Differences: Query Builder vs Raw SQL

| | Query Builder | Raw SQL |
|---|---|---|
| **Key type** | Atom keys (with `select/2`) or string keys | Always string keys |
| **Use case** | Simple CRUD | JOINs, aggregates, complex filters |
| **Returns** | `{:ok, rows}` | `{:ok, rows}` |

## 6. Anti-Patterns

```elixir
# WRONG — do not create a custom Repo
defmodule MyApp.Repo do
  use Ecto.Repo, otp_app: :my_app, adapter: Ecto.Adapters.Postgres
end

# WRONG — SQL injection risk
NexBase.sql("SELECT * FROM users WHERE name = '#{name}'", [])

# WRONG — manually zipping rows and columns
{:ok, %{rows: rows, columns: cols}} = NexBase.query(sql, [])
Enum.map(rows, fn row -> Enum.zip(cols, row) |> Map.new() end)

# RIGHT — NexBase.sql/2 returns maps directly
{:ok, rows} = NexBase.sql("SELECT * FROM users WHERE name = $1", [name])
```
