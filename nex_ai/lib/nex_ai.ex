defmodule NexAI do
  @moduledoc """
  NexAI - The Standalone AI SDK for Elixir, inspired by Vercel AI SDK.
  
  Provides high-level functions for streaming and generating text from LLMs.
  Now fully refactored to support true lazy streaming and provider abstraction.
  """

  alias NexAI.LanguageModel.Protocol, as: ModelProtocol
  alias NexAI.Provider.OpenAI
  alias NexAI.Result.{GenerateTextResult, Usage, Response, ToolCall, ToolResult, Step}
  require Logger

  defmacro __using__(_opts) do
    quote do
      import NexAI, only: [
        stream_text: 1, 
        generate_text: 1,
        generate_text: 2,
        openai: 1,
        openai: 2,
        to_data_stream: 1,
        to_datastar: 1, 
        to_datastar: 2,
        embed: 1,
        embed_many: 1,
        generate_image: 1,
        transcribe: 1,
        generate_speech: 1,
        generate_id: 0,
        tool: 1,
        json_schema: 1,
        zod_schema: 1
      ]
    end
  end

  # --- Types and Structs ---

  defmodule StreamTextResult do
    @moduledoc "Result of a stream_text call."
    defstruct [:full_stream, :opts]
  end

  # --- Core API ---

  @doc "Factory for OpenAI models"
  def openai(model_id, opts \\ []), do: OpenAI.chat(model_id, opts)

  @doc "Factory for Anthropic models"
  def anthropic(model_id, opts \\ []), do: NexAI.Provider.Anthropic.claude(model_id, opts)

  @doc "Generates text from a language model."
  def generate_text(opts) when is_list(opts) do
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
  def generate_text(messages, opts), do: generate_text(Keyword.put(opts, :messages, messages))

  @doc "Streams text from a language model (True Lazy Streaming)."
  def stream_text(opts) do
    opts = normalize_opts(opts)
    {opts, output_config} = handle_output_config(opts)
    messages = build_messages(opts)
    model = opts[:model] || OpenAI.chat("gpt-4o")
    
    # We create a stream of events that automatically handles tool loops
    full_stream = build_lazy_stream(model, messages, opts, output_config)

    %StreamTextResult{full_stream: full_stream, opts: opts}
  end

  # --- Adapters ---

  @doc "Converts a StreamTextResult to Vercel AI SDK Data Stream Protocol."
  def to_data_stream(%StreamTextResult{full_stream: stream}) do
    body_fn = fn send ->
      Enum.each(stream, fn event ->
        send.(NexAI.Protocol.encode(event.type, event.payload))
      end)
      send.("[DONE]")
    end

    case response_module() do
      nil -> body_fn
      mod ->
        Kernel.struct(mod, [
          status: 200,
          content_type: "text/event-stream",
          headers: %{
            "cache-control" => "no-cache, no-transform",
            "connection" => "keep-alive",
            "x-vercel-ai-data-stream" => "v1"
          },
          body: body_fn
        ])
    end
  end

  @doc "Converts a StreamTextResult to Datastar Signal Patches."
  def to_datastar(%StreamTextResult{full_stream: stream, opts: opts}, datastar_opts \\ []) do
    datastar_opts = normalize_opts(datastar_opts)
    signal_name = to_string(datastar_opts[:signal] || "aiResponse")
    
    body_fn = fn send ->
      # We need to accumulate text for Datastar
      Enum.reduce(stream, "", fn event, acc ->
        case event.type do
          :text ->
            new_acc = acc <> event.payload
            send.(%{event: "datastar-patch-signals", data: "signals {#{Jason.encode!(signal_name)}: #{Jason.encode!(new_acc)}}"})
            new_acc
          _ -> acc
        end
      end)
    end

    case response_module() do
      nil -> body_fn
      mod ->
        Kernel.struct(mod, [
          status: 200,
          content_type: "text/event-stream; charset=utf-8",
          headers: %{"cache-control" => "no-cache", "connection" => "keep-alive"},
          body: body_fn
        ])
    end
  end

  # --- Internal Loops ---

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

    # This is the core transform that makes it lazy
    Stream.resource(
      fn -> 
        %{
          stream: ModelProtocol.do_stream(model, params),
          tool_calls: %{},
          full_text: "",
          done: false,
          current_step: step
        }
      end,
      fn state ->
        if state.done do
          {:halt, state}
        else
          # Consume one chunk from provider stream
          case Enum.take(state.stream, 1) do
            [] ->
              # Provider stream ended. Check if we need to loop tools
              if state.current_step + 1 < max_steps and map_size(state.tool_calls) > 0 do
                # Run tools and start next step stream
                {tool_results, tool_messages} = execute_tools_sync(Map.values(state.tool_calls), tool_map)
                
                # We need to emit tool-results events here
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
                
                # Trick: halt this resource and return the next stream's elements
                # But Stream.resource expects {elements, next_state}
                # So we emit tool results and then transition to a state that just pumps from the next stream
                {result_events, %{state | stream: next_stream, done: false, tool_calls: %{}, current_step: state.current_step + 1}}
              else
                # Truly finished
                {[%{type: :stream_finish, payload: %{finishReason: "stop"}}], %{state | done: true}}
              end

            [chunk] ->
              # Process chunk (OpenAI style delta)
              {events, new_state} = process_chunk(chunk, state, output_config)
              {events, new_state}
          end
        end
      end,
      fn _state -> :ok end
    )
  end

  defp process_chunk(chunk, state, output_config) do
    # This maps provider-specific chunks to standard events
    # For now, we assume OpenAI-compatible chunks from the provider's do_stream
    delta = get_in(chunk, ["choices", Access.at(0), "delta"]) || %{}
    
    events = []
    new_state = state

    # 1. Text content
    {events, new_state} = if content = delta["content"] do
      type = if output_config, do: :object_delta, else: :text
      {events ++ [%{type: type, payload: content}], %{new_state | full_text: state.full_text <> content}}
    else
      {events, new_state}
    end

    # 2. Tool calls
    {events, new_state} = if tcs = delta["tool_calls"] do
      Enum.reduce(tcs, {events, new_state}, fn tc, {evs, st} ->
        idx = tc["index"]
        existing = st.tool_calls[idx] || %ToolCall{args: ""}
        
        # Start event
        evs = if is_nil(existing.toolCallId) and tc["id"] do
          evs ++ [%{type: :tool_call_start, payload: %{toolCallId: tc["id"], toolName: tc["function"]["name"]}}]
        else
          evs
        end

        # Delta event
        arg_delta = get_in(tc, ["function", "arguments"])
        evs = if arg_delta, do: evs ++ [%{type: :tool_call_delta, payload: %{toolCallId: tc["id"] || existing.toolCallId, inputTextDelta: arg_delta}}], else: evs

        updated = %ToolCall{
          toolCallId: tc["id"] || existing.toolCallId,
          toolName: get_in(tc, ["function", "name"]) || existing.toolName,
          args: existing.args <> (arg_delta || "")
        }
        
        {evs, %{st | tool_calls: Map.put(st.tool_calls, idx, updated)}}
      end)
    else
      {events, new_state}
    end

    # 3. Final tool call finish event (when a tool call is fully received)
    # This is tricky because we don't know it's finished until the next chunk or stream end.
    # For simplicity, we'll emit the full tool-call event at the end of the step.

    {events, new_state}
  end

  defp execute_tools_sync(tool_calls, tool_map) do
    results = Enum.map(tool_calls, fn tc ->
      tool_def = tool_map[tc.toolName]
      args = if is_binary(tc.args), do: Jason.decode!(tc.args), else: tc.args
      
      result_content = if tool_def && tool_def.execute do
        try do
          tool_def.execute.(args) |> Jason.encode!()
        rescue e -> "Error: #{inspect(e)}" end
      else
        "Tool not found"
      end

      %ToolResult{toolCallId: tc.toolCallId, toolName: tc.toolName, args: args, result: result_content}
    end)

    messages = Enum.map(results, fn tr ->
      %{"role" => "tool", "tool_call_id" => tr.toolCallId, "content" => tr.result}
    end)

    {results, messages}
  end

  defp build_tool_map(nil), do: %{}
  defp build_tool_map(tools), do: Map.new(tools, fn t -> {t.name, t} end)

  # --- Helpers ---

  defp build_params(messages, opts) do
    %{
      prompt: messages,
      mode: if(opts[:output], do: :object, else: :text),
      tools: opts[:tools],
      tool_choice: opts[:tool_choice],
      response_format: opts[:response_format],
      config: opts
    }
  end

  defp build_messages(opts) do
    system = opts[:system]
    messages = NexAI.Message.normalize(opts[:messages] || [])
    if system, do: [%{"role" => "system", "content" => system} | messages], else: messages
  end

  defp normalize_opts(opts) do
    mapping = [
      {:maxSteps, :max_steps}, 
      {:onFinish, :on_finish}, 
      {:onToken, :on_token}
    ]
    Enum.reduce(mapping, opts, fn {camel, snake}, acc ->
      if val = acc[camel], do: Keyword.put(acc, snake, val), else: acc
    end)
  end

  defp handle_output_config(opts) do
    case opts[:output] do
      %{mode: mode, schema: schema} = config when mode in [:object, :array, :enum, :json] ->
        instr = "You must return a JSON object matching this schema: #{Jason.encode!(schema)}"
        opts = opts
          |> Keyword.put(:response_format, %{type: "json_object"})
          |> Keyword.update(:system, instr, &"#{&1}\n\n#{instr}")
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

  def tool(opts), do: NexAI.Tool.new(opts)
  def json_schema(s), do: NexAI.Schema.json_schema(s)
  def zod_schema(s), do: NexAI.Schema.json_schema(s)
  def generate_id, do: :crypto.strong_rand_bytes(5) |> Base.encode32(case: :lower, padding: false) |> binary_part(0, 7)

  defp response_module, do: if(Code.ensure_compiled?(Nex.Response), do: Nex.Response, else: nil)

  # Delegation to providers
  def embed(opts), do: (opts[:model] || OpenAI).embed_many([opts[:value]], opts)
  def embed_many(opts), do: (opts[:model] || OpenAI).embed_many(opts[:values], opts)
  def generate_image(opts), do: (opts[:model] || OpenAI).generate_image(opts[:prompt], opts)
  def transcribe(opts), do: (opts[:model] || OpenAI).transcribe(opts[:file], opts)
  def generate_speech(opts), do: (opts[:model] || OpenAI).generate_speech(opts[:input] || opts[:text], opts)
end
