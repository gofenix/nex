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
          {:nex_core, "~> 0.2.4"}
        ]
      end
    end
    """
  end

  defp application(a) do
    """
    defmodule #{a.module_name}.Application do
      use Application

      @impl true
      def start(_type, _args) do
        children = []
        opts = [strategy: :one_for_one, name: #{a.module_name}.Supervisor]
        Supervisor.start_link(children, opts)
      end
    end
    """
  end

  defp layouts(a) do
    """
    defmodule #{a.module_name}.Layouts do
      use Nex.Page

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
      use Nex.Page

      def mount(_params) do
        %{
          title: "Welcome to #{a.module_name}",
          message: "Your Nex app is running!"
        }
      end

      def render(assigns) do
        ~H\"\"\"
        <div class="text-center py-12">
          <h1 class="text-4xl font-bold mb-4">{@message}</h1>
          <p class="text-base-content/70 mb-8">
            Edit <code class="bg-base-300 px-2 py-1 rounded">src/pages/index.ex</code> to get started.
          </p>

          <div class="card bg-base-100 shadow-xl max-w-md mx-auto">
            <div class="card-body">
              <h2 class="card-title">Project Structure</h2>
              <ul class="space-y-2 text-left mt-4">
                <li>📁 <code>src/pages/</code> - Page components</li>
                <li>🔌 <code>src/api/</code> - API endpoints</li>
                <li>🧩 <code>src/partials/</code> - Reusable components</li>
                <li>🎨 <code>src/layouts.ex</code> - Layout template</li>
              </ul>
              <div class="card-actions justify-end mt-4">
                <a href="https://github.com/gofenix/nex" class="btn btn-primary">Documentation</a>
              </div>
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
    PORT=4000
    HOST=localhost
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

    ## Deployment

    Deploy with Docker:

    ```bash
    docker build -t #{a.app_name} .
    docker run -p 4000:4000 #{a.app_name}
    ```
    """
  end
end
