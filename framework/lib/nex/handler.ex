defmodule Nex.Handler do
  @moduledoc """
  Request handler that dispatches to Pages and API modules.
  """

  require Logger

  alias Nex.Handler.{Dispatch, Errors, Lifecycle}

  @doc "Handle incoming request"
  def handle(conn) do
    conn = Lifecycle.prepare(conn)

    try do
      method = conn.method |> String.downcase() |> safe_to_method_atom()
      path = conn.path_info
      conn = Nex.Middleware.run(conn)

      if conn.halted do
        conn
      else
        Dispatch.route(conn, method, path)
      end
    rescue
      error ->
        Logger.error(
          "Unhandled error: #{inspect(error)}\n#{Exception.format_stacktrace(__STACKTRACE__)}"
        )

        Process.put(:nex_last_stacktrace, __STACKTRACE__)
        Errors.send_error_page(conn, 500, "Internal Server Error", error)
    catch
      kind, reason ->
        Logger.error("Caught #{kind}: #{inspect(reason)}")
        Process.put(:nex_last_stacktrace, __STACKTRACE__)
        Errors.send_error_page(conn, 500, "Internal Server Error", reason)
    end
  end

  @known_methods [:get, :post, :put, :patch, :delete, :head, :options, :connect, :trace]

  defp safe_to_method_atom(method_str) do
    case String.to_existing_atom(method_str) do
      atom when atom in @known_methods -> atom
      _ -> :get
    end
  rescue
    ArgumentError -> :get
  end
end
