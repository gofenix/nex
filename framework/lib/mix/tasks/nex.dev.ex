defmodule Mix.Tasks.Nex.Dev do
  @moduledoc """
  Start Nex development server.

  ## Usage

      mix nex.dev

  ## Options

      --port PORT    Port to listen on (default: 4000)
      --host HOST    Host to bind to (default: localhost)
  """

  use Mix.Task

  @shortdoc "Start Nex development server"

  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        switches: [port: :integer, host: :string]
      )

    # Check and install dependencies if needed
    ensure_deps_installed()

    # Ensure dependencies are compiled
    Mix.Task.run("compile")

    # Set Nex environment to dev for hot reload
    Application.put_env(:nex_core, :env, :dev)

    # Load environment
    Nex.Env.init()

    # Get project info from mix.exs
    app_name = Mix.Project.config()[:app]

    # Configure app module
    app_module = get_app_module()
    Application.put_env(:nex_core, :app_module, app_module)

    if app_name do
      Application.ensure_all_started(app_name)
    end

    # Start required applications
    Application.ensure_all_started(:bandit)
    Application.ensure_all_started(:phoenix_html)
    Application.ensure_all_started(:phoenix_live_view)
    Application.ensure_all_started(:file_system)

    # Start Nex framework supervisor (manages Store, PubSub, Reloader)
    {:ok, _} = Nex.Supervisor.start_link()

    port = opts[:port] || Nex.Env.get_integer(:PORT, 4000)
    host = opts[:host] || Nex.Env.get(:HOST, "localhost")

    # Configure app module
    app_module = get_app_module()
    Application.put_env(:nex, :app_module, app_module)

    IO.puts("""

    🚀 Nex dev server starting...

       App module: #{app_module}
       URL: http://#{host}:#{port}
       Hot reload: enabled

    Press Ctrl+C to stop.
    """)

    # Start the server
    {:ok, _} = Bandit.start_link(plug: Nex.Router, port: port)

    # Keep the process alive
    Process.sleep(:infinity)
  end

  defp get_app_module do
    # Try to infer from mix.exs project name
    case Mix.Project.config()[:app] do
      nil -> "MyApp"
      app -> app |> to_string() |> Macro.camelize()
    end
  end

  defp ensure_deps_installed do
    deps_path = Mix.Project.deps_path()

    # Check if dependencies are available
    missing_deps =
      Mix.Project.config()[:deps]
      |> Enum.filter(fn
        {dep, _opts} when is_atom(dep) ->
          dep_path = Path.join(deps_path, to_string(dep))
          not File.exists?(dep_path)
        _ -> false
      end)

    if length(missing_deps) > 0 do
      IO.puts("\n📦 Installing missing dependencies...\n")
      Mix.Task.run("deps.get")
      IO.puts("")
    end
  end
end
