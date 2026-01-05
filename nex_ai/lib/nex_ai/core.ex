defmodule NexAI.Core do
  @moduledoc "Core logic for text generation and streaming loops."
  
  alias NexAI.LanguageModel.Protocol, as: ModelProtocol
  alias NexAI.Result.{GenerateTextResult, Step, ToolCall, ToolResult}
  alias NexAI.Provider.OpenAI
  alias NexAI.Message

  def generate_text(opts) do
    opts = normalize_opts(opts)
    {opts, output_config} = handle_output_config(opts)
    messages = build_messages(opts)
    model = opts[:model] || OpenAI.chat("gpt-4o")
    max_steps = opts[:max_steps] || 1

    case do_generate_loop(model, messages, opts, max_steps, 0, []) do
      {:ok, result} ->
        result = if output_config, do: process_object_result(result, output_config), else: result
        {:ok, result}
      error -> error
    end
  end

  def stream_text(opts) do
    opts = normalize_opts(opts)
    {opts, output_config} = handle_output_config(opts)
    messages = build_messages(opts)
    model = opts[:model] || OpenAI.chat("gpt-4o")
    
    full_stream = build_lazy_stream(model, messages, opts, output_config)
    %{full_stream: full_stream, opts: opts}
  end

  # --- Internal Helpers ---

  defp do_generate_loop(model, messages, opts, max_steps, step, steps_acc) do
    params = build_params(messages, opts)
    tool_map = build_tool_map(opts[:tools])
    
    case ModelProtocol.do_generate(model, params) do
      {:ok, res} ->
        current_step = %Step{
          stepType: if(step == 0, do: :initial, else: :tool_result),
          text: res.text,
          toolCalls: res.tool_calls,
          usage: res.usage,
          finishReason: res.finish_reason
        }
        
        new_steps = steps_acc ++ [current_step]

        if step + 1 < max_steps and length(res.tool_calls) > 0 do
          {tool_results, tool_messages} = execute_tools_sync(res.tool_calls, tool_map)
          
          assistant_msg = %{
            "role" => "assistant",
            "content" => res.text,
            "tool_calls" => Enum.map(res.tool_calls, fn tc -> 
              %{"id" => tc.toolCallId, "type" => "function", "function" => %{"name" => tc.toolName, "arguments" => Jason.encode!(tc.args)}}
            end)
          }
          
          new_messages = messages ++ [assistant_msg] ++ tool_messages
          do_generate_loop(model, new_messages, opts, max_steps, step + 1, new_steps)
        else
          {:ok, %GenerateTextResult{
            text: res.text,
            toolCalls: res.tool_calls,
            toolResults: List.last(steps_acc || []) |> Kernel.get_in([Access.key(:toolResults)]) || [],
            finishReason: res.finish_reason,
            usage: res.usage,
            response: res.response,
            steps: new_steps
          }}
        end
      error -> error
    end
  end

  defp build_lazy_stream(model, messages, opts, output_config, step \\ 0) do
    params = build_params(messages, opts)
    max_steps = opts[:max_steps] || 1
    tool_map = build_tool_map(opts[:tools])
    receive_timeout = opts[:receive_timeout] || 30_000

    Stream.resource(
      fn -> %{stream: ModelProtocol.do_stream(model, params), tool_calls: %{}, full_text: "", done: false, current_step: step} end,
      fn state ->
        if state.done do
          {:halt, state}
        else
          case Enum.take(state.stream, 1) do
            [] ->
              if state.current_step + 1 < max_steps and map_size(state.tool_calls) > 0 do
                {tool_results, tool_messages} = execute_tools_sync(Map.values(state.tool_calls), tool_map)
                result_events = Enum.map(tool_results, fn tr -> %{type: :tool_result, payload: tr} end)
                
                assistant_msg = %{
                  "role" => "assistant",
                  "content" => state.full_text,
                  "tool_calls" => Enum.map(state.tool_calls, fn {_, tc} -> 
                    %{"id" => tc.toolCallId, "type" => "function", "function" => %{"name" => tc.toolName, "arguments" => Jason.encode!(tc.args)}}
                  end)
                }
                
                new_messages = messages ++ [assistant_msg] ++ tool_messages
                next_stream = build_lazy_stream(model, new_messages, opts, output_config, state.current_step + 1)
                {result_events, %{state | stream: next_stream, done: false, tool_calls: %{}, current_step: state.current_step + 1}}
              else
                {[%{type: :stream_finish, payload: %{finishReason: "stop"}}], %{state | done: true}}
              end

            [chunk] ->
              {events, new_state} = process_chunk(chunk, state, output_config)
              {events, new_state}
          end
        end
      end,
      fn _state -> :ok end
    )
  end

  defp process_chunk(chunk, state, output_config) do
    cond do
      error = chunk["error"] ->
        message = if is_map(error), do: error["message"] || inspect(error), else: to_string(error)
        {[%{type: :error, payload: message}], %{state | done: true}}

      usage = chunk["usage"] ->
        {[%{type: :metadata, payload: %{usage: usage}}], state}

      delta = get_in(chunk, ["choices", Access.at(0), "delta"]) ->
        events = []
        
        {events, full_text} = if content = delta["content"] do
          type = if output_config, do: :object_delta, else: :text
          {events ++ [%{type: type, payload: content}], state.full_text <> content}
        else
          {events, state.full_text}
        end

        {events, tool_calls} = if tcs = delta["tool_calls"] do
          Enum.reduce(tcs, {events, state.tool_calls}, fn tc, {evs, st} ->
            idx = tc["index"]
            existing = st[idx] || %ToolCall{args: ""}
            
            evs = if is_nil(existing.toolCallId) and tc["id"], do: evs ++ [%{type: :tool_call_start, payload: %{toolCallId: tc["id"], toolName: tc["function"]["name"]}}], else: evs
            arg_delta = get_in(tc, ["function", "arguments"])
            evs = if arg_delta, do: evs ++ [%{type: :tool_call_delta, payload: %{toolCallId: tc["id"] || existing.toolCallId, inputTextDelta: arg_delta}}], else: evs

            updated = %ToolCall{
              toolCallId: tc["id"] || existing.toolCallId,
              toolName: get_in(tc, ["function", "name"]) || existing.toolName,
              args: existing.args <> (arg_delta || "")
            }
            {evs, Map.put(st, idx, updated)}
          end)
        else
          {events, state.tool_calls}
        end

        {events, %{state | full_text: full_text, tool_calls: tool_calls}}

      true ->
        {[], state}
    end
  end

  defp execute_tools_sync(tool_calls, tool_map) do
    results = Enum.map(tool_calls, fn tc ->
      tool_def = tool_map[tc.toolName]
      args = if is_binary(tc.args), do: Jason.decode!(tc.args), else: tc.args
      result_content = if tool_def && tool_def.execute do
        try do tool_def.execute.(args) |> Jason.encode!() rescue e -> "Error: #{inspect(e)}" end
      else "Tool not found" end
      %ToolResult{toolCallId: tc.toolCallId, toolName: tc.toolName, args: args, result: result_content}
    end)
    messages = Enum.map(results, fn tr -> %{"role" => "tool", "tool_call_id" => tr.toolCallId, "content" => tr.result} end)
    {results, messages}
  end

  defp build_params(messages, opts), do: %{prompt: messages, mode: if(opts[:output], do: :object, else: :text), tools: opts[:tools], tool_choice: opts[:tool_choice], response_format: opts[:response_format], config: opts}
  defp build_messages(opts) do
    system = opts[:system]
    messages = Message.normalize(opts[:messages] || [])
    if system, do: [%{"role" => "system", "content" => system} | messages], else: messages
  end
  defp build_tool_map(nil), do: %{}
  defp build_tool_map(tools), do: Map.new(tools, fn t -> {t.name, t} end)

  defp normalize_opts(opts) do
    mapping = [{:maxSteps, :max_steps}, {:onFinish, :on_finish}, {:onToken, :on_token}]
    Enum.reduce(mapping, opts, fn {camel, snake}, acc -> if val = acc[camel], do: Keyword.put(acc, snake, val), else: acc end)
  end

  defp handle_output_config(opts) do
    case opts[:output] do
      %{mode: mode, schema: schema} = config when mode in [:object, :array, :enum, :json] ->
        instr = "You must return a JSON object matching this schema: #{Jason.encode!(schema)}"
        opts = opts |> Keyword.put(:response_format, %{type: "json_object"}) |> Keyword.update(:system, instr, &"#{&1}\n\n#{instr}")
        {opts, config}
      _ -> {opts, nil}
    end
  end

  defp process_object_result(res, %{mode: _}) do
    clean_text = res.text |> String.replace(~r/^```json\s*/, "") |> String.replace(~r/\s*```$/, "") |> String.trim()
    case Jason.decode(clean_text) do
      {:ok, obj} -> %{res | object: obj}
      _ -> res
    end
  end
end
