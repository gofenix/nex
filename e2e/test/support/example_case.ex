defmodule E2E.ExampleCase do
  use ExUnit.CaseTemplate

  using opts do
    example_name = Keyword.fetch!(opts, :example)

    quote do
      use ExUnit.Case, async: false

      import E2E.Assertions
      import E2E.HTML

      alias E2E.{CookieJar, Example, ExampleServer, Examples, HTTP, SSE, WebSocketClient}

      @e2e_example unquote(example_name)
      @moduletag example: @e2e_example

      setup_all do
        example = Examples.fetch!(@e2e_example)

        {:ok, server} =
          case ExampleServer.start_link(example) do
            {:ok, pid} ->
              {:ok, pid}

            {:error, {:deps_get_failed, status}} ->
              raise "failed to prepare dependencies for #{example.name} (exit #{status})"

            {:error, reason} ->
              raise "failed to start example server for #{example.name}: #{inspect(reason)}"
          end

        case ExampleServer.wait_until_ready(server, example) do
          :ok ->
            on_exit(fn -> ExampleServer.stop(server) end)

            {:ok,
             example_config: example,
             client: HTTP.client(example),
             cookie_jar: CookieJar.new(),
             server: server}

          {:error, message} ->
            ExampleServer.stop(server)
            raise message
        end
      end
    end
  end
end
