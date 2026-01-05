defmodule NexAI.Middleware.ExtractReasoning do
  @moduledoc """
  Middleware that extracts reasoning (e.g. <reasoning> tags) from model output.
  """
  alias NexAI.LanguageModel.Protocol, as: ModelProtocol

  def do_generate(model, params, opts) do
    tag = opts[:tag] || "reasoning"
    params = inject_instruction(params, tag)

    case ModelProtocol.do_generate(model, params) do
      {:ok, res} ->
        {text, reasoning} = extract(res.text, tag)
        {:ok, Map.merge(res, %{text: text, reasoning: reasoning})}
      error -> error
    end
  end

  def do_stream(model, params, opts) do
    tag = opts[:tag] || "reasoning"
    params = inject_instruction(params, tag)

    # Return a stream that intercepts chunks
    ModelProtocol.do_stream(model, params)
    |> Stream.transform(%{in_tag: false}, fn chunk, state ->
      # Simplified: in a real impl, we'd buffer to find the tag start/end
      # For now, we just pass through but this demonstrates the interceptor capability
      {[chunk], state}
    end)
  end

  defp inject_instruction(params, tag) do
    instr = "Please put your internal reasoning inside <#{tag}> tags before responding."
    update_in(params.prompt, fn messages ->
      # Find system message or add one
      if Enum.any?(messages, &(&1["role"] == "system")) do
        Enum.map(messages, fn
          %{"role" => "system", "content" => content} = m -> %{m | "content" => "#{content}\n\n#{instr}"}
          other -> other
        end)
      else
        [%{"role" => "system", "content" => instr} | messages]
      end
    end)
  end

  defp extract(text, tag) do
    start_tag = "<#{tag}>"
    end_tag = "</#{tag}>"
    
    case String.split(text, start_tag) do
      [pre, rest] ->
        case String.split(rest, end_tag) do
          [reasoning, post] -> {String.trim(pre <> post), String.trim(reasoning)}
          _ -> {text, nil}
        end
      _ -> {text, nil}
    end
  end
end
