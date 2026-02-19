defmodule Nex.Helpers do
  @moduledoc """
  Common formatting helpers automatically imported into all Nex page and component modules.

  These functions are available in any module that uses `use Nex` — no explicit import needed.

  ## Available Helpers

  - `format_number/1` — Format integers with k/M suffix (e.g. `12345` → `"12.3k"`)
  - `format_date/1` — Format dates/datetimes to human-readable string
  - `time_ago/1` — Relative time string (e.g. `"3 days ago"`)
  """

  @doc """
  Formats a number with k/M suffix for compact display.

  ## Examples

      format_number(500)      # => "500"
      format_number(1_200)    # => "1.2k"
      format_number(45_000)   # => "45.0k"
      format_number(1_500_000) # => "1.5M"
  """
  def format_number(nil), do: "0"
  def format_number(n) when is_integer(n) and n >= 1_000_000 do
    "#{Float.round(n / 1_000_000, 1)}M"
  end
  def format_number(n) when is_integer(n) and n >= 1_000 do
    "#{Float.round(n / 1_000, 1)}k"
  end
  def format_number(n) when is_integer(n), do: "#{n}"
  def format_number(n) when is_float(n), do: format_number(round(n))
  def format_number(n), do: "#{n}"

  @doc """
  Formats a date or datetime to a human-readable string.

  Accepts `%Date{}`, `%NaiveDateTime{}`, `%DateTime{}`, or an ISO 8601 string.

  ## Examples

      format_date(~D[2026-02-19])             # => "Feb 19, 2026"
      format_date(~N[2026-02-19 10:30:00])    # => "Feb 19, 2026"
      format_date("2026-02-19T10:30:00Z")     # => "Feb 19, 2026"
      format_date(nil)                         # => ""
  """
  def format_date(nil), do: ""
  def format_date(%Date{} = d), do: Calendar.strftime(d, "%b %d, %Y")
  def format_date(%NaiveDateTime{} = dt), do: Calendar.strftime(dt, "%b %d, %Y")
  def format_date(%DateTime{} = dt), do: Calendar.strftime(dt, "%b %d, %Y")
  def format_date(s) when is_binary(s) do
    cond do
      String.length(s) >= 10 ->
        case Date.from_iso8601(String.slice(s, 0, 10)) do
          {:ok, d} -> format_date(d)
          _ -> s
        end
      true -> s
    end
  end
  def format_date(_), do: ""

  @doc """
  Returns a relative time string from a past datetime.

  ## Examples

      time_ago(DateTime.add(DateTime.utc_now(), -30, :second))  # => "just now"
      time_ago(DateTime.add(DateTime.utc_now(), -90, :second))  # => "2 minutes ago"
      time_ago(DateTime.add(DateTime.utc_now(), -3600 * 5, :second)) # => "5 hours ago"
      time_ago(DateTime.add(DateTime.utc_now(), -86400 * 3, :second)) # => "3 days ago"
  """
  def time_ago(nil), do: ""
  def time_ago(%NaiveDateTime{} = dt) do
    dt |> DateTime.from_naive!("Etc/UTC") |> time_ago()
  end
  def time_ago(%DateTime{} = dt) do
    diff = DateTime.diff(DateTime.utc_now(), dt, :second)
    cond do
      diff < 60      -> "just now"
      diff < 3_600   -> "#{div(diff, 60)} minutes ago"
      diff < 86_400  -> "#{div(diff, 3_600)} hours ago"
      diff < 604_800 -> "#{div(diff, 86_400)} days ago"
      diff < 2_592_000 -> "#{div(diff, 604_800)} weeks ago"
      true           -> "#{div(diff, 2_592_000)} months ago"
    end
  end
  def time_ago(s) when is_binary(s) do
    case DateTime.from_iso8601(s) do
      {:ok, dt, _} -> time_ago(dt)
      _ -> ""
    end
  end
  def time_ago(_), do: ""
end
