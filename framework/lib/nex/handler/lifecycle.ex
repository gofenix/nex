defmodule Nex.Handler.Lifecycle do
  @moduledoc false

  import Plug.Conn

  def prepare(conn) do
    conn
    |> Nex.Cookie.load_from_conn()
    |> Nex.Session.load_from_conn()
    |> register_before_send(&cleanup/1)
  end

  defp cleanup(conn) do
    conn = Nex.Session.persist_to_conn(conn)
    conn = Nex.Cookie.apply_to_conn(conn)

    Nex.Store.clear_process_dictionary()
    Nex.Cookie.clear_process_state()
    Nex.Session.clear_process_state()

    conn
  end
end
