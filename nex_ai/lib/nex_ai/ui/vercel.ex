defmodule NexAI.UI.Vercel do
  @moduledoc """
  UI Helper for converting NexAI streams to Vercel AI Data Stream Protocol responses.
  """

  def to_data_stream({:error, reason}) do
    body_fn = fn send ->
      send.(NexAI.Protocol.encode(:error, inspect(reason)))
    end
    wrap_response(body_fn, "text/event-stream", %{"x-vercel-ai-data-stream" => "v1"})
  end

  def to_data_stream(%{full_stream: stream}) do
    body_fn = fn send ->
      Enum.each(stream, fn event ->
        case event.type do
          :text_delta -> send.(NexAI.Protocol.encode(:text, event.text))
          :reasoning_delta -> send.(NexAI.Protocol.encode(:data, %{type: "reasoning", content: event.content}))
          :tool_call_start -> send.(NexAI.Protocol.encode(:tool_call_start, %{toolCallId: event.tool_call_id, toolName: event.tool_name}))
          :tool_call_delta -> send.(NexAI.Protocol.encode(:tool_call_delta, %{toolCallId: event.tool_call_id, inputTextDelta: event.args_delta}))
          :tool_call_finish -> send.(NexAI.Protocol.encode(:tool_result, %{toolCallId: event.tool_call_id, result: event.content}))
          :finish -> send.(NexAI.Protocol.encode(:stream_finish, %{finishReason: event.finish_reason, usage: event.usage}))
          :error -> send.(NexAI.Protocol.encode(:error, inspect(event.error)))
          _ -> :ok
        end
      end)
      send.("[DONE]")
    end
    wrap_response(body_fn, "text/event-stream", %{"x-vercel-ai-data-stream" => "v1"})
  end

  defp wrap_response(body_fn, content_type, extra_headers) do
    case if(Code.ensure_compiled(Nex.Response) == {:module, Nex.Response}, do: Nex.Response, else: nil) do
      nil -> body_fn
      mod ->
        Kernel.struct(mod, [
          status: 200,
          content_type: content_type,
          headers: Map.merge(%{"cache-control" => "no-cache, no-transform", "connection" => "keep-alive"}, extra_headers),
          body: body_fn
        ])
    end
  end
end
