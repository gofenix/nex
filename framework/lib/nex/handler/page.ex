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

    assigns =
      if function_exported?(module, :mount, 1) do
        module.mount(params)
      else
        %{}
      end

    assigns =
      assigns
      |> Map.put(:_page_id, page_id)
      |> Map.put(:_csrf_token, csrf_token)

    if function_exported?(module, :render, 1) do
      content = module.render(assigns)
      content_html = Phoenix.HTML.Safe.to_iodata(content) |> IO.iodata_to_binary()
      nex_script = build_nex_script(page_id, csrf_token)
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

      html_binary =
        case html do
          binary when is_binary(binary) -> binary
          _ -> Phoenix.HTML.Safe.to_iodata(html) |> IO.iodata_to_binary()
        end

      csrf_meta = ~s(<meta name="csrf-token" content="#{csrf_token}" />)
      csrf_input = "<input type=\"hidden\" name=\"_csrf_token\" value=\"#{csrf_token}\">"

      final_html =
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

  defp get_layout_module do
    app_module = Nex.Config.app_module()

    case Nex.Utils.safe_to_existing_module("#{app_module}.Layouts") do
      {:ok, module} -> module
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
