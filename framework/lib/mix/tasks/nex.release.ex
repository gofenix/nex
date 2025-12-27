defmodule Mix.Tasks.Nex.Release do
  @moduledoc """
  Build a Nex application for production deployment.

  ## Usage

      mix nex.release

  ## Options

      --output PATH    Output directory (default: _build/prod/rel)
      --name NAME      Release name (default: app name from mix.exs)

  ## What it does

  1. Compiles the application in production mode
  2. Creates an Elixir release with all dependencies
  3. Generates a startup script

  ## Deployment

  After running `mix nex.release`, you can deploy the release:

      # Copy to server
      scp -r _build/prod/rel/my_app user@server:/app

      # On server, start the application
      /app/my_app/bin/my_app start

  ## Environment Variables

  In production, configure via environment variables:

      PORT=8080 /app/my_app/bin/my_app start
  """

  use Mix.Task

  @shortdoc "Build for production deployment"

  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args, switches: [output: :string, name: :string])

    app_name = opts[:name] || get_app_name()
    module_name = Macro.camelize(app_name)

    Mix.shell().info("""

    🔨 Building #{module_name} for production...
    """)

    # Step 1: Set production environment
    Mix.shell().info("  → Setting MIX_ENV=prod")
    System.put_env("MIX_ENV", "prod")
    Mix.env(:prod)

    # Step 2: Configure Nex for production
    Application.put_env(:nex, :env, :prod)

    # Step 3: Get dependencies
    Mix.shell().info("  → Fetching dependencies")
    Mix.Task.run("deps.get", ["--only", "prod"])

    # Step 4: Compile
    Mix.shell().info("  → Compiling application")
    Mix.Task.run("compile", [])

    # Step 5: Check if release is configured in mix.exs
    if has_release_config?() do
      # Use native mix release
      Mix.shell().info("  → Creating release")
      Mix.Task.run("release", [app_name])
    else
      # Create a simple release structure
      create_simple_release(app_name, module_name, opts)
    end

    Mix.shell().info("""

    ✅ Build complete!

    To run in production:

        MIX_ENV=prod PORT=4000 mix run --no-halt

    Or with the release (if configured):

        _build/prod/rel/#{app_name}/bin/#{app_name} start

    Environment variables:
        PORT     - HTTP port (default: 4000)
        HOST     - Bind host (default: 0.0.0.0)
        NEX_ENV  - Environment (automatically set to prod)
    """)
  end

  defp get_app_name do
    case Mix.Project.config()[:app] do
      nil -> "my_app"
      app -> to_string(app)
    end
  end

  defp has_release_config? do
    Mix.Project.config()[:releases] != nil
  end

  defp create_simple_release(app_name, module_name, opts) do
    output_dir = opts[:output] || "_build/prod/rel/#{app_name}"

    Mix.shell().info("  → Creating simple release in #{output_dir}")

    # Create directories
    File.mkdir_p!(output_dir)
    File.mkdir_p!(Path.join(output_dir, "bin"))

    # Create startup script
    start_script = """
    #!/bin/bash
    # #{module_name} Production Startup Script

    set -e

    export MIX_ENV=prod
    export NEX_ENV=prod
    export PORT=${PORT:-4000}
    export HOST=${HOST:-0.0.0.0}

    cd "$(dirname "$0")/.."

    echo "Starting #{module_name}..."
    echo "  Port: $PORT"
    echo "  Host: $HOST"

    exec elixir --sname #{app_name} -S mix run --no-halt
    """

    start_script_path = Path.join([output_dir, "bin", "start"])
    File.write!(start_script_path, start_script)
    File.chmod!(start_script_path, 0o755)

    # Create a prod config reminder
    config_reminder = """
    # #{module_name} Production Configuration

    ## Environment Variables

    - PORT: HTTP port (default: 4000)
    - HOST: Bind address (default: 0.0.0.0)
    - DATABASE_URL: Database connection string
    - SECRET_KEY_BASE: Secret for sessions/tokens

    ## Starting the Application

    ```bash
    ./bin/start
    ```

    ## Using systemd

    Create `/etc/systemd/system/#{app_name}.service`:

    ```ini
    [Unit]
    Description=#{module_name}
    After=network.target

    [Service]
    Type=simple
    User=deploy
    WorkingDirectory=/app/#{app_name}
    Environment=PORT=4000
    Environment=MIX_ENV=prod
    ExecStart=/app/#{app_name}/bin/start
    Restart=on-failure

    [Install]
    WantedBy=multi-user.target
    ```

    ## Using Docker

    See the generated Dockerfile for containerized deployment.
    """

    File.write!(Path.join(output_dir, "DEPLOY.md"), config_reminder)

    # Create a simple Dockerfile
    dockerfile = """
    FROM elixir:1.18-alpine AS builder

    RUN apk add --no-cache build-base git

    WORKDIR /app

    ENV MIX_ENV=prod

    COPY mix.exs mix.lock ./
    RUN mix local.hex --force && mix local.rebar --force
    RUN mix deps.get --only prod
    RUN mix deps.compile

    COPY . .
    RUN mix compile

    FROM elixir:1.18-alpine

    RUN apk add --no-cache libstdc++ openssl ncurses-libs

    WORKDIR /app

    COPY --from=builder /app .

    ENV MIX_ENV=prod
    ENV PORT=4000

    EXPOSE 4000

    CMD ["mix", "run", "--no-halt"]
    """

    File.write!(Path.join(output_dir, "Dockerfile"), dockerfile)

    Mix.shell().info("  → Created startup script: #{start_script_path}")
    Mix.shell().info("  → Created deployment guide: #{output_dir}/DEPLOY.md")
    Mix.shell().info("  → Created Dockerfile: #{output_dir}/Dockerfile")
  end
end
