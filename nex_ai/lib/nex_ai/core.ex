defmodule NexAI.Core do
  @moduledoc "Core logic for text generation and streaming loops."
  
  alias NexAI.LanguageModel.Protocol, as: ModelProtocol
  alias NexAI.Result.{GenerateTextResult, Step, ToolCall, ToolResult}
  alias NexAI.Message

  @common_schema [
    model: [type: :any, required: true],
    messages: [type: {:list, :any}, required: true],
    system: [type: :string],
    max_steps: [type: :integer, default: 1],
    maxSteps: [type: :integer], # CamelCase compatibility
    temperature: [type: :float],
    top_p: [type: :float],
    presence_penalty: [type: :float],
    frequency_penalty: [type: :float],
    max_tokens: [type: :integer],
    stop: [type: {:custom, __MODULE__, :validate_stop, []}],
    tools: [type: {:list, :any}],
    tool_choice: [type: :any],
    output: [type: :map]
  ]

  def validate_stop(val) when is_list(val) or is_binary(val), do: {:ok, val}
  def validate_stop(_), do: {:error, "must be a string or a list of strings"}

  def generate_text(opts) when is_list(opts) do
    case NimbleOptions.validate(opts, @common_schema) do
      {:ok, opts} ->
        metadata = %{opts: opts, method: :generate_text}
        :telemetry.span([:nex_ai, :generate], metadata, fn ->
          opts = normalize_opts(opts)
          {opts, output_config} = handle_output_config(opts)
          messages = build_messages(opts)
          model = opts[:model]
          max_steps = opts[:max_steps]

          result = case do_generate_loop(model, messages, opts, max_steps, 0, []) do
            {:ok, result} ->
              result = if output_config, do: process_object_result(result, output_config), else: result
              {:ok, result}
            error -> error
          end
          {result, Map.put(metadata, :result, result)}
        end)
      {:error, %NimbleOptions.ValidationError{message: msg}} ->
        {:error, %NexAI.Error.InvalidRequestError{message: msg}}
    end
  end

  def generate_text(messages, opts) do
    generate_text(Keyword.put(opts, :messages, messages))
  end

  def stream_text(opts) do
    case NimbleOptions.validate(opts, @common_schema) do
      {:ok, opts} ->
        metadata = %{opts: opts, method: :stream_text}
        :telemetry.execute([:nex_ai, :stream, :start], %{system_time: System.system_time()}, metadata)
        
        opts = normalize_opts(opts)
        {opts, output_config} = handle_output_config(opts)
        messages = build_messages(opts)
        model = opts[:model]
        
        full_stream = build_lazy_stream(model, messages, opts, output_config)
        %{full_stream: full_stream, opts: opts}
      {:error, %NimbleOptions.ValidationError{message: msg}} ->
        # For stream, we return a map with an error stream or just raise?
        # Vercel SDK usually throws, let's return an error object that can be handled
        {:error, %NexAI.Error.InvalidRequestError{message: msg}}
    end
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
          reasoning: Map.get(res, :reasoning),
          toolCalls: res.tool_calls,
          usage: res.usage,
          finishReason: res.finish_reason
        }
        
        new_steps = steps_acc ++ [current_step]

        if step + 1 < max_steps and length(res.tool_calls) > 0 do
          {_tool_results, tool_messages} = execute_tools_sync(res.tool_calls, tool_map)
          
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
            reasoning: Map.get(res, :reasoning),
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
    max_steps = opts[:max_steps] || 1
    tool_map = build_tool_map(opts[:tools])

    Stream.resource(
      fn ->
        # Start the first step's stream and pull the first chunk
        stream = ModelProtocol.do_stream(model, build_params(messages, opts))
        case Enumerable.reduce(stream, {:cont, nil}, fn x, _ -> {:suspend, x} end) do
          {:suspended, chunk, next} -> %{next: next, chunk: chunk, tool_calls: %{}, full_text: "", full_reasoning: "", step: step}
          _ -> %{next: nil, chunk: nil, tool_calls: %{}, full_text: "", full_reasoning: "", step: step}
        end
      end,
      fn state ->
        cond do
          state.step == :done ->
            {:halt, state}

          is_nil(state.chunk) ->
            # Current step is finished, check for tool calls
            if state.step + 1 < max_steps and map_size(state.tool_calls) > 0 do
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
              
              # Start the next step's stream
              new_stream = ModelProtocol.do_stream(model, build_params(new_messages, opts))
              case Enumerable.reduce(new_stream, {:cont, nil}, fn x, _ -> {:suspend, x} end) do
                {:suspended, first_chunk, next} ->
                  {result_events, %{state | next: next, chunk: first_chunk, step: state.step + 1, tool_calls: %{}, full_text: "", full_reasoning: ""}}
                _ ->
                  {result_events ++ [%{type: :stream_finish, payload: %{finishReason: "stop"}}], %{state | step: :done}}
              end
            else
              {[%{type: :stream_finish, payload: %{finishReason: "stop"}}], %{state | step: :done}}
            end

          true ->
            # Process the current chunk
            {events, new_acc} = process_chunk(state.chunk, state, output_config)
            
            # Pull the next chunk from the current stream
            new_state = case state.next.({:cont, nil}) do
              {:suspended, next_chunk, next_next} ->
                %{state | next: next_next, chunk: next_chunk, tool_calls: new_acc.tool_calls, full_text: new_acc.full_text, full_reasoning: new_acc.full_reasoning}
              _ ->
                # Current stream is finished
                %{state | next: nil, chunk: nil, tool_calls: new_acc.tool_calls, full_text: new_acc.full_text, full_reasoning: new_acc.full_reasoning}
            end
            {events, new_state}
        end
      end,
      fn 
        %{next: next} when is_function(next) -> 
          :telemetry.execute([:nex_ai, :stream, :stop], %{system_time: System.system_time()}, %{step: step})
          next.({:halt, nil})
        _ -> 
          :telemetry.execute([:nex_ai, :stream, :stop], %{system_time: System.system_time()}, %{step: step})
          :ok
      end
    )
  end

  defp process_chunk(chunk, state, output_config) do
    if error = chunk["error"] do
      message = if is_map(error), do: error["message"] || inspect(error), else: to_string(error)
      {[%{type: :error, payload: message}], %{state | chunk: nil, next: nil}}
    else
      events = []
      
      # 1. Handle Usage/Metadata (Non-exclusive)
      events = if usage = chunk["usage"], do: events ++ [%{type: :metadata, payload: %{usage: usage}}], else: events

      # 2. Handle Delta (Non-exclusive)
      delta = get_in(chunk, ["choices", Access.at(0), "delta"])
      
      {events, full_text} = case delta && delta["content"] do
        nil -> {events, state.full_text}
        content ->
          type = if output_config, do: :object_delta, else: :text
          {events ++ [%{type: type, payload: content}], state.full_text <> content}
      end

      # 3. Handle Native Reasoning Content (OpenAI style)
      {events, full_reasoning} = case delta && delta["reasoning_content"] do
        nil -> {events, state.full_reasoning}
        reasoning ->
          {events ++ [%{type: :reasoning, payload: reasoning}], state.full_reasoning <> reasoning}
      end

      {events, tool_calls} = case delta && delta["tool_calls"] do
        nil -> {events, state.tool_calls}
        tcs ->
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
      end

      {events, %{state | full_text: full_text, full_reasoning: full_reasoning, tool_calls: tool_calls}}
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

  def normalize_opts(opts) do
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
