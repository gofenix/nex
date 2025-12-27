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

    # Ensure dependencies are compiled
    Mix.Task.run("compile")

    # Load environment
    Nex.Env.init()

    # Start required applications
    Application.ensure_all_started(:bandit)
    Application.ensure_all_started(:phoenix_html)
    Application.ensure_all_started(:phoenix_live_view)

    # Start Nex.Store for session-scoped state management
    {:ok, _} = Nex.Store.start_link()

    port = opts[:port] || Nex.Env.get_integer(:PORT, 4000)
    host = opts[:host] || Nex.Env.get(:HOST, "localhost")

    # Configure app module
    app_module = get_app_module()
    Application.put_env(:nex, :app_module, app_module)

    IO.puts("""

    🚀 Nex dev server starting...

       App module: #{app_module}
       URL: http://#{host}:#{port}

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
end
