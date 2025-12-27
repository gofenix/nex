defmodule Mix.Tasks.Nex.New do
  @moduledoc """
  Creates a new Nex project.

  ## Usage

      mix nex.new my_app
      mix nex.new my_app --path /some/path

  ## Options

      --path PATH    Directory to create project in (default: ./)

  ## Examples

      mix nex.new blog
      mix nex.new my_shop --path ~/projects
  """

  use Mix.Task

  @shortdoc "Create a new Nex project"

  @template_files %{
    "mix.exs" => &__MODULE__.mix_exs_template/1,
    "src/application.ex" => &__MODULE__.application_template/1,
    "src/layouts.ex" => &__MODULE__.layouts_template/1,
    "src/pages/index.ex" => &__MODULE__.index_template/1,
    ".gitignore" => &__MODULE__.gitignore_template/1,
    ".env.example" => &__MODULE__.env_example_template/1,
    "README.md" => &__MODULE__.readme_template/1
  }

  def run([]) do
    Mix.raise("Expected project name. Usage: mix nex.new my_app")
  end

  def run(args) do
    {opts, [name | _], _} =
      OptionParser.parse(args, switches: [path: :string])

    # Validate project name
    unless valid_name?(name) do
      Mix.raise("Project name must start with a letter and contain only lowercase letters, numbers, and underscores")
    end

    base_path = opts[:path] || "."
    project_path = Path.join(base_path, name)

    # Check if directory already exists
    if File.dir?(project_path) do
      Mix.raise("Directory #{project_path} already exists")
    end

    module_name = Macro.camelize(name)

    assigns = %{
      app_name: name,
      module_name: module_name,
      nex_version: nex_version()
    }

    Mix.shell().info("\n🚀 Creating new Nex project: #{name}\n")

    # Create directory structure
    create_directories(project_path)

    # Generate files from templates
    Enum.each(@template_files, fn {file_path, template_fn} ->
      full_path = Path.join(project_path, file_path)
      content = template_fn.(assigns)
      create_file(full_path, content)
    end)

    Mix.shell().info("""

    ✅ Project created successfully!

    Next steps:

        cd #{name}
        mix deps.get
        mix nex.dev

    Then open http://localhost:4000 in your browser.
    """)
  end

  defp valid_name?(name) do
    Regex.match?(~r/^[a-z][a-z0-9_]*$/, name)
  end

  defp nex_version do
    # Try to get version from mix.exs, fallback to github
    case Application.spec(:nex, :vsn) do
      nil -> ~s({:nex, github: "your-org/nex"})
      vsn -> ~s({:nex, "~> #{vsn}"})
    end
  end

  defp create_directories(project_path) do
    dirs = [
      project_path,
      Path.join(project_path, "src"),
      Path.join(project_path, "src/pages"),
      Path.join(project_path, "src/api"),
      Path.join(project_path, "src/partials")
    ]

    Enum.each(dirs, fn dir ->
      File.mkdir_p!(dir)
      Mix.shell().info("  Created: #{dir}/")
    end)
  end

  defp create_file(path, content) do
    dir = Path.dirname(path)
    File.mkdir_p!(dir)
    File.write!(path, content)
    Mix.shell().info("  Created: #{path}")
  end

  # Template functions

  def mix_exs_template(assigns) do
    """
    defmodule #{assigns.module_name}.MixProject do
      use Mix.Project

      def project do
        [
          app: :#{assigns.app_name},
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
          mod: {#{assigns.module_name}.Application, []}
        ]
      end

      defp deps do
        [
          #{assigns.nex_version}
        ]
      end
    end
    """
  end

  def application_template(assigns) do
    """
    defmodule #{assigns.module_name}.Application do
      @moduledoc \"\"\"
      The #{assigns.module_name} application.
      \"\"\"

      use Application

      @impl true
      def start(_type, _args) do
        children = [
          # Add supervised processes here
        ]

        opts = [strategy: :one_for_one, name: #{assigns.module_name}.Supervisor]
        Supervisor.start_link(children, opts)
      end
    end
    """
  end

  def layouts_template(assigns) do
    ~s"""
    defmodule #{assigns.module_name}.Layouts do
      use Nex.Page

      def render(assigns) do
        ~H\"\"\"
        <!DOCTYPE html>
        <html lang="en">
          <head>
            <meta charset="UTF-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1.0" />
            <title>{@title}</title>
            <script src="https://cdn.tailwindcss.com?plugins=forms,typography,aspect-ratio"></script>
            <script src="https://unpkg.com/htmx.org@2.0.4"></script>
          </head>
          <body class="bg-gray-100 min-h-screen">
            <nav class="bg-white shadow-sm border-b">
              <div class="max-w-4xl mx-auto px-4 py-3">
                <a href="/" class="text-xl font-bold text-blue-600">#{assigns.module_name}</a>
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

  def index_template(assigns) do
    ~s"""
    defmodule #{assigns.module_name}.Pages.Index do
      use Nex.Page

      def mount(_params) do
        %{
          title: "Welcome to #{assigns.module_name}",
          message: "Your Nex app is running!"
        }
      end

      def render(assigns) do
        ~H\"\"\"
        <div class="text-center py-12">
          <h1 class="text-4xl font-bold text-gray-800 mb-4">{@message}</h1>
          <p class="text-gray-600 mb-8">
            Edit <code class="bg-gray-200 px-2 py-1 rounded">src/pages/index.ex</code> to get started.
          </p>

          <div class="space-y-4">
            <div class="bg-white rounded-lg p-6 shadow max-w-md mx-auto">
              <h2 class="text-xl font-semibold mb-4">Quick Links</h2>
              <ul class="space-y-2 text-left">
                <li>📁 <code>src/pages/</code> - Page components</li>
                <li>🔌 <code>src/api/</code> - API endpoints</li>
                <li>🧩 <code>src/partials/</code> - Reusable components</li>
                <li>🎨 <code>src/layouts.ex</code> - Layout template</li>
              </ul>
            </div>
          </div>
        </div>
        \"\"\"
      end
    end
    """
  end

  def gitignore_template(_assigns) do
    """
    # Dependencies
    /deps/
    /_build/

    # Environment
    .env
    .env.local

    # Generated
    *.beam
    erl_crash.dump

    # IDE
    .elixir_ls/
    .vscode/
    .idea/

    # OS
    .DS_Store
    Thumbs.db
    """
  end

  def env_example_template(_assigns) do
    """
    # Server configuration
    PORT=4000
    HOST=localhost

    # Add your environment variables here
    # DATABASE_URL=postgres://localhost/myapp
    # SECRET_KEY=your-secret-key
    """
  end

  def readme_template(assigns) do
    """
    # #{assigns.module_name}

    A web application built with [Nex](https://github.com/your-org/nex).

    ## Getting Started

    ```bash
    # Install dependencies
    mix deps.get

    # Start development server
    mix nex.dev
    ```

    Then open [http://localhost:4000](http://localhost:4000) in your browser.

    ## Project Structure

    ```
    src/
    ├── pages/        # Page components (routes)
    ├── api/          # API endpoints
    ├── partials/     # Reusable components
    ├── layouts.ex    # Layout template
    └── application.ex
    ```

    ## Deployment

    ```bash
    # Build for production
    mix nex.release

    # Run in production
    MIX_ENV=prod mix run --no-halt
    ```

    ## Learn More

    - [Nex Documentation](https://github.com/your-org/nex)
    - [HTMX Documentation](https://htmx.org/docs/)
    """
  end
end
