defmodule Nex.Handler.Errors do
  @moduledoc false

  import Plug.Conn

  def send_json_error(conn, status, message) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(%{error: message}))
  end

  def send_error_page(conn, status, message, error) do
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
    case resolve_convention_error_module(status) do
      {:ok, module} ->
        try do
          render_convention_error(module, status, message)
        rescue
          _ -> fallback_error_page(conn, status, message, error)
        end

      :none ->
        fallback_error_page(conn, status, message, error)
    end
  end

  defp resolve_convention_error_module(status) do
    app_module = Nex.Config.app_module()
    module_name = "#{app_module}.Pages.Error#{status}"

    case Nex.Utils.safe_to_existing_module(module_name) do
      {:ok, module} -> {:ok, module}
      :error -> :none
    end
  end

  defp render_convention_error(module, status, message) do
    assigns = %{
      status: status,
      message: message,
      title: "#{status} — #{message}"
    }

    if function_exported?(module, :render, 1) do
      assigns
      |> module.render()
      |> to_html_binary()
      |> wrap_with_error_shell(module, assigns)
    else
      raise "Convention error module missing render/1"
    end
  end

  defp wrap_with_error_shell(content_html, module, assigns) do
    content_html
    |> wrap_with_app(module, assigns)
    |> wrap_with_document(assigns)
  end

  defp wrap_with_app(content_html, error_module, assigns) do
    case resolve_app_module(error_module) do
      nil ->
        content_html

      layout_module ->
        layout_assigns =
          assigns
          |> Map.put(:inner_content, content_html)
          |> Map.put_new(:title, "Nex App")

        layout_module.render(layout_assigns) |> to_html_binary()
    end
  end

  defp wrap_with_document(inner_html, assigns) do
    case resolve_document_module() do
      nil ->
        default_document(inner_html, Map.get(assigns, :title, "Nex App"))

      document_module ->
        document_assigns = %{
          inner_content: inner_html,
          title: Map.get(assigns, :title, "Nex App")
        }

        document_module.render(document_assigns) |> to_html_binary()
    end
  end

  defp resolve_app_module(error_module) do
    case layout_override(error_module) do
      :none -> nil
      nil -> resolve_default_app_module()
      layout_module -> layout_module
    end
  end

  defp layout_override(error_module) do
    if function_exported?(error_module, :layout, 0) do
      case error_module.layout() do
        :none -> :none
        module when is_atom(module) -> module
        _ -> nil
      end
    else
      nil
    end
  end

  defp resolve_default_app_module do
    app_module = Nex.Config.app_module()

    with :error <- Nex.Utils.safe_to_existing_module("#{app_module}.Pages.App"),
         :error <- Nex.Utils.safe_to_existing_module("#{app_module}.Layouts") do
      nil
    else
      {:ok, module} -> module
    end
  end

  defp resolve_document_module do
    app_module = Nex.Config.app_module()

    case Nex.Utils.safe_to_existing_module("#{app_module}.Pages.Document") do
      {:ok, module} -> module
      :error -> nil
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

  defp to_html_binary(html) when is_binary(html), do: html
  defp to_html_binary(html), do: Phoenix.HTML.Safe.to_iodata(html) |> IO.iodata_to_binary()

  defp fallback_error_page(conn, status, message, error) do
    case Application.get_env(:nex_core, :error_page_module) do
      nil ->
        build_default_error_page(conn, status, message, error)

      module ->
        try do
          apply(module, :render_error, [conn, status, message, error])
        rescue
          _ -> build_default_error_page(conn, status, message, error)
        end
    end
  end

  defp build_default_error_page(conn, status, message, error) do
    is_dev = dev_env?()

    {exception_section, stacktrace_section, request_section} =
      if is_dev && error != nil do
        {build_exception_section(error), build_stacktrace_section(), build_request_section(conn)}
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

            is_app =
              not String.starts_with?(mod_str, "Elixir.Phoenix") and
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
        params -> inspect(params, pretty: true, limit: 10)
      end

    rows = [
      {"Method", conn.method},
      {"Path", conn.request_path},
      {"Params", params_str},
      {"Host", conn.host}
    ]

    rows_html =
      Enum.map_join(rows, "", fn {key, value} ->
        """
        <div class="req-row">
          <span class="req-key">#{key}</span>
          <span class="req-val">#{html_escape(to_string(value))}</span>
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

  defp dev_env?, do: Nex.Config.dev?()

  defp html_escape(text) when is_binary(text) do
    Phoenix.HTML.html_escape(text) |> Phoenix.HTML.safe_to_string()
  end

  defp html_escape(text) do
    text |> to_string() |> html_escape()
  end
end
