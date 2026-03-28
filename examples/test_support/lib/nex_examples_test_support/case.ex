defmodule NexExamplesTestSupport.Case do
  use ExUnit.CaseTemplate

  alias NexExamplesTestSupport.{Artifacts, Config, CookieJar, ExampleServer, HTTP}

  using opts do
    quote bind_quoted: [opts: opts] do
      use ExUnit.Case, async: false

      import NexExamplesTestSupport.Assertions
      import NexExamplesTestSupport.HTML

      alias NexExamplesTestSupport.{
        Artifacts,
        Commands,
        Config,
        CookieJar,
        ExampleServer,
        Fixtures,
        HTTP,
        SSE,
        WebSocketClient
      }

      @example_opts opts

      setup_all do
        {:ok, _apps} = Application.ensure_all_started(:req)

        config =
          @example_opts
          |> Config.current()
          |> NexExamplesTestSupport.Case.apply_example_env(__MODULE__)

        Artifacts.ensure!(config)
        NexExamplesTestSupport.Case.run_prepare_callback(__MODULE__, config)

        {:ok, server} = ExampleServer.start_link(config)

        case ExampleServer.wait_until_ready(server, config) do
          :ok ->
            on_exit(fn -> ExampleServer.stop(server) end)

            {:ok,
             example_config: config,
             client: HTTP.client(config),
             cookie_jar: CookieJar.new(),
             server: server}

          {:error, message} ->
            ExampleServer.stop(server)
            raise message
        end
      end
    end
  end

  def apply_example_env(%Config{} = config, module) do
    if function_exported?(module, :example_env, 1) do
      Config.with_env(config, module.example_env(config))
    else
      config
    end
  end

  def run_prepare_callback(module, %Config{} = config) do
    if function_exported?(module, :prepare_example, 1) do
      module.prepare_example(config)
    else
      :ok
    end
  end
end
