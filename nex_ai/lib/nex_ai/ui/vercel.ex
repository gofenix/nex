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
        send.(NexAI.Protocol.encode(event.type, event.payload))
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
