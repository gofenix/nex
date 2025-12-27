defmodule Nex.Router do
  @moduledoc """
  Router that discovers and dispatches routes from src/ directory.

  ## Route Discovery

  - `src/pages/*.ex` → Page routes (GET for render, POST for actions)
  - `src/api/*.ex` → API routes (function name = HTTP method)
  - `src/partials/*.ex` → No routes (pure components)
  """

  use Plug.Router

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason

  plug :match
  plug :dispatch

  # Catch-all route that delegates to Nex.Handler
  match _ do
    Nex.Handler.handle(conn)
  end
end

defmodule Nex.Router.Compiler do
  @moduledoc """
  Compiles routes from src/ directory at compile time.
  """

  @doc "Discover all routes from src/ directory"
  def discover_routes(src_path \\ "src") do
    page_routes = discover_pages(Path.join(src_path, "pages"))
    api_routes = discover_api(Path.join(src_path, "api"))

    page_routes ++ api_routes
  end

  @doc "Discover page routes"
  def discover_pages(pages_path) do
    if File.dir?(pages_path) do
      pages_path
      |> Path.join("**/*.ex")
      |> Path.wildcard()
      |> Enum.flat_map(&parse_page_file(&1, pages_path))
    else
      []
    end
  end

  @doc "Discover API routes"
  def discover_api(api_path) do
    if File.dir?(api_path) do
      api_path
      |> Path.join("**/*.ex")
      |> Path.wildcard()
      |> Enum.flat_map(&parse_api_file(&1, api_path))
    else
      []
    end
  end

  defp parse_page_file(path, base_path) do
    module = path_to_module(path, base_path, "Pages")
    route_path = file_to_route_path(path, base_path)

    routes = []

    # We can't check function_exported? at compile time for user modules
    # So we'll generate routes that check at runtime
    # render/1 → GET
    routes = [{:get, route_path, module, :render, :page} | routes]

    # Other functions will be discovered at runtime by Handler
    routes
  end

  defp parse_api_file(path, base_path) do
    module = path_to_module(path, base_path, "Api")
    route_path = file_to_route_path(path, base_path) |> prefix_path("/api")

    # Generate routes for common HTTP methods
    [:get, :post, :put, :patch, :delete]
    |> Enum.map(fn method ->
      {method, route_path, module, method, :api}
    end)
  end

  defp path_to_module(path, base_path, prefix) do
    path
    |> String.replace_prefix(base_path <> "/", "")
    |> String.replace_suffix(".ex", "")
    |> String.split("/")
    |> Enum.map(&camelize_segment/1)
    |> then(fn parts -> [prefix | parts] end)
    |> Enum.join(".")
    |> then(fn name -> Module.concat([name]) end)
  end

  defp camelize_segment(segment) do
    # Handle [id] → Id, [...path] → Path
    segment
    |> String.replace(~r/^\[\.\.\.(.+)\]$/, "\\1")
    |> String.replace(~r/^\[(.+)\]$/, "\\1")
    |> Macro.camelize()
  end

  defp file_to_route_path(path, base_path) do
    path
    |> String.replace_prefix(base_path, "")
    |> String.replace_suffix(".ex", "")
    |> String.replace("/index", "")
    |> String.replace(~r/\[\.\.\.([^\]]+)\]/, "*\\1")
    |> String.replace(~r/\[([^\]]+)\]/, ":\\1")
    |> case do
      "" -> "/"
      p -> p
    end
  end

  defp prefix_path(path, prefix) do
    case path do
      "/" -> prefix
      _ -> prefix <> path
    end
  end
end
