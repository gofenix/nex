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
      method = conn.method |> String.downcase() |> String.to_atom()
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
end
