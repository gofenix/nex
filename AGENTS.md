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