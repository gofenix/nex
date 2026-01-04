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
      Mix.raise("Project name must start with a letter and contain only lowercase letters, numbers, and underscores. Reserved names (elixir, mix, nex, etc.) are not allowed.")
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

    # Initialize Git
    if System.find_executable("git") do
      Mix.shell().info("\n🌿 Initializing Git repository...\n")
      System.cmd("git", ["init"], cd: project_path)
    end

    # Install dependencies automatically
    Mix.shell().info("\n📦 Installing dependencies...\n")
    Mix.shell().cmd("cd #{project_path} && mix deps.get")

    Mix.shell().info("""

    ✅ Project created successfully!

    Next steps:

        cd #{name}
        mix nex.dev

    Then open http://localhost:4000 in your browser.
    """)
  end

  defp valid_name?(name) do
    reserved = ["elixir", "mix", "nex", "nex_core", "node", "phoenix", "proxy"]
    Regex.match?(~r/^[a-z][a-z0-9_]*$/, name) and name not in reserved
  end

  defp create_project(path, assigns) do
    # Create directories
    dirs = [path, "#{path}/src", "#{path}/src/pages", "#{path}/src/api", "#{path}/src/components"]
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
      {"src/components/card.ex", component_card(assigns)},
      {".gitignore", gitignore()},
      {".dockerignore", dockerignore()},
      {"Dockerfile", dockerfile()},
      {".env.example", env_example()},
      {".formatter.exs", formatter_exs()},
      {"AGENTS.md", agents_md(assigns)},
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
          {:nex_core, "~> 0.3.2"}
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

      def mount(_params) do
        %{
          title: "Welcome to #{a.module_name}",
          count: Nex.Store.get(:count, 0)
        }
      end

      def render(assigns) do
        ~H\"\"\"
        <div class="space-y-8 max-w-2xl mx-auto">
          <div class="text-center py-12 bg-base-100 rounded-3xl shadow-sm border border-base-300">
            <h1 class="text-5xl font-black mb-4 tracking-tight text-primary">Nex + HTMX</h1>
            <p class="text-lg text-base-content/60 mb-8">
              The simplest way to build modern web apps with Elixir.
            </p>

            <div class="flex flex-col items-center gap-4">
              <div id="counter-display" class="stat place-items-center bg-base-200 rounded-xl w-48 py-4 border border-base-300">
                <div class="stat-title text-base-content/50 uppercase tracking-widest text-xs font-bold">Current Count</div>
                <div class="stat-value text-4xl font-mono tracking-tighter">{@count}</div>
              </div>

              <div class="flex gap-2">
                <button
                  class="btn btn-primary btn-lg shadow-lg"
                  hx-post="/increment"
                  hx-target="#counter-display"
                  hx-indicator="#loading-spinner"
                >
                  Increment
                </button>

                <button
                  class="btn btn-ghost btn-lg"
                  hx-post="/reset"
                  hx-target="#counter-display"
                >
                  Reset
                </button>
              </div>

              <div id="loading-spinner" class="htmx-indicator">
                <span class="loading loading-spinner loading-sm text-primary"></span>
              </div>
            </div>
          </div>

          <div class="grid md:grid-cols-2 gap-6">
            <#{a.module_name}.Components.Card.card title="📁 Folder Routing" icon="⚡️">
              No router files. Just create a file in <code>src/pages/</code>.
            </#{a.module_name}.Components.Card.card>

            <#{a.module_name}.Components.Card.card title="🧩 UI Components" icon="📦">
              Composable components with slots. See <code>src/components/</code>.
            </#{a.module_name}.Components.Card.card>
          </div>

          <div class="alert alert-info shadow-sm border-none bg-blue-50 text-blue-800">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-current shrink-0 w-6 h-6"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
            <span>Check <code>AGENTS.md</code> to see how to pair Nex with AI agents.</span>
          </div>
        </div>
        \"\"\"
      end

      # --- Actions (Intent-Driven) ---

      def increment(_params) do
        # 1. Update Truth
        new_count = Nex.Store.update(:count, 0, &(&1 + 1))

        # 2. Render surgical update
        assigns = %{count: new_count}
        ~H\"\"\"
        <div class="stat-title text-base-content/50 uppercase tracking-widest text-xs font-bold">Current Count</div>
        <div class="stat-value text-4xl font-mono tracking-tighter text-primary animate-bounce-short">{@count}</div>
        \"\"\"
      end

      def reset(_params) do
        Nex.Store.put(:count, 0)

        assigns = %{count: 0}
        ~H\"\"\"
        <div class="stat-title text-base-content/50 uppercase tracking-widest text-xs font-bold">Current Count</div>
        <div class="stat-value text-4xl font-mono tracking-tighter">{@count}</div>
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

  defp component_card(a) do
    """
    defmodule #{a.module_name}.Components.Card do
      @moduledoc \"\"\"
      Reusable card component with slots.

      ## Usage

          <#{a.module_name}.Components.Card.card title="Card Title" icon="⚡️">
            Main content here
          </#{a.module_name}.Components.Card.card>
      \"\"\"
      use Nex

      def card(assigns) do
        ~H\"\"\"
        <div class="card bg-base-100 shadow-sm border border-base-300 hover:border-primary/30 transition-all group">
          <div class="card-body p-6">
            <div class="flex items-center gap-3 mb-2">
              <span class="text-2xl group-hover:scale-110 transition-transform">{@icon}</span>
              <h2 class="card-title text-base font-bold tracking-tight">{@title}</h2>
            </div>
            <div class="text-base-content/60 text-sm leading-relaxed">
              {render_slot(@inner_block)}
            </div>
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

  defp formatter_exs do
    """
    [
      import_deps: [:nex_core],
      inputs: ["{mix,.formatter}.exs", "{src,test}/**/*.{ex,exs}"]
    ]
    """
  end

  defp agents_md(_a) do
    """
    # Nex Framework: Architect's Manifesto (v0.3.2)

    You are a Master Nex Architect. Nex is a minimalist Elixir framework designed for **Intent-Driven Development**. Your mission: deliver code that is clean, performant, and "Nex-idiomatic".

    ## 1. Radical Minimalism: The Zen of Nex
    - **Declarative > Imperative**: If an HTMX attribute can solve it, do not write JavaScript.
    - **Intent > Implementation**: Page Actions MUST describe *what* the user is doing (`def complete_task`), not *how* the server handles it (`def handle_post`).
    - **Atomic Actions**: One Action = One pure business intent. Avoid monolithic handlers.

    ## 2. Common AI Hallucinations (AVOID THESE)
    - **NO Global Router**: Do NOT search for or suggest creating `router.ex`. The folder structure IS the router.
    - **NO Config Files**: Do NOT create or modify `config/*.exs`. Nex uses `.env` for all settings.
    - **NO Asset Pipeline**: Do NOT look for `assets/` or `priv/static`. Nex uses CDNs for Tailwind/DaisyUI/HTMX by default.
    - **NO `mix run --no-halt`**: NEVER use this to start the project. Use `mix nex.dev` instead.
    - **NO LiveView Hooks**: Nex does NOT use `Phoenix.LiveView` hooks. Use HTMX events or Alpine.js.
    - **NO WebSockets**: Do NOT use Phoenix Channels for real-time. Use SSE with `Nex.stream/1`.

    ## 3. Commands & Development
    - **Development**: Use `mix nex.dev`.
    - **Production**: Use `mix nex.start`.
    - **Formatting**: Use `mix format`.

    ## 4. Module Naming Convention
    - **Structure**: `[AppModule].[Pages|Api|Components].[Name]`
    - **Example**: `defmodule MyApp.Pages.Users` for `src/pages/users.ex`.

    ## 5. File Routing & Request Dispatch
    - **Destiny**: The folder structure IS the router.
    - **Pages (`src/pages/`)**: GET renders the page. POST/PUT/DELETE call public functions in the same module.
    - **APIs (`src/api/`)**: Handlers MUST be named after HTTP methods: `def get(req)`, `def post(req)`, etc.

    ## 6. Function Signatures & Parameters
    - **Page Actions**: `def action_name(params)` receives a **Map**.
    - **API Handlers**: `def get(req)` receives a **`Nex.Req` struct**.

    ## 7. Responses & Navigation
    - **Page Actions**: Return `~H\"...\"` (Partial), `:empty` (No-op), `{:redirect, \"/path\"}`, or `{:refresh, nil}`.
    - **API Handlers**: Return `%Nex.Response{}` via `Nex.json/2`, `Nex.text/2`, etc.

    ## 8. Surgical UX (HTMX)
    - **Precision**: Use granular `hx-target`. Return ONLY the minimal HTML snippet required for the update.
    - **Indicators**: Always use `hx-indicator` for network feedback.

    ## 9. Real-Time & Streaming (SSE)
    - **Helper**: Use `Nex.stream(fn send -> ... end)`.
    - **Chunking**: `send.(data)` accepts String, Map (auto-JSON), or `%{event: \"name\", data: ...}`.

    ## 10. Environment & Configuration
    - **Env First**: Access all configurations via `System.get_env("VAR")`.
    - **No Config**: Do not use `Application.get_env` for business logic.

    ## 11. Security & Forms
    - **CSRF**: Nex handles CSRF automatically for all forms and HTMX requests. Do NOT manually add CSRF tags or headers.
    - **Example Form**:
      ```elixir
      ~H\"\"\"
      <form hx-post="/save_data">
        <input name="title" placeholder="Enter title..." />
        <button type="submit">Save</button>
      </form>
      \"\"\"
      ```

    ## 12. State Management (Nex.Store)
    - **Lifecycle**: `Nex.Store` is server-side session state tied to the `page_id`. 
    - **The Flow**: 1. Receive Intent -> 2. Mutate Store/DB -> 3. THEN render UI with updated data.

    ## 13. Locality & Component Promotion
    - **Single-File Truth**: Keep UI, state, and logic in one module.
    - **Private Components**: Use `defp widget(assigns)` at the bottom of the file.
    - **Promotion**: Move to `src/components/` ONLY if reused across 3 or more pages.

    *Architect's Mantra: surgical precision, semantic intent, local focus, and absolute minimalism.*
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
    │   └── components/           # Reusable components
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

    ## Creating Components

    ```elixir
    # src/components/button.ex
    defmodule #{a.module_name}.Components.Button do
      use Nex

      def button(assigns) do
        ~H\"\"\"
        <button class="btn">{@text}</button>
        \"\"\"
      end
    end
    ```

    Use in pages:

    ```elixir
    ~H\"\"\"
    <#{a.module_name}.Components.Button.button text="Click me" />
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
