defmodule Nex.Handler.Stream do
  @moduledoc false

  import Plug.Conn
  require Logger

  def send_response(conn, %Nex.Response{} = response) do
    if String.starts_with?(response.content_type || "", "text/event-stream") do
      handle_sse_response(conn, response)
    else
      handle_regular_response(conn, response)
    end
  end

  def handle_sse_response(conn, response) do
    conn =
      conn
      |> put_resp_header("content-type", "text/event-stream; charset=utf-8")
      |> put_resp_header("cache-control", "no-cache, no-transform")
      |> put_resp_header("connection", "keep-alive")

    conn =
      Enum.reduce(response.headers, conn, fn {key, value}, conn ->
        put_resp_header(conn, to_string(key), to_string(value))
      end)

    conn = send_chunked(conn, response.status)
    callback = response.body

    send_fn = fn data ->
      chunk = format_sse_chunk(data)

      case Plug.Conn.chunk(conn, chunk) do
        {:ok, conn} -> conn
        {:error, :closed} -> throw(:connection_closed)
      end
    end

    try do
      callback.(send_fn)
      conn
    rescue
      error ->
        Logger.error(
          "SSE stream error: #{inspect(error)}\n#{Exception.format_stacktrace(__STACKTRACE__)}"
        )

        conn
    catch
      :connection_closed ->
        Logger.debug("SSE connection closed by client")
        conn
    end
  end

  def handle_regular_response(conn, response) do
    conn =
      Enum.reduce(response.headers, conn, fn {key, value}, conn ->
        put_resp_header(conn, to_string(key), to_string(value))
      end)

    body =
      if response.content_type == "application/json" and not is_binary(response.body) do
        Jason.encode!(response.body)
      else
        response.body || ""
      end

    conn
    |> put_resp_content_type(response.content_type)
    |> send_resp(response.status, body)
  end

  defp format_sse_chunk({:raw, data}) when is_binary(data), do: data

  defp format_sse_chunk(data) when is_binary(data) do
    if String.starts_with?(data, "data: ") or String.starts_with?(data, "event: ") do
      data
    else
      "data: #{data}\n\n"
    end
  end

  defp format_sse_chunk(%{event: event, data: data}) do
    encoded = encode_sse_data(data)

    formatted_data =
      encoded
      |> String.split("\n")
      |> Enum.map(&"data: #{&1}")
      |> Enum.join("\n")

    "event: #{event}\n#{formatted_data}\n\n"
  end

  defp format_sse_chunk(data) when is_map(data) or is_list(data) do
    "data: #{Jason.encode!(data)}\n\n"
  end

  defp encode_sse_data(data) when is_binary(data), do: data
  defp encode_sse_data(data), do: Jason.encode!(data)
end
