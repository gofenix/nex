defmodule Nex.Handler do
  @moduledoc """
  Request handler that dispatches to Pages and API modules.
  """

  import Plug.Conn
  require Logger

  @doc "Handle incoming request"
  def handle(conn) do
    # Register cleanup callback to clear process dictionary after response
    conn = register_before_send(conn, fn conn ->
      Nex.Store.clear_process_dictionary()
      conn
    end)

    try do
      method = conn.method |> String.downcase() |> String.to_atom()
      path = conn.path_info

      cond do
        # Live reload WebSocket endpoint
        path == ["nex", "live-reload-ws"] ->
          WebSockAdapter.upgrade(conn, Nex.LiveReloadSocket, %{}, [])

        # Live reload HTTP endpoint (fallback for old clients)
        path == ["nex", "live-reload"] ->
          handle_live_reload(conn)

        # API routes: /api/* (check for SSE endpoints first)
        match?(["api" | _], path) ->
          handle_api_or_sse(conn, method, path)

        # Legacy SSE endpoint: /sse/* (for backward compatibility)
        match?(["sse" | _], path) ->
          handle_sse(conn, method, path)

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

  # API or SSE handlers - check if module uses Nex.SSE
  defp handle_api_or_sse(conn, method, path) do
    api_path = case path do
      ["api" | rest] -> rest
      _ -> path
    end

    case resolve_api_module(api_path) do
      {:ok, module, params} ->
        # Check if this is an SSE endpoint (has __sse_endpoint__ function)
        is_sse = Code.ensure_loaded?(module) and function_exported?(module, :__sse_endpoint__, 0)

        if is_sse do
          # Handle as SSE endpoint
          handle_sse_endpoint(conn, module, Map.merge(conn.params, params))
        else
          # Handle as regular API endpoint
          handle_api_endpoint(conn, method, module, Map.merge(conn.params, params))
        end

      :error ->
        send_json_error(conn, 404, "Not Found")
    end
  end

  # Handle SSE endpoint (module uses Nex.SSE)
  defp handle_sse_endpoint(conn, module, params) do
    page_id = get_page_id_from_request(conn)
    Nex.Store.set_page_id(page_id)

    # Check for stream/2 callback function
    has_stream = function_exported?(module, :stream, 2)

    if has_stream do
      conn
      |> put_resp_header("content-type", "text/event-stream")
      |> put_resp_header("cache-control", "no-cache")
      |> put_resp_header("connection", "keep-alive")
      |> send_chunked(200)
      |> send_sse_stream(module, params)
    else
      send_json_error(conn, 500, "SSE endpoint must implement stream/2")
    end
  end

  # Handle regular API endpoint
  defp handle_api_endpoint(conn, method, module, params) do
    page_id = get_page_id_from_request(conn)
    Nex.Store.set_page_id(page_id)

    # Try arity 1 first (with params), then arity 0 (no params)
    result = cond do
      function_exported?(module, method, 1) ->
        apply(module, method, [params])
      function_exported?(module, method, 0) ->
        apply(module, method, [])
      true ->
        :method_not_allowed
    end

    send_api_response(conn, result)
  end

  # SSE handlers
  defp handle_sse(conn, _method, path) do
    sse_path = case path do
      ["sse" | rest] -> rest
      _ -> path
    end

    app_module = get_app_module()
    # Convert path segments to PascalCase (e.g., "stream" -> "Stream")
    camelized_path = Enum.map(sse_path, &Macro.camelize/1)
    module_name = [app_module, "Sse" | camelized_path] |> Enum.join(".")

    # Use safe module resolution to prevent atom exhaustion
    case safe_to_existing_module(module_name) do
      {:ok, module} ->
        if function_exported?(module, :stream, 2) or function_exported?(module, :stream, 1) do
          page_id = get_page_id_from_request(conn)
          Nex.Store.set_page_id(page_id)
          params = conn.params

          # Send SSE headers and stream response
          conn
          |> put_resp_header("content-type", "text/event-stream")
          |> put_resp_header("cache-control", "no-cache")
          |> put_resp_header("connection", "keep-alive")
          |> send_chunked(200)
          |> send_sse_stream(module, params)
        else
          try_sse_index_module(conn, module_name)
        end

      :error ->
        try_sse_index_module(conn, module_name)
    end
  end

  defp try_sse_index_module(conn, module_name) do
    case safe_to_existing_module("#{module_name}.Index") do
      {:ok, index_module} ->
        if function_exported?(index_module, :stream, 2) or function_exported?(index_module, :stream, 1) do
          page_id = get_page_id_from_request(conn)
          Nex.Store.set_page_id(page_id)
          params = conn.params

          conn
          |> put_resp_header("content-type", "text/event-stream")
          |> put_resp_header("cache-control", "no-cache")
          |> put_resp_header("connection", "keep-alive")
          |> put_resp_header("x-nex-page-id", page_id)
          |> send_chunked(200)
          |> send_sse_stream(index_module, params)
        else
          send_json_error(conn, 404, "SSE endpoint not found")
        end

      :error ->
        send_json_error(conn, 404, "SSE endpoint not found")
    end
  end

  defp send_sse_stream(conn, module, params) do
    # Check if module supports callback-based streaming
    if function_exported?(module, :stream, 2) do
      # Callback-based streaming: stream(params, send_fn)
      # send_fn is called for each event to send immediately
      apply(module, :stream, [params, fn event ->
        sse_data = format_sse_event(event)
        case chunk(conn, sse_data) do
          {:ok, _} -> :ok
          {:error, _} -> throw(:closed)
        end
      end])
      conn
    else
      # Legacy: return list of events
      events = apply(module, :stream, [params])

      Enum.reduce(events, conn, fn event, conn ->
        sse_data = format_sse_event(event)
        case chunk(conn, sse_data) do
          {:ok, conn} -> conn
          {:error, _} -> throw(:closed)
        end
      end)
    end
  catch
    :closed ->
      # Connection was closed by client
      :ok
  end

  defp format_sse_event(%{event: event_type, data: data, id: id}) do
    # For HTMX SSE extension compatibility: send plain text for "message" event
    if event_type == "message" do
      "event: #{event_type}\ndata: #{data}\nid: #{id}\n\n"
    else
      # Send JSON-encoded data for custom events
      json_data = Jason.encode!(%{event: event_type, data: data, id: id})
      "data: #{json_data}\n\n"
    end
  end

  defp format_sse_event(%{event: event_type, data: data}) do
    # For HTMX SSE extension compatibility: send plain text for "message" event
    if event_type == "message" do
      "event: #{event_type}\ndata: #{data}\n\n"
    else
      # Send JSON-encoded data for custom events
      json_data = Jason.encode!(%{event: event_type, data: data})
      "data: #{json_data}\n\n"
    end
  end

  defp format_sse_event(event) when is_map(event) do
    "data: #{Jason.encode!(event)}\n\n"
  end

  defp format_sse_event(event) when is_binary(event) do
    # Plain text fallback
    "data: #{Jason.encode!(event)}\n\n"
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
        # Validate CSRF token for POST requests (skip for API routes)
        case Nex.CSRF.validate(conn) do
          :ok ->
            # POST requests call action functions
            # e.g., POST /create_todo → Index.create_todo/2
            # e.g., POST /todos/123/toggle → Todos.Id.toggle/2
            case resolve_action(path) do
              {:ok, module, action, params} ->
                handle_page_action(conn, module, action, Map.merge(conn.params, params))

              :error ->
                send_error_page(conn, 404, "Action Not Found", nil)
            end

          {:error, :missing_token} ->
            send_error_page(conn, 403, "CSRF token missing", nil)

          {:error, :invalid_token} ->
            send_error_page(conn, 403, "CSRF token invalid", nil)
        end

      _ ->
        send_error_page(conn, 405, "Method Not Allowed", nil)
    end
  end

  defp handle_page_render(conn, module, params) do
    # Generate a new page_id for this page view
    page_id = Nex.Store.generate_page_id()
    Nex.Store.set_page_id(page_id)

    # Generate CSRF token for this page
    csrf_token = Nex.CSRF.generate_token()

    assigns =
      if function_exported?(module, :mount, 1) do
        module.mount(params)
      else
        %{}
      end

    # Add page_id and csrf_token to assigns for template injection
    assigns = assigns
      |> Map.put(:_page_id, page_id)
      |> Map.put(:_csrf_token, csrf_token)

    if function_exported?(module, :render, 1) do
      content = module.render(assigns)
      # Convert to string for layout embedding
      content_html = Phoenix.HTML.Safe.to_iodata(content) |> IO.iodata_to_binary()

      # Inject page_id and CSRF token for HTMX
      # Live reload script only in dev environment
      nex_script = build_nex_script(page_id, csrf_token)

      # Try to get layout module from app config
      layout_module = get_layout_module()

      html =
        if layout_module && function_exported?(layout_module, :render, 1) do
          layout_module.render(%{
            inner_content: content_html <> nex_script,
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

  defp handle_live_reload(conn) do
    last_reload = Nex.Reloader.last_reload_time()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{time: last_reload}))
  end

  defp handle_page_action(conn, module, action, params) do
    # Set page_id from HTMX request header
    page_id = get_page_id_from_request(conn)
    Nex.Store.set_page_id(page_id)

    # Use to_existing_atom to prevent atom exhaustion attacks
    case safe_to_existing_atom(action) do
      {:ok, action_atom} ->
        if function_exported?(module, action_atom, 1) do
          result = apply(module, action_atom, [params])
          send_action_response(conn, result)
        else
          send_resp(conn, 404, "Action not found: #{action}")
        end

      :error ->
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
    # e.g., POST /todos/123/delete → resolve module path, last segment is action

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

        # Try dynamic route discovery first
        routes = Nex.RouteDiscovery.get_routes(src_path, :pages)

        case Nex.RouteDiscovery.match_route(routes, module_path, app_module, "Pages") do
          {:ok, module_name, params} ->
            case safe_to_existing_module(module_name) do
              {:ok, module} -> {:ok, module, action, params}
              :error -> resolve_action_legacy(module_path, action, app_module)
            end

          :error ->
            resolve_action_legacy(module_path, action, app_module)
        end
    end
  end

  defp resolve_action_legacy(module_path, action, app_module) do
    {module_parts, params} = path_to_module_parts(module_path)
    module_name = [app_module, "Pages" | module_parts] |> Enum.join(".")

    case safe_to_existing_module(module_name) do
      {:ok, module} ->
        {:ok, module, action, params}

      :error ->
        case safe_to_existing_module("#{module_name}.Index") do
          {:ok, index_module} -> {:ok, index_module, action, params}
          :error -> :error
        end
    end
  end

  defp resolve_page_module(path) do
    # Try dynamic route discovery first, then fall back to legacy behavior
    app_module = get_app_module()
    src_path = get_src_path()

    # Get cached routes
    routes = Nex.RouteDiscovery.get_routes(src_path, :pages)

    case Nex.RouteDiscovery.match_route(routes, path, app_module, "Pages") do
      {:ok, module_name, params} ->
        case safe_to_existing_module(module_name) do
          {:ok, module} -> {:ok, module, params}
          :error -> resolve_page_module_legacy(path, app_module)
        end

      :error ->
        resolve_page_module_legacy(path, app_module)
    end
  end

  defp resolve_page_module_legacy(path, app_module) do
    # Legacy behavior for backward compatibility
    {module_parts, params} = path_to_module_parts(path)

    module_name =
      [app_module, "Pages" | module_parts]
      |> Enum.join(".")

    case safe_to_existing_module(module_name) do
      {:ok, module} ->
        {:ok, module, params}

      :error ->
        case safe_to_existing_module("#{module_name}.Index") do
          {:ok, index_module} -> {:ok, index_module, params}
          :error -> :error
        end
    end
  end

  defp resolve_api_module(path) do
    app_module = get_app_module()
    src_path = get_src_path()

    # Get cached routes for API
    routes = Nex.RouteDiscovery.get_routes(src_path, :api)

    case Nex.RouteDiscovery.match_route(routes, path, app_module, "Api") do
      {:ok, module_name, params} ->
        case safe_to_existing_module(module_name) do
          {:ok, module} -> {:ok, module, params}
          :error -> resolve_api_module_legacy(path, app_module)
        end

      :error ->
        resolve_api_module_legacy(path, app_module)
    end
  end

  defp resolve_api_module_legacy(path, app_module) do
    # Legacy behavior for backward compatibility
    {module_parts, params} = path_to_module_parts(path)

    module_name =
      [app_module, "Api" | module_parts]
      |> Enum.join(".")

    case safe_to_existing_module(module_name) do
      {:ok, module} ->
        {:ok, module, params}

      :error ->
        case safe_to_existing_module("#{module_name}.Index") do
          {:ok, index_module} -> {:ok, index_module, params}
          :error -> :error
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

  defp get_src_path do
    # Get the source path from application config
    Application.get_env(:nex, :src_path, "src")
  end

  defp get_layout_module do
    app_module = get_app_module()

    case safe_to_existing_module("#{app_module}.Layouts") do
      {:ok, module} -> module
      :error -> nil
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

  # Safe atom/module conversion to prevent atom exhaustion attacks
  # Only converts to atom if it already exists (i.e., module was compiled)
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

  # Get page_id from request (header or fallback to param for backward compatibility)
  defp get_page_id_from_request(conn) do
    case get_req_header(conn, "x-nex-page-id") do
      [page_id | _] when is_binary(page_id) and page_id != "" -> page_id
      _ -> conn.params["_page_id"] || "unknown"
    end
  end

  # Build the Nex script for page_id, CSRF token, and optional live reload
  defp build_nex_script(page_id, csrf_token) do
    base_script = """
    <script>
      // Store page_id and CSRF token, configure HTMX to send them via headers
      document.body.dataset.pageId = "#{page_id}";
      document.body.dataset.csrfToken = "#{csrf_token}";
      document.body.addEventListener('htmx:configRequest', function(evt) {
        evt.detail.headers['X-Nex-Page-Id'] = document.body.dataset.pageId;
        evt.detail.headers['X-CSRF-Token'] = document.body.dataset.csrfToken;
      });
    """

    # Only add live reload script in dev environment
    live_reload_script = if Nex.Reloader.enabled?() do
      """
        // Live reload via WebSocket (dev only)
        (function() {
          const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
          const ws = new WebSocket(protocol + '//' + window.location.host + '/nex/live-reload-ws');

          ws.onmessage = function(event) {
            const data = JSON.parse(event.data);
            if (data.reload) {
              console.log('[Nex] File changed, reloading...');
              window.location.reload();
            }
          };

          ws.onerror = function() {
            console.log('[Nex] WebSocket error');
          };

          ws.onclose = function() {
            setTimeout(function() { window.location.reload(); }, 1000);
          };
        })();
      """
    else
      ""
    end

    base_script <> live_reload_script <> "</script>"
  end
end
