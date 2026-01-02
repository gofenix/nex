defmodule Mix.Tasks.Nex.New do
  @moduledoc """
  Creates a new Nex project.

  ## Usage

      mix nex.new my_app
      mix nex.new my_app --path ~/projects

  ## Options

      --path PATH    Directory to create project in (default: current directory)

  ## Installation

      cd installer
      mix archive.build
      mix archive.install
  """

  use Mix.Task

  @shortdoc "Create a new Nex project"

  def run([]) do
    Mix.raise("Expected project name. Usage: mix nex.new my_app")
  end

  def run(args) do
    {opts, [name | _], _} = OptionParser.parse(args, switches: [path: :string])

    unless valid_name?(name) do
      Mix.raise("Project name must start with a letter and contain only lowercase letters, numbers, and underscores")
    end

    base_path = opts[:path] || "."
    project_path = Path.expand(Path.join(base_path, name))

    if File.dir?(project_path) do
      Mix.raise("Directory #{project_path} already exists")
    end

    module_name = Macro.camelize(name)
    assigns = %{app_name: name, module_name: module_name}

    Mix.shell().info("\n🚀 Creating Nex project: #{name}\n")

    create_project(project_path, assigns)

    # Install dependencies automatically
    Mix.shell().info("\n📦 Installing dependencies...\n")
    original_dir = File.cwd!()
    File.cd!(project_path)
    System.cmd("mix", ["deps.get"], into: IO.stream(:stdio, :line))
    File.cd!(original_dir)

    Mix.shell().info("""

    ✅ Project created successfully!

    Next steps:

        cd #{name}
        mix nex.dev

    Then open http://localhost:4000 in your browser.
    """)
  end

  defp valid_name?(name), do: Regex.match?(~r/^[a-z][a-z0-9_]*$/, name)

  defp create_project(path, assigns) do
    # Create directories
    dirs = [path, "#{path}/src", "#{path}/src/pages", "#{path}/src/api", "#{path}/src/partials"]
    Enum.each(dirs, fn dir ->
      File.mkdir_p!(dir)
      Mix.shell().info("  Created: #{dir}/")
    end)

    # Create files
    files = [
      {"mix.exs", mix_exs(assigns)},
      {"src/application.ex", application(assigns)},
      {"src/layouts.ex", layouts(assigns)},
      {"src/pages/index.ex", index(assigns)},
      {"src/api/hello.ex", api_hello(assigns)},
      {"src/partials/card.ex", partial_card(assigns)},
      {".gitignore", gitignore()},
      {".dockerignore", dockerignore()},
      {"Dockerfile", dockerfile()},
      {".env.example", env_example()},
      {"README.md", readme(assigns)}
    ]

    Enum.each(files, fn {file, content} ->
      full_path = Path.join(path, file)
      File.write!(full_path, content)
      Mix.shell().info("  Created: #{full_path}")
    end)
  end

  # Templates

  defp mix_exs(a) do
    """
    defmodule #{a.module_name}.MixProject do
      use Mix.Project

      def project do
        [
          app: :#{a.app_name},
          version: "0.1.0",
          elixir: "~> 1.18",
          start_permanent: Mix.env() == :prod,
          elixirc_paths: ["src"],
          deps: deps()
        ]
      end

      def application do
        [
          extra_applications: [:logger],
          mod: {#{a.module_name}.Application, []}
        ]
      end

      defp deps do
        [
          {:nex_core, "~> 0.3.0"}
        ]
      end
    end
    """
  end

  defp application(a) do
    """
    defmodule #{a.module_name}.Application do
      @moduledoc \"\"\"
      The #{a.module_name} application.

      ## What Nex Framework Already Does

      When you run `mix nex.dev` or `mix nex.start`, the framework automatically:

      1. **Starts your application** - `Application.ensure_all_started(:#{a.app_name})`
      2. **Starts framework dependencies**:
         - :bandit (HTTP server)
         - :phoenix_html (HEEx templates)
         - :phoenix_live_view (LiveView components)
         - :file_system (hot reload file watcher, dev only)
      3. **Starts Nex.Supervisor** - Framework-level processes:
         - Phoenix.PubSub - Hot reload WebSocket communication
         - Nex.Store - Page-level state storage
         - Nex.Reloader - File watcher (dev only)
      4. **Starts Bandit web server** - Listens on configured port

      ## What This Module Is For

      This is YOUR application's supervision tree.
      Most simple apps don't need any supervised processes here.

      ## When to Add Children

      Add supervised processes only when you need:
      - **Database connections** - `{#{a.module_name}.Repo, []}`
      - **HTTP clients** - `{Finch, name: #{a.module_name}.Finch}` (for calling external APIs)
      - **Background workers** - `{#{a.module_name}.Worker, arg}`
      - **Custom GenServers/Agents** - Your own stateful processes

      ## Example: Adding an HTTP Client

          children = [
            {Finch, name: #{a.module_name}.Finch}
          ]

      Then add to mix.exs:

          {:finch, "~> 0.18"}
      \"\"\"

      use Application

      @impl true
      def start(_type, _args) do
        children = [
          # Add your supervised processes here
          # Examples:
          # {Finch, name: #{a.module_name}.Finch},
          # {#{a.module_name}.Repo, []},
          # {#{a.module_name}.Worker, arg}
        ]

        opts = [strategy: :one_for_one, name: #{a.module_name}.Supervisor]
        Supervisor.start_link(children, opts)
      end
    end
    """
  end

  defp layouts(a) do
    """
    defmodule #{a.module_name}.Layouts do
      use Nex

      def render(assigns) do
        ~H\"\"\"
        <!DOCTYPE html>
        <html lang="en" data-theme="light">
          <head>
            <meta charset="UTF-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1.0" />
            <title>{@title}</title>
            <script src="https://cdn.tailwindcss.com?plugins=forms,typography,aspect-ratio"></script>
            <link href="https://cdn.jsdelivr.net/npm/daisyui@4.12.23/dist/full.min.css" rel="stylesheet" type="text/css" />
            <script src="https://unpkg.com/htmx.org@2.0.4"></script>
          </head>
          <body class="min-h-screen bg-base-200" hx-boost="true">
            <nav class="navbar bg-base-100 shadow-sm">
              <div class="max-w-4xl mx-auto w-full px-4">
                <a href="/" class="btn btn-ghost text-xl">#{a.module_name}</a>
              </div>
            </nav>
            <main class="max-w-4xl mx-auto px-4 py-8">
              {raw(@inner_content)}
            </main>
          </body>
        </html>
        \"\"\"
      end
    end
    """
  end

  defp index(a) do
    """
    defmodule #{a.module_name}.Pages.Index do
      use Nex
      alias #{a.module_name}.Partials.Card

      def mount(_params) do
        %{
          title: "Welcome to #{a.module_name}",
          message: "Your Nex app is running!"
        }
      end

      def render(assigns) do
        ~H\"\"\"
        <div class="space-y-8">
          <div class="text-center py-8">
            <h1 class="text-4xl font-bold mb-4">{@message}</h1>
            <p class="text-base-content/70 mb-8">
              Edit <code class="bg-base-300 px-2 py-1 rounded">src/pages/index.ex</code> to get started.
            </p>
          </div>

          <div class="grid md:grid-cols-2 gap-6">
            <Card.card title="📁 Project Structure" description="Nex follows a simple, intuitive structure" />

            <div class="card bg-base-100 shadow-xl">
              <div class="card-body">
                <h2 class="card-title">🚀 Try the API</h2>
                <button
                  class="btn btn-primary w-full"
                  hx-get="/api/hello?name=Developer"
                  hx-target="#api-response"
                  hx-swap="innerHTML"
                >
                  Test GET /api/hello
                </button>
                <div id="api-response" class="p-4 bg-base-200 rounded min-h-[60px]">
                  <span class="text-base-content/50">Click to test the API</span>
                </div>
              </div>
            </div>
          </div>

          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h2 class="card-title">📚 Next Steps</h2>
              <ul class="space-y-2">
                <li>✅ Create pages in <code>src/pages/</code></li>
                <li>✅ Add API endpoints in <code>src/api/</code> (Next.js style)</li>
                <li>✅ Build components in <code>src/partials/</code></li>
                <li>✅ Check the <a href="https://github.com/gofenix/nex" class="link link-primary">docs</a></li>
              </ul>
            </div>
          </div>
        </div>
        \"\"\"
      end
    end
    """
  end

  defp api_hello(a) do
    """
    defmodule #{a.module_name}.Api.Hello do
      @moduledoc \"\"\"
      Example API endpoint - Next.js style.

      ## Endpoints
      - GET /api/hello?name=World
      - POST /api/hello with body: {"name": "Alice"}

      ## Next.js API Routes Alignment
      - `req.query` - Path params + query string (path params take precedence)
      - `req.body` - Request body (always a Map, never nil)
      - `Nex.json/2` - JSON response helper
      \"\"\"
      use Nex

      def get(req) do
        # Access query parameters - Next.js style
        name = req.query["name"] || "World"

        Nex.json(%{
          message: "Hello, \#{name}!",
          timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
        })
      end

      def post(req) do
        # Access request body - Next.js style
        name = req.body["name"]

        cond do
          is_nil(name) or name == "" ->
            Nex.json(%{error: "Name is required"}, status: 400)

          true ->
            Nex.json(%{
              message: "Hello, \#{name}! Welcome to Nex.",
              created_at: DateTime.utc_now() |> DateTime.to_iso8601()
            }, status: 201)
        end
      end
    end
    """
  end

  defp partial_card(a) do
    """
    defmodule #{a.module_name}.Partials.Card do
      @moduledoc \"\"\"
      Reusable card component.

      ## Usage in Pages

          # Import the module
          alias #{a.module_name}.Partials.Card

          # Use in HEEx template
          <Card.card title="Welcome" description="Get started" />
      \"\"\"
      use Nex.Partial

      def card(assigns) do
        ~H\"\"\"
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h2 class="card-title">{@title}</h2>
            <p class="text-base-content/70">{@description}</p>
          </div>
        </div>
        \"\"\"
      end
    end
    """
  end

  defp gitignore do
    """
    /deps/
    /_build/
    .env
    .env.local
    *.beam
    erl_crash.dump
    .elixir_ls/
    .DS_Store
    """
  end

  defp dockerignore do
    """
    _build/
    deps/
    .git/
    .gitignore
    *.log
    erl_crash.dump
    .DS_Store
    .vscode/
    .idea/
    .elixir_ls/
    """
  end

  defp dockerfile do
    """
    FROM elixir:1.18-alpine

    RUN apk add --no-cache build-base git openssl ncurses-libs

    WORKDIR /app

    RUN mix local.hex --force && mix local.rebar --force

    COPY . .

    RUN mix deps.get

    EXPOSE 4000

    CMD ["mix", "nex.start"]
    """
  end

  defp env_example do
    """
    # Server Configuration
    PORT=4000
    HOST=localhost

    # Add your environment variables here
    # DATABASE_URL=postgres://user:pass@localhost/myapp_dev
    # API_KEY=your_api_key_here
    """
  end

  defp readme(a) do
    """
    # #{a.module_name}

    A web application built with [Nex](https://github.com/gofenix/nex).

    ## Getting Started

    ```bash
    mix deps.get
    mix nex.dev
    ```

    Open http://localhost:4000

    ## Project Structure

    ```
    #{a.app_name}/
    ├── src/
    │   ├── application.ex      # Application supervision tree
    │   ├── layouts.ex          # HTML layout template
    │   ├── pages/              # Page components (routes)
    │   │   └── index.ex        # Homepage (/)
    │   ├── api/                # API endpoints (Next.js style)
    │   │   └── hello.ex        # Example: GET/POST /api/hello
    │   └── partials/           # Reusable components
    │       └── card.ex         # Example card component
    ├── mix.exs                 # Project configuration
    └── .env.example            # Environment variables template
    ```

    ## Creating Pages

    ```elixir
    # src/pages/about.ex -> /about
    defmodule #{a.module_name}.Pages.About do
      use Nex

      def render(assigns) do
        ~H\"\"\"
        <h1>About Us</h1>
        \"\"\"
      end
    end
    ```

    ## Creating API Endpoints (Next.js Style)

    ```elixir
    # src/api/users.ex -> /api/users
    defmodule #{a.module_name}.Api.Users do
      use Nex

      def get(req) do
        # req.query - path params + query string
        id = req.query["id"]
        Nex.json(%{users: []})
      end

      def post(req) do
        # req.body - request body (always a Map)
        name = req.body["name"]
        Nex.json(%{created: true}, status: 201)
      end
    end
    ```

    ## Creating Partials

    ```elixir
    # src/partials/button.ex
    defmodule #{a.module_name}.Partials.Button do
      use Nex.Partial

      def button(assigns) do
        ~H\"\"\"
        <button class="btn">{@text}</button>
        \"\"\"
      end
    end
    ```

    Use in pages:

    ```elixir
    alias #{a.module_name}.Partials.Button

    ~H\"\"\"
    <Button.button text="Click me" />
    \"\"\"
    ```

    ## Deployment

    ```bash
    # Docker
    docker build -t #{a.app_name} .
    docker run -p 4000:4000 #{a.app_name}

    # Production
    MIX_ENV=prod mix nex.start
    ```

    ## Resources

    - [Nex Documentation](https://hexdocs.pm/nex_core)
    - [Nex GitHub](https://github.com/gofenix/nex)
    - [HTMX](https://htmx.org)
    """
  end
end
