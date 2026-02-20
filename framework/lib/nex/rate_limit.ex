defmodule Nex.RateLimit do
  @moduledoc """
  ETS-based sliding window rate limiting for Nex applications.

  ## Configuration

      # Global defaults
      Application.put_env(:nex_core, :rate_limit, max: 100, window: 60)

      # As middleware plug
      Application.put_env(:nex_core, :plugs, [
        {Nex.RateLimit.Plug, max: 60, window: 60}
      ])

  ## Standalone Usage

      case Nex.RateLimit.check(ip, max: 10, window: 60) do
        :ok -> Nex.json(%{result: "ok"})
        {:error, :rate_limited} -> Nex.status(429, "Too Many Requests")
      end

  ## Options

    * `:max` - Max requests per window (default: `100`)
    * `:window` - Window size in seconds (default: `60`)
    * `:key_prefix` - Prefix for namespacing limits (default: `"default"`)
  """

  @table :nex_rate_limit

  @doc """
  Checks and increments the counter for the given key.
  Returns `:ok` if within limit, `{:error, :rate_limited}` otherwise.
  """
  def check(key, opts \\ []) do
    {max, window, prefix} = parse_opts(opts)
    ensure_table()

    now = System.system_time(:second)
    bucket = div(now, window)
    ets_key = {prefix, key, bucket}

    count =
      case :ets.lookup(@table, ets_key) do
        [{^ets_key, c, _exp}] ->
          :ets.update_counter(@table, ets_key, {2, 1})
          c + 1

        [] ->
          expires_at = (bucket + 1) * window
          :ets.insert(@table, {ets_key, 1, expires_at})
          1
      end

    if count <= max, do: :ok, else: {:error, :rate_limited}
  end

  @doc """
  Returns the current request count for a key in the current window.
  """
  def count(key, opts \\ []) do
    {_max, window, prefix} = parse_opts(opts)
    ensure_table()

    now = System.system_time(:second)
    bucket = div(now, window)
    ets_key = {prefix, key, bucket}

    case :ets.lookup(@table, ets_key) do
      [{^ets_key, c, _exp}] -> c
      [] -> 0
    end
  end

  @doc """
  Resets the counter for a key (useful in tests).
  """
  def reset(key, opts \\ []) do
    {_max, window, prefix} = parse_opts(opts)
    ensure_table()

    now = System.system_time(:second)
    bucket = div(now, window)
    :ets.delete(@table, {prefix, key, bucket})
    :ok
  end

  @doc false
  def ensure_table do
    case :ets.whereis(@table) do
      :undefined -> :ets.new(@table, [:named_table, :public, :set])
      _ -> @table
    end
  end

  defp parse_opts(opts) do
    global = Application.get_env(:nex_core, :rate_limit, [])
    max = Keyword.get(opts, :max, Keyword.get(global, :max, 100))
    window = Keyword.get(opts, :window, Keyword.get(global, :window, 60))
    prefix = Keyword.get(opts, :key_prefix, "default")
    {max, window, prefix}
  end
end

defmodule Nex.RateLimit.Plug do
  @moduledoc """
  Plug middleware that applies rate limiting based on client IP.

  ## Usage

      Application.put_env(:nex_core, :plugs, [
        {Nex.RateLimit.Plug, max: 100, window: 60}
      ])

  Returns HTTP 429 with a JSON error body when the limit is exceeded.
  Adds `X-RateLimit-Limit` and `X-RateLimit-Remaining` response headers.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, opts) do
    ip = client_ip(conn)
    {max, window, prefix} = parse_opts(opts)

    case Nex.RateLimit.check(ip, max: max, window: window, key_prefix: prefix) do
      :ok ->
        remaining = max - Nex.RateLimit.count(ip, max: max, window: window, key_prefix: prefix)

        conn
        |> put_resp_header("x-ratelimit-limit", to_string(max))
        |> put_resp_header("x-ratelimit-remaining", to_string(max(0, remaining)))

      {:error, :rate_limited} ->
        conn
        |> put_resp_content_type("application/json")
        |> put_resp_header("x-ratelimit-limit", to_string(max))
        |> put_resp_header("x-ratelimit-remaining", "0")
        |> send_resp(429, Jason.encode!(%{error: "Too Many Requests", retry_after: window}))
        |> halt()
    end
  end

  defp client_ip(conn) do
    forwarded = get_req_header(conn, "x-forwarded-for")

    case forwarded do
      [ip | _] -> ip |> String.split(",") |> hd() |> String.trim()
      [] -> conn.remote_ip |> :inet.ntoa() |> to_string()
    end
  end

  defp parse_opts(opts) do
    global = Application.get_env(:nex_core, :rate_limit, [])
    max = Keyword.get(opts, :max, Keyword.get(global, :max, 100))
    window = Keyword.get(opts, :window, Keyword.get(global, :window, 60))
    prefix = Keyword.get(opts, :key_prefix, "rate_limit")
    {max, window, prefix}
  end
end
