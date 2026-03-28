defmodule NexExamplesTestSupport.Config do
  defstruct [:slug, :cwd, :port, :ready_path, env: []]

  def current(opts) do
    cwd = File.cwd!()

    %__MODULE__{
      slug: Path.basename(cwd),
      cwd: cwd,
      port: Keyword.fetch!(opts, :port),
      ready_path: Keyword.get(opts, :ready_path, "/"),
      env: Keyword.get(opts, :env, [])
    }
  end

  def with_env(%__MODULE__{} = config, env) when is_list(env) do
    %{config | env: config.env ++ env}
  end

  def base_url(%__MODULE__{port: port}) do
    "http://127.0.0.1:#{port}"
  end

  def ready_url(%__MODULE__{} = config) do
    URI.merge(base_url(config), config.ready_path) |> to_string()
  end

  def websocket_url(%__MODULE__{} = config, path) do
    request_uri = URI.parse(path)

    config
    |> base_url()
    |> URI.parse()
    |> Map.put(:scheme, "ws")
    |> Map.put(:path, request_uri.path)
    |> Map.put(:query, request_uri.query)
    |> URI.to_string()
  end
end
