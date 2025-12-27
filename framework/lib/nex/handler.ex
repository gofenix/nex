defmodule Nex.Handler do
  @moduledoc """
  Request handler that dispatches to Pages and API modules.
  """

  import Plug.Conn
  require Logger

  @doc "Handle incoming request"
  def handle(conn) do
    try do
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
    rescue
      e ->
        Logger.error("Unhandled error: #{inspect(e)}\n#{Exception.format_stacktrace(__STACKTRACE__)}")
        send_error_page(conn, 500, "Internal Server Error", e)
    catch
      kind, reason ->
        Logger.error("Caught #{kind}: #{inspect(reason)}")
        send_error_page(conn, 500, "Internal Server Error", reason)
    end
  end

  defp handle_api(conn, method, path) do
    # Remove "api" prefix
    api_path = case path do
      ["api" | rest] -> rest
      _ -> path
    end

    # Set page_id for Nex.Store (from params if present)
    page_id = conn.params["_page_id"] || "api"
    Nex.Store.set_page_id(page_id)

    case resolve_api_module(api_path) do
      {:ok, module, params} ->
        merged_params = Map.merge(conn.params, params)

        # Try arity 1 first (with params), then arity 0 (no params)
        result = cond do
          function_exported?(module, method, 1) ->
            apply(module, method, [merged_params])
          function_exported?(module, method, 0) ->
            apply(module, method, [])
          true ->
            :method_not_allowed
        end

        send_api_response(conn, result)

      :error ->
        send_json_error(conn, 404, "Not Found")
    end
  end

  defp send_api_response(conn, :method_not_allowed) do
    send_json_error(conn, 405, "Method Not Allowed")
  end

  defp send_api_response(conn, :empty) do
    send_resp(conn, 204, "")
  end

  defp send_api_response(conn, {:error, status, message}) do
    send_json_error(conn, status, message)
  end

  defp send_api_response(conn, {status, data}) when is_integer(status) do
    send_json(conn, status, data)
  end

  defp send_api_response(conn, data) when is_map(data) do
    send_json(conn, 200, data)
  end

  defp send_json(conn, status, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(data))
  end

  defp send_json_error(conn, status, message) do
    send_json(conn, status, %{error: message})
  end

  defp handle_page(conn, method, path) do
    case method do
      :get ->
        # GET requests render pages
        case resolve_page_module(path) do
          {:ok, module, params} ->
            handle_page_render(conn, module, Map.merge(conn.params, params))

          :error ->
            send_error_page(conn, 404, "Page Not Found", nil)
        end

      :post ->
        # POST requests call action functions
        # e.g., POST /create_todo → Index.create_todo/2
        # e.g., POST /todos/123/toggle → Todos.Id.toggle/2
        case resolve_action(path) do
          {:ok, module, action, params} ->
            handle_page_action(conn, module, action, Map.merge(conn.params, params))

          :error ->
            send_error_page(conn, 404, "Action Not Found", nil)
        end

      _ ->
        send_error_page(conn, 405, "Method Not Allowed", nil)
    end
  end

  defp handle_page_render(conn, module, params) do
    # Generate a new page_id for this page view
    page_id = Nex.Store.generate_page_id()
    Nex.Store.set_page_id(page_id)

    assigns =
      if function_exported?(module, :mount, 1) do
        module.mount(params)
      else
        %{}
      end

    # Add page_id to assigns for template injection
    assigns = Map.put(assigns, :_page_id, page_id)

    if function_exported?(module, :render, 1) do
      content = module.render(assigns)
      # Convert to string for layout embedding
      content_html = Phoenix.HTML.Safe.to_iodata(content) |> IO.iodata_to_binary()

      # Inject page_id script for HTMX
      page_id_script = """
      <script>
        document.body.setAttribute('hx-vals', JSON.stringify({_page_id: "#{page_id}"}));
      </script>
      """

      # Try to get layout module from app config
      layout_module = get_layout_module()

      html =
        if layout_module && function_exported?(layout_module, :render, 1) do
          layout_module.render(%{
            inner_content: content_html <> page_id_script,
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
    # Set page_id from HTMX request params
    page_id = params["_page_id"] || "unknown"
    Nex.Store.set_page_id(page_id)

    action_atom = String.to_atom(action)

    if function_exported?(module, action_atom, 1) do
      result = apply(module, action_atom, [params])
      send_action_response(conn, result)
    else
      send_resp(conn, 404, "Action not found: #{action}")
    end
  end

  defp send_action_response(conn, :empty) do
    send_resp(conn, 200, "")
  end

  defp send_action_response(conn, {:redirect, to}) do
    conn
    |> put_resp_header("hx-redirect", to)
    |> send_resp(200, "")
  end

  defp send_action_response(conn, {:refresh, _}) do
    conn
    |> put_resp_header("hx-refresh", "true")
    |> send_resp(200, "")
  end

  defp send_action_response(conn, heex) do
    html = Phoenix.HTML.Safe.to_iodata(heex) |> IO.iodata_to_binary()

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html)
  end

  defp resolve_action(path) do
    # Resolve POST action: find module and action function
    # e.g., POST /create_todo → Index.create_todo/2
    # e.g., POST /todos/toggle_todo → Todos.Index.toggle_todo/2
    # e.g., POST /todos/123/delete → Todos.Id.delete/2

    app_module = get_app_module()

    case path do
      [] ->
        # POST / → Index.index
        module = String.to_atom("Elixir.#{app_module}.Pages.Index")
        if Code.ensure_loaded?(module), do: {:ok, module, "index", %{}}, else: :error

      [action] ->
        # POST /create_todo → Index.create_todo
        module = String.to_atom("Elixir.#{app_module}.Pages.Index")
        if Code.ensure_loaded?(module), do: {:ok, module, action, %{}}, else: :error

      segments ->
        # POST /todos/123/delete → resolve module path, last segment is action
        {module_path, action} = Enum.split(segments, -1)
        action = List.first(action)
        {module_parts, params} = path_to_module_parts(module_path)

        module_name = [app_module, "Pages" | module_parts] |> Enum.join(".")
        module = String.to_atom("Elixir.#{module_name}")

        cond do
          Code.ensure_loaded?(module) ->
            {:ok, module, action, params}

          true ->
            # Try Index submodule
            index_module = String.to_atom("Elixir.#{module_name}.Index")
            if Code.ensure_loaded?(index_module) do
              {:ok, index_module, action, params}
            else
              :error
            end
        end
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

  defp send_error_page(conn, status, message, error) do
    # Check if request is from HTMX
    is_htmx = get_req_header(conn, "hx-request") != []

    # Check if request expects JSON
    is_json = match?(["api" | _], conn.path_info) or
              get_req_header(conn, "accept") |> Enum.any?(&String.contains?(&1, "application/json"))

    cond do
      is_json ->
        send_json_error(conn, status, message)

      is_htmx ->
        # For HTMX requests, return a simple error fragment
        html = """
        <div class="p-4 bg-red-100 border border-red-400 text-red-700 rounded">
          <strong>Error #{status}:</strong> #{html_escape(message)}
        </div>
        """
        conn
        |> put_resp_content_type("text/html")
        |> send_resp(status, html)

      true ->
        # Full error page
        error_detail = if error && Mix.env() == :dev do
          "<pre class=\"mt-4 p-4 bg-gray-800 text-green-400 rounded overflow-auto text-sm\">#{html_escape(inspect(error, pretty: true))}</pre>"
        else
          ""
        end

        html = """
        <!DOCTYPE html>
        <html lang="en">
          <head>
            <meta charset="UTF-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1.0" />
            <title>#{status} - #{html_escape(message)}</title>
            <script src="https://cdn.tailwindcss.com"></script>
          </head>
          <body class="bg-gray-100 min-h-screen flex items-center justify-center">
            <div class="text-center p-8">
              <h1 class="text-6xl font-bold text-gray-300 mb-4">#{status}</h1>
              <p class="text-xl text-gray-600 mb-8">#{html_escape(message)}</p>
              <a href="/" class="text-blue-500 hover:underline">← Back to Home</a>
              #{error_detail}
            </div>
          </body>
        </html>
        """

        conn
        |> put_resp_content_type("text/html")
        |> send_resp(status, html)
    end
  end

  defp html_escape(text) when is_binary(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
  end

  defp html_escape(text), do: html_escape(to_string(text))
end
