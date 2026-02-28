defmodule Nex.Session do
  @moduledoc """
  Session-scoped state management — persists across page navigations for the same browser session.

  Unlike `Nex.Store` (which is page-scoped and cleared on refresh), session state
  survives page navigations and is tied to a session cookie (`_nex_session`).

  ## Usage

      # In mount/1 — read session state
      def mount(_params) do
        user_id = Nex.Session.get(:user_id)
        %{logged_in: user_id != nil, user_id: user_id}
      end

      # In an action — write session state
      def login(%{"email" => email, "password" => password}) do
        case authenticate(email, password) do
          {:ok, user} ->
            Nex.Session.put(:user_id, user.id)
            {:redirect, "/dashboard"}

          {:error, _} ->
            Nex.Flash.put(:error, "Invalid credentials")
            {:redirect, "/login"}
        end
      end

      def logout(_params) do
        Nex.Session.clear()
        {:redirect, "/"}
      end

  ## How it works

  Session data is stored in `Nex.Store` (ETS) keyed by a session ID.
  The session ID is stored in a signed cookie (`_nex_session`) using `Phoenix.Token`.
  This is stateful server-side session storage — no data is stored in the cookie itself.

  ## TTL

  Session data expires after 7 days of inactivity (configurable via `:nex_core, :session_ttl`).
  """

  require Logger

  @cookie_name "_nex_session"
  @session_id_key :nex_session_id
  @salt "nex.session"
  @default_ttl_seconds 7 * 24 * 3600
  @table :nex_session_store

  # ── Client API ──────────────────────────────────────────────────────────────

  @doc """
  Gets a value from the current session.
  """
  def get(key, default \\ nil) do
    session_id = get_session_id()
    table_get(session_id, key, default)
  end

  @doc """
  Puts a value into the current session.
  """
  def put(key, value) do
    session_id = get_or_create_session_id()
    table_put(session_id, key, value)
    value
  end

  @doc """
  Updates a value in the current session using a function.
  """
  def update(key, default, fun) do
    current = get(key, default)
    new_value = fun.(current)
    put(key, new_value)
  end

  @doc """
  Deletes a key from the current session.
  """
  def delete(key) do
    session_id = get_session_id()
    if session_id, do: table_delete(session_id, key)
    :ok
  end

  @doc """
  Clears all data from the current session and deletes the session cookie.
  """
  def clear do
    session_id = get_session_id()

    if session_id do
      table_clear(session_id)
      Nex.Cookie.delete(@cookie_name)
      Process.delete(@session_id_key)
    end

    :ok
  end

  @doc """
  Returns the current session ID, or nil if no session exists.
  """
  def session_id do
    get_session_id()
  end

  # ── Called by Nex.Handler ────────────────────────────────────────────────────

  @doc """
  Loads the session from the cookie. Called by `Nex.Handler` at request start.
  """
  def load_from_conn(conn) do
    conn = Plug.Conn.fetch_cookies(conn)
    session_cookie = Map.get(conn.cookies, @cookie_name)

    session_id =
      if session_cookie do
        verify_session_cookie(session_cookie)
      else
        nil
      end

    Process.put(@session_id_key, session_id)
    conn
  end

  @doc """
  Persists the session cookie if a session was created or modified.
  Called by `Nex.Handler` before sending the response.
  """
  def persist_to_conn(conn) do
    session_id = Process.get(@session_id_key)

    if session_id do
      signed = sign_session_cookie(session_id)
      ttl = Application.get_env(:nex_core, :session_ttl, @default_ttl_seconds)

      Nex.Cookie.put(@cookie_name, signed,
        max_age: ttl,
        http_only: true,
        secure: Application.get_env(:nex_core, :session_secure_cookie, false),
        same_site: "Lax"
      )
    end

    conn
  end

  @doc """
  Clears session state from the process dictionary. Called after response is sent.
  """
  def clear_process_state do
    Process.delete(@session_id_key)
  end

  # ── ETS Table Helpers ────────────────────────────────────────────────────────

  @doc false
  def ensure_table do
    case :ets.whereis(@table) do
      :undefined ->
        :ets.new(@table, [
          :named_table,
          :public,
          :set,
          read_concurrency: true,
          write_concurrency: true
        ])

      _ ->
        @table
    end
  end

  # Cache TTL to avoid repeated Application.get_env calls
  defp session_ttl_ms do
    @default_ttl_seconds * 1000
  end

  defp table_get(nil, _key, default), do: default

  defp table_get(session_id, key, default) do
    ensure_table()
    ttl_ms = Application.get_env(:nex_core, :session_ttl, @default_ttl_seconds) * 1000
    now = System.system_time(:millisecond)

    case :ets.lookup(@table, {session_id, key}) do
      [{_, value, expires_at}] when expires_at > now ->
        # Touch expiry on access
        :ets.insert(@table, {{session_id, key}, value, now + ttl_ms})
        value

      _ ->
        default
    end
  end

  defp table_put(session_id, key, value) do
    ensure_table()
    ttl_ms = Application.get_env(:nex_core, :session_ttl, @default_ttl_seconds) * 1000
    expires_at = System.system_time(:millisecond) + ttl_ms
    :ets.insert(@table, {{session_id, key}, value, expires_at})
  end

  defp table_delete(session_id, key) do
    ensure_table()
    :ets.delete(@table, {session_id, key})
  end

  defp table_clear(session_id) do
    ensure_table()
    :ets.match_delete(@table, {{session_id, :_}, :_, :_})
  end

  # ── Session ID Management ────────────────────────────────────────────────────

  defp get_session_id do
    Process.get(@session_id_key)
  end

  defp get_or_create_session_id do
    case Process.get(@session_id_key) do
      nil ->
        id = generate_session_id()
        Process.put(@session_id_key, id)
        id

      id ->
        id
    end
  end

  defp generate_session_id do
    :crypto.strong_rand_bytes(24) |> Base.url_encode64(padding: false)
  end

  defp sign_session_cookie(session_id) do
    Phoenix.Token.sign(secret(), @salt, session_id)
  end

  defp verify_session_cookie(cookie) do
    ttl = Application.get_env(:nex_core, :session_ttl, @default_ttl_seconds)

    case Phoenix.Token.verify(secret(), @salt, cookie, max_age: ttl) do
      {:ok, session_id} -> session_id
      {:error, _} -> nil
    end
  end

  # Session ID Management

  defp secret do
    case System.get_env("SECRET_KEY_BASE") do
      nil ->
        if Mix.env() == :dev do
          # In development, generate a deterministic but unique secret
          # This allows sessions to persist across restarts during development
          "nex_dev_secret_key_base_do_not_use_in_production_#{node()}"
        else
          raise """
          SECRET_KEY_BASE environment variable is not set.
          
          Please set it in your .env file or production environment:
          
              SECRET_KEY_BASE=<random 64 character string>
          
          You can generate one with: mix phx.gen.secret
          """
        end

      s when byte_size(s) >= 32 ->
        s

      s ->
        raise """
        SECRET_KEY_BASE must be at least 32 characters.
        Current length: #{byte_size(s)}
        
        You can generate one with: mix phx.gen.secret
        """
    end
  end
end
