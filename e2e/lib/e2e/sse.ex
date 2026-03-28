defmodule E2E.SSE do
  @default_timeout 10_000

  def collect(url, event_count, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    uri = URI.parse(url)
    port = uri.port || 80
    path = (uri.path || "/") <> if(uri.query, do: "?#{uri.query}", else: "")

    {:ok, conn} =
      Mint.HTTP.connect(:http, uri.host, port, timeout: 5_000, protocols: [:http1])

    {:ok, conn, request_ref} =
      Mint.HTTP.request(conn, "GET", path, [{"accept", "text/event-stream"}], nil)

    deadline = System.monotonic_time(:millisecond) + timeout
    {conn, events} = receive_events(conn, request_ref, deadline, "", [], event_count)
    Mint.HTTP.close(conn)

    if length(events) < event_count do
      raise "expected #{event_count} SSE events, received #{length(events)}"
    end

    Enum.take(events, event_count)
  end

  defp receive_events(conn, request_ref, deadline, buffer, events, event_count) do
    cond do
      length(events) >= event_count ->
        {conn, events}

      System.monotonic_time(:millisecond) >= deadline ->
        {conn, events}

      true ->
        receive do
          message ->
            {:ok, conn, responses} = Mint.HTTP.stream(conn, message)

            {buffer, events} =
              Enum.reduce(responses, {buffer, events}, fn
                {:data, ^request_ref, chunk}, {current_buffer, current_events} ->
                  consume_chunk(current_buffer <> chunk, current_events)

                _, acc ->
                  acc
              end)

            receive_events(conn, request_ref, deadline, buffer, events, event_count)
        after
          1_000 ->
            receive_events(conn, request_ref, deadline, buffer, events, event_count)
        end
    end
  end

  defp consume_chunk(buffer, events) do
    normalized = String.replace(buffer, "\r\n", "\n")

    case String.split(normalized, "\n\n", parts: 2) do
      [single] ->
        {single, events}

      [event_chunk, rest] ->
        event =
          event_chunk
          |> String.split("\n", trim: true)
          |> Enum.reduce(%{event: "message", data: []}, fn line, acc ->
            cond do
              String.starts_with?(line, "event:") ->
                %{acc | event: String.trim_leading(line, "event:") |> String.trim()}

              String.starts_with?(line, "data:") ->
                data = String.trim_leading(line, "data:") |> String.trim()
                %{acc | data: acc.data ++ [data]}

              true ->
                acc
            end
          end)
          |> then(fn event -> %{event | data: Enum.join(event.data, "\n")} end)

        consume_chunk(rest, events ++ [event])
    end
  end
end
