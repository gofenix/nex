defmodule ChatbotSse.Api.Sse.Stream do
  use Nex

  @moduledoc """
  SSE (Server-Sent Events) endpoint for streaming AI responses.

  Uses HTMX SSE extension for zero-JS streaming.
  Identified as SSE endpoint by `use Nex`.
  """
  require Logger

  @impl true
  def stream(params, send_fn) do
    message = params["message"]

    if message do
      api_key = Nex.Env.get(:OPENAI_API_KEY)
      base_url = Nex.Env.get(:OPENAI_BASE_URL, "https://api.openai.com/v1")

      if api_key == nil or api_key == "" do
        simulate_streaming_response(message, send_fn)
      else
        call_openai_stream(base_url, api_key, message, send_fn)
      end
    else
      send_fn.(%{event: "error", data: "Missing message parameter"})
    end
  end

  defp simulate_streaming_response(user_message, send_fn) do
    input = String.downcase(user_message)

    response_text = cond do
      String.contains?(input, "hello") ->
        "Hello! Nice to meet you. Is there anything I can help you with?"

      String.contains?(input, "name") ->
        "I'm an SSE chatbot for the Nex framework, implementing zero-JS streaming responses using HTMX SSE extension!"

      String.contains?(input, "who") or String.contains?(input, "what") ->
        "I'm an AI chatbot using SSE streaming. Nex framework + HTMX SSE extension = Zero JS!"

      true ->
        "This is a simulated reply. Configure OPENAI_API_KEY environment variable to use real AI!"
    end

    # Stream each character with cumulative content for HTMX SSE
    response_text
    |> String.graphemes()
    |> Enum.reduce("", fn char, acc ->
      new_content = acc <> char
      send_fn.(%{event: "message", data: new_content})
      Process.sleep(30)
      new_content
    end)

    :ok
  end

  defp call_openai_stream(base_url, api_key, user_message, send_fn) do
    messages = [
      %{"role" => "system", "content" => "You are a friendly AI assistant."},
      %{"role" => "user", "content" => user_message}
    ]

    body = %{
      "model" => "gpt-3.5-turbo",
      "messages" => messages,
      "stream" => true
    }

    base_url = String.trim_trailing(base_url, "/")
    url = "#{base_url}/chat/completions"

    case Req.post(url, json: body, auth: {:bearer, api_key}, finch: MyFinch) do
      {:ok, %{status: 200, body: body}} when is_binary(body) ->
        parse_and_send_sse_chunks(body, send_fn)

      {:ok, %{status: 200, body: %{"choices" => [%{"message" => %{"content" => content}} | _]}}} ->
        # Non-streaming response: send cumulative content
        content
        |> String.graphemes()
        |> Enum.reduce("", fn char, acc ->
          new_content = acc <> char
          send_fn.(%{event: "message", data: new_content})
          Process.sleep(30)
          new_content
        end)
        :ok

      {:ok, %{status: status, body: _body}} ->
        send_fn.(%{event: "error", data: "Request failed (HTTP #{status})"})

      {:error, reason} ->
        send_fn.(%{event: "error", data: "Request failed: #{inspect(reason)}"})
    end
  end

  defp parse_and_send_sse_chunks(body, send_fn) do
    # Parse OpenAI streaming response and send cumulative content
    body
    |> String.split("\n\n", trim: true)
    |> Enum.reduce("", fn line, acc ->
      case String.trim_leading(line, "data: ") do
        "[DONE]" -> acc
        json_str ->
          case Jason.decode(json_str) do
            {:ok, %{"choices" => [%{"delta" => %{"content" => content}} | _]}}
            when content != "" and not is_nil(content) ->
              new_content = acc <> content
              send_fn.(%{event: "message", data: new_content})
              new_content
            _ -> acc
          end
      end
    end)

    :ok
  end
end
