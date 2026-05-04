# Nex New

Project generator for the Nex web framework.

## Installation

Install the archive from Hex:

```bash
mix archive.install hex nex_new
```

## Usage

Create a new Nex project with the default `basic` starter:

```bash
mix nex.new my_app
cd my_app
mix nex.dev
```

Use `--starter saas` when you want the product-shaped path with auth, NexBase, and a protected dashboard:

```bash
mix nex.new my_app --starter saas
cd my_app
mix nex.dev
```

Visit `http://localhost:4000` to see your app running.

## What's Included

The generator creates a new Nex project with:

- File-based routing structure
- HTMX integration
- `AGENTS.md` plus a project-local skill at `.agents/skills/nex-project/SKILL.md`
- TailwindCSS and DaisyUI for styling
- Hot reload in development
- Example pages and components

The default `basic` starter is the best first step when you want to learn Nex's page, API, and component model.

With `--starter saas`, it also adds:

- SQLite by default via NexBase
- Session-backed authentication
- Protected dashboard routes
- Starter project CRUD
- Automatic schema bootstrap on app start

## Documentation

For more information about the Nex framework, visit the [GitHub repository](https://github.com/gofenix/nex).

## License

MIT
