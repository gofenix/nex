defmodule ChatbotSse.Api.Sse.Stream do
  use Nex

  @moduledoc """
  SSE (Server-Sent Events) endpoint for streaming AI responses from OpenAI.

  Uses HTMX SSE extension for zero-JS streaming with Nex.stream/1.

  ## Usage

  HTMX SSE extension uses GET requests with query parameters:

      GET /api/sse/stream?message=Hello

  ## Environment Variables

  - `OPENAI_API_KEY`: OpenAI API key (required)
  - `OPENAI_BASE_URL`: OpenAI API base URL (default: https://api.openai.com/v1)

  ## Example

      # Set your API key
      export OPENAI_API_KEY=sk-...

      # Start the server
      mix nex.dev

      # Test the endpoint
      curl "http://localhost:4000/api/sse/stream?msg_id=123"
  """
  require Logger

  def get(req) do
    # Get message from Store using msg_id
    msg_id_str = req.query["msg_id"]
    api_key = Nex.Env.get(:OPENAI_API_KEY)
    base_url = Nex.Env.get(:OPENAI_BASE_URL, "https://api.openai.com/v1")

    cond do
      !msg_id_str ->
        Nex.json(%{error: "Missing msg_id parameter"}, status: 400)

      !api_key ->
        Nex.json(%{error: "OPENAI_API_KEY not configured"}, status: 500)

      true ->
        # Get the pending message from Store
        pending = Nex.Store.get(:pending_message)

        if pending && to_string(pending.msg_id) == msg_id_str do
          # Get chat history from Store
          chat_messages = Nex.Store.get(:chat_messages, [])

          # Clean up pending message
          Nex.Store.delete(:pending_message)

          Nex.stream(fn send ->
            call_openai_stream(base_url, api_key, pending.message, chat_messages, send)
          end)
        else
          Nex.json(%{error: "Message not found"}, status: 404)
        end
    end
  end

  defp call_openai_stream(base_url, api_key, user_message, chat_messages, send) do
    Logger.info("Streaming OpenAI response for: #{String.slice(user_message, 0, 50)}...")

    url = "#{String.trim_trailing(base_url, "/")}/chat/completions"

    # Build message history from chat_messages
    # chat_messages is in reverse order (newest first), so we need to reverse it
    history_messages =
      chat_messages
      |> Enum.reverse()
      |> Enum.map(fn msg ->
        role = case msg.role do
          :user -> "user"
          :assistant -> "assistant"
          _ -> "user"
        end
        %{"role" => role, "content" => msg.content}
      end)

    # Combine system message + history + current message
    all_messages = [
      %{"role" => "system", "content" => "You are a friendly AI assistant."}
      | history_messages
    ]

    request_body = Jason.encode!(%{
      "model" => "gpt-3.5-turbo",
      "messages" => all_messages,
      "stream" => true
    })

    # Build Finch request
    request = Finch.build(:post, url, [
      {"authorization", "Bearer #{api_key}"},
      {"content-type", "application/json"}
    ], request_body)

    # Stream the response
    accumulated = ""
    buffer = ""

    stream_fun = fn
      {:status, _status}, acc ->
        acc

      {:headers, _headers}, acc ->
        acc

      {:data, chunk}, {buf, acc} ->
        # Process each chunk as it arrives
        new_buffer = buf <> chunk
        {remaining, new_acc} = process_sse_buffer(new_buffer, acc, send)
        {remaining, new_acc}
    end

    case Finch.stream(request, MyFinch, {buffer, accumulated}, stream_fun) do
      {:ok, _final_acc} ->
        send.(%{event: "close", data: ""})
        Logger.info("OpenAI streaming complete")

      {:error, reason} ->
        error_msg = "Request failed: #{inspect(reason)}"
        Logger.error("OpenAI request failed: #{error_msg}")
        send.(%{event: "error", data: error_msg})
    end
  end

  # Process SSE buffer and extract complete messages
  defp process_sse_buffer(buffer, accumulated, send) do
    case String.split(buffer, "\n\n", parts: 2) do
      [complete_msg, rest] ->
        # Process the complete message
        new_accumulated = process_sse_message(complete_msg, accumulated, send)
        # Continue processing remaining buffer
        process_sse_buffer(rest, new_accumulated, send)

      [incomplete] ->
        # Not enough data yet, keep in buffer
        {incomplete, accumulated}
    end
  end

  # Process a single SSE message
  defp process_sse_message(message, accumulated, send) do
    case String.trim_leading(message, "data: ") do
      "[DONE]" ->
        accumulated

      json_str ->
        case Jason.decode(json_str) do
          {:ok, %{"choices" => [%{"delta" => %{"content" => content}} | _]}}
          when content != "" and not is_nil(content) ->
            new_accumulated = accumulated <> content
            send.(new_accumulated)
            new_accumulated

          _ ->
            accumulated
        end
    end
  end
end
