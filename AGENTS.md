# Nex Framework — AI Agent Guide


## 7. Commit Convention

Follow [Conventional Commits](https://www.conventionalcommits.org/):
- Format: `<type>(<scope>): <subject>`
- Subject: ≤50 chars, imperative mood
- **NO triple backticks** in commit messages

---

## 8. Additional Rules

- **English Only**: All code, comments, docs, commits in English
- **Changelog First**: Update changelog before any framework change
- **No Config Files**: Use `.env` only, never `config/*.exs`
- **Cursor Rules**: If project has `.cursorrules`, follow it (see `bestof_ex/.cursorrules`)

---

## 9. Nex Request Contract

- **Canonical Request Type**: Page Actions in `src/pages/` receive `Nex.Req`.
- **API Consistency**: API Handlers in `src/api/` also receive `Nex.Req`.
- **Comparison Target**: Model Nex request handling after **Next.js Pages Router API Routes**.
- **Parameter Access**: Read path params and query string values from `req.query`. Read request body values from `req.body`.
- **Do Not Model After**: Do not model Page Actions after App Router Route Handlers, Server Actions, `FormData`-first handlers, or a flat merged params map.
- **Keep The Contract Visible**: When the request argument is unused, prefer `_req`, not `_params`.

Example:

```elixir
def save(req) do
  id = req.query["id"]
  name = req.body["name"]

  {:ok, %{id: id, name: name}}
end
```

<!-- opensrc:start -->

## Source Code Reference

Source code for dependencies is available in `opensrc/` for deeper understanding of implementation details.

See `opensrc/sources.json` for the list of available packages and their versions.

Use this source code when you need to understand how a package works internally, not just its types/interface.

### Fetching Additional Source Code

To fetch source code for a package or repository you need to understand, run:

```bash
npx opensrc <package>           # npm package (e.g., npx opensrc zod)
npx opensrc pypi:<package>      # Python package (e.g., npx opensrc pypi:requests)
npx opensrc crates:<package>    # Rust crate (e.g., npx opensrc crates:serde)
npx opensrc <owner>/<repo>      # GitHub repo (e.g., npx opensrc vercel/ai)
```

<!-- opensrc:end -->
