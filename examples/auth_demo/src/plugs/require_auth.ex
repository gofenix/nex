defmodule AuthDemo.Plugs.RequireAuth do
  import Plug.Conn

  # Public paths that don't require authentication
  @public_prefixes [["login"], ["static"], ["nex"]]
  @public_exact [[]]

  def init(opts), do: opts

  def call(conn, _opts) do
    path = conn.path_info
    public? =
      path in @public_exact or
        Enum.any?(@public_prefixes, fn p -> List.starts_with?(path, p) end)

    if public? do
      conn
    else
      user_id = Nex.Session.get(:user)

      if user_id do
        conn
      else
        Nex.Flash.put(:error, "Please log in to access that page.")

        conn
        |> put_resp_header("location", "/login")
        |> send_resp(302, "")
        |> halt()
      end
    end
  end
end
