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
              if reserved_file?(entry) do
                acc
              else
                route = build_route(full_path, base_path)
                [route | acc]
              end

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
    segments =
      case List.last(segments) do
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
      has_catchall:
        Enum.any?(pattern, fn
          {:catchall, _} -> true
          {:optional_catchall, _} -> true
          _ -> false
        end),
      segment_count: length(pattern)
    }
  end

  defp parse_segments(segments) do
    {pattern_rev, param_names_rev} =
      Enum.reduce(segments, {[], []}, fn segment, {pattern, params} ->
        case parse_segment(segment) do
          {:dynamic, name} ->
            {[{:dynamic, name} | pattern], [name | params]}

          {:catchall, name} ->
            {[{:catchall, name} | pattern], [name | params]}

          {:optional_catchall, name} ->
            {[{:optional_catchall, name} | pattern], [name | params]}

          {:static, value} ->
            {[{:static, value} | pattern], params}
        end
      end)

    {Enum.reverse(pattern_rev), Enum.reverse(param_names_rev)}
  end

  defp parse_segment(segment) do
    cond do
      # Optional catch-all: [[...param]]
      String.starts_with?(segment, "[[...") and String.ends_with?(segment, "]]") ->
        name = segment |> String.slice(5..-3//1)
        {:optional_catchall, name}

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
        String.starts_with?(segment, "[[...") and String.ends_with?(segment, "]]") ->
          name = segment |> String.slice(5..-3//1)
          Macro.camelize(name)

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

  defp match_pattern([{:optional_catchall, name} | _], remaining, params) do
    # Optional catch-all consumes remaining segments (may be empty)
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
  # Segment precedence: static > dynamic > catch-all > optional catch-all
  defp route_priority(route) do
    specificity =
      Enum.map(route.pattern, fn
        {:static, _} -> 0
        {:dynamic, _} -> 1
        {:catchall, _} -> 2
        {:optional_catchall, _} -> 3
      end)

    {specificity, -route.segment_count}
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

  def resolve(:action, path, referer_path \\ []) do
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
        # POST /action_name → resolve against the current page when available.
        # Root-page actions still resolve to Pages.Index.
        case safe_to_existing_atom(action) do
          {:ok, action_atom} ->
            resolve_single_segment_action(app_module, action, action_atom, referer_path)

          :error ->
            :error
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

  defp reserved_file?(filename) do
    String.starts_with?(filename, "_") or filename in ["404.ex", "500.ex"]
  end

  defp resolve_single_segment_action(app_module, action, action_atom, referer_path) do
    case referer_path do
      [] ->
        resolve_index_action(app_module, action, action_atom)

      _path ->
        resolve_action_in_current_page(app_module, action, action_atom, referer_path)
    end
  end

  defp resolve_index_action(app_module, action, action_atom) do
    case safe_to_existing_module("#{app_module}.Pages.Index") do
      {:ok, module} ->
        if function_exported?(module, action_atom, 1) do
          {:ok, module, action, %{}}
        else
          :error
        end

      :error ->
        :error
    end
  end

  defp resolve_action_in_current_page(app_module, action, action_atom, referer_path) do
    case get_current_page_module(app_module, referer_path) do
      {:ok, module} ->
        if function_exported?(module, action_atom, 1) do
          {:ok, module, action, %{}}
        else
          :error
        end

      :error ->
        :error
    end
  end

  # Config helpers
  defp get_app_module, do: Nex.Config.app_module()
  defp get_src_path, do: Nex.Config.src_path()

  # Safe atom/module conversion - now delegated to Nex.Utils
  defp safe_to_existing_atom(string), do: Nex.Utils.safe_to_existing_atom(string)
  defp safe_to_existing_module(module_name), do: Nex.Utils.safe_to_existing_module(module_name)

  # Get current page module from referer path
  defp get_current_page_module(app_module, referer_path) do
    case referer_path do
      [] ->
        # No referer or root path, use Index
        safe_to_existing_module("#{app_module}.Pages.Index")

      path ->
        # Try to resolve the referer path to a page module
        # e.g., ["requests"] -> Pages.Requests
        routes = get_routes(get_src_path(), :pages)

        case match_route(routes, path, app_module, "Pages") do
          {:ok, module_name, _params} ->
            safe_to_existing_module(module_name)

          :error ->
            # Fallback: try to construct module name directly from path
            # e.g., ["requests"] -> "Pages.Requests"
            module_name =
              path
              |> Enum.map(&Macro.camelize/1)
              |> then(&[app_module, "Pages" | &1])
              |> Enum.join(".")

            safe_to_existing_module(module_name)
        end
    end
  end
end
