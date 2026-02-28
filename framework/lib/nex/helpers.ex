defmodule Nex.Helpers do
  @moduledoc """
  Common formatting helpers automatically imported into all Nex page and component modules.

  These functions are available in any module that uses `use Nex` — no explicit import needed.

  ## Available Helpers

  - `format_number/1` — Format integers with k/M suffix (e.g. `12345` → `"12.3k"`)
  - `format_date/1` — Format dates/datetimes to human-readable string
  - `time_ago/1` — Relative time string (e.g. `"3 days ago"`)
  - `truncate/3` — Truncate strings with ellipsis
  - `pluralize/3` — Singular/plural based on count
  - `clsx/1` — Build CSS classes from lists
  - `class/2` — Build CSS classes with template support
  - `attrs/1` — Build HTML attributes conditionally
  """

  @type date_input :: Date.t() | NaiveDateTime.t() | DateTime.t() | String.t() | nil

  @doc """
  Formats a number with k/M suffix for compact display.

  ## Examples

      format_number(500)      # => "500"
      format_number(1_200)    # => "1.2k"
      format_number(45_000)   # => "45.0k"
      format_number(1_500_000) # => "1.5M"
  """
  @spec format_number(integer() | float() | nil) :: String.t()
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
  @spec format_date(date_input()) :: String.t()
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

      true ->
        s
    end
  end

  def format_date(_), do: ""

  @doc """
  Truncates a string to the given length, appending an ellipsis if truncated.

  ## Options
    * `:omission` - String appended when truncated (default: `"..."`)

  ## Examples

      truncate("Hello, world!", 8)              # => "Hello..."
      truncate("Hello", 10)                     # => "Hello"
      truncate("Hello, world!", 8, omission: "…") # => "Hello, …"
      truncate(nil, 10)                         # => ""
  """
  @spec truncate(String.t() | nil, pos_integer(), keyword()) :: String.t()
  def truncate(str, length, opts \\ [])
  def truncate(nil, _length, _opts), do: ""

  def truncate(str, length, opts) when is_binary(str) and is_integer(length) do
    omission = Keyword.get(opts, :omission, "...")

    if String.length(str) <= length do
      str
    else
      truncated_length = max(0, length - String.length(omission))
      String.slice(str, 0, truncated_length) <> omission
    end
  end

  @doc """
  Returns the singular or plural form of a word based on count.

  ## Examples

      pluralize(1, "item", "items")   # => "1 item"
      pluralize(5, "item", "items")   # => "5 items"
      pluralize(0, "item", "items")   # => "0 items"
  """
  @spec pluralize(integer(), String.t(), String.t()) :: String.t()
  def pluralize(count, singular, plural) when is_integer(count) do
    word = if count == 1, do: singular, else: plural
    "#{count} #{word}"
  end

  @doc """
  Builds a CSS class string from a list of values, filtering out falsy entries.

  Accepts strings, `{class, condition}` tuples, and ignores `nil`/`false`.

  ## Examples

      clsx(["btn", "btn-primary"])                    # => "btn btn-primary"
      clsx(["btn", nil, false, "active"])             # => "btn active"
      clsx(["btn", {"btn-active", true}, {"hidden", false}])  # => "btn btn-active"
      clsx([])                                        # => ""
  """
  @spec clsx([String.t() | {String.t(), boolean()} | nil | false]) :: String.t()
  def clsx(list) when is_list(list) do
    list
    |> Enum.flat_map(fn
      {class, true} when is_binary(class) -> [class]
      {_class, _} -> []
      class when is_binary(class) and class != "" -> [class]
      _ -> []
    end)
    |> Enum.join(" ")
  end

  @doc """
  Returns a relative time string from a past datetime.

  ## Examples

      time_ago(DateTime.add(DateTime.utc_now(), -30, :second))  # => "just now"
      time_ago(DateTime.add(DateTime.utc_now(), -90, :second))  # => "2 minutes ago"
      time_ago(DateTime.add(DateTime.utc_now(), -3600 * 5, :second)) # => "5 hours ago"
      time_ago(DateTime.add(DateTime.utc_now(), -86400 * 3, :second)) # => "3 days ago"
  """
  @spec time_ago(date_input()) :: String.t()
  def time_ago(nil), do: ""

  def time_ago(%NaiveDateTime{} = dt) do
    dt |> DateTime.from_naive!("Etc/UTC") |> time_ago()
  end

  def time_ago(%DateTime{} = dt) do
    diff = DateTime.diff(DateTime.utc_now(), dt, :second)

    cond do
      diff < 60 -> "just now"
      diff < 3_600 -> "#{div(diff, 60)} minutes ago"
      diff < 86_400 -> "#{div(diff, 3_600)} hours ago"
      diff < 604_800 -> "#{div(diff, 86_400)} days ago"
      diff < 2_592_000 -> "#{div(diff, 604_800)} weeks ago"
      true -> "#{div(diff, 2_592_000)} months ago"
    end
  end

  def time_ago(s) when is_binary(s) do
    case DateTime.from_iso8601(s) do
      {:ok, dt, _} -> time_ago(dt)
      _ -> ""
    end
  end

  def time_ago(_), do: ""

  @doc """
  Builds CSS classes with template support.

  Similar to `clsx/1` but supports nested templates with the `&` placeholder.

  ## Examples

      class("btn &", ["btn-primary", "btn-large"])
      # => "btn-primary btn-large"

      class("item active-&1", ["active", "disabled"])
      # => "item active-active"

      class("btn &-state", ["success", "large"])
      # => "btn success-state btn large-state"
  """
  @spec class(String.t(), [String.t() | nil | false]) :: String.t()
  def class(template, values) when is_binary(template) and is_list(values) do
    values
    |> Enum.filter(& &1)
    |> Enum.map(fn val -> String.replace(template, "&", to_string(val)) end)
    |> Enum.join(" ")
    |> String.replace(" ", " ")
    |> String.trim()
  end

  @doc """
  Builds HTML attributes from a keyword list, filtering out nil/false values.

  ## Examples

      attrs([class: "btn", disabled: false, data_action: "submit"])
      # => "class=\"btn\" data-action=\"submit\""

      attrs([id: "my-form", required: true])
      # => "id=\"my-form\" required"
  """
  @spec attrs([{atom() | String.t(), term()}]) :: String.t()
  def attrs(attrs) when is_list(attrs) do
    attrs
    |> Enum.filter(fn
      {_key, nil} -> false
      {_key, false} -> false
      {_key, _value} -> true
    end)
    |> Enum.map(fn
      {key, true} ->
        "#{attr_key(key)}"

      {key, value} when is_binary(value) or is_number(value) ->
        "#{attr_key(key)}=\"#{value}\""

      {key, value} ->
        "#{attr_key(key)}=\"#{inspect(value)}\""
    end)
    |> Enum.join(" ")
  end

  defp attr_key(key) when is_atom(key) do
    key
    |> Atom.to_string()
    |> String.replace("_", "-")
  end

  defp attr_key(key) when is_binary(key), do: key
end
