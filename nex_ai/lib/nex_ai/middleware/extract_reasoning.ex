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
        # Ensure we don't overwrite if provider already gave us reasoning
        reasoning = reasoning || Map.get(res, :reasoning)
        {:ok, Map.merge(res, %{text: text, reasoning: reasoning})}
      error -> error
    end
  end

  def do_stream(model, params, opts) do
    tag = opts[:tag] || "reasoning"
    start_tag = "<#{tag}>"
    end_tag = "</#{tag}>"
    params = inject_instruction(params, tag)

    ModelProtocol.do_stream(model, params)
    |> Stream.transform(
      fn -> %{in_reasoning: false, buffer: ""} end,
      fn chunk, state ->
        # Providers output maps. Try to find content in choices[0].delta.content
        content = get_in(chunk, ["choices", Access.at(0), "delta", "content"])
        
        if is_binary(content) do
          full_content = state.buffer <> content
          {modified_chunks, new_state} = process_delta_raw(full_content, start_tag, end_tag, state.in_reasoning)
          {modified_chunks, new_state}
        else
          # Pass through other chunks (metadata, tool calls, etc)
          {[chunk], state}
        end
      end,
      fn state ->
        # Final flush: strip any trailing tags and emit as either content or reasoning
        if state.buffer != "" do
          clean_buf = state.buffer
            |> String.replace(start_tag, "")
            |> String.replace(end_tag, "")
          
          if clean_buf != "" do
            field = if state.in_reasoning, do: "reasoning_content", else: "content"
            {[wrap_chunk(field, clean_buf)], state}
          else
            {[], state}
          end
        else
          {[], state}
        end
      end
    )
  end

  defp process_delta_raw(delta, start_tag, end_tag, in_reasoning) do
    target = if in_reasoning, do: end_tag, else: start_tag
    
    case String.split(delta, target, parts: 2) do
      [pre, post] ->
        # Found the tag! Consume it and switch state
        field = if in_reasoning, do: "reasoning_content", else: "content"
        chunks = if pre != "", do: [wrap_chunk(field, pre)], else: []
        
        # Recursively process the remainder with the flipped state
        {more_chunks, final_state} = process_delta_raw(post, start_tag, end_tag, !in_reasoning)
        {chunks ++ more_chunks, final_state}

      [content] ->
        # Target tag not found. Check for partial suffix match to buffer.
        match_len = find_partial_match_len(content, target)
        split_pos = String.length(content) - match_len
        {to_emit, new_buffer} = String.split_at(content, split_pos)
        
        field = if in_reasoning, do: "reasoning_content", else: "content"
        chunks = if to_emit != "", do: [wrap_chunk(field, to_emit)], else: []
        {chunks, %{in_reasoning: in_reasoning, buffer: new_buffer}}
    end
  end

  defp wrap_chunk(field, value) do
    %{"choices" => [%{"index" => 0, "delta" => %{field => value}}]}
  end

  defp find_partial_match_len(content, target) do
    content_len = String.length(content)
    target_len = String.length(target)
    max_prefix_len = min(content_len, target_len - 1)
    
    Enum.find(max_prefix_len..1//-1, 0, fn len ->
      suffix = String.slice(content, (content_len - len)..-1//1)
      String.starts_with?(target, suffix)
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
    
    case String.split(text, start_tag, parts: 2) do
      [pre, rest] ->
        case String.split(rest, end_tag, parts: 2) do
          [reasoning, post] -> {String.trim(pre <> post), String.trim(reasoning)}
          _ -> {text, nil}
        end
      _ -> {text, nil}
    end
  end
end
