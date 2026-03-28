defmodule E2E.HTTP do
  alias E2E.{CookieJar, Example, HTML}

  @default_headers [{"user-agent", "nex-e2e"}]

  def client(%Example{} = example) do
    Req.new(
      base_url: Example.base_url(example),
      connect_options: [timeout: 5_000],
      receive_timeout: 15_000,
      retry: false,
      redirect: false,
      headers: @default_headers
    )
  end

  def get(client, path, opts \\ []), do: request(client, :get, path, opts)
  def post(client, path, opts \\ []), do: request(client, :post, path, opts)
  def put(client, path, opts \\ []), do: request(client, :put, path, opts)
  def delete(client, path, opts \\ []), do: request(client, :delete, path, opts)

  def request(client, method, path, opts) do
    jar = Keyword.get(opts, :jar, CookieJar.new())

    {body, body_headers} =
      cond do
        Keyword.has_key?(opts, :json) ->
          {Jason.encode!(Keyword.fetch!(opts, :json)), [{"content-type", "application/json"}]}

        Keyword.has_key?(opts, :form) ->
          form =
            opts
            |> Keyword.fetch!(:form)
            |> stringify_keys()
            |> URI.encode_query()

          {form, [{"content-type", "application/x-www-form-urlencoded"}]}

        Keyword.has_key?(opts, :multipart) ->
          build_multipart(Keyword.fetch!(opts, :multipart))

        Keyword.has_key?(opts, :body) ->
          {Keyword.fetch!(opts, :body), []}

        true ->
          {nil, []}
      end

    headers =
      opts
      |> Keyword.get(:headers, [])
      |> Kernel.++(body_headers)
      |> Kernel.++(CookieJar.headers(jar))

    response =
      Req.request!(client,
        method: method,
        url: path,
        headers: headers,
        body: body
      )

    {response, CookieJar.merge(jar, response)}
  end

  def header(%{headers: headers}, name) do
    wanted = String.downcase(name)

    case headers do
      header_map when is_map(header_map) ->
        header_map
        |> Enum.find_value(fn {header_name, values} ->
          if String.downcase(header_name) == wanted, do: List.first(values)
        end)

      header_list when is_list(header_list) ->
        Enum.find_value(header_list, fn {header_name, value} ->
          if String.downcase(header_name) == wanted, do: value
        end)
    end
  end

  def json_body(%{body: body}) when is_map(body), do: body
  def json_body(%{body: body}) when is_binary(body), do: Jason.decode!(body)

  def htmx_headers(target \\ nil) do
    [{"hx-request", "true"}] ++
      if(target, do: [{"hx-target", target}], else: [])
  end

  def nex_headers(page_html, opts \\ []) do
    headers = [
      {"x-nex-page-id", nex_page_id(page_html)},
      {"x-csrf-token", csrf_token(page_html)}
    ]

    headers =
      if Keyword.get(opts, :htmx, false) do
        [{"hx-request", "true"} | headers]
      else
        headers
      end

    headers =
      case Keyword.get(opts, :target) do
        nil -> headers
        target -> headers ++ [{"hx-target", target}]
      end

    case Keyword.get(opts, :referer) do
      nil -> headers
      referer -> headers ++ [{"referer", referer}]
    end
  end

  def file_part(name, path, content_type) do
    {:file, to_string(name), path, Path.basename(path), content_type}
  end

  def file_part(name, path, content_type, filename) do
    {:file, to_string(name), path, filename, content_type}
  end

  defp build_multipart(parts) do
    boundary = "nex-e2e-#{System.unique_integer([:positive])}"

    body =
      parts
      |> Enum.map(&multipart_part(&1, boundary))
      |> Kernel.++(["--", boundary, "--\r\n"])
      |> IO.iodata_to_binary()

    {body, [{"content-type", "multipart/form-data; boundary=#{boundary}"}]}
  end

  defp multipart_part({:file, name, path, filename, content_type}, boundary) do
    file = File.read!(path)

    [
      "--",
      boundary,
      "\r\n",
      "Content-Disposition: form-data; name=\"",
      name,
      "\"; filename=\"",
      filename,
      "\"\r\n",
      "Content-Type: ",
      content_type,
      "\r\n\r\n",
      file,
      "\r\n"
    ]
  end

  defp multipart_part({name, value}, boundary) do
    [
      "--",
      boundary,
      "\r\n",
      "Content-Disposition: form-data; name=\"",
      to_string(name),
      "\"\r\n\r\n",
      to_string(value),
      "\r\n"
    ]
  end

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn {key, value} -> {to_string(key), value} end)
  end

  defp csrf_token(page_html) do
    HTML.first_attr(page_html, ~s(meta[name="csrf-token"]), "content")
  end

  defp nex_page_id(page_html) do
    case Regex.run(~r/document\.body\.dataset\.pageId = "([^"]+)"/, page_html) do
      [_, page_id] -> page_id
      _ -> raise "could not find injected Nex page id in response body"
    end
  end
end
