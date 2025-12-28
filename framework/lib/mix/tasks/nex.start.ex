defmodule Mix.Tasks.Nex.Start do
  @moduledoc """
  Start Nex production server.

  ## Usage

      mix nex.start

  ## Environment Variables

      PORT    Port to listen on (default: 4000)
      HOST    Host to bind to (default: 0.0.0.0)

  ## Example

      PORT=8080 mix nex.start

  This command is designed for production deployment on platforms like:
  - Railway
  - Fly.io
  - Docker containers
  - Traditional VPS
  """

  use Mix.Task

  @shortdoc "Start Nex production server"

  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        switches: [port: :integer, host: :string]
      )

    # Ensure dependencies are compiled
    Mix.Task.run("compile")

    # Set production environment
    Application.put_env(:nex_core, :env, :prod)

    # Load environment variables from .env if exists
    Nex.Env.init()

    # Get project info from mix.exs
    app_name = Mix.Project.config()[:app]

    # Configure app module
    app_module = get_app_module()
    Application.put_env(:nex_core, :app_module, app_module)

    # Start the application
    if app_name do
      Application.ensure_all_started(app_name)
    end

    # Start required applications
    Application.ensure_all_started(:bandit)
    Application.ensure_all_started(:phoenix_html)
    Application.ensure_all_started(:phoenix_live_view)

    # Start Nex framework supervisor (manages Store, PubSub only, no Reloader in prod)
    {:ok, _} = Nex.Supervisor.start_link()

    # Get port and host from environment variables or options
    port = opts[:port] || Nex.Env.get_integer(:PORT, 4000)
    host = opts[:host] || Nex.Env.get(:HOST, "0.0.0.0")

    IO.puts("""
    🚀 Nex server starting in production mode...

       App module: #{app_module}
       URL: http://#{host}:#{port}
       Hot reload: disabled

    Press Ctrl+C to stop.
    """)

    # Start the server
    {:ok, _} = Bandit.start_link(plug: Nex.Router, port: port, ip: :any)

    # Keep the process alive
    Process.sleep(:infinity)
  end

  defp get_app_module do
    case Mix.Project.config()[:app] do
      nil -> "MyApp"
      app -> app |> to_string() |> Macro.camelize()
    end
  end
end
