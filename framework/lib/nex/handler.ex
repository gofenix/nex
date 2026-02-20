defmodule Nex.Handler do
  @moduledoc """
  Request handler that dispatches to Pages and API modules.
  """

  import Plug.Conn
  require Logger

  @doc "Handle incoming request"
  def handle(conn) do
    # Register cleanup callback to clear process dictionary after response
    conn =
      register_before_send(conn, fn conn ->
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

        # Static files: /static/* served from priv/static/
        match?(["static" | _], path) ->
          serve_static(conn)

        # API routes: /api/*
        match?(["api" | _], path) ->
          handle_api(conn, method, path)

        # Page routes
        true ->
          handle_page(conn, method, path)
      end
    rescue
      e ->
        Logger.error(
          "Unhandled error: #{inspect(e)}\n#{Exception.format_stacktrace(__STACKTRACE__)}"
        )

        Process.put(:nex_last_stacktrace, __STACKTRACE__)
        send_error_page(conn, 500, "Internal Server Error", e)
    catch
      kind, reason ->
        Logger.error("Caught #{kind}: #{inspect(reason)}")
        Process.put(:nex_last_stacktrace, __STACKTRACE__)
        send_error_page(conn, 500, "Internal Server Error", reason)
    end
  end

  # API handlers
  defp handle_api(conn, method, path) do
    api_path =
      case path do
        ["api" | rest] -> rest
        _ -> path
      end

    case Nex.RouteDiscovery.resolve(:api, api_path) do
      {:ok, module, params} ->
        handle_api_endpoint(conn, method, module, Map.merge(conn.params, params))

      :error ->
        send_json_error(conn, 404, "Not Found")
    end
  end

  # Handle regular API endpoint
  defp handle_api_endpoint(conn, method, module, params) do
    page_id = get_page_id_from_request(conn)
    Nex.Store.set_page_id(page_id)

    # Convert Plug.Conn to Nex.Req (only path params are extracted from resolving)
    req = Nex.Req.from_plug_conn(conn, params)

    try do
      # JSON API: Always pass `req` struct
      # We intentionally do not check for arity 0 or 1 with Map to force upgrade
      if function_exported?(module, method, 1) do
        result = apply(module, method, [req])
        send_api_response(conn, result)
      else
        send_api_response(conn, :method_not_allowed)
      end
    rescue
      e in FunctionClauseError ->
        # Check if the error happened in the called function due to argument mismatch
        if e.function == method and e.arity == 1 and e.module == module do
          Logger.error("""
          [Nex] API Breaking Change Detected!
          The API signature for #{inspect(module)}.#{method}/1 has changed.
          It now expects a `Nex.Req` struct instead of a map.

          Please update your code:

              def #{method}(req) do
                id = req.query["id"]  # Use req.query for path/query params
                name = req.body["name"]  # Use req.body for POST data
                # ...
                Nex.json(%{data: ...})
              end
          """)

          send_json_error(conn, 500, "Internal Server Error: API signature mismatch")
        else
          reraise e, __STACKTRACE__
        end
    end
  end

  # Format data for SSE streaming (used by Nex.stream/1)
  defp format_sse_chunk({:raw, data}) when is_binary(data) do
    data
  end

  defp format_sse_chunk(data) when is_binary(data) do
    if String.starts_with?(data, "data: ") or String.starts_with?(data, "event: ") do
      data
    else
      "data: #{data}\n\n"
    end
  end

  defp format_sse_chunk(%{event: event, data: data}) do
    encoded = encode_sse_data(data)
    # Ensure multiline data each have data: prefix
    formatted_data =
      encoded
      |> String.split("\n")
      |> Enum.map(&"data: #{&1}")
      |> Enum.join("\n")

    "event: #{event}\n#{formatted_data}\n\n"
  end

  defp format_sse_chunk(data) when is_map(data) or is_list(data) do
    "data: #{Jason.encode!(data)}\n\n"
  end

  defp encode_sse_data(data) when is_binary(data), do: data
  defp encode_sse_data(data), do: Jason.encode!(data)

  defp send_api_response(conn, %Nex.Response{} = response) do
    if String.starts_with?(response.content_type || "", "text/event-stream") do
      handle_sse_response(conn, response)
    else
      handle_regular_response(conn, response)
    end
  end

  defp send_api_response(conn, :method_not_allowed) do
    send_json_error(conn, 405, "Method Not Allowed")
  end

  defp send_api_response(conn, other) do
    # JSON API: Enforce Nex.Response
    # We do NOT implicitly convert Maps/Lists to JSON anymore to ensure strict DX.
    error_msg = """
    [Nex] API Response Error!
    Your API handler returned an invalid response type.
    It must return a `%Nex.Response{}` struct using one of the helper functions:

    * `Nex.json(data, opts \\\\ [])`
    * `Nex.text(string, opts \\\\ [])`
    * `Nex.html(content, opts \\\\ [])`
    * `Nex.redirect(to, opts \\\\ [])`
    * `Nex.status(code)`

    Received: #{inspect(other)}
    """

    Logger.error(error_msg)

    # Development: return detailed error in response
    # Production: return generic error
    if Mix.env() == :dev do
      send_json(conn, 500, %{
        error: "Internal Server Error: Invalid Response Type",
        details: %{
          message: "Your API handler returned an invalid response type",
          received_type: other.__struct__ || "unknown",
          hint: "Return a `%Nex.Response{}` struct using helper functions like `Nex.json/2`"
        }
      })
    else
      send_json_error(conn, 500, "Internal Server Error")
    end
  end

  defp handle_sse_response(conn, response) do
    # Handle SSE streaming response
    conn =
      conn
      |> put_resp_header("content-type", "text/event-stream; charset=utf-8")
      |> put_resp_header("cache-control", "no-cache, no-transform")
      |> put_resp_header("connection", "keep-alive")

    # Apply additional headers
    conn =
      Enum.reduce(response.headers, conn, fn {k, v}, conn ->
        put_resp_header(conn, to_string(k), to_string(v))
      end)

    conn = send_chunked(conn, response.status)

    # Execute the callback function
    callback = response.body

    send_fn = fn data ->
      chunk = format_sse_chunk(data)

      case Plug.Conn.chunk(conn, chunk) do
        {:ok, conn} -> conn
        {:error, :closed} -> throw(:connection_closed)
      end
    end

    try do
      callback.(send_fn)
      conn
    rescue
      e ->
        Logger.error(
          "SSE stream error: #{inspect(e)}\n#{Exception.format_stacktrace(__STACKTRACE__)}"
        )

        conn
    catch
      :connection_closed ->
        Logger.debug("SSE connection closed by client")
        conn
    end
  end

  defp handle_regular_response(conn, response) do
    conn =
      Enum.reduce(response.headers, conn, fn {k, v}, conn ->
        put_resp_header(conn, to_string(k), to_string(v))
      end)

    body =
      if response.content_type == "application/json" and not is_binary(response.body) do
        Jason.encode!(response.body)
      else
        response.body || ""
      end

    conn
    |> put_resp_content_type(response.content_type)
    |> send_resp(response.status, body)
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
        case Nex.RouteDiscovery.resolve(:pages, path) do
          {:ok, module, params} ->
            handle_page_render(conn, module, Map.merge(conn.params, params))

          :error ->
            send_error_page(conn, 404, "Page Not Found", nil)
        end

      method when method in [:post, :delete, :put, :patch] ->
        # Attempt to validate CSRF token for requests
        # Note: In current stateless implementation, strict validation only occurs
        # if token was generated in the same request (rare for POST) or if signed tokens are implemented.
        case Nex.CSRF.validate(conn) do
          :ok ->
            # Requests call action functions
            # e.g., POST /create_todo → Index.create_todo/2
            # e.g., DELETE /delete_todo → Index.delete_todo/2
            # Get current page context from Referer header
            referer_path = get_referer_path(conn)

            case Nex.RouteDiscovery.resolve(:action, path, referer_path) do
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
    assigns =
      assigns
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
      html_binary =
        case html do
          binary when is_binary(binary) -> binary
          _ -> Phoenix.HTML.Safe.to_iodata(html) |> IO.iodata_to_binary()
        end

      # Automatically inject CSRF meta tag into <head>.
      # This removes the need for manual {meta_tag()} in layouts.
      csrf_meta = ~s(<meta name="csrf-token" content="#{csrf_token}" />)

      # Automatically inject CSRF token into all POST/PUT/PATCH/DELETE forms.
      # Covers both standard HTML forms (method="post") and HTMX forms (hx-post, hx-put, etc.)
      # This removes the need for manual {csrf_input_tag()} boilerplate.
      csrf_input = "<input type=\"hidden\" name=\"_csrf_token\" value=\"#{csrf_token}\">"

      final_html =
        html_binary
        |> String.replace("</head>", "#{csrf_meta}\n</head>", global: false)
        |> String.replace(
          ~r/(<form\b[^>]*\bmethod=["'](?:post|put|patch|delete)["'][^>]*>)/i,
          "\\1#{csrf_input}"
        )
        |> String.replace(
          ~r/(<form\b[^>]*\bhx-(?:post|put|patch|delete)=["'][^"']*["'][^>]*>)/i,
          "\\1#{csrf_input}"
        )

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

  # Serve static files from priv/static via /static/* URLs.
  # Automatically detects the priv/static directory relative to the app's otp_app.
  # Falls back to a 404 if the directory does not exist or the file is not found.
  defp serve_static(conn) do
    static_dir = find_static_dir()

    if static_dir && File.dir?(static_dir) do
      # Strip /static prefix and serve from priv/static
      opts =
        Plug.Static.init(
          at: "/static",
          from: static_dir,
          gzip: false
        )

      case Plug.Static.call(conn, opts) do
        %Plug.Conn{halted: true} = conn -> conn
        conn -> send_error_page(conn, 404, "File Not Found", nil)
      end
    else
      send_error_page(conn, 404, "File Not Found", nil)
    end
  end

  # Finds the priv/static directory for the user's application.
  # Checks :nex_core config for :priv_dir, then tries :code.priv_dir for the app,
  # then falls back to "priv/static" relative to cwd.
  defp find_static_dir do
    case Application.get_env(:nex_core, :priv_dir) do
      nil ->
        app_module = get_app_module()

        otp_app =
          app_module
          |> String.split(".")
          |> hd()
          |> Macro.underscore()
          |> String.to_existing_atom()

        case :code.priv_dir(otp_app) do
          {:error, _} -> Path.join(File.cwd!(), "priv/static")
          priv -> Path.join(to_string(priv), "static")
        end
    end
  rescue
    _ -> Path.join(File.cwd!(), "priv/static")
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

  defp get_app_module do
    Application.get_env(:nex_core, :app_module, "MyApp")
  end

  defp get_layout_module do
    app_module = get_app_module()

    case safe_to_existing_module("#{app_module}.Layouts") do
      {:ok, module} -> module
      :error -> nil
    end
  end

  defp send_error_page(conn, status, message, error) do
    is_htmx = get_req_header(conn, "hx-request") != []

    is_json =
      match?(["api" | _], conn.path_info) or
        get_req_header(conn, "accept") |> Enum.any?(&String.contains?(&1, "application/json"))

    cond do
      is_json ->
        send_json_error(conn, status, message)

      is_htmx ->
        html = """
        <div class="p-4 bg-red-100 border border-red-400 text-red-700 rounded">
          <strong>Error #{status}:</strong> #{html_escape(message)}
        </div>
        """

        conn
        |> put_resp_content_type("text/html")
        |> send_resp(status, html)

      true ->
        html = build_error_page(conn, status, message, error)

        conn
        |> put_resp_content_type("text/html")
        |> send_resp(status, html)
    end
  end

  defp build_error_page(conn, status, message, error) do
    is_dev = dev_env?()

    {exception_section, stacktrace_section, request_section} =
      if is_dev && error != nil do
        ex_section = build_exception_section(error)
        st_section = build_stacktrace_section()
        req_section = build_request_section(conn)
        {ex_section, st_section, req_section}
      else
        {"", "", ""}
      end

    """
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>#{status} — #{html_escape(message)}</title>
        <style>
          * { box-sizing: border-box; margin: 0; padding: 0; }
          body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; background: #0f0f0f; color: #e8e8e8; min-height: 100vh; }
          .header { background: #1a0000; border-bottom: 2px solid #cc3333; padding: 24px 32px; }
          .status-badge { display: inline-block; background: #cc3333; color: white; font-size: 12px; font-weight: 700; padding: 2px 8px; border-radius: 4px; letter-spacing: 0.05em; margin-bottom: 8px; }
          .error-title { font-size: 28px; font-weight: 700; color: #ff6b6b; margin-bottom: 4px; }
          .error-message { font-size: 15px; color: #aaa; }
          .content { max-width: 960px; margin: 0 auto; padding: 32px; }
          .section { margin-bottom: 28px; }
          .section-title { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.1em; color: #666; margin-bottom: 10px; }
          .card { background: #1a1a1a; border: 1px solid #2a2a2a; border-radius: 8px; overflow: hidden; }
          .card-body { padding: 16px 20px; }
          pre { font-family: "SF Mono", Monaco, "Cascadia Code", monospace; font-size: 13px; line-height: 1.6; overflow-x: auto; white-space: pre-wrap; word-break: break-all; }
          .exception-type { color: #ff6b6b; font-weight: 700; }
          .exception-msg { color: #ffd93d; }
          .frame { padding: 6px 20px; border-bottom: 1px solid #222; display: flex; gap: 16px; align-items: baseline; }
          .frame:last-child { border-bottom: none; }
          .frame-app { background: #1a1a2e; }
          .frame-file { color: #7eb8f7; font-size: 13px; font-family: monospace; flex: 1; }
          .frame-line { color: #666; font-size: 12px; white-space: nowrap; }
          .frame-func { color: #a8d8a8; font-size: 12px; font-family: monospace; white-space: nowrap; }
          .req-row { display: flex; gap: 12px; padding: 6px 0; border-bottom: 1px solid #222; font-size: 13px; }
          .req-row:last-child { border-bottom: none; }
          .req-key { color: #666; width: 100px; flex-shrink: 0; }
          .req-val { color: #e8e8e8; font-family: monospace; }
          .back-link { display: inline-block; margin-top: 24px; color: #7eb8f7; text-decoration: none; font-size: 14px; }
          .back-link:hover { text-decoration: underline; }
        </style>
      </head>
      <body>
        <div class="header">
          <div class="status-badge">#{status}</div>
          <div class="error-title">#{html_escape(message)}</div>
          <div class="error-message">#{if is_dev, do: "Development mode — full error details below", else: "An unexpected error occurred"}</div>
        </div>
        <div class="content">
          #{exception_section}
          #{stacktrace_section}
          #{request_section}
          <a href="/" class="back-link">← Back to Home</a>
        </div>
      </body>
    </html>
    """
  end

  defp build_exception_section(error) do
    {type, msg} =
      case error do
        %{__struct__: mod, message: m} -> {inspect(mod), m}
        %{__struct__: mod} -> {inspect(mod), inspect(error)}
        _ -> {"RuntimeError", inspect(error, pretty: true)}
      end

    """
    <div class="section">
      <div class="section-title">Exception</div>
      <div class="card">
        <div class="card-body">
          <pre><span class="exception-type">#{html_escape(type)}</span>
    <span class="exception-msg">#{html_escape(msg)}</span></pre>
        </div>
      </div>
    </div>
    """
  end

  defp build_stacktrace_section do
    # Retrieve the last stored stacktrace from the process
    stacktrace = Process.get(:nex_last_stacktrace, [])

    if stacktrace == [] do
      ""
    else
      frames =
        stacktrace
        |> Enum.take(15)
        |> Enum.map_join("", fn
          {mod, fun, arity, info} ->
            file = Keyword.get(info, :file, "unknown") |> to_string()
            line = Keyword.get(info, :line, 0)
            mod_str = inspect(mod)
            fun_str = "#{fun}/#{arity}"
            is_app = not String.starts_with?(mod_str, "Elixir.Phoenix") and
                     not String.starts_with?(mod_str, "Elixir.Plug") and
                     not String.starts_with?(mod_str, "Elixir.Bandit") and
                     not String.starts_with?(mod_str, "Elixir.Nex.")
            frame_class = if is_app, do: "frame frame-app", else: "frame"

            """
            <div class="#{frame_class}">
              <span class="frame-file">#{html_escape(file)}</span>
              <span class="frame-line">:#{line}</span>
              <span class="frame-func">#{html_escape(mod_str)}.#{html_escape(fun_str)}</span>
            </div>
            """

          entry ->
            "<div class=\"frame\"><span class=\"frame-file\">#{html_escape(inspect(entry))}</span></div>"
        end)

      """
      <div class="section">
        <div class="section-title">Stacktrace <span style="color:#444;font-weight:400;text-transform:none;">(app frames highlighted)</span></div>
        <div class="card">#{frames}</div>
      </div>
      """
    end
  end

  defp build_request_section(conn) do
    params_str =
      case conn.params do
        %Plug.Conn.Unfetched{} -> "(unfetched)"
        p -> inspect(p, pretty: true, limit: 10)
      end

    rows = [
      {"Method", conn.method},
      {"Path", conn.request_path},
      {"Params", params_str},
      {"Host", conn.host}
    ]

    rows_html =
      Enum.map_join(rows, "", fn {k, v} ->
        """
        <div class="req-row">
          <span class="req-key">#{k}</span>
          <span class="req-val">#{html_escape(to_string(v))}</span>
        </div>
        """
      end)

    """
    <div class="section">
      <div class="section-title">Request</div>
      <div class="card"><div class="card-body">#{rows_html}</div></div>
    </div>
    """
  end

  defp dev_env? do
    Application.get_env(:nex_core, :env, :prod) == :dev
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
    # Try to get page_id from header (set by HTMX/client-side JS)
    case get_req_header(conn, "x-nex-page-id") do
      [page_id | _] -> page_id
      [] -> generate_page_id()
    end
  end

  defp generate_page_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end

  # Extract path from Referer header
  defp get_referer_path(conn) do
    case get_req_header(conn, "referer") do
      [referer | _] ->
        # Parse the referer URL and extract the path
        # e.g., "http://localhost:4000/requests" -> ["requests"]
        uri = URI.parse(referer)

        case uri.path do
          nil ->
            []

          "/" ->
            []

          path ->
            path
            |> String.trim_leading("/")
            |> String.split("/")
            |> Enum.reject(&(&1 == ""))
        end

      [] ->
        # No referer, default to empty path (will use Index)
        []
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
    live_reload_script =
      if Nex.Reloader.enabled?() do
        """
          // Live reload via WebSocket (dev only)
          (function() {
            var pendingReload = false;
            function connect() {
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
                // Reconnect instead of reloading - avoids killing long-running operations
                setTimeout(function() { connect(); }, 2000);
              };
            }
            connect();
          })();
        """
      else
        ""
      end

    base_script <> live_reload_script <> "</script>"
  end
end
