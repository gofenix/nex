defmodule NexExamplesTestSupport.CookieJar do
  @type t :: %{optional(String.t()) => String.t()}

  def new, do: %{}

  def merge(jar, %{headers: headers}) when is_map(headers) do
    headers
    |> Enum.flat_map(fn {name, values} ->
      Enum.map(values, &{name, &1})
    end)
    |> merge_headers(jar)
  end

  def merge(jar, %{headers: headers}) when is_list(headers) do
    merge_headers(headers, jar)
  end

  def headers(jar) when map_size(jar) == 0, do: []

  def headers(jar) do
    cookie =
      jar
      |> Enum.map_join("; ", fn {name, value} -> "#{name}=#{value}" end)

    [{"cookie", cookie}]
  end

  defp merge_headers(headers, jar) do
    Enum.reduce(headers, jar, fn {name, value}, acc ->
      if String.downcase(name) == "set-cookie" do
        put_cookie(acc, value)
      else
        acc
      end
    end)
  end

  defp put_cookie(jar, set_cookie) do
    [cookie_pair | attrs] = String.split(set_cookie, ";")
    [name, value] = String.split(cookie_pair, "=", parts: 2)

    attributes =
      attrs
      |> Enum.map(&String.trim/1)
      |> Enum.map(fn attribute ->
        case String.split(attribute, "=", parts: 2) do
          [key, attr_value] -> {String.downcase(key), attr_value}
          [key] -> {String.downcase(key), true}
        end
      end)
      |> Map.new()

    cond do
      value == "" ->
        Map.delete(jar, name)

      attributes["max-age"] == "0" ->
        Map.delete(jar, name)

      true ->
        Map.put(jar, name, value)
    end
  end
end
