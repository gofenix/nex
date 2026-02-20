defmodule Nex.Cookie do
  @moduledoc """
  Cookie read/write helpers for Nex actions and API handlers.

  Cookies are set by storing pending cookie operations in the process dictionary.
  `Nex.Handler` applies them to the `Plug.Conn` response before sending.

  ## Usage

      # In a page action
      def login(%{"token" => token}) do
        Nex.Cookie.put(:session_id, token, max_age: 86_400, http_only: true)
        Nex.redirect("/dashboard")
      end

      def logout(_params) do
        Nex.Cookie.delete(:session_id)
        Nex.redirect("/")
      end

      # Read cookies in mount/1 via params (cookies are in req.cookies for API,
      # or use Nex.Cookie.get/1 in page mount)
      def mount(params) do
        session_id = Nex.Cookie.get(:session_id)
        %{logged_in: session_id != nil}
      end

  ## Options for `put/3`

    * `:max_age` - Seconds until expiry (default: session cookie)
    * `:http_only` - Prevent JS access (default: `true`)
    * `:secure` - HTTPS only (default: `false`)
    * `:same_site` - `"Strict"`, `"Lax"`, or `"None"` (default: `"Lax"`)
    * `:path` - Cookie path (default: `"/"`)
    * `:domain` - Cookie domain (default: not set)
  """

  @pending_key :nex_pending_cookies
  @incoming_key :nex_incoming_cookies

  @doc """
  Sets a cookie. The cookie is applied to the response by `Nex.Handler`.
  """
  def put(name, value, opts \\ []) do
    name_str = to_string(name)
    value_str = to_string(value)

    cookie = %{
      name: name_str,
      value: value_str,
      max_age: Keyword.get(opts, :max_age),
      http_only: Keyword.get(opts, :http_only, true),
      secure: Keyword.get(opts, :secure, false),
      same_site: Keyword.get(opts, :same_site, "Lax"),
      path: Keyword.get(opts, :path, "/"),
      domain: Keyword.get(opts, :domain),
      delete: false
    }

    pending = Process.get(@pending_key, [])
    Process.put(@pending_key, [cookie | pending])
    value
  end

  @doc """
  Deletes a cookie by setting its max_age to 0.
  """
  def delete(name, opts \\ []) do
    name_str = to_string(name)

    cookie = %{
      name: name_str,
      value: "",
      max_age: 0,
      http_only: Keyword.get(opts, :http_only, true),
      secure: Keyword.get(opts, :secure, false),
      same_site: Keyword.get(opts, :same_site, "Lax"),
      path: Keyword.get(opts, :path, "/"),
      domain: Keyword.get(opts, :domain),
      delete: true
    }

    pending = Process.get(@pending_key, [])
    Process.put(@pending_key, [cookie | pending])
    :ok
  end

  @doc """
  Reads a cookie value from the current request.

  Returns `nil` if the cookie is not present.
  Cookies are populated by `Nex.Handler` at the start of each request.
  """
  def get(name, default \\ nil) do
    name_str = to_string(name)
    cookies = Process.get(@incoming_key, %{})
    Map.get(cookies, name_str, default)
  end

  @doc """
  Returns all cookies from the current request as a map.
  """
  def all do
    Process.get(@incoming_key, %{})
  end

  @doc """
  Stores incoming cookies from the request in the process dictionary.
  Called by `Nex.Handler` at the start of each request.
  """
  def load_from_conn(conn) do
    conn = Plug.Conn.fetch_cookies(conn)
    Process.put(@incoming_key, conn.cookies)
    conn
  end

  @doc """
  Applies all pending cookie operations to the `Plug.Conn`.
  Called by `Nex.Handler` before sending the response.
  """
  def apply_to_conn(conn) do
    pending = Process.get(@pending_key, [])

    Enum.reduce(pending, conn, fn cookie, conn ->
      opts = build_plug_opts(cookie)
      Plug.Conn.put_resp_cookie(conn, cookie.name, cookie.value, opts)
    end)
  end

  @doc """
  Clears pending cookie state from the process dictionary.
  Called by `Nex.Handler` after the response is sent.
  """
  def clear_process_state do
    Process.delete(@pending_key)
    Process.delete(@incoming_key)
  end

  # Build Plug.Conn.put_resp_cookie/4 options from our cookie map
  defp build_plug_opts(cookie) do
    opts = [
      http_only: cookie.http_only,
      secure: cookie.secure,
      same_site: cookie.same_site,
      path: cookie.path
    ]

    opts = if cookie.max_age != nil, do: Keyword.put(opts, :max_age, cookie.max_age), else: opts
    opts = if cookie.domain != nil, do: Keyword.put(opts, :domain, cookie.domain), else: opts
    opts
  end
end
