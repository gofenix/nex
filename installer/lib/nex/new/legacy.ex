defmodule Nex.New.Legacy do
  @moduledoc false

  def run([]) do
    Mix.raise(
      "Expected project name. Usage: mix nex.new my_app [--path PATH] [--starter STARTER]"
    )
  end

  def run(args) do
    {opts, parsed_args, _} =
      OptionParser.parse(args, switches: [path: :string, starter: :string])

    name =
      case parsed_args do
        [n | _] ->
          n

        [] ->
          Mix.raise(
            "Expected project name. Usage: mix nex.new my_app [--path PATH] [--starter STARTER]"
          )
      end

    unless valid_name?(name) do
      Mix.raise(
        "Project name must start with a letter and contain only lowercase letters, numbers, and underscores. Reserved names (elixir, mix, nex, etc.) are not allowed."
      )
    end

    base_path = opts[:path] || "."
    project_path = Path.expand(Path.join(base_path, name))
    starter = normalize_starter(opts[:starter])

    if File.dir?(project_path) do
      Mix.raise("Directory #{project_path} already exists")
    end

    module_name = Macro.camelize(name)
    assigns = %{app_name: name, module_name: module_name}

    Mix.shell().info("\n🚀 Creating Nex project: #{name}#{starter_label(starter)}\n")

    create_project(project_path, assigns, starter)

    # Initialize Git
    if System.find_executable("git") do
      Mix.shell().info("\n🌿 Initializing Git repository...\n")

      case System.cmd("git", ["init"], cd: project_path, stderr_to_stdout: true) do
        {_, 0} -> :ok
        {error, _} -> Mix.shell().error("Git init failed: #{error}")
      end
    end

    # Install dependencies automatically
    Mix.shell().info("\n📦 Installing dependencies...\n")

    if skip_deps_install?() do
      Mix.shell().info(success_message(name, starter, false))
    else
      case System.cmd("mix", ["deps.get"], cd: project_path, stderr_to_stdout: true) do
        {_, 0} ->
          Mix.shell().info(success_message(name, starter, true))

        {error, _} ->
          Mix.raise("""
          Dependencies installation failed!

          Error: #{error}

          You can try installing manually:
              cd #{name}
              mix deps.get
          """)
      end
    end
  end

  def normalize_starter(nil), do: :basic
  def normalize_starter("basic"), do: :basic
  def normalize_starter("saas"), do: :saas

  def normalize_starter(other) do
    Mix.raise("Unknown starter #{inspect(other)}. Available starters: basic, saas")
  end

  def starter_label(:basic), do: ""
  def starter_label(:saas), do: " (starter: saas)"

  def normalize_frontend(nil), do: :htmx
  def normalize_frontend("htmx"), do: :htmx
  def normalize_frontend("datastar"), do: :datastar

  def normalize_frontend(other) do
    Mix.raise("Unknown frontend #{inspect(other)}. Available frontends: htmx, datastar")
  end

  def frontend_label(:htmx), do: ""
  def frontend_label(:datastar), do: " (frontend: datastar)"

  def skip_deps_install? do
    System.get_env("NEX_NEW_SKIP_DEPS") == "1"
  end

  def success_message(name, :basic, true) do
    """

    ✅ Project created successfully!

    Next steps:

        cd #{name}
        mix nex.dev

    Then open http://localhost:4000 in your browser.
    """
  end

  def success_message(name, :basic, false) do
    """

    ✅ Project created successfully!

    Dependencies were not installed automatically.

    Next steps:

        cd #{name}
        mix deps.get
        mix nex.dev

    Then open http://localhost:4000 in your browser.
    """
  end

  def success_message(name, :saas, true) do
    """

    ✅ SaaS starter created successfully!

    Next steps:

        cd #{name}
        mix nex.dev

    The starter will bootstrap its SQLite schema on first run.
    Then open http://localhost:4000 in your browser.
    """
  end

  def success_message(name, :saas, false) do
    """

    ✅ SaaS starter created successfully!

    Dependencies were not installed automatically.

    Next steps:

        cd #{name}
        mix deps.get
        mix nex.dev

    The starter will bootstrap its SQLite schema on first run.
    Then open http://localhost:4000 in your browser.
    """
  end

  def valid_name?(name) do
    reserved = ["elixir", "mix", "nex", "nex_core", "node", "phoenix", "proxy"]
    Regex.match?(~r/^[a-z][a-z0-9_]*$/, name) and name not in reserved
  end

  def create_project(path, assigns, starter) do
    # Create directories
    dirs = project_dirs(path, starter)

    Enum.each(dirs, fn dir ->
      File.mkdir_p!(dir)
      Mix.shell().info("  Created: #{dir}/")
    end)

    # Create files
    files = project_files(assigns, starter)

    Enum.each(files, fn {file, content} ->
      full_path = Path.join(path, file)
      File.write!(full_path, content)
      Mix.shell().info("  Created: #{full_path}")
    end)
  end

  def project_dirs(path, :basic) do
    [path, "#{path}/src", "#{path}/src/pages", "#{path}/src/api", "#{path}/src/components"]
  end

  def project_dirs(path, :saas) do
    [
      path,
      "#{path}/db",
      "#{path}/src",
      "#{path}/src/api",
      "#{path}/src/components",
      "#{path}/src/pages",
      "#{path}/src/plugs"
    ]
  end

  def project_files(assigns, :basic) do
    [
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
  end

  def project_files(assigns, :saas) do
    [
      {"mix.exs", saas_mix_exs(assigns)},
      {"src/application.ex", saas_application(assigns)},
      {"src/layouts.ex", saas_layouts(assigns)},
      {"src/data.ex", saas_data(assigns)},
      {"src/accounts.ex", saas_accounts(assigns)},
      {"src/workspace.ex", saas_workspace(assigns)},
      {"src/plugs/require_auth.ex", saas_require_auth(assigns)},
      {"src/components/flash.ex", saas_flash_component(assigns)},
      {"src/pages/index.ex", saas_index(assigns)},
      {"src/pages/login.ex", saas_login(assigns)},
      {"src/pages/signup.ex", saas_signup(assigns)},
      {"src/pages/dashboard.ex", saas_dashboard(assigns)},
      {"src/api/health.ex", saas_api_health(assigns)},
      {"db/.gitkeep", ""},
      {".gitignore", gitignore()},
      {".dockerignore", dockerignore()},
      {"Dockerfile", dockerfile()},
      {".env.example", saas_env_example(assigns)},
      {".formatter.exs", formatter_exs()},
      {"AGENTS.md", agents_md(assigns)},
      {"README.md", saas_readme(assigns)}
    ]
  end

  # Templates

  def mix_exs(a) do
    nex_core_version = nex_core_version()

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
          {:nex_core, "~> #{nex_core_version}"}
        ]
      end
    end
    """
  end

  def nex_core_version do
    case Application.spec(:nex_new, :vsn) do
      nil -> "0.4.2"
      vsn -> List.to_string(vsn)
    end
  end

  def application(a) do
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

  def layouts(a) do
    frontend_script = ~s(<script src="https://unpkg.com/htmx.org@2.0.4"></script>)
    build_document(a, frontend_script, ~s( hx-boost="true"))
  end

  def app_template(a) do
    build_app(a)
  end

  def document_template(a) do
    frontend_script = ~s(<script src="https://unpkg.com/htmx.org@2.0.4"></script>)
    build_document(a, frontend_script, ~s( hx-boost="true"))
  end

  def index(a) do
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

  def api_hello(a) do
    """
    defmodule #{a.module_name}.Api.Hello do
      @moduledoc \"\"\"
      Example API endpoint - Next.js style.

      ## Endpoints
      - GET /api/hello?name=World
      - POST /api/hello with body: {"name": "Alice"}

      ## Next.js API Routes Alignment
      - `req.query` - Path params + query string (path params take precedence)
      - `req.body` - Request body (Map for POST/PUT/PATCH, nil for GET/DELETE)
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

  def component_card(a) do
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

  # --- Datastar Frontend Templates ---

  def datastar_layouts(a) do
    frontend_script =
      ~s(<script type="module" src="https://cdn.jsdelivr.net/npm/@starfederation/datastar@1.0.0-beta.11/dist/datastar.min.js"></script>)

    build_document(a, frontend_script, "")
  end

  def datastar_app_template(a) do
    build_app(a)
  end

  def datastar_document_template(a) do
    frontend_script =
      ~s(<script type="module" src="https://cdn.jsdelivr.net/npm/@starfederation/datastar@1.0.0-beta.11/dist/datastar.min.js"></script>)

    build_document(a, frontend_script, "")
  end

  def datastar_index(a) do
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
          <div class="text-center py-12 bg-base-100 rounded-3xl shadow-sm border border-base-300"
               data-signals={Jason.encode!(%{count: @count})}>
            <h1 class="text-5xl font-black mb-4 tracking-tight text-primary">Nex + Datastar</h1>
            <p class="text-lg text-base-content/60 mb-8">
              The simplest way to build reactive web apps with Elixir.
            </p>

            <div class="flex flex-col items-center gap-4">
              <div id="counter-display" class="stat place-items-center bg-base-200 rounded-xl w-48 py-4 border border-base-300">
                <div class="stat-title text-base-content/50 uppercase tracking-widest text-xs font-bold">Current Count</div>
                <div class="stat-value text-4xl font-mono tracking-tighter" data-text="$count">{@count}</div>
              </div>

              <div class="flex gap-2">
                <button
                  class="btn btn-primary btn-lg shadow-lg"
                  data-on:click="@post('/api/counter', {action: 'increment'})"
                >
                  Increment
                </button>

                <button
                  class="btn btn-ghost btn-lg"
                  data-on:click="@post('/api/counter', {action: 'reset'})"
                >
                  Reset
                </button>
              </div>
            </div>
          </div>

          <div class="grid md:grid-cols-2 gap-6">
            <#{a.module_name}.Components.Card.card title="Reactive Signals" icon="⚡️">
              Datastar signals provide two-way binding and reactive UI updates without JavaScript.
            </#{a.module_name}.Components.Card.card>

            <#{a.module_name}.Components.Card.card title="SSE Native" icon="📡">
              Built-in Server-Sent Events support for real-time streaming updates.
            </#{a.module_name}.Components.Card.card>
          </div>

          <div class="alert alert-info shadow-sm border-none bg-blue-50 text-blue-800">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-current shrink-0 w-6 h-6"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
            <span>Check <code>AGENTS.md</code> to see how to pair Nex with AI agents.</span>
          </div>
        </div>
        \"\"\"
      end
    end
    """
  end

  def datastar_api_counter(a) do
    """
    defmodule #{a.module_name}.Api.Counter do
      @moduledoc \"\"\"
      Counter API endpoint for Datastar integration.

      Handles increment and reset actions, returning HTML fragments
      that Datastar morphs into the DOM via signal updates.

      ## Endpoints
      - POST /api/counter  {action: "increment"} or {action: "reset"}
      \"\"\"
      use Nex

      def post(req) do
        case req.body["action"] do
          "increment" ->
            new_count = Nex.Store.update(:count, 0, &(&1 + 1))
            Nex.json(%{count: new_count})

          "reset" ->
            Nex.Store.put(:count, 0)
            Nex.json(%{count: 0})

          _ ->
            Nex.json(%{error: "Unknown action"}, status: 400)
        end
      end
    end
    """
  end

  defp build_app(a) do
    """
    defmodule #{a.module_name}.Pages.App do
      use Nex

      def render(assigns) do
        ~H\"\"\"
        <nav class="navbar bg-base-100 shadow-sm">
          <div class="max-w-4xl mx-auto w-full px-4">
            <a href="/" class="btn btn-ghost text-xl">#{a.module_name}</a>
          </div>
        </nav>
        <main class="max-w-4xl mx-auto px-4 py-8">
          {raw(@inner_content)}
        </main>
        \"\"\"
      end
    end
    """
  end

  defp build_document(a, frontend_script, body_attrs) do
    """
    defmodule #{a.module_name}.Pages.Document do
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
            #{frontend_script}
          </head>
          <body class="min-h-screen bg-base-200"#{body_attrs}>
            {raw(@inner_content)}
          </body>
        </html>
        \"\"\"
      end
    end
    """
  end

  def gitignore do
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

  def dockerignore do
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

  def dockerfile do
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

  def env_example do
    """
    # Server Configuration
    PORT=4000
    HOST=localhost

    # Add your environment variables here
    # DATABASE_URL=postgres://user:pass@localhost/myapp_dev
    # API_KEY=your_api_key_here
    """
  end

  def formatter_exs do
    """
    [
      import_deps: [:nex_core],
      inputs: ["{mix,.formatter}.exs", "{src,test}/**/*.{ex,exs}"]
    ]
    """
  end

  def saas_mix_exs(a) do
    nex_version = nex_core_version()

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
          extra_applications: [:logger, :crypto],
          mod: {#{a.module_name}.Application, []}
        ]
      end

      defp deps do
        [
          {:nex_core, "~> #{nex_version}"},
          {:nex_base, "~> #{nex_version}"},
          {:nex_env, "~> #{nex_version}"},
          {:ecto_sqlite3, "~> 0.17"},
          {:pbkdf2_elixir, "~> 2.3"}
        ]
      end
    end
    """
  end

  def saas_application(a) do
    default_database_url = "sqlite://db/#{a.app_name}_dev.db"

    """
    defmodule #{a.module_name}.Application do
      use Application

      @impl true
      def start(_type, _args) do
        Nex.Env.init()
        #{a.module_name}.Data.ensure_database_dir!()

        Application.put_env(:nex_core, :plugs, [
          #{a.module_name}.Plugs.RequireAuth
        ])

        conn =
          NexBase.init(
            url: Nex.Env.get(:database_url, "#{default_database_url}"),
            ssl: Nex.Env.get_boolean(:database_ssl, false),
            prepare: :unnamed
          )

        children = [
          {NexBase.Repo, conn}
        ]

        opts = [strategy: :one_for_one, name: #{a.module_name}.Supervisor]

        case Supervisor.start_link(children, opts) do
          {:ok, pid} ->
            #{a.module_name}.Data.ensure_schema!()
            {:ok, pid}

          other ->
            other
        end
      end
    end
    """
  end

  def saas_data(a) do
    default_database_url = "sqlite://db/#{a.app_name}_dev.db"

    """
    defmodule #{a.module_name}.Data do
      @default_database_url "#{default_database_url}"

      def ensure_database_dir! do
        url = database_url()

        if String.starts_with?(url, "sqlite") do
          url
          |> sqlite_path()
          |> Path.dirname()
          |> File.mkdir_p!()
        end
      end

      def ensure_schema! do
        statements =
          case NexBase.adapter() do
            :sqlite -> sqlite_schema()
            :postgres -> postgres_schema()
          end

        Enum.each(statements, &NexBase.query!(&1, []))
      end

      defp database_url do
        Nex.Env.get(:database_url, @default_database_url)
      end

      defp sqlite_path("sqlite:///" <> path), do: "/" <> path
      defp sqlite_path("sqlite://" <> path), do: path
      defp sqlite_path(path), do: path

      defp sqlite_schema do
        [
          \"\"\"
          CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL,
            password_hash TEXT NOT NULL,
            inserted_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
          \"\"\",
          "CREATE UNIQUE INDEX IF NOT EXISTS users_email_idx ON users (email)",
          \"\"\"
          CREATE TABLE IF NOT EXISTS projects (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            plan TEXT NOT NULL,
            status TEXT NOT NULL,
            inserted_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            archived_at TEXT,
            FOREIGN KEY(user_id) REFERENCES users(id)
          )
          \"\"\",
          "CREATE INDEX IF NOT EXISTS projects_user_id_idx ON projects (user_id)"
        ]
      end

      defp postgres_schema do
        [
          \"\"\"
          CREATE TABLE IF NOT EXISTS users (
            id BIGSERIAL PRIMARY KEY,
            name TEXT NOT NULL,
            email TEXT NOT NULL,
            password_hash TEXT NOT NULL,
            inserted_at TIMESTAMPTZ NOT NULL,
            updated_at TIMESTAMPTZ NOT NULL
          )
          \"\"\",
          "CREATE UNIQUE INDEX IF NOT EXISTS users_email_idx ON users (email)",
          \"\"\"
          CREATE TABLE IF NOT EXISTS projects (
            id BIGSERIAL PRIMARY KEY,
            user_id BIGINT NOT NULL REFERENCES users(id),
            name TEXT NOT NULL,
            plan TEXT NOT NULL,
            status TEXT NOT NULL,
            inserted_at TIMESTAMPTZ NOT NULL,
            updated_at TIMESTAMPTZ NOT NULL,
            archived_at TIMESTAMPTZ
          )
          \"\"\",
          "CREATE INDEX IF NOT EXISTS projects_user_id_idx ON projects (user_id)"
        ]
      end
    end
    """
  end

  def saas_accounts(a) do
    """
    defmodule #{a.module_name}.Accounts do
      @min_password_length 8

      def current_user do
        case Nex.Session.get(:user_id) do
          nil ->
            nil

          user_id ->
            case get_user(user_id) do
              {:ok, user} -> user
              {:error, _message} -> nil
            end
        end
      end

      def get_user(user_id) do
        with {:ok, id} <- parse_id(user_id),
             {:ok, [user]} <-
               NexBase.from("users")
               |> NexBase.eq(:id, id)
               |> NexBase.single()
               |> NexBase.run() do
          {:ok, user}
        else
          {:ok, []} -> {:error, "User not found."}
          {:error, reason} -> {:error, inspect(reason)}
        end
      end

      def register_user(attrs) do
        name = normalize_text(attrs["name"])
        email = normalize_email(attrs["email"])
        password = to_string(attrs["password"] || "")

        with :ok <- validate_registration(name, email, password),
             {:ok, nil} <- find_user_by_email(email),
             {:ok, _} <-
               NexBase.from("users")
               |> NexBase.insert(%{
                 name: name,
                 email: email,
                 password_hash: Pbkdf2.hash_pwd_salt(password),
                 inserted_at: timestamp(),
                 updated_at: timestamp()
               })
               |> NexBase.run(),
             {:ok, user} <- find_user_by_email(email) do
          {:ok, user}
        else
          {:ok, _user} ->
            {:error, "An account with that email already exists."}

          {:error, reason} ->
            {:error, reason}
        end
      end

      def authenticate_user(email, password) do
        normalized_email = normalize_email(email)
        password = to_string(password || "")

        with {:ok, user} <- find_user_by_email(normalized_email),
             true <- Pbkdf2.verify_pass(password, user["password_hash"]) do
          {:ok, user}
        else
          {:ok, nil} ->
            {:error, "Invalid email or password."}

          false ->
            {:error, "Invalid email or password."}

          {:error, _reason} ->
            {:error, "Invalid email or password."}
        end
      end

      defp validate_registration(name, email, password) do
        cond do
          name == "" ->
            {:error, "Name is required."}

          String.length(name) < 2 ->
            {:error, "Name must be at least 2 characters."}

          email == "" ->
            {:error, "Email is required."}

          not String.contains?(email, "@") ->
            {:error, "Email must look valid."}

          String.length(password) < @min_password_length ->
            {:error, "Password must be at least \#{@min_password_length} characters."}

          true ->
            :ok
        end
      end

      defp find_user_by_email(email) do
        case NexBase.from("users")
             |> NexBase.eq(:email, email)
             |> NexBase.single()
             |> NexBase.run() do
          {:ok, [user]} -> {:ok, user}
          {:ok, []} -> {:ok, nil}
          {:error, reason} -> {:error, inspect(reason)}
        end
      end

      defp normalize_email(value) do
        value
        |> to_string()
        |> String.trim()
        |> String.downcase()
      end

      defp normalize_text(value) do
        value
        |> to_string()
        |> String.trim()
      end

      defp parse_id(value) when is_integer(value), do: {:ok, value}

      defp parse_id(value) when is_binary(value) do
        case Integer.parse(value) do
          {id, ""} -> {:ok, id}
          _ -> {:error, "Invalid identifier."}
        end
      end

      defp parse_id(_value), do: {:error, "Invalid identifier."}

      defp timestamp do
        DateTime.utc_now()
        |> DateTime.truncate(:second)
        |> DateTime.to_iso8601()
      end
    end
    """
  end

  def saas_workspace(a) do
    """
    defmodule #{a.module_name}.Workspace do
      @plans ["starter", "growth", "scale"]

      def list_projects(user_id) do
        with {:ok, id} <- parse_id(user_id) do
          NexBase.from("projects")
          |> NexBase.eq(:user_id, id)
          |> NexBase.is(:archived_at, nil)
          |> NexBase.order(:inserted_at, :desc)
          |> NexBase.run()
        else
          {:error, reason} -> {:error, reason}
        end
      end

      def create_project(user_id, attrs) do
        with {:ok, id} <- parse_id(user_id),
             {:ok, name} <- validate_name(attrs["name"]),
             plan <- normalize_plan(attrs["plan"]),
             {:ok, result} <-
               NexBase.from("projects")
               |> NexBase.insert(%{
                 user_id: id,
                 name: name,
                 plan: plan,
                 status: "active",
                 inserted_at: timestamp(),
                 updated_at: timestamp(),
                 archived_at: nil
               })
               |> NexBase.run() do
          {:ok, result}
        else
          {:error, reason} -> {:error, reason}
        end
      end

      def archive_project(user_id, project_id) do
        with {:ok, user_id} <- parse_id(user_id),
             {:ok, project_id} <- parse_id(project_id),
             {:ok, result} <-
               NexBase.from("projects")
               |> NexBase.eq(:id, project_id)
               |> NexBase.eq(:user_id, user_id)
               |> NexBase.update(%{
                 status: "archived",
                 archived_at: timestamp(),
                 updated_at: timestamp()
               })
               |> NexBase.run() do
          {:ok, result}
        else
          {:error, reason} -> {:error, reason}
        end
      end

      defp validate_name(nil), do: {:error, "Project name is required."}

      defp validate_name(name) do
        cleaned = name |> to_string() |> String.trim()

        cond do
          cleaned == "" -> {:error, "Project name is required."}
          String.length(cleaned) < 2 -> {:error, "Project name must be at least 2 characters."}
          true -> {:ok, cleaned}
        end
      end

      defp normalize_plan(plan) do
        normalized =
          plan
          |> to_string()
          |> String.trim()
          |> String.downcase()

        if normalized in @plans, do: normalized, else: "starter"
      end

      defp parse_id(value) when is_integer(value), do: {:ok, value}

      defp parse_id(value) when is_binary(value) do
        case Integer.parse(value) do
          {id, ""} -> {:ok, id}
          _ -> {:error, "Invalid identifier."}
        end
      end

      defp parse_id(_value), do: {:error, "Invalid identifier."}

      defp timestamp do
        DateTime.utc_now()
        |> DateTime.truncate(:second)
        |> DateTime.to_iso8601()
      end
    end
    """
  end

  def saas_require_auth(a) do
    """
    defmodule #{a.module_name}.Plugs.RequireAuth do
      import Plug.Conn

      @public_exact [[]]
      @public_prefixes [["login"], ["signup"], ["static"], ["nex"], ["api", "health"]]

      def init(opts), do: opts

      def call(conn, _opts) do
        path = conn.path_info

        public? =
          path in @public_exact or
            Enum.any?(@public_prefixes, fn prefix -> List.starts_with?(path, prefix) end)

        if public? or Nex.Session.get(:user_id) do
          conn
        else
          Nex.Flash.put(:error, "Please sign in to continue.")

          conn
          |> put_resp_header("location", "/login")
          |> send_resp(302, "")
          |> halt()
        end
      end
    end
    """
  end

  def saas_flash_component(a) do
    """
    defmodule #{a.module_name}.Components.Flash do
      use Nex

      def messages(assigns) do
        flash = Map.get(assigns, :flash, %{})
        assigns = Map.put(assigns, :flash, flash)

        ~H\"\"\"
        <div class="space-y-3" :if={map_size(@flash) > 0}>
          <div :if={@flash[:error]} class="rounded-2xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-700">
            {@flash[:error]}
          </div>
          <div :if={@flash[:success]} class="rounded-2xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700">
            {@flash[:success]}
          </div>
          <div :if={@flash[:info]} class="rounded-2xl border border-sky-200 bg-sky-50 px-4 py-3 text-sm text-sky-700">
            {@flash[:info]}
          </div>
        </div>
        \"\"\"
      end
    end
    """
  end

  def saas_layouts(a) do
    saas_document_template(a)
  end

  def saas_app_template(a) do
    """
    defmodule #{a.module_name}.Pages.App do
      use Nex

      def render(assigns) do
        ~H\"\"\"
        <div class="min-h-screen">
          <header class="border-b border-black/10 bg-white/80 backdrop-blur">
            <div class="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
              <a href="/" class="text-lg font-black tracking-tight text-slate-950">#{a.module_name}</a>

              <nav class="flex items-center gap-3 text-sm">
                <a :if={@current_user} href="/dashboard" class="btn btn-sm btn-ghost">Dashboard</a>
                <span :if={@current_user} class="hidden text-slate-500 sm:inline">
                  Signed in as {@current_user["name"]}
                </span>
                <form :if={@current_user} hx-post="/dashboard/logout" hx-target="body">
                  <button type="submit" class="btn btn-sm btn-primary">Logout</button>
                </form>
                <a :if={!@current_user} href="/login" class="btn btn-sm btn-ghost">Log in</a>
                <a :if={!@current_user} href="/signup" class="btn btn-sm btn-primary">Create account</a>
              </nav>
            </div>
          </header>

          <main class="mx-auto max-w-6xl px-6 py-10">
            {raw(@inner_content)}
          </main>
        </div>
        \"\"\"
      end
    end
    """
  end

  def saas_document_template(a) do
    """
    defmodule #{a.module_name}.Pages.Document do
      use Nex

      def render(assigns) do
        ~H\"\"\"
        <!DOCTYPE html>
        <html lang="en">
          <head>
            <meta charset="UTF-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1.0" />
            <title>{@title}</title>
            <script src="https://cdn.tailwindcss.com?plugins=forms,typography,aspect-ratio"></script>
            <link href="https://cdn.jsdelivr.net/npm/daisyui@4.12.23/dist/full.min.css" rel="stylesheet" type="text/css" />
            <script src="https://unpkg.com/htmx.org@2.0.4"></script>
          </head>
          <body class="min-h-screen bg-[#f5f1e8] text-slate-900" hx-boost="true">
            {raw(@inner_content)}
          </body>
        </html>
        \"\"\"
      end
    end
    """
  end

  def saas_index(a) do
    """
    defmodule #{a.module_name}.Pages.Index do
      use Nex

      def mount(_params) do
        current_user = #{a.module_name}.Accounts.current_user()

        recent_projects =
          if current_user do
            case #{a.module_name}.Workspace.list_projects(current_user["id"]) do
              {:ok, projects} -> Enum.take(projects, 3)
              {:error, _reason} -> []
            end
          else
            []
          end

        %{
          title: "#{a.module_name} Starter",
          current_user: current_user,
          recent_projects: recent_projects,
          flash: Flash.pop_all()
        }
      end

      def render(assigns) do
        ~H\"\"\"
        <div class="space-y-8">
          <#{a.module_name}.Components.Flash.messages flash={@flash} />

          <section class="grid gap-8 rounded-[2rem] bg-slate-950 px-8 py-10 text-white lg:grid-cols-[1.3fr_0.7fr]">
            <div class="space-y-5">
              <p class="text-xs font-semibold uppercase tracking-[0.24em] text-cyan-300">
                SaaS starter
              </p>
              <h1 class="max-w-2xl text-4xl font-black tracking-tight sm:text-5xl">
                Ship auth, data, and a real dashboard before lunch.
              </h1>
              <p class="max-w-2xl text-base leading-7 text-slate-300">
                This starter wires Nex pages, HTMX actions, NexBase, session auth, and a
                protected product dashboard into one cohesive starting point.
              </p>

              <div class="flex flex-wrap gap-3">
                <a :if={@current_user} href="/dashboard" class="btn btn-primary">Open dashboard</a>
                <a :if={!@current_user} href="/signup" class="btn btn-primary">Create account</a>
                <a :if={!@current_user} href="/login" class="btn btn-outline btn-info">Log in</a>
              </div>
            </div>

            <div class="rounded-[1.75rem] border border-white/10 bg-white/5 p-6">
              <p class="text-sm font-semibold uppercase tracking-[0.18em] text-slate-400">
                What is included
              </p>
              <ul class="mt-4 space-y-3 text-sm text-slate-200">
                <li>Database-backed accounts with secure password hashing</li>
                <li>Protected dashboard routes via Nex middleware</li>
                <li>Starter project CRUD powered by HTMX actions</li>
                <li>SQLite by default, Postgres-ready via `DATABASE_URL`</li>
              </ul>
            </div>
          </section>

          <section
            :if={@current_user}
            class="grid gap-6 rounded-[2rem] border border-black/10 bg-white/80 p-8 shadow-sm lg:grid-cols-[0.55fr_0.45fr]"
          >
            <div class="space-y-2">
              <p class="text-sm font-semibold uppercase tracking-[0.18em] text-slate-400">
                Welcome back
              </p>
              <h2 class="text-3xl font-black tracking-tight text-slate-950">
                {@current_user["name"]}
              </h2>
              <p class="max-w-xl text-sm leading-7 text-slate-600">
                Your account is live. Head to the dashboard to create and manage projects,
                inspect the generated code, and start shaping the product from a real base.
              </p>
            </div>

            <div class="rounded-[1.5rem] bg-stone-100 p-6">
              <p class="text-sm font-semibold uppercase tracking-[0.18em] text-stone-500">
                Recent projects
              </p>
              <div class="mt-4 space-y-3" :if={@recent_projects != []}>
                <div
                  :for={project <- @recent_projects}
                  class="rounded-2xl border border-stone-200 bg-white px-4 py-3"
                >
                  <div class="flex items-center justify-between gap-3">
                    <div>
                      <p class="font-semibold text-slate-900">{project["name"]}</p>
                      <p class="text-xs uppercase tracking-[0.18em] text-slate-400">
                        {project["plan"]} plan
                      </p>
                    </div>
                    <span class="rounded-full bg-emerald-100 px-3 py-1 text-xs font-semibold text-emerald-700">
                      {project["status"]}
                    </span>
                  </div>
                </div>
              </div>

              <p :if={@recent_projects == []} class="mt-4 text-sm text-slate-500">
                No projects yet. Create your first one from the dashboard.
              </p>
            </div>
          </section>
        </div>
        \"\"\"
      end
    end
    """
  end

  def saas_login(a) do
    """
    defmodule #{a.module_name}.Pages.Login do
      use Nex

      def mount(_params) do
        %{
          title: "Log in",
          current_user: #{a.module_name}.Accounts.current_user(),
          flash: Flash.pop_all()
        }
      end

      def render(assigns) do
        ~H\"\"\"
        <div class="mx-auto max-w-md space-y-6">
          <#{a.module_name}.Components.Flash.messages flash={@flash} />

          <div class="rounded-[2rem] border border-black/10 bg-white/90 p-8 shadow-sm">
            <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">
              Sign in
            </p>
            <h1 class="mt-3 text-3xl font-black tracking-tight text-slate-950">
              Welcome back
            </h1>
            <p class="mt-2 text-sm leading-7 text-slate-600">
              Use the account you created from the starter signup flow.
            </p>

            <div :if={@current_user} class="mt-6 rounded-2xl bg-emerald-50 px-4 py-3 text-sm text-emerald-700">
              You are already signed in as {@current_user["name"]}. Head to
              <a href="/dashboard" class="font-semibold underline">the dashboard</a>.
            </div>

            <form :if={!@current_user} hx-post="/login/authenticate" hx-target="body" class="mt-8 space-y-4">
              <label class="form-control">
                <div class="label">
                  <span class="label-text font-medium text-slate-700">Email</span>
                </div>
                <input
                  type="email"
                  name="email"
                  placeholder="founder@example.com"
                  class="input input-bordered w-full bg-white"
                />
              </label>

              <label class="form-control">
                <div class="label">
                  <span class="label-text font-medium text-slate-700">Password</span>
                </div>
                <input
                  type="password"
                  name="password"
                  placeholder="At least 8 characters"
                  class="input input-bordered w-full bg-white"
                />
              </label>

              <button type="submit" class="btn btn-primary mt-2 w-full">
                Log in
              </button>
            </form>
          </div>
        </div>
        \"\"\"
      end

      def authenticate(req) do
        case #{a.module_name}.Accounts.authenticate_user(req.body["email"], req.body["password"]) do
          {:ok, user} ->
            Session.put(:user_id, user["id"])
            Flash.put(:success, "Welcome back, \#{user["name"]}.")
            Nex.redirect("/dashboard")

          {:error, message} ->
            Flash.put(:error, message)
            Nex.redirect("/login")
        end
      end
    end
    """
  end

  def saas_signup(a) do
    """
    defmodule #{a.module_name}.Pages.Signup do
      use Nex

      def mount(_params) do
        %{
          title: "Create account",
          current_user: #{a.module_name}.Accounts.current_user(),
          flash: Flash.pop_all()
        }
      end

      def render(assigns) do
        ~H\"\"\"
        <div class="mx-auto max-w-md space-y-6">
          <#{a.module_name}.Components.Flash.messages flash={@flash} />

          <div class="rounded-[2rem] border border-black/10 bg-white/90 p-8 shadow-sm">
            <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">
              Create account
            </p>
            <h1 class="mt-3 text-3xl font-black tracking-tight text-slate-950">
              Launch your first workspace
            </h1>
            <p class="mt-2 text-sm leading-7 text-slate-600">
              This starter provisions the database schema automatically and signs you in
              after the account is created.
            </p>

            <div :if={@current_user} class="mt-6 rounded-2xl bg-emerald-50 px-4 py-3 text-sm text-emerald-700">
              You already have an active session. Go straight to
              <a href="/dashboard" class="font-semibold underline">the dashboard</a>.
            </div>

            <form :if={!@current_user} hx-post="/signup/create_account" hx-target="body" class="mt-8 space-y-4">
              <label class="form-control">
                <div class="label">
                  <span class="label-text font-medium text-slate-700">Name</span>
                </div>
                <input
                  type="text"
                  name="name"
                  placeholder="Ada Lovelace"
                  class="input input-bordered w-full bg-white"
                />
              </label>

              <label class="form-control">
                <div class="label">
                  <span class="label-text font-medium text-slate-700">Email</span>
                </div>
                <input
                  type="email"
                  name="email"
                  placeholder="ada@example.com"
                  class="input input-bordered w-full bg-white"
                />
              </label>

              <label class="form-control">
                <div class="label">
                  <span class="label-text font-medium text-slate-700">Password</span>
                </div>
                <input
                  type="password"
                  name="password"
                  placeholder="At least 8 characters"
                  class="input input-bordered w-full bg-white"
                />
              </label>

              <button type="submit" class="btn btn-primary mt-2 w-full">
                Create account
              </button>
            </form>
          </div>
        </div>
        \"\"\"
      end

      def create_account(req) do
        with {:ok, user} <- #{a.module_name}.Accounts.register_user(req.body),
             {:ok, _result} <-
               #{a.module_name}.Workspace.create_project(
                 user["id"],
                 %{"name" => user["name"] <> "'s first project"}
               ) do
          Session.put(:user_id, user["id"])
          Flash.put(:success, "Account created. Your workspace is ready.")
          Nex.redirect("/dashboard")
        else
          {:error, message} ->
            Flash.put(:error, message)
            Nex.redirect("/signup")
        end
      end
    end
    """
  end

  def saas_dashboard(a) do
    """
    defmodule #{a.module_name}.Pages.Dashboard do
      use Nex

      def mount(_params) do
        current_user = #{a.module_name}.Accounts.current_user()

        projects =
          if current_user do
            case #{a.module_name}.Workspace.list_projects(current_user["id"]) do
              {:ok, rows} -> rows
              {:error, _reason} -> []
            end
          else
            []
          end

        %{
          title: "Dashboard",
          current_user: current_user,
          flash: Flash.pop_all(),
          projects: projects,
          project_count: length(projects),
          latest_project: List.first(projects)
        }
      end

      def render(assigns) do
        ~H\"\"\"
        <div class="space-y-8">
          <div class="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
            <div>
              <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">
                Protected dashboard
              </p>
              <h1 class="mt-2 text-4xl font-black tracking-tight text-slate-950">
                {@current_user["name"]}'s workspace
              </h1>
              <p class="mt-2 max-w-2xl text-sm leading-7 text-slate-600">
                This page is protected by Nex middleware and backed by NexBase. Use it as
                the first product surface you customize after generating the starter.
              </p>
            </div>

            <div class="rounded-2xl bg-white/80 px-4 py-3 text-sm shadow-sm">
              Signed in as <span class="font-semibold text-slate-950">{@current_user["email"]}</span>
            </div>
          </div>

          <#{a.module_name}.Components.Flash.messages flash={@flash} />

          <section class="grid gap-4 md:grid-cols-3">
            <div class="rounded-[1.75rem] border border-black/10 bg-white/90 p-6 shadow-sm">
              <p class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">
                Active projects
              </p>
              <p class="mt-3 text-4xl font-black tracking-tight text-slate-950">
                {@project_count}
              </p>
            </div>

            <div class="rounded-[1.75rem] border border-black/10 bg-white/90 p-6 shadow-sm">
              <p class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">
                Latest project
              </p>
              <p :if={@latest_project} class="mt-3 text-xl font-semibold text-slate-950">
                {@latest_project["name"]}
              </p>
              <p :if={!@latest_project} class="mt-3 text-xl font-semibold text-slate-950">
                No projects yet
              </p>
            </div>

            <div class="rounded-[1.75rem] border border-black/10 bg-slate-950 p-6 text-white shadow-sm">
              <p class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">
                Next move
              </p>
              <p class="mt-3 text-lg font-semibold">
                Add billing, invitations, and your first customer-facing workflow.
              </p>
            </div>
          </section>

          <section class="grid gap-6 lg:grid-cols-[0.48fr_0.52fr]">
            <div class="rounded-[2rem] border border-black/10 bg-white/90 p-8 shadow-sm">
              <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">
                Create project
              </p>
              <h2 class="mt-3 text-2xl font-black tracking-tight text-slate-950">
                Add the next thing you want to ship
              </h2>

              <form hx-post="/dashboard/create_project" hx-target="body" class="mt-6 space-y-4">
                <label class="form-control">
                  <div class="label">
                    <span class="label-text font-medium text-slate-700">Project name</span>
                  </div>
                  <input
                    type="text"
                    name="name"
                    placeholder="Weekly revenue dashboard"
                    class="input input-bordered w-full bg-white"
                  />
                </label>

                <label class="form-control">
                  <div class="label">
                    <span class="label-text font-medium text-slate-700">Plan</span>
                  </div>
                  <select name="plan" class="select select-bordered w-full bg-white">
                    <option value="starter">Starter</option>
                    <option value="growth">Growth</option>
                    <option value="scale">Scale</option>
                  </select>
                </label>

                <button type="submit" class="btn btn-primary w-full">
                  Create project
                </button>
              </form>
            </div>

            <div class="rounded-[2rem] border border-black/10 bg-white/90 p-8 shadow-sm">
              <div class="flex items-center justify-between gap-4">
                <div>
                  <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">
                    Live projects
                  </p>
                  <h2 class="mt-3 text-2xl font-black tracking-tight text-slate-950">
                    Current workspace list
                  </h2>
                </div>
                <span class="rounded-full bg-stone-100 px-3 py-1 text-xs font-semibold uppercase tracking-[0.18em] text-stone-600">
                  HTMX powered
                </span>
              </div>

              <div :if={@projects == []} class="mt-6 rounded-[1.5rem] bg-stone-100 px-5 py-6 text-sm leading-7 text-stone-600">
                No projects yet. Create one from the form to the left and this list will
                become your first product workflow.
              </div>

              <div :if={@projects != []} class="mt-6 space-y-4">
                <div
                  :for={project <- @projects}
                  class="rounded-[1.5rem] border border-stone-200 bg-stone-50 px-5 py-4"
                >
                  <div class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
                    <div class="space-y-2">
                      <div class="flex flex-wrap items-center gap-2">
                        <h3 class="text-lg font-semibold text-slate-950">{project["name"]}</h3>
                        <span class="rounded-full bg-slate-900 px-2.5 py-1 text-[11px] font-semibold uppercase tracking-[0.18em] text-white">
                          {project["plan"]}
                        </span>
                      </div>

                      <p class="text-xs uppercase tracking-[0.18em] text-slate-400">
                        Created {project["inserted_at"]}
                      </p>
                    </div>

                    <form hx-post="/dashboard/archive_project" hx-target="body">
                      <input type="hidden" name="project_id" value={project["id"]} />
                      <button type="submit" class="btn btn-sm btn-ghost text-rose-600 hover:bg-rose-50">
                        Archive
                      </button>
                    </form>
                  </div>
                </div>
              </div>
            </div>
          </section>
        </div>
        \"\"\"
      end

      def create_project(req) do
        case #{a.module_name}.Accounts.current_user() do
          nil ->
            Flash.put(:error, "Please sign in to create projects.")
            Nex.redirect("/login")

          user ->
            case #{a.module_name}.Workspace.create_project(user["id"], req.body) do
              {:ok, _result} ->
                Flash.put(:success, "Project created.")
                Nex.redirect("/dashboard")

              {:error, message} ->
                Flash.put(:error, message)
                Nex.redirect("/dashboard")
            end
        end
      end

      def archive_project(req) do
        case #{a.module_name}.Accounts.current_user() do
          nil ->
            Flash.put(:error, "Please sign in to manage projects.")
            Nex.redirect("/login")

          user ->
            case #{a.module_name}.Workspace.archive_project(user["id"], req.body["project_id"]) do
              {:ok, %{count: 0}} ->
                Flash.put(:error, "Project not found.")
                Nex.redirect("/dashboard")

              {:ok, _result} ->
                Flash.put(:info, "Project archived.")
                Nex.redirect("/dashboard")

              {:error, message} ->
                Flash.put(:error, message)
                Nex.redirect("/dashboard")
            end
        end
      end

      def logout(_req) do
        Session.clear()
        Flash.put(:success, "You have been signed out.")
        Nex.redirect("/")
      end
    end
    """
  end

  def saas_api_health(a) do
    """
    defmodule #{a.module_name}.Api.Health do
      use Nex

      def get(_req) do
        case NexBase.sql("SELECT 1 AS ok", []) do
          {:ok, [%{"ok" => 1}]} ->
            Nex.json(%{ok: true, service: "#{a.app_name}", database: "ready"})

          {:ok, _rows} ->
            Nex.json(%{ok: true, service: "#{a.app_name}", database: "ready"})

          {:error, reason} ->
            Nex.json(%{ok: false, error: inspect(reason)}, status: 500)
        end
      end
    end
    """
  end

  def saas_env_example(a) do
    """
    # Server Configuration
    PORT=4000
    HOST=localhost

    # Database
    DATABASE_URL=sqlite://db/#{a.app_name}_dev.db
    DATABASE_SSL=false

    # Optional for production
    # SECRET_KEY_BASE=replace_me
    """
  end

  def saas_readme(a) do
    """
    # #{a.module_name}

    A SaaS starter generated with [Nex](https://github.com/gofenix/nex).

    ## What You Get

    - Nex pages + HTMX actions
    - SQLite by default via NexBase
    - Session-backed authentication
    - Protected dashboard routes
    - Starter project CRUD
    - Automatic schema bootstrap on app start

    ## Getting Started

    ```bash
    mix deps.get
    mix nex.dev
    ```

    Open http://localhost:4000, create an account, and you are in.

    ## Starter Routes

    - `/` — landing page
    - `/signup` — account creation
    - `/login` — sign in
    - `/dashboard` — protected workspace
    - `/api/health` — health probe

    ## Project Structure

    ```
    #{a.app_name}/
    ├── db/                    # SQLite database files (default starter setup)
    ├── src/
    │   ├── accounts.ex        # Account registration + authentication
    │   ├── application.ex     # App startup + middleware + NexBase boot
    │   ├── data.ex            # Database directory + schema bootstrap
    │   ├── workspace.ex       # Project CRUD helpers
    │   ├── api/
    │   │   └── health.ex      # Health endpoint
    │   ├── components/
    │   │   └── flash.ex       # Shared flash banner component
    │   ├── pages/
    │   │   ├── dashboard.ex   # Protected dashboard + project actions
    │   │   ├── index.ex       # Landing page
    │   │   ├── login.ex       # Sign-in page
    │   │   └── signup.ex      # Account creation page
    │   └── plugs/
    │       └── require_auth.ex
    ├── mix.exs
    └── .env.example
    ```

    ## Switching to Postgres

    Replace `DATABASE_URL` in `.env`:

    ```bash
    DATABASE_URL=postgresql://user:password@localhost:5432/#{a.app_name}
    DATABASE_SSL=false
    ```

    The starter will bootstrap the same schema against PostgreSQL.

    ## Suggested Next Customizations

    - Replace projects with your actual core resource
    - Add billing and plan enforcement
    - Add invitations / multi-user workspaces
    - Add background jobs or AI workflows behind the dashboard

    ## Resources

    - [Nex Documentation](https://hexdocs.pm/nex_core)
    - [Nex GitHub](https://github.com/gofenix/nex)
    - [NexBase Guide](https://github.com/gofenix/nex/tree/main/nex_base)
    """
  end

  def agents_md(a) do
    """
    # #{a.module_name} — Nex Agent Guide

    > Nex is a minimalist Elixir web framework. Folder structure = router. No config files. No asset pipeline. CDN-first.

    ---

    ## 0. Critical Anti-Patterns (Read First)

    ### DO NOT create a router file
    ```elixir
    # WRONG — router.ex does not exist in Nex
    # RIGHT — create src/pages/users.ex and it becomes /users automatically
    ```

    ### DO NOT use config/*.exs
    ```elixir
    # WRONG
    config :#{a.app_name}, key: "value"
    # RIGHT — use .env + Nex.Env
    Nex.Env.get(:key)
    ```

    ### DO NOT use <%= for/if %> in HEEx templates
    ```elixir
    # WRONG — syntax error
    <%= for item <- @items do %>
      <div>{item["name"]}</div>
    <% end %>

    # RIGHT — use :for directive
    <div :for={item <- @items}>{item["name"]}</div>
    <div :if={condition}>...</div>
    ```

    ### DO NOT manually add CSRF tokens or hx-headers
    ```elixir
    # WRONG — framework handles this automatically
    <body hx-headers={hx_headers()}>
    <head>{meta_tag()}</head>
    <form hx-post="/save">{csrf_input_tag()}</form>

    # RIGHT — just write the form, framework injects everything
    <form hx-post="/save">
      <input name="title" />
      <button type="submit">Save</button>
    </form>
    ```

    ### DO NOT use mix run --no-halt
    ```bash
    # WRONG
    mix run --no-halt
    # RIGHT
    mix nex.dev       # development
    mix nex.start     # production
    ```

    ### DO NOT use NexBase with a custom Repo
    ```elixir
    # WRONG
    defmodule #{a.module_name}.Repo do
      use Ecto.Repo, otp_app: :#{a.app_name}, adapter: Ecto.Adapters.Postgres
    end

    # RIGHT — NexBase provides the Repo internally
    NexBase.from("users") |> NexBase.run()
    ```

    ### DO NOT manually zip SQL columns and rows
    ```elixir
    # WRONG
    {:ok, %{rows: rows, columns: cols}} = NexBase.query(sql, [])
    Enum.map(rows, fn row -> Enum.zip(cols, row) |> Map.new() end)

    # RIGHT — NexBase.sql/2 returns list of maps directly
    {:ok, rows} = NexBase.sql("SELECT * FROM users WHERE id = $1", [id])
    ```

    ### DO NOT interpolate user input into SQL strings
    ```elixir
    # WRONG — SQL injection risk!
    NexBase.sql("SELECT * FROM users WHERE name = '\#{name}'", [])

    # RIGHT — always use parameterized queries
    NexBase.sql("SELECT * FROM users WHERE name = $1", [name])

    # RIGHT — for IN queries, use filter_in/3
    NexBase.from("tags") |> NexBase.filter_in(:project_id, ids) |> NexBase.run()
    ```

    ---

    ## 1. Project Structure

    ```
    #{a.app_name}/
      src/
        application.ex      # App startup
        pages/              # File = route (index.ex → /)
          _app.ex           # Shared page wrapper (nav, footer)
          _document.ex      # HTML shell (head, body, scripts)
        api/                # API endpoints (get/post/put/delete functions)
        components/         # Shared components (promote only if 3+ pages use it)
      .env                  # Environment variables (never commit)
      mix.exs
    ```

    ---

    ## 2. Application Startup

    ### Without database
    ```elixir
    defmodule #{a.module_name}.Application do
      use Application

      @impl true
      def start(_type, _args) do
        Nex.Env.init()
        children = []
        Supervisor.start_link(children, strategy: :one_for_one, name: #{a.module_name}.Supervisor)
      end
    end
    ```

    ### With NexBase (PostgreSQL or SQLite)
    ```elixir
    defmodule #{a.module_name}.Application do
      use Application

      @impl true
      def start(_type, _args) do
        Nex.Env.init()
        conn = NexBase.init(url: Nex.Env.get(:database_url), ssl: true)

        children = [{NexBase.Repo, conn}]
        Supervisor.start_link(children, strategy: :one_for_one, name: #{a.module_name}.Supervisor)
      end
    end
    ```

    ---

    ## 3. Layout (_document.ex + _app.ex)

    The framework automatically injects:
    - `<meta name="csrf-token">` into `</head>`
    - CSRF header into every HTMX request (via JS `htmx:configRequest`)

    `_document.ex` — HTML shell:
    ```elixir
    defmodule #{a.module_name}.Pages.Document do
      use Nex

      def render(assigns) do
        ~H\"\"\"
        <!DOCTYPE html>
        <html lang="en">
          <head>
            <meta charset="UTF-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1.0" />
            <title>{@title}</title>
            <script src="https://cdn.tailwindcss.com"></script>
            <link href="https://cdn.jsdelivr.net/npm/daisyui@4/dist/full.min.css" rel="stylesheet" />
            <script src="https://unpkg.com/htmx.org@2"></script>
          </head>
          <body hx-boost="true">
            {raw(@inner_content)}
          </body>
        </html>
        \"\"\"
      end
    end
    ```

    ### Per-page layout override
    ```elixir
    def layout, do: :none              # skip _app.ex for this page
    def layout, do: MyApp.AdminLayout  # use a different wrapper
    ```

    ### Convention error pages
    Create `src/pages/404.ex` or `src/pages/500.ex`:
    ```elixir
    defmodule #{a.module_name}.Pages.Error404 do
      use Nex
      def render(assigns) do
        ~H\"\"\"
        <h1>{@status} — {@message}</h1>
        \"\"\"
      end
    end
    ```

    ---

    ## 4. Page Module Pattern

    ```elixir
    defmodule #{a.module_name}.Pages.Index do
      use Nex

      def mount(_params) do
        %{
          title: "Home",
          items: fetch_items()
        }
      end

      def render(assigns) do
        ~H\"\"\"
        <div :for={item <- @items}>{item["name"]}</div>
        <div :if={@items == []}>No items yet.</div>
        \"\"\"
      end

      # Page Action — called via hx-post="/action_name"
      def save(req) do
        name = req.body["name"]

        # 1. mutate state/db
        # 2. return partial HTML
        ~H\"\"\"
        <div>Saved: {name}</div>
        \"\"\"
      end

      defp fetch_items, do: []
    end
    ```

    ### File → Route mapping
    | File | Route |
    |------|-------|
    | `src/pages/index.ex` | `GET /` |
    | `src/pages/about.ex` | `GET /about` |
    | `src/pages/users/index.ex` | `GET /users` |
    | `src/pages/users/[id].ex` | `GET /users/42` |
    | `src/pages/docs/[...path].ex` | `GET /docs/a/b/c` |
    | `src/pages/docs/[[...path]].ex` | `GET /docs` or `GET /docs/a/b` |

    ### mount/1 return values
    - `%{key: val}` — assigns for render
    - `{:redirect, "/path"}` — 302 redirect
    - `{:redirect, "/path", 301}` — redirect with custom status
    - `:not_found` — 404

    ### Page Action responses
    - `~H"..."` — return HTML partial (HTMX swap)
    - `:empty` — no-op (204)
    - `{:redirect, "/path"}` — redirect
    - `{:refresh, nil}` — full page refresh

    ---

    ## 5. API Module Pattern

    ```elixir
    defmodule #{a.module_name}.Api.Users do
      use Nex

      def get(req) do
        id = req.query["id"]          # path params + query string
        Nex.json(%{user: find(id)})
      end

      def post(req) do
        name = req.body["name"]       # request body (nil for GET)
        Nex.json(%{created: true}, status: 201)
      end

      def delete(req) do
        id = req.query["id"]
        Nex.json(%{deleted: id})
      end
    end
    ```

    ### File → Route mapping
    | File | Route |
    |------|-------|
    | `src/api/users.ex` | `/api/users` |
    | `src/api/users/[id].ex` | `/api/users/42` |

    ### API responses
    - `Nex.json(map)` — JSON response
    - `Nex.html("<div>...</div>")` — HTML fragment (for HTMX)
    - `Nex.text("string")` — plain text
    - `Nex.status(404)` — status only
    - `Nex.redirect("/path")` — redirect
    - `Nex.stream(fn send -> ... end)` — SSE streaming

    ### Pipeline alternative (Nex.Res)
    ```elixir
    Nex.Res.new() |> Nex.Res.status(201) |> Nex.Res.json(%{ok: true})
    Nex.Res.new() |> Nex.Res.redirect("/login")
    Nex.Res.new() |> Nex.Res.set_header("x-req-id", id) |> Nex.Res.json(data)
    ```

    ### HTMX response headers (Nex.HTMX)
    Available in page modules. Pipe HTML or Response through these:
    ```elixir
    ~H"<div>saved</div>" |> push_url("/new") |> trigger("toast", %{msg: "Done"})
    ```
    Helpers: `push_url/2`, `replace_url/2`, `trigger/2,3`, `retarget/2`, `reswap/2`

    ---

    ## 6. NexBase (Database)

    Add to `mix.exs`: `{:nex_base, "~> 0.3"}`

    ### Query Builder
    ```elixir
    # SELECT
    {:ok, rows} = NexBase.from("users") |> NexBase.order(:created_at, :desc) |> NexBase.limit(10) |> NexBase.run()

    # Filters
    NexBase.from("users") |> NexBase.eq(:active, true) |> NexBase.run()
    NexBase.from("users") |> NexBase.ilike(:name, "%alice%") |> NexBase.run()
    NexBase.from("tags")  |> NexBase.filter_in(:id, [1, 2, 3]) |> NexBase.run()

    # INSERT
    NexBase.from("users") |> NexBase.insert(%{name: "Alice", email: "alice@example.com"}) |> NexBase.run()

    # UPDATE
    NexBase.from("users") |> NexBase.eq(:id, 1) |> NexBase.update(%{name: "Bob"}) |> NexBase.run()

    # DELETE
    NexBase.from("users") |> NexBase.eq(:id, 1) |> NexBase.delete() |> NexBase.run()
    ```

    ### Raw SQL (for JOINs and complex queries)
    ```elixir
    # Returns {:ok, [%{"col" => val}]} — always string keys
    {:ok, rows} = NexBase.sql("SELECT u.name, p.title FROM users u JOIN posts p ON p.user_id = u.id WHERE u.id = $1", [user_id])

    # DDL (migrations, schema creation)
    NexBase.query!("CREATE TABLE IF NOT EXISTS users (id SERIAL PRIMARY KEY, name TEXT NOT NULL)", [])
    ```

    ### Scripts (seeds, migrations)
    ```elixir
    # At top of script file
    Nex.Env.init()
    NexBase.init(url: Nex.Env.get(:database_url), ssl: true, start: true)

    NexBase.from("users") |> NexBase.insert(%{name: "Seed User"}) |> NexBase.run()
    ```

    ---

    ## 7. Built-in Helpers (Nex.Helpers)

    Available in all page/component/layout modules automatically:

    ```elixir
    format_number(12_345)    # => "12.3k"
    format_number(1_500_000) # => "1.5M"
    format_date(~D[2026-01-15])          # => "Jan 15, 2026"
    format_date("2026-01-15T10:00:00Z")  # => "Jan 15, 2026"
    time_ago(datetime)       # => "3 hours ago", "2 days ago", etc.
    ```

    ---

    ## 8. SSE Streaming

    ```elixir
    # API handler
    def get(_req) do
      Nex.stream(fn send ->
        send.("Processing...")
        send.(%{event: "update", data: "Step 1 done"})
        send.(%{event: "done", data: "success"})
      end)
    end
    ```

    ```javascript
    // Client — use native EventSource, NOT HTMX SSE extension
    var es = new EventSource('/api/stream');
    var done = false;

    es.onmessage = function(e) { appendMessage(e.data); };

    es.addEventListener('done', function(e) {
      if (!done) { done = true; es.close(); updateUI(e.data); }
    });

    es.onerror = function() {
      if (!done) { done = true; es.close(); showError(); }
    };
    ```

    ---

    ## 9. State Management (Nex.Store)

    Page-scoped server-side state, tied to `page_id` (reset on page refresh).

    ```elixir
    Nex.Store.get(:count, 0)           # get with default
    Nex.Store.put(:count, 5)           # set
    Nex.Store.update(:count, 0, &(&1 + 1))  # atomic update, returns new value
    ```

    ---

    ## 10. Environment

    ```bash
    # .env (never commit)
    DATABASE_URL=postgresql://user:pass@host:5432/mydb
    API_KEY=secret
    ```

    ```elixir
    Nex.Env.init()                       # load .env (call in Application.start/2)
    Nex.Env.get(:database_url)           # => "postgresql://..."
    Nex.Env.get!(:api_key)              # raises if missing
    Nex.Env.get_integer(:pool_size, 10) # parse as integer with default
    ```

    ---

    ## 11. Commands

    ```bash
    mix nex.dev      # start development server (hot reload)
    mix nex.start    # start production server
    mix format       # format code
    ```

    ---

    ## 12. Browser Automation

    Use `agent-browser` for validation. Run `agent-browser --help` for all commands.

    ```bash
    agent-browser open http://localhost:4000   # navigate
    agent-browser snapshot -i                  # get interactive elements with refs
    agent-browser click @e1                    # click by ref
    agent-browser fill @e2 "text"              # fill input by ref
    ```
    """
  end

  def readme(a) do
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
    │   ├── pages/              # Page components (routes)
    │   │   ├── _app.ex         # Shared page wrapper (nav, footer)
    │   │   ├── _document.ex    # HTML shell (head, body, scripts)
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
        # req.body - request body (nil for GET/DELETE)
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
