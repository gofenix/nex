# Nex Project Generator

The official project generator for the Nex web framework.

## Installation

Install the archive from Hex:

```bash
mix archive.install hex nex_new
```

## Usage

Create a new Nex project:

```bash
mix nex.new my_app
cd my_app
mix nex.dev
```

Create a project in a specific directory:

```bash
mix nex.new my_app --path ~/projects
```

## What's Included

The generator creates a complete Nex project with:

- File-based routing structure (`src/pages/` and `src/api/`)
- Example pages and API endpoints
- Application module with supervision tree
- Environment configuration (`.env.example`)
- Development server setup
- Production build configuration

## Next Steps

After creating your project:

1. Navigate to the project directory
2. Copy `.env.example` to `.env` and configure as needed
3. Run `mix nex.dev` to start the development server
4. Visit `http://localhost:4000`

## Documentation

For more information about Nex, visit:
- [Nex Framework](https://hex.pm/packages/nex_core)
- [GitHub Repository](https://github.com/fenix/nex)

## License

MIT
