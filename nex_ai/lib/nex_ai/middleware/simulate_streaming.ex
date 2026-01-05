defmodule NexAI.Middleware.SimulateStreaming do
  @moduledoc """
  Middleware that simulates streaming for models that only support generate.
  """
  alias NexAI.LanguageModel.Protocol, as: ModelProtocol

  def do_stream(model, params, opts) do
    chunk_size = opts[:chunk_size] || 5
    delay = opts[:delay] || 50

    Stream.resource(
      fn ->
        case ModelProtocol.do_generate(model, params) do
          {:ok, res} -> {String.graphemes(res.text || ""), res}
          {:error, _} = err -> err
        end
      end,
      fn
        {:error, _} = err -> {[err], :done}
        :done -> {:halt, :done}
        {chars, res} ->
          {chunk, rest} = Enum.split(chars, chunk_size)
          Process.sleep(delay)
          
          events = if rest == [] do
            # Final chunk: include usage/metadata
            [%{"choices" => [%{"delta" => %{"content" => Enum.join(chunk)}}]}, %{"usage" => res.usage}]
          else
            [%{"choices" => [%{"delta" => %{"content" => Enum.join(chunk)}}]}]
          end

          {events, if(rest == [], do: :done, else: {rest, res})}
      end,
      fn _ -> :ok end
    )
  end
end
