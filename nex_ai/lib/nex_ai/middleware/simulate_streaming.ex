defmodule NexAI.Middleware.SimulateStreaming do
  @moduledoc """
  Middleware that simulates streaming by converting a non-streaming response
  into a stream of text chunks.
  """
  alias NexAI.LanguageModel.Protocol, as: ModelProtocol

  def do_stream(model, params, opts) do
    chunk_size = opts[:chunk_size] || 5
    delay = opts[:delay] || 50

    Stream.resource(
      fn ->
        case ModelProtocol.do_generate(model, params) do
          {:ok, res} ->
            text = extract_text_from_content(res.content)
            {String.graphemes(text || ""), res}
          {:error, _} = err ->
            err
        end
      end,
      fn
        {:error, _} = err -> {[err], :done}
        :done -> {:halt, :done}
        {chars, res} ->
          {chunk, rest} = Enum.split(chars, chunk_size)
          Process.sleep(delay)

          if chunk == [] do
            {[{:finish, res.finish_reason}], :done}
          else
            {[%NexAI.LanguageModel.StreamPart{type: :text_delta, text: Enum.join(chunk)}], {rest, res}}
          end
      end,
      fn _ -> :ok end
    )
  end

  defp extract_text_from_content(content) when is_list(content) do
    Enum.filter_map(content, fn
      %{type: "text", text: t} -> true
      _ -> false
    end, fn
      %{type: "text", text: t} -> t
    end)
    |> Enum.join("")
  end
  defp extract_text_from_content(_), do: ""
end
