defmodule Nex.Handler.Page do
  @moduledoc false

  import Plug.Conn

  alias Nex.Handler.Errors

  def handle(conn, method, path) do
    case method do
      :get ->
        case Nex.RouteDiscovery.resolve(:pages, path) do
          {:ok, module, params} ->
            handle_page_render(conn, module, Map.merge(conn.params, params))

          :error ->
            Errors.send_error_page(conn, 404, "Page Not Found", nil)
        end

      method when method in [:post, :delete, :put, :patch] ->
        case Nex.CSRF.validate(conn) do
          :ok ->
            referer_path = referer_path(conn)

            case Nex.RouteDiscovery.resolve(:action, path, referer_path) do
              {:ok, module, action, params} ->
                handle_page_action(conn, module, action, Map.merge(conn.params, params))

              :error ->
                Errors.send_error_page(conn, 404, "Action Not Found", nil)
            end

          {:error, :missing_token} ->
            Errors.send_error_page(conn, 403, "CSRF token missing", nil)

          {:error, :invalid_token} ->
            Errors.send_error_page(conn, 403, "CSRF token invalid", nil)
        end

      _ ->
        Errors.send_error_page(conn, 405, "Method Not Allowed", nil)
    end
  end

  def page_id_from_request(conn) do
    case get_req_header(conn, "x-nex-page-id") do
      [page_id | _] -> page_id
      [] -> generate_page_id()
    end
  end

  defp handle_page_render(conn, module, params) do
    page_id = Nex.Store.generate_page_id()
    Nex.Store.set_page_id(page_id)
    csrf_token = Nex.CSRF.generate_token()

    case call_mount(module, params) do
      {:redirect, path} ->
        conn |> put_resp_header("location", path) |> send_resp(302, "")

      {:redirect, path, status} ->
        conn |> put_resp_header("location", path) |> send_resp(status, "")

      :not_found ->
        Errors.send_error_page(conn, 404, "Page Not Found", nil)

      %{} = assigns ->
        render_page(conn, module, assigns, page_id, csrf_token)
    end
  end

  defp call_mount(module, params) do
    if function_exported?(module, :mount, 1), do: module.mount(params), else: %{}
  end

  defp render_page(conn, module, assigns, page_id, csrf_token) do
    assigns =
      assigns
      |> Map.put(:_page_id, page_id)
      |> Map.put(:_csrf_token, csrf_token)

    if function_exported?(module, :render, 1) do
      content = module.render(assigns)
      content_html = Phoenix.HTML.Safe.to_iodata(content) |> IO.iodata_to_binary()
      page_path = "/" <> Enum.join(conn.path_info, "/")
      nex_script = build_nex_script(page_id, csrf_token, page_path)

      # Phase 1: _app.ex wraps page content (receives all assigns)
      app_html = wrap_with_app(module, assigns, content_html)

      # Phase 2: _document.ex provides HTML shell
      doc_html = wrap_with_document(assigns, app_html <> nex_script)

      # Phase 3: CSRF injection
      final_html = inject_csrf(doc_html, csrf_token)

      conn
      |> put_resp_content_type("text/html")
      |> send_resp(200, final_html)
    else
      send_resp(conn, 500, "Page module missing render/1")
    end
  end

  defp handle_page_action(conn, module, action, params) do
    page_id = page_id_from_request(conn)
    Nex.Store.set_page_id(page_id)
    req = Nex.Req.from_plug_conn(conn, params)

    case Nex.Utils.safe_to_existing_atom(action) do
      {:ok, action_atom} ->
        if function_exported?(module, action_atom, 1) do
          result = apply(module, action_atom, [req])
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

  defp send_action_response(conn, %Nex.Response{
         status: status,
         headers: headers,
         body: body,
         content_type: content_type
       }) do
    is_redirect = status in [301, 302, 303, 307, 308]
    is_htmx = get_req_header(conn, "hx-request") != []

    conn = Enum.reduce(headers, conn, fn {key, value}, conn -> put_resp_header(conn, key, value) end)
    conn = if content_type, do: put_resp_content_type(conn, content_type), else: conn

    cond do
      is_redirect and is_htmx ->
        location = Map.get(headers, "location", "/")

        conn
        |> put_resp_header("hx-redirect", location)
        |> send_resp(200, "")

      is_redirect ->
        send_resp(conn, status, "")

      is_struct(body, Phoenix.LiveView.Rendered) ->
        html = Phoenix.HTML.Safe.to_iodata(body) |> IO.iodata_to_binary()
        send_resp(conn, status, html)

      is_function(body, 1) ->
        conn = send_chunked(conn, 200)
        body.(fn chunk -> Plug.Conn.chunk(conn, chunk) end)
        conn

      true ->
        body_str = if is_binary(body), do: body, else: Jason.encode!(body)
        send_resp(conn, status, body_str)
    end
  end

  defp send_action_response(conn, heex) do
    html = Phoenix.HTML.Safe.to_iodata(heex) |> IO.iodata_to_binary()

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html)
  end

  # --- Two-phase layout rendering ---

  defp wrap_with_app(page_module, assigns, content_html) do
    app_module = resolve_app_module(page_module)

    if app_module && function_exported?(app_module, :render, 1) do
      app_assigns =
        assigns
        |> Map.put(:inner_content, content_html)
        |> Map.put_new(:title, "Nex App")

      app_module.render(app_assigns) |> to_html_binary()
    else
      content_html
    end
  end

  defp wrap_with_document(assigns, inner_html) do
    doc_module = resolve_document_module()

    if doc_module && function_exported?(doc_module, :render, 1) do
      doc_assigns = %{inner_content: inner_html, title: Map.get(assigns, :title, "Nex App")}
      doc_module.render(doc_assigns) |> to_html_binary()
    else
      default_document(inner_html, Map.get(assigns, :title, "Nex App"))
    end
  end

  defp default_document(inner_html, title) do
    """
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>#{title}</title>
      </head>
      <body>
        #{inner_html}
      </body>
    </html>
    """
  end

  defp inject_csrf(html_binary, csrf_token) do
    csrf_meta = ~s(<meta name="csrf-token" content="#{csrf_token}" />)
    csrf_input = "<input type=\"hidden\" name=\"_csrf_token\" value=\"#{csrf_token}\">"

    html_binary
    |> String.replace("</head>", "#{csrf_meta}\n</head>", global: false)
    |> String.replace(
      ~r/(<form\b[^>]*\bmethod=["'](?:post|put|patch|delete)["'][^>]*>)/i,
      "\\1#{csrf_input}"
    )
    |> String.replace(
      ~r/(<form\b[^>]*\bhx-(?:post|put|patch|delete)=["'][^\"']*[\"'][^>]*>)/i,
      "\\1#{csrf_input}"
    )
  end

  defp to_html_binary(html) when is_binary(html), do: html
  defp to_html_binary(html), do: Phoenix.HTML.Safe.to_iodata(html) |> IO.iodata_to_binary()

  # --- Module resolution ---

  defp resolve_app_module(page_module) do
    if function_exported?(page_module, :layout, 0) do
      case page_module.layout() do
        :none -> nil
        mod when is_atom(mod) -> mod
        _ -> resolve_default_app_module()
      end
    else
      resolve_default_app_module()
    end
  end

  defp resolve_default_app_module do
    app = Nex.Config.app_module()

    with :error <- Nex.Utils.safe_to_existing_module("#{app}.Pages.App"),
         :error <- Nex.Utils.safe_to_existing_module("#{app}.Layouts") do
      nil
    else
      {:ok, mod} -> mod
    end
  end

  defp resolve_document_module do
    app = Nex.Config.app_module()

    case Nex.Utils.safe_to_existing_module("#{app}.Pages.Document") do
      {:ok, mod} -> mod
      :error -> nil
    end
  end

  defp generate_page_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end

  defp referer_path(conn) do
    case get_req_header(conn, "referer") do
      [referer | _] ->
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
        []
    end
  end

  defp build_nex_script(page_id, csrf_token, page_path) do
    base_script = """
    <script>
      document.body.dataset.pageId = "#{page_id}";
      document.body.dataset.csrfToken = "#{csrf_token}";
      document.body.dataset.pagePath = "#{page_path}";
      document.body.addEventListener('htmx:configRequest', function(evt) {
        evt.detail.headers['X-Nex-Page-Id'] = document.body.dataset.pageId;
        evt.detail.headers['X-CSRF-Token'] = document.body.dataset.csrfToken;

        var pagePath = document.body.dataset.pagePath;
        if (pagePath && pagePath !== '/') {
          var path = evt.detail.path;
          var segments = path.split('/').filter(Boolean);
          if (segments.length === 1 && !path.startsWith('/api/') && !path.startsWith('/static/') && !path.startsWith('/ws/')) {
            evt.detail.path = pagePath + path;
          }
        }
      });
    """

    live_reload_script =
      if Nex.Reloader.enabled?() do
        """
          // Live reload via WebSocket (dev only)
          (function() {
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
