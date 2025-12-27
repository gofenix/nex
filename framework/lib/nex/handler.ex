defmodule Nex.Handler do
  @moduledoc """
  Request handler that dispatches to Pages and API modules.
  """

  import Plug.Conn

  @doc "Handle incoming request"
  def handle(conn) do
    method = conn.method |> String.downcase() |> String.to_atom()
    path = conn.path_info

    cond do
      # API routes: /api/*
      match?(["api" | _], path) ->
        handle_api(conn, method, path)

      # Page routes
      true ->
        handle_page(conn, method, path)
    end
  end

  defp handle_api(conn, method, path) do
    # Remove "api" prefix
    api_path = case path do
      ["api" | rest] -> rest
      _ -> path
    end

    case resolve_api_module(api_path) do
      {:ok, module, params} ->
        if function_exported?(module, method, 2) do
          merged_params = Map.merge(conn.params, params)
          apply(module, method, [conn, merged_params])
        else
          send_resp(conn, 405, "Method Not Allowed")
        end

      :error ->
        send_resp(conn, 404, "Not Found")
    end
  end

  defp handle_page(conn, method, path) do
    case resolve_page_module(path) do
      {:ok, module, params} ->
        merged_params = Map.merge(conn.params, params)

        case method do
          :get ->
            handle_page_render(conn, module, merged_params)

          :post ->
            # POST requests go to action functions
            action = get_action_from_path(path)
            handle_page_action(conn, module, action, merged_params)

          _ ->
            send_resp(conn, 405, "Method Not Allowed")
        end

      :error ->
        send_resp(conn, 404, "Not Found")
    end
  end

  defp handle_page_render(conn, module, params) do
    assigns =
      if function_exported?(module, :mount, 2) do
        module.mount(conn, params)
      else
        %{}
      end

    if function_exported?(module, :render, 1) do
      content = module.render(assigns)
      # Convert to string for layout embedding
      content_html = Phoenix.HTML.Safe.to_iodata(content) |> IO.iodata_to_binary()

      # Try to get layout module from app config
      layout_module = get_layout_module()

      html =
        if layout_module && function_exported?(layout_module, :render, 1) do
          layout_module.render(%{
            inner_content: content_html,
            title: Map.get(assigns, :title, "Nex App")
          })
        else
          content
        end

      # Handle both HEEx output (Phoenix.HTML.Safe) and plain strings
      final_html =
        case html do
          binary when is_binary(binary) -> binary
          _ -> Phoenix.HTML.Safe.to_iodata(html) |> IO.iodata_to_binary()
        end

      conn
      |> put_resp_content_type("text/html")
      |> send_resp(200, final_html)
    else
      send_resp(conn, 500, "Page module missing render/1")
    end
  end

  defp handle_page_action(conn, module, action, params) do
    action_atom = String.to_atom(action)

    if function_exported?(module, action_atom, 2) do
      apply(module, action_atom, [conn, params])
    else
      send_resp(conn, 404, "Action not found: #{action}")
    end
  end

  defp get_action_from_path(path) do
    # For POST requests, the last segment is the action name
    # e.g., POST /create_todo → action = "create_todo"
    case path do
      [] -> "index"
      segments -> List.last(segments)
    end
  end

  defp resolve_page_module(path) do
    # Try to find a matching page module
    # e.g., [] → Pages.Index
    # e.g., ["about"] → Pages.About
    # e.g., ["todos", "123"] → Pages.Todos.Id with params %{"id" => "123"}

    app_module = get_app_module()

    {module_parts, params} = path_to_module_parts(path)

    module_name =
      [app_module, "Pages" | module_parts]
      |> Enum.join(".")

    module = String.to_atom("Elixir.#{module_name}")

    if Code.ensure_loaded?(module) do
      {:ok, module, params}
    else
      # Try index
      index_module = String.to_atom("Elixir.#{module_name}.Index")

      if Code.ensure_loaded?(index_module) do
        {:ok, index_module, params}
      else
        :error
      end
    end
  end

  defp resolve_api_module(path) do
    app_module = get_app_module()

    {module_parts, params} = path_to_module_parts(path)

    module_name =
      [app_module, "Api" | module_parts]
      |> Enum.join(".")

    module = String.to_atom("Elixir.#{module_name}")

    if Code.ensure_loaded?(module) do
      {:ok, module, params}
    else
      index_module = String.to_atom("Elixir.#{module_name}.Index")

      if Code.ensure_loaded?(index_module) do
        {:ok, index_module, params}
      else
        :error
      end
    end
  end

  defp path_to_module_parts(path) do
    # Convert path segments to module parts, extracting dynamic params
    # e.g., ["todos", "123"] with [id].ex → (["Todos", "Id"], %{"id" => "123"})

    # For MVP, we'll use a simple approach:
    # Assume dynamic segments are IDs
    path
    |> Enum.reduce({[], %{}}, fn segment, {parts, params} ->
      if is_dynamic_segment?(segment) do
        # This is a dynamic value, add "Id" as module part
        {parts ++ ["Id"], Map.put(params, "id", segment)}
      else
        {parts ++ [Macro.camelize(segment)], params}
      end
    end)
  end

  defp is_dynamic_segment?(segment) do
    # A segment is dynamic if it looks like an ID (numeric or UUID-like)
    String.match?(segment, ~r/^[0-9a-f-]+$/i)
  end

  defp get_app_module do
    # Get the app module name from application config
    Application.get_env(:nex, :app_module, "MyApp")
  end

  defp get_layout_module do
    app_module = get_app_module()
    module = String.to_atom("Elixir.#{app_module}.Layouts")

    if Code.ensure_loaded?(module) do
      module
    else
      nil
    end
  end
end
