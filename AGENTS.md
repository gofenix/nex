# AI Agent Handbook & Principles

## 1. Core Principles

### Principle 1: Changelog First
Every modification to the framework code must be recorded in the changelog to facilitate future framework version releases.
Check the changelog before and after any modification.

### Principle 2: Framework Modification Policy
When creating example projects (in `website/` or `examples/`), if you determine that we need to modify the framework code to support them, please let me know. I will evaluate whether to make those changes.

### Principle 3: Upgrade Verification
When upgrading the framework:
1. Ensure the changelog is actually updated.
2. Ensure the version number is correctly bumped.
3. Ensure the installer code (`installer/`) is updated to reflect the change.

### Principle 4: English Only
All code, comments, documentation, README files, and commit messages **must be in English**.
The only exception is `website/priv/docs/zh/` which holds Chinese translations for the documentation site.

---

## 2. Project Context

### Project Structure
```
nex/
  framework/      # Core package (nex_core) — published to hex.pm
  installer/      # Project generator (nex_new) — published to hex.pm
  nex_base/       # PostgreSQL query builder (nex_base) — published to hex.pm (independent version)
  website/        # Official documentation site
  examples/       # Example projects (counter, todos, bestof_ex, etc.)
  scripts/        # Release scripts
```

### Package Versions
- `nex_core` + `nex_new`: Synchronized version via `/VERSION` file. Published together with `./scripts/publish_hex.sh`.
- `nex_base`: Independent version in `nex_base/mix.exs`. Published separately with `./scripts/publish_nex_base.sh`.

### Commit Message Convention
Follow [Conventional Commits](https://www.conventionalcommits.org/):
- **Format**: `<type>(<scope>): <subject>`
- **Strict Rule**: **NO triple backticks (```)** in the commit message.
- Subject: ≤ 50 chars, imperative mood.

### Developer Experience (DX)
- **Zero Boilerplate**: Nex handles CSRF automatically. Do NOT manually add CSRF input tags or headers unless specifically requested.
- **Convention over Configuration**: File paths are routes. Modules use a unified `use Nex` interface.
- **No config files**: Use `.env` + `Nex.Env` instead of `config/*.exs`.

---

## 3. Critical Anti-Patterns

### DO NOT create a custom Repo
```elixir
# WRONG
defmodule MyApp.Repo do
  use Ecto.Repo, otp_app: :my_app, adapter: Ecto.Adapters.Postgres
end

# RIGHT — NexBase provides the Repo internally
NexBase.from("users") |> NexBase.run()
```

### DO NOT create a NexBase client object
```elixir
# WRONG — client pattern was removed in 0.1.1
@client NexBase.client()
@client |> NexBase.from("users") |> NexBase.run()

# RIGHT — call NexBase directly
NexBase.from("users") |> NexBase.run()
```

### DO NOT use `config/config.exs`
```elixir
# WRONG — Nex does not use config files
config :my_app, MyApp.Repo, url: "..."

# RIGHT — use .env files + Nex.Env
# .env
DATABASE_URL=postgresql://...
```

### DO NOT use `for` comprehension inline in HEEx
```elixir
# WRONG — syntax error
<%= for item <- @items do %>
  <div>{item["name"]}</div>
<% end %>

# RIGHT — use :for directive
<div :for={item <- @items}>{item["name"]}</div>
```

### DO NOT manually add CSRF tags
```elixir
# WRONG — Nex handles CSRF automatically
<form hx-post="/action">
  {csrf_input_tag()}
</form>

# RIGHT — just write the form
<form hx-post="/action">
  ...
</form>
```

### DO NOT manually zip SQL columns and rows
```elixir
# WRONG
{:ok, %{rows: rows, columns: columns}} = NexBase.query(sql, params)
Enum.map(rows, fn row -> Enum.zip(columns, row) |> Map.new() end)

# RIGHT — NexBase.sql/2 returns list of maps directly
{:ok, rows} = NexBase.sql("SELECT * FROM users WHERE id = $1", [id])
```

---

## 4. Release Process

### nex_core + nex_new (synchronized)
1. Update `/VERSION` file.
2. Update `CHANGELOG.md`, `framework/CHANGELOG.md`, `installer/CHANGELOG.md`.
3. Run `./scripts/publish_hex.sh`.

### nex_base (independent)
1. Update version in `nex_base/mix.exs`.
2. Update `CHANGELOG.md` (NexBase section).
3. Run `./scripts/publish_nex_base.sh`.

---

## 5. Example Projects

Dependencies for example projects:
```elixir
# Use path dep for nex_core (monorepo), hex dep for nex_base
defp deps do
  [
    {:nex_core, path: "../../framework"},
    {:nex_base, "~> 0.1.1"}  # only if project needs database
  ]
end
```

- Do NOT add bandit, jason, plug, etc. — they are transitive deps of nex_core.
- Do NOT add extra_applications for those deps.

---

## 6. Browser Automation

Use `agent-browser` for web automation. Run `agent-browser --help` for all commands.

Core workflow:
1. `agent-browser open <url>` - Navigate to page
2. `agent-browser snapshot -i` - Get interactive elements with refs (@e1, @e2)
3. `agent-browser click @e1` / `fill @e2 "text"` - Interact using refs
4. Re-snapshot after page changes