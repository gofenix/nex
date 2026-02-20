defmodule Nex.Middleware do
  @moduledoc """
  Plug pipeline middleware support for Nex applications.

  Allows users to declare a list of Plugs that run on every request before
  the framework's own routing logic. Useful for authentication, logging,
  request rate limiting, and other cross-cutting concerns.

  ## Configuration

  In your `application.ex` or `mix.exs` config:

      # application.ex
      def start(_type, _args) do
        Application.put_env(:nex_core, :plugs, [
          MyApp.Plugs.Auth,
          MyApp.Plugs.RequestLogger
        ])
        # ...
      end

  ## Writing a Plug

      defmodule MyApp.Plugs.Auth do
        import Plug.Conn

        def init(opts), do: opts

        def call(conn, _opts) do
          session_user = Nex.Session.get(:user_id)

          if session_user do
            conn
          else
            conn
            |> put_resp_header("location", "/login")
            |> send_resp(302, "")
            |> halt()
          end
        end
      end

  ## Path-scoped Middleware

  To apply a plug only to certain paths, check `conn.path_info` inside the plug:

      def call(conn, _opts) do
        if List.starts_with?(conn.path_info, ["admin"]) do
          # apply auth check
        else
          conn
        end
      end
  """

  @doc """
  Runs all configured plugs against the conn in order.
  Returns the (possibly halted) conn.
  """
  def run(conn) do
    plugs = Application.get_env(:nex_core, :plugs, [])
    run_plugs(conn, plugs)
  end

  defp run_plugs(conn, []), do: conn
  defp run_plugs(%Plug.Conn{halted: true} = conn, _plugs), do: conn

  defp run_plugs(conn, [plug | rest]) do
    opts = plug.init([])
    conn = plug.call(conn, opts)
    run_plugs(conn, rest)
  end
end
