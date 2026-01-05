defmodule ChatbotSse.Api.Sse.Stream do
  use Nex
  use NexAI

  @moduledoc """
  SSE (Server-Sent Events) endpoint for streaming AI responses from OpenAI.
  """
  require Logger

  def get(req) do
    # ...
    pending_msg = case req.query["msg_id"] do
      nil -> req.query["message"] || "Hello (Testing Nex.AI Protocol)"
      id_str ->
        id_int = String.to_integer(id_str)
        case :ets.lookup(:chatbot_sse_pending, id_int) do
          [{^id_int, data}] -> 
            :ets.delete(:chatbot_sse_pending, id_int)
            data.message
          [] -> req.query["message"] || "Hello (Testing Nex.AI Protocol)"
        end
    end

    # Clean SDK Style:
    stream_text(
      messages: [%{"role" => "user", "content" => pending_msg}],
      max_steps: 5
    )
    |> to_data_stream()
  end
end
