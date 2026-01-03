# Environment Configuration (Nex.Env)

Nex provides a simple yet powerful environment configuration system that not only automatically loads environment variables but also intelligently locates the project root directory in development environments.

## 1. Core Features

*   **Auto-loading**: Automatically searches for and loads the `.env` file in the root directory upon project startup.
*   **Multi-environment Support**: Supports multiple suffixes like `.env`, `.env.local`, `.env.dev` (loading order: `.env` first, subsequent files override previous ones).
*   **Smart Root Directory Detection**: Uses the `Nex.Env.root_path/0` algorithm to automatically handle path differences between development environments (like the `_build` directory) and source code directories.

## 2. Usage

You can safely retrieve configuration via `Nex.Env.get/2`.

### Example

Define in `.env`:
```bash
STRIPE_API_KEY=sk_test_12345
MAX_RETRY=5
```

Read in code:
```elixir
# Get string configuration
api_key = Nex.Env.get("STRIPE_API_KEY")

# Provide a default value
retry_count = Nex.Env.get("MAX_RETRY", "3") |> String.to_integer()
```

## 3. Smart Root Directory Detection

Because Elixir compiled files are usually located in the `_build` directory, using `File.cwd!` directly sometimes fails to find the project root correctly. Nex uses a recursive detection algorithm:

1.  Starts searching upwards from the current working directory.
2.  Looks for folders containing `mix.exs` or `.env`.
3.  Ensures that the developer can correctly load configuration files when starting the project (or running tests) from any location.

## 4. Best Practices

*   **Don't commit `.env` to Git**: You should ignore `.env` in your `.gitignore` and provide a `.env.example` template.
*   **Type Conversion**: Environment variables are always stored as strings. After reading, please convert them as needed using functions like `String.to_integer/1`.
*   **Production Environment**: On Docker or cloud platforms, it's recommended to set operating system-level environment variables directly; Nex will prioritize reading these.
