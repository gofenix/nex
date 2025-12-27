defmodule Nex.Page do
  @moduledoc """
  Page module for rendering full HTML pages and handling HTMX requests.
  
  ## Usage
  
      defmodule MyApp.Pages.Index do
        use Nex.Page
        
        def mount(_conn, _params) do
          %{title: "Home", items: []}
        end
        
        def render(assigns) do
          ~H\"\"\"
          <h1>{@title}</h1>
          \"\"\"
        end
        
        # HTMX handler: POST /create_item
        def create_item(conn, params) do
          item = create(params)
          render_fragment(conn, ~H"<li>{item.name}</li>")
        end
      end
  """

  defmacro __using__(_opts) do
    quote do
      import Phoenix.Component, only: [sigil_H: 2]
      import Nex.Page.Helpers
    end
  end
end

defmodule Nex.Page.Helpers do
  @moduledoc false
  import Plug.Conn

  @doc "Render an HTML fragment (for HTMX responses)"
  def render_fragment(conn, heex) do
    html = heex |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html)
  end

  @doc "Return empty response (for delete operations)"
  def empty(conn) do
    send_resp(conn, 200, "")
  end

  @doc "HTMX redirect"
  def hx_redirect(conn, to) do
    conn
    |> put_resp_header("hx-redirect", to)
    |> send_resp(200, "")
  end

  @doc "HTMX refresh"
  def hx_refresh(conn) do
    conn
    |> put_resp_header("hx-refresh", "true")
    |> send_resp(200, "")
  end
end
