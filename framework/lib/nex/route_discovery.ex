defmodule Nex.RouteDiscovery do
  @moduledoc """
  Discovers and matches dynamic routes from file system structure.

  Supports:
  - `[param]` - Single dynamic parameter (e.g., `users/[id].ex` matches `/users/123`)
  - `[...param]` - Catch-all parameter (e.g., `docs/[...path].ex` matches `/docs/a/b/c`)
  - Mixed routes (e.g., `files/[category]/[...path].ex`)
  - Nested dynamic routes (e.g., `users/[id]/profile.ex`)
  """

  @doc """
  Discovers all routes from the given source directory.
  Returns a list of route definitions.
  """
  def discover_routes(src_path, type \\ :pages) do
    base_path = Path.join(src_path, to_string(type))

    if File.dir?(base_path) do
      discover_routes_recursive(base_path, base_path, [])
      |> Enum.sort_by(&route_priority/1)
    else
      []
    end
  end

  defp discover_routes_recursive(current_path, base_path, acc) do
    case File.ls(current_path) do
      {:ok, entries} ->
        Enum.reduce(entries, acc, fn entry, acc ->
          full_path = Path.join(current_path, entry)

          cond do
            File.dir?(full_path) ->
              discover_routes_recursive(full_path, base_path, acc)

            String.ends_with?(entry, ".ex") ->
              route = build_route(full_path, base_path)
              [route | acc]

            true ->
              acc
          end
        end)

      {:error, _} ->
        acc
    end
  end

  defp build_route(file_path, base_path) do
    # Get relative path from base
    relative = Path.relative_to(file_path, base_path)

    # Remove .ex extension
    relative = String.replace_suffix(relative, ".ex", "")

    # Split into segments
    segments = Path.split(relative)

    # Special case: "index" at the end means it matches the parent path
    # e.g., "index" -> [], "users/index" -> ["users"]
    segments = case List.last(segments) do
      "index" -> List.delete_at(segments, -1)
      _ -> segments
    end

    # Parse each segment into route parts
    {pattern, param_names} = parse_segments(segments)

    # Build module name (always include Index for index files)
    module_parts = segments_to_module_parts(Path.split(relative))

    %{
      file_path: file_path,
      pattern: pattern,
      param_names: param_names,
      module_parts: module_parts,
      has_catchall: Enum.any?(pattern, &match?({:catchall, _}, &1)),
      segment_count: length(pattern)
    }
  end

  defp parse_segments(segments) do
    {pattern, param_names} =
      Enum.reduce(segments, {[], []}, fn segment, {pattern, params} ->
        case parse_segment(segment) do
          {:dynamic, name} ->
            {pattern ++ [{:dynamic, name}], params ++ [name]}

          {:catchall, name} ->
            {pattern ++ [{:catchall, name}], params ++ [name]}

          {:static, value} ->
            {pattern ++ [{:static, value}], params}
        end
      end)

    {pattern, param_names}
  end

  defp parse_segment(segment) do
    cond do
      # Catch-all: [...param]
      String.starts_with?(segment, "[...") and String.ends_with?(segment, "]") ->
        name = segment |> String.slice(4..-2//1)
        {:catchall, name}

      # Dynamic: [param]
      String.starts_with?(segment, "[") and String.ends_with?(segment, "]") ->
        name = segment |> String.slice(1..-2//1)
        {:dynamic, name}

      # Static
      true ->
        {:static, segment}
    end
  end

  defp segments_to_module_parts(segments) do
    Enum.map(segments, fn segment ->
      cond do
        String.starts_with?(segment, "[...") and String.ends_with?(segment, "]") ->
          # [...path] -> Path
          name = segment |> String.slice(4..-2//1)
          Macro.camelize(name)

        String.starts_with?(segment, "[") and String.ends_with?(segment, "]") ->
          # [id] -> Id
          name = segment |> String.slice(1..-2//1)
          Macro.camelize(name)

        true ->
          Macro.camelize(segment)
      end
    end)
  end

  @doc """
  Matches a URL path against discovered routes.
  Returns {:ok, module_name, params} or :error
  """
  def match_route(routes, url_path, app_module, prefix) do
    # Try each route in priority order
    Enum.find_value(routes, :error, fn route ->
      case match_pattern(route.pattern, url_path, %{}) do
        {:ok, params} ->
          module_name = build_module_name(app_module, prefix, route.module_parts)
          {:ok, module_name, params}

        :error ->
          nil
      end
    end)
  end

  defp match_pattern([], [], params), do: {:ok, params}
  defp match_pattern([], _remaining, _params), do: :error

  defp match_pattern([{:catchall, name} | _], remaining, params) do
    # Catch-all consumes all remaining segments
    {:ok, Map.put(params, name, remaining)}
  end

  defp match_pattern([{:dynamic, name} | rest_pattern], [segment | rest_path], params) do
    # Dynamic matches any single segment
    match_pattern(rest_pattern, rest_path, Map.put(params, name, segment))
  end

  defp match_pattern([{:static, value} | rest_pattern], [segment | rest_path], params) do
    # Static must match exactly
    if value == segment do
      match_pattern(rest_pattern, rest_path, params)
    else
      :error
    end
  end

  defp match_pattern(_pattern, [], _params), do: :error

  defp build_module_name(app_module, prefix, module_parts) do
    [app_module, prefix | module_parts] |> Enum.join(".")
  end

  # Route priority for sorting (lower = higher priority)
  # 1. Static routes first
  # 2. Routes with fewer dynamic segments
  # 3. Routes without catch-all before routes with catch-all
  # 4. Longer routes before shorter routes (more specific)
  defp route_priority(route) do
    static_count = Enum.count(route.pattern, &match?({:static, _}, &1))
    dynamic_count = Enum.count(route.pattern, &match?({:dynamic, _}, &1))
    catchall_penalty = if route.has_catchall, do: 1000, else: 0

    # Lower score = higher priority
    {-static_count, dynamic_count, catchall_penalty, -route.segment_count}
  end

  @doc """
  Gets or initializes the route cache for an application.
  Routes are cached in ETS for performance.
  """
  def get_routes(src_path, type) do
    cache_key = {src_path, type}

    case :ets.whereis(:nex_route_cache) do
      :undefined ->
        :ets.new(:nex_route_cache, [:named_table, :public, :set])
        routes = discover_routes(src_path, type)
        :ets.insert(:nex_route_cache, {cache_key, routes})
        routes

      _table ->
        case :ets.lookup(:nex_route_cache, cache_key) do
          [{^cache_key, routes}] ->
            routes

          [] ->
            routes = discover_routes(src_path, type)
            :ets.insert(:nex_route_cache, {cache_key, routes})
            routes
        end
    end
  end

  @doc """
  Clears the route cache. Called when files change during development.
  """
  def clear_cache do
    case :ets.whereis(:nex_route_cache) do
      :undefined -> :ok
      _table -> :ets.delete_all_objects(:nex_route_cache)
    end
    :ok
  end

  # =============================================================================
  # Unified Route Resolution API
  # =============================================================================

  @doc """
  Unified route resolution entry point.

  ## Examples

      resolve(:pages, ["users", "123"])
      # => {:ok, MyApp.Pages.Users.Id, %{"id" => "123"}}

      resolve(:api, ["users"])
      # => {:ok, MyApp.Api.Users, %{}}

      resolve(:action, ["todos", "create_todo"])
      # => {:ok, MyApp.Pages.Todos, "create_todo", %{}}
  """
  def resolve(type, path)

  def resolve(type, path) when type in [:pages, :api] do
    app_module = get_app_module()
    src_path = get_src_path()
    prefix = if type == :pages, do: "Pages", else: "Api"

    routes = get_routes(src_path, type)

    case match_route(routes, path, app_module, prefix) do
      {:ok, module_name, params} ->
        case safe_to_existing_module(module_name) do
          {:ok, module} -> {:ok, module, params}
          :error -> :error
        end

      :error ->
        :error
    end
  end

  def resolve(:action, path) do
    app_module = get_app_module()
    src_path = get_src_path()

    case path do
      [] ->
        # POST / → Index.index
        case safe_to_existing_module("#{app_module}.Pages.Index") do
          {:ok, module} -> {:ok, module, "index", %{}}
          :error -> :error
        end

      [action] ->
        # POST /create_todo → Index.create_todo
        # Also try: POST /stream → Stream.stream
        action_module_name = [app_module, "Pages", Macro.camelize(action)] |> Enum.join(".")

        with {:ok, action_module} <- safe_to_existing_module(action_module_name),
             {:ok, action_atom} <- safe_to_existing_atom(action),
             true <- function_exported?(action_module, action_atom, 1) do
          {:ok, action_module, action, %{}}
        else
          _ ->
            case safe_to_existing_module("#{app_module}.Pages.Index") do
              {:ok, module} -> {:ok, module, action, %{}}
              :error -> :error
            end
        end

      segments ->
        # POST /todos/123/delete → resolve module path, last segment is action
        {module_path, [action]} = Enum.split(segments, -1)

        routes = get_routes(src_path, :pages)

        case match_route(routes, module_path, app_module, "Pages") do
          {:ok, module_name, params} ->
            case safe_to_existing_module(module_name) do
              {:ok, module} -> {:ok, module, action, params}
              :error -> :error
            end

          :error ->
            :error
        end
    end
  end

  # Config helpers
  defp get_app_module do
    Application.get_env(:nex_core, :app_module, "MyApp")
  end

  defp get_src_path do
    Application.get_env(:nex_core, :src_path, "src")
  end

  # Safe atom/module conversion to prevent atom exhaustion attacks
  defp safe_to_existing_atom(string) do
    {:ok, String.to_existing_atom(string)}
  rescue
    ArgumentError -> :error
  end

  defp safe_to_existing_module(module_name) do
    case safe_to_existing_atom("Elixir.#{module_name}") do
      {:ok, module} ->
        if Code.ensure_loaded?(module), do: {:ok, module}, else: :error

      :error ->
        :error
    end
  end
end
