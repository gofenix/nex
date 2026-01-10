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
    experimental_continueSteps: [type: :boolean, default: false],
    temperature: [type: :float],
    top_p: [type: :float],
    presence_penalty: [type: :float],
    frequency_penalty: [type: :float],
    max_tokens: [type: :integer],
    stop: [type: {:custom, __MODULE__, :validate_stop, []}],
    tools: [type: {:list, :any}],
    tool_choice: [type: :any],
    output: [type: :map],
    experimental_telemetry: [type: :map],
    on_finish: [type: {:custom, __MODULE__, :validate_fn, []}],
    onFinish: [type: {:custom, __MODULE__, :validate_fn, []}],
    on_token: [type: {:custom, __MODULE__, :validate_fn, []}],
    onToken: [type: {:custom, __MODULE__, :validate_fn, []}],
    on_step_finish: [type: {:custom, __MODULE__, :validate_fn, []}],
    onStepFinish: [type: {:custom, __MODULE__, :validate_fn, []}]
  ]

  def validate_fn(val) when is_function(val), do: {:ok, val}
  def validate_fn(_), do: {:error, "must be a function"}

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
          continue_steps = opts[:experimental_continueSteps]

          result = case do_generate_loop(model, messages, opts, max_steps, 0, [], continue_steps) do
            {:ok, result} ->
              result = if output_config, do: process_object_result(result, output_config), else: result

              # Lifecycle: onFinish
              if on_finish = opts[:on_finish] || opts[:onFinish], do: on_finish.(result)

              {:ok, result}
            error -> error
          end
          {result, Map.merge(metadata, %{result: result})}
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

  defp do_generate_loop(model, messages, opts, max_steps, step, steps_acc, continue_steps) do
    params = build_params(messages, opts)

    case ModelProtocol.do_generate(model, params) do
      {:ok, res} ->
        current_step = %Step{
          stepType: if(step == 0, do: :initial, else: :tool_result),
          text: res.text,
          reasoning: res.reasoning,
          toolCalls: res.tool_calls,
          usage: res.usage,
          finishReason: res.finish_reason,
          response: res.response
        }

        new_steps = steps_acc ++ [current_step]

        cond do
          # 1. Handle continueSteps (finish_reason: :length)
          continue_steps and res.finish_reason == :length and step + 1 < max_steps ->
            assistant_msg = %NexAI.Message.Assistant{content: res.text}
            new_messages = messages ++ [assistant_msg]
            do_generate_loop(model, new_messages, opts, max_steps, step + 1, new_steps, continue_steps)

          # 2. Handle Tool Calls
          step + 1 < max_steps and length(res.tool_calls || []) > 0 ->
            tool_map = build_tool_map(opts[:tools])
            {_tool_results, tool_messages} = execute_tools_sync(res.tool_calls, tool_map)

            assistant_msg = %NexAI.Message.Assistant{
              content: res.text,
              tool_calls:
                Enum.map(res.tool_calls, fn tc ->
                  %{
                    "id" => tc.toolCallId,
                    "type" => "function",
                    "function" =>
                      %{"name" => tc.toolName, "arguments" => Jason.encode!(tc.args)}
                  }
                end)
            }

            new_messages = messages ++ [assistant_msg] ++ tool_messages
            do_generate_loop(model, new_messages, opts, max_steps, step + 1, new_steps, continue_steps)

          # 3. Final Step
          true ->
            {:ok,
             %GenerateTextResult{
               text: combine_steps_text(new_steps),
               reasoning: combine_steps_reasoning(new_steps),
               toolCalls: res.tool_calls,
               toolResults: List.last(new_steps).toolResults || [],
               finishReason: res.finish_reason,
               usage: calculate_total_usage(new_steps),
               response: res.response,
               steps: new_steps,
               raw_call: res.raw_call
             }}
        end

      error ->
        error
    end
  end

  defp combine_steps_text(steps) do
    steps |> Enum.map_join("", &(&1.text || ""))
  end

  defp combine_steps_reasoning(steps) do
    steps |> Enum.map_join("", &(&1.reasoning || ""))
  end

  defp calculate_total_usage(steps) do
    Enum.reduce(steps, %NexAI.Result.Usage{promptTokens: 0, completionTokens: 0, totalTokens: 0}, fn step, acc ->
      if step.usage do
        %NexAI.Result.Usage{
          promptTokens: acc.promptTokens + (step.usage.promptTokens || 0),
          completionTokens: acc.completionTokens + (step.usage.completionTokens || 0),
          totalTokens: acc.totalTokens + (step.usage.totalTokens || 0)
        }
      else
        acc
      end
    end)
  end

  defp build_lazy_stream(model, messages, opts, output_config, step \\ 0) do
    max_steps = opts[:max_steps] || 1
    continue_steps = opts[:experimental_continueSteps]

    Stream.resource(
      fn ->
        # Start the first step's stream
        case ModelProtocol.do_stream(model, build_params(messages, opts)) do
          {:ok, stream} ->
            case Enumerable.reduce(stream, {:cont, nil}, fn x, _ -> {:suspend, x} end) do
              {:suspended, chunk, next} ->
                %{
                  next: next,
                  chunk: chunk,
                  tool_calls: %{},
                  full_text: "",
                  full_reasoning: "",
                  step: step,
                  opts: opts,
                  messages: messages,
                  finish_reason: nil
                }

              _ ->
                %{
                  next: nil,
                  chunk: nil,
                  tool_calls: %{},
                  full_text: "",
                  full_reasoning: "",
                  step: step,
                  opts: opts,
                  messages: messages,
                  finish_reason: nil
                }
            end

          {:error, err} ->
            # Error during stream initialization
            %{
              next: nil,
              chunk: %NexAI.LanguageModel.StreamPart{type: :error, error: err},
              step: :error,
              opts: opts
            }
        end
      end,
      fn state ->
        cond do
          state.step == :done ->
            {:halt, state}

          state.step == :error ->
            {[state.chunk], %{state | step: :done}}

          is_nil(state.chunk) ->
            # Current step is finished, check for continuation or tool calls
            cond do
              # 1. Continue Steps (Truncated by length)
              continue_steps and state.finish_reason == :length and state.step + 1 < max_steps ->
                assistant_msg = %NexAI.Message.Assistant{content: state.full_text}
                new_messages = state.messages ++ [assistant_msg]
                start_next_step(model, new_messages, opts, state)

              # 2. Tool Calls
              state.step + 1 < max_steps and map_size(state.tool_calls) > 0 ->
                tool_map = build_tool_map(opts[:tools])
                tool_calls_list = Map.values(state.tool_calls)
                {tool_results, tool_messages} = execute_tools_sync(tool_calls_list, tool_map)

                # Lifecycle: onStepFinish
                step_result = %{
                  step: state.step,
                  text: state.full_text,
                  toolCalls: tool_calls_list,
                  toolResults: tool_results
                }

                if on_step_finish = opts[:on_step_finish] || opts[:onStepFinish],
                  do: on_step_finish.(step_result)

                # Map tool results to stream events
                result_events =
                  Enum.map(tool_results, fn tr ->
                    %NexAI.LanguageModel.StreamPart{
                      type: :tool_call_finish,
                      tool_call_id: tr.toolCallId,
                      tool_name: tr.toolName,
                      content: tr.result
                    }
                  end)

                assistant_msg = %NexAI.Message.Assistant{
                  content: state.full_text,
                  tool_calls:
                    Enum.map(tool_calls_list, fn tc ->
                      %{
                        "id" => tc.toolCallId,
                        "type" => "function",
                        "function" =>
                          %{"name" => tc.toolName, "arguments" => Jason.encode!(tc.args)}
                      }
                    end)
                }

                new_messages = state.messages ++ [assistant_msg] ++ tool_messages
                {new_events, next_state} = start_next_step(model, new_messages, opts, state)
                {result_events ++ new_events, next_state}

              # 3. Actually Done
              true ->
                {[], %{state | step: :done}}
            end

          true ->
            # Process the current chunk (already a StreamPart from Provider)
            {events, new_acc} = process_v1_chunk(state.chunk, state, output_config)

            # Pull the next chunk from the current stream
            new_state =
              case state.next.({:cont, nil}) do
                {:suspended, next_chunk, next_next} ->
                  %{
                    state
                    | next: next_next,
                      chunk: next_chunk,
                      tool_calls: new_acc.tool_calls,
                      full_text: new_acc.full_text,
                      full_reasoning: new_acc.full_reasoning,
                      finish_reason: new_acc.finish_reason
                  }

                _ ->
                  # Current stream is finished
                  %{
                    state
                    | next: nil,
                      chunk: nil,
                      tool_calls: new_acc.tool_calls,
                      full_text: new_acc.full_text,
                      full_reasoning: new_acc.full_reasoning,
                      finish_reason: new_acc.finish_reason
                  }
              end

            {events, new_state}
        end
      end,
      fn
        %{next: next, step: step} when is_function(next) ->
          :telemetry.execute([:nex_ai, :stream, :stop], %{system_time: System.system_time()}, %{
            step: step,
            status: :halted
          })

          next.({:halt, nil})

        %{step: step} ->
          :telemetry.execute([:nex_ai, :stream, :stop], %{system_time: System.system_time()}, %{
            step: step,
            status: :finished
          })

          :ok
      end
    )
  end

  defp start_next_step(model, new_messages, opts, state) do
    case ModelProtocol.do_stream(model, build_params(new_messages, opts)) do
      {:ok, next_stream} ->
        case Enumerable.reduce(next_stream, {:cont, nil}, fn x, _ -> {:suspend, x} end) do
          {:suspended, first_chunk, next_next} ->
            {[],
             %{
               state
               | next: next_next,
                 chunk: first_chunk,
                 step: state.step + 1,
                 messages: new_messages,
                 tool_calls: %{},
                 full_text: "",
                 full_reasoning: "",
                 finish_reason: nil
             }}

          _ ->
            {[], %{state | step: :done}}
        end

      {:error, err} ->
        {[ %NexAI.LanguageModel.StreamPart{type: :error, error: err} ], %{state | step: :done}}
    end
  end

  defp process_v1_chunk(chunk, state, output_config) do
    opts = state.opts

    case chunk.type do
      :text_delta ->
        full_text = state.full_text <> chunk.content
        events = if output_config do
          case NexAI.PartialJSON.parse(full_text) do
            {:ok, obj} ->
              if on_token = opts[:on_token] || opts[:onToken], do: on_token.(obj)
              [ %{chunk | type: :object_delta, payload: obj} ]
            _ -> []
          end
        else
          if on_token = opts[:on_token] || opts[:onToken], do: on_token.(chunk.content)
          [ chunk ]
        end
        {events, %{state | full_text: full_text}}

      :reasoning_delta ->
        full_reasoning = state.full_reasoning <> chunk.content
        {[ chunk ], %{state | full_reasoning: full_reasoning}}

      :tool_call_start ->
        # Initialize tool call tracking in state
        tc = %ToolCall{toolCallId: chunk.tool_call_id, toolName: chunk.tool_name, args: ""}
        new_tool_calls = Map.put(state.tool_calls, chunk.tool_call_id, tc)
        {[ chunk ], %{state | tool_calls: new_tool_calls}}

      :tool_call_delta ->
        tc = state.tool_calls[chunk.tool_call_id]
        updated_tc = %{tc | args: tc.args <> (chunk.args_delta || "")}
        new_tool_calls = Map.put(state.tool_calls, chunk.tool_call_id, updated_tc)
        {[ chunk ], %{state | tool_calls: new_tool_calls}}

      :finish ->
        {[ chunk ], %{state | finish_reason: chunk.finish_reason}}

      _ ->
        {[ chunk ], state}
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
    messages = opts[:messages] || []
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
