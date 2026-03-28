defmodule E2E.Example do
  defstruct [:name, :cwd, :port, :kind, :ready_path, :test_file]

  def base_url(%__MODULE__{port: port}) do
    "http://127.0.0.1:#{port}"
  end

  def ready_url(%__MODULE__{} = example) do
    URI.merge(base_url(example), example.ready_path) |> to_string()
  end

  def websocket_url(%__MODULE__{} = example, path) do
    request_uri = URI.parse(path)

    example
    |> base_url()
    |> URI.parse()
    |> Map.put(:scheme, "ws")
    |> Map.put(:path, request_uri.path)
    |> Map.put(:query, request_uri.query)
    |> URI.to_string()
  end
end

defmodule E2E.Examples do
  alias E2E.{Example, Root}

  @examples [
    %{
      name: "alpine_showcase",
      cwd: "examples/alpine_showcase",
      port: 4201,
      kind: :ui,
      ready_path: "/",
      test_file: "test/examples/alpine_showcase_test.exs"
    },
    %{
      name: "auth_demo",
      cwd: "examples/auth_demo",
      port: 4202,
      kind: :ui,
      ready_path: "/",
      test_file: "test/examples/auth_demo_test.exs"
    },
    %{
      name: "counter",
      cwd: "examples/counter",
      port: 4203,
      kind: :ui,
      ready_path: "/",
      test_file: "test/examples/counter_test.exs"
    },
    %{
      name: "dynamic_routes",
      cwd: "examples/dynamic_routes",
      port: 4204,
      kind: :routes,
      ready_path: "/",
      test_file: "test/examples/dynamic_routes_test.exs"
    },
    %{
      name: "energy_dashboard",
      cwd: "examples/energy_dashboard",
      port: 4205,
      kind: :realtime,
      ready_path: "/",
      test_file: "test/examples/energy_dashboard_test.exs"
    },
    %{
      name: "error_pages",
      cwd: "examples/error_pages",
      port: 4206,
      kind: :routes,
      ready_path: "/",
      test_file: "test/examples/error_pages_test.exs"
    },
    %{
      name: "guestbook",
      cwd: "examples/guestbook",
      port: 4207,
      kind: :ui,
      ready_path: "/",
      test_file: "test/examples/guestbook_test.exs"
    },
    %{
      name: "ratelimit",
      cwd: "examples/ratelimit",
      port: 4208,
      kind: :routes,
      ready_path: "/",
      test_file: "test/examples/ratelimit_test.exs"
    },
    %{
      name: "todos",
      cwd: "examples/todos",
      port: 4209,
      kind: :ui,
      ready_path: "/",
      test_file: "test/examples/todos_test.exs"
    },
    %{
      name: "todos_api",
      cwd: "examples/todos_api",
      port: 4210,
      kind: :api,
      ready_path: "/",
      test_file: "test/examples/todos_api_test.exs"
    },
    %{
      name: "upload",
      cwd: "examples/upload",
      port: 4211,
      kind: :ui,
      ready_path: "/",
      test_file: "test/examples/upload_test.exs"
    },
    %{
      name: "validator",
      cwd: "examples/validator",
      port: 4212,
      kind: :ui,
      ready_path: "/",
      test_file: "test/examples/validator_test.exs"
    },
    %{
      name: "websocket",
      cwd: "examples/websocket",
      port: 4213,
      kind: :realtime,
      ready_path: "/",
      test_file: "test/examples/websocket_test.exs"
    }
  ]

  def all do
    Enum.map(@examples, &build_example/1)
  end

  def names do
    Enum.map(all(), & &1.name)
  end

  def fetch!(name) do
    Enum.find(all(), &(&1.name == name)) ||
      raise ArgumentError,
            "unknown example #{inspect(name)}; expected one of: #{Enum.join(names(), ", ")}"
  end

  defp build_example(attrs) do
    %Example{
      name: attrs.name,
      cwd: Root.repo_path(attrs.cwd),
      port: attrs.port,
      kind: attrs.kind,
      ready_path: attrs.ready_path,
      test_file: attrs.test_file
    }
  end
end
