defmodule NexAI do
  @moduledoc """
  NexAI - The Standalone AI SDK for Elixir, inspired by Vercel AI SDK.
  
  Provides high-level functions for streaming and generating text from LLMs.
  This package is decoupled from any web framework.
  """

  alias NexAI.Protocol
  alias NexAI.Provider.OpenAI
  require Logger

  defmacro __using__(_opts) do
    quote do
      import NexAI, only: [
        stream_text: 1, 
        generate_text: 1,
        generate_text: 2,
        generate_object: 1,
        stream_object: 1,
        agent: 1,
        tool: 1, 
        openai: 1,
        openai: 2,
        to_data_stream: 1,
        to_datastar: 1, 
        to_datastar: 2,
        to_text_stream: 1,
        embed: 1,
        embed_many: 1,
        cosine_similarity: 2,
        generate_image: 1,
        transcribe: 1,
        generate_speech: 1,
        rerank: 1,
        generate_id: 0,
        create_id_generator: 0,
        create_id_generator: 1,
        create_provider_registry: 1,
        json_schema: 1,
        simulate_readable_stream: 1,
        wrap_language_model: 2,
        extract_reasoning_middleware: 1,
        default_settings_middleware: 1,
        simulate_streaming_middleware: 1,
        smooth_stream: 1,
        zod_schema: 1,
        create_mcp_client: 1
      ]
    end
  end

  # ... (previous code)

  @doc """
  Middleware to simulate streaming.
  """
  def simulate_streaming_middleware(opts \\ []), do: {NexAI.Middleware.SimulateStreaming, opts}

  @doc """
  Smooths a stream by chunking or delaying.
  Maps to `smoothStream`.
  In Elixir, this is largely identity, but provided for API compatibility.
  """
  def smooth_stream(_opts \\ []) do
    fn stream -> 
      # Logic to smooth stream would go here.
      # For now, we return the stream as is.
      stream
    end
  end

  @doc """
  Helper for Zod schema compatibility.
  Maps to `zodSchema`.
  Actually returns a JSON Schema since Elixir uses map-based schemas.
  """
  def zod_schema(schema), do: NexAI.Schema.json_schema(schema)

  @doc """
  Creates a client for the Model Context Protocol (MCP).
  Maps to `createMCPClient`.
  """
  def create_mcp_client(opts) do
    # Placeholder for MCP client implementation
    %{type: :mcp_client, opts: opts}
  end

  @doc """
  Wraps a language model with middlewares.
  Maps to `wrapLanguageModel`.
  """
  def wrap_language_model(model, middlewares), do: NexAI.Middleware.wrap_model(model, middlewares)

  @doc """
  Middleware to extract reasoning.
  """
  def extract_reasoning_middleware(opts \\ []), do: {NexAI.Middleware.ExtractReasoning, opts}

  @doc """
  Middleware to apply default settings.
  """
  def default_settings_middleware(opts \\ []), do: {NexAI.Middleware.DefaultSettings, opts}

  @doc """
  Creates a provider registry.
  """
  def create_provider_registry(providers), do: NexAI.Registry.new(providers)

  @doc """
  Creates a JSON schema definition helper.
  """
  def json_schema(schema), do: NexAI.Schema.json_schema(schema)

  @doc """
  Simulates a readable stream from a value with optional delay.
  Maps to `simulateReadableStream`.
  """
  def simulate_readable_stream(value, opts \\ []) do
    chunk_size = opts[:chunk_size] || 5
    delay_ms = opts[:delay_ms] || 50

    Stream.resource(
      fn -> 
        String.graphemes(value) 
      end,
      fn 
        [] -> {:halt, nil}
        chars ->
          {chunk, rest} = Enum.split(chars, chunk_size)
          Process.sleep(delay_ms)
          {[Enum.join(chunk)], rest}
      end,
      fn _ -> :ok end
    )
  end

  @doc """
  Reranks documents based on a query.
  """
  def rerank(opts) do
    opts = normalize_opts(opts)
    query = opts[:query]
    documents = opts[:documents]
    model = opts[:model] || OpenAI
    
    if function_exported?(model, :rerank, 3) do
      model.rerank(query, documents, opts)
    else
      {:error, :not_implemented_by_provider}
    end
  end

  @doc """
  Generates a unique ID (default 7 chars).
  """
  def generate_id do
    :crypto.strong_rand_bytes(5) |> Base.encode32(case: :lower, padding: false) |> binary_part(0, 7)
  end

  @doc """
  Creates a custom ID generator.
  """
  def create_id_generator(opts \\ []) do
    size = opts[:size] || 7
    # Returns a function that generates ID of 'size'
    fn -> 
      bytes = ceil(size * 5 / 8)
      :crypto.strong_rand_bytes(bytes) |> Base.encode32(case: :lower, padding: false) |> binary_part(0, size)
    end
  end

  @doc """
  Transcribes audio from a file content.
  Maps to `experimental_transcribe` in Vercel AI SDK.
  """
  def transcribe(opts) do
    opts = normalize_opts(opts)
    file = opts[:file]
    model = opts[:model] || OpenAI
    
    model.transcribe(file, opts)
  end

  @doc """
  Generates speech from text.
  Maps to `experimental_generateSpeech` in Vercel AI SDK.
  """
  def generate_speech(opts) do
    opts = normalize_opts(opts)
    text = opts[:input] || opts[:text]
    model = opts[:model] || OpenAI
    
    model.generate_speech(text, opts)
  end

  @doc """
  Generates an image from a prompt.
  """
  def generate_image(opts) do
    opts = normalize_opts(opts)
    prompt = opts[:prompt]
    model = opts[:model] || OpenAI
    
    model.generate_image(prompt, opts)
  end

  @doc """
  Calculates the cosine similarity between two vectors.
  """
  def cosine_similarity(v1, v2) when is_list(v1) and is_list(v2) do
    if length(v1) != length(v2) do
      raise ArgumentError, "Vectors must have the same length"
    end

    dot_product = Enum.zip(v1, v2) |> Enum.map(fn {a, b} -> a * b end) |> Enum.sum()
    magnitude1 = :math.sqrt(Enum.map(v1, &(&1 * &1)) |> Enum.sum())
    magnitude2 = :math.sqrt(Enum.map(v2, &(&1 * &1)) |> Enum.sum())

    if magnitude1 == 0 or magnitude2 == 0 do
      0.0
    else
      dot_product / (magnitude1 * magnitude2)
    end
  end

  @doc """
  Embeds a single value.
  """
  def embed(opts) do
    value = opts[:value]
    opts = normalize_opts(opts)
    model = opts[:model] || OpenAI
    
    case model.embed_many([value], opts) do
      {:ok, [embedding]} -> {:ok, %{embedding: embedding}}
      error -> error
    end
  end

  @doc """
  Embeds multiple values.
  """
  def embed_many(opts) do
    values = opts[:values]
    opts = normalize_opts(opts)
    model = opts[:model] || OpenAI
    
    case model.embed_many(values, opts) do
      {:ok, embeddings} -> {:ok, %{embeddings: embeddings}}
      error -> error
    end
  end

  # --- Provider Factories ---

  @doc "Factory for OpenAI models"
  def openai(model_id, opts \\ []), do: OpenAI.chat(model_id, opts)

  defmodule Agent do
    @moduledoc """
    High-level Agent class for managing loops, tools, and state.
    """
    defstruct [:model, :system, :tools, :max_steps, :description]

    def new(opts) do
      struct!(__MODULE__, opts)
    end

    def stream_text(agent, opts) do
      opts = Keyword.merge([
        model: agent.model,
        system: agent.system,
        tools: agent.tools,
        max_steps: agent.max_steps
      ], opts)
      NexAI.stream_text(opts)
    end

    def generate_text(agent, opts) do
      opts = Keyword.merge([
        model: agent.model,
        system: agent.system,
        tools: agent.tools,
        max_steps: agent.max_steps
      ], opts)
      NexAI.generate_text(opts)
    end
  end

  def agent(opts), do: Agent.new(normalize_opts(opts))

  defmodule StreamTextResult do
    @moduledoc """
    The result of a `stream_text` call. 
    Contains the logic to execute the stream but is decoupled from HTTP responses.
    """
    defstruct [:logic, :opts, :messages]
  end

  defmodule StreamObjectResult do
    @moduledoc """
    The result of a `stream_object` call.
    """
    defstruct [:logic, :opts, :schema]
  end

  @doc """
  Generates a typed, structured object.
  Deprecated: Use generate_text with output: NexAI.Output.object(schema) instead.
  """
  def generate_object(opts) do
    Logger.warning("NexAI.generate_object/1 is deprecated. Use NexAI.generate_text/1 with output: NexAI.Output.object(schema) instead.")
    opts = normalize_opts(opts)
    schema = opts[:schema]
    
    generate_text(Keyword.put(opts, :output, NexAI.Output.object(schema)))
    |> case do
      {:ok, %{object: _object} = res} -> {:ok, res} # generate_text now returns object if configured
      error -> error
    end
  end

  @doc """
  Streams a structured object.
  Deprecated: Use stream_text with output: NexAI.Output.object(schema) instead.
  """
  def stream_object(opts) do
    Logger.warning("NexAI.stream_object/1 is deprecated. Use NexAI.stream_text/1 with output: NexAI.Output.object(schema) instead.")
    opts = normalize_opts(opts)
    schema = opts[:schema]
    
    stream_text(Keyword.put(opts, :output, NexAI.Output.object(schema)))
  end

  @doc """
  Streams text from a language model.
  """
  def stream_text(opts) do
    opts = normalize_opts(opts)
    
    # Handle output parameter for structured streaming
    {opts, output_config} = handle_output_config(opts)
    
    system = opts[:system]
    messages = convert_to_core_messages(opts[:messages] || [])
    
    messages = if system do
      [%{"role" => "system", "content" => system} | messages]
    else
      messages
    end
    
    # Check if we are in object streaming mode
    opts = if output_config && output_config.mode == :object do
      Keyword.put(opts, :output_mode, :object)
    else
      opts
    end

    logic = fn send_fn, adapter_type ->
      do_stream_text(opts[:model], messages, opts[:tools] || [], opts[:max_steps] || 1, send_fn, 0, opts, adapter_type)
    end

    %StreamTextResult{logic: logic, opts: opts, messages: messages}
  end

  @doc """
  Converts to AI SDK 6 Data Stream Protocol (JSON over SSE).
  Sets 'x-vercel-ai-data-stream: v1' header.
  """
  def to_data_stream(%StreamTextResult{logic: logic}) do
    body_fn = fn send -> 
      logic.(send, :data_protocol)
      send.("[DONE]")
    end
    
    case response_module() do
      nil -> body_fn
      mod ->
        Kernel.struct(mod, [
          status: 200,
          content_type: "text/event-stream",
          body: body_fn,
          headers: %{
            "cache-control" => "no-cache, no-transform",
            "connection" => "keep-alive",
            "x-vercel-ai-data-stream" => "v1"
          }
        ])
    end
  end


  @doc """
  Converts a `StreamTextResult` to Datastar Signal Patches.
  If used within a Nex application, returns a `%Nex.Response{}` (SSE).
  Otherwise, returns a generic body function.
  """
  def to_datastar(%StreamTextResult{logic: logic, opts: opts}, datastar_opts \\ []) do
    datastar_opts = normalize_opts(datastar_opts)
    signal_name = to_string(datastar_opts[:signal] || "aiResponse")
    status_signal = to_string(datastar_opts[:status_signal] || "aiStatus")
    messages_signal = datastar_opts[:messages_signal] || (if opts[:messages], do: "messages", else: nil)

    body_fn = fn send ->
      adapter_send = fn type, payload ->
        case type do
          :text ->
            acc = Process.get(:nex_ai_full_acc)
            send.(%{event: "datastar-patch-signals", data: "signals {#{Jason.encode!(signal_name)}: #{Jason.encode!(acc)}}"})
          :tool_call ->
            send.(%{event: "datastar-patch-signals", data: "signals {#{Jason.encode!(status_signal)}: \"Calling #{payload.toolName}...\"}"})
          :stream_finish ->
            patches = %{status_signal => "Ready", "isLoading" => false}
            patches = if messages_signal do
              updated = opts[:messages] ++ [%{role: "assistant", content: Process.get(:nex_ai_full_acc)}]
              patches |> Map.put(to_string(messages_signal), updated) |> Map.put(to_string(signal_name), "")
            else
              patches
            end
            send.(%{event: "datastar-patch-signals", data: "signals #{Jason.encode!(patches)}"})
          _ -> :ok
        end
      end

      logic.(adapter_send, :datastar)
    end

    case response_module() do
      nil -> body_fn
      mod ->
        Kernel.struct(mod, [
          status: 200,
          content_type: "text/event-stream; charset=utf-8",
          body: body_fn,
          headers: %{
            "cache-control" => "no-cache, no-transform",
            "connection" => "keep-alive"
          }
        ])
    end
  end

  @doc """
  Converts to a raw Elixir Stream.
  """
  def to_text_stream(%StreamTextResult{logic: logic, opts: opts}) do
    timeout = opts[:timeout] || 15_000

    Stream.resource(
      fn ->
        parent = self()
        spawn_link(fn ->
          logic.(fn type, payload -> 
            case type do
              :text -> send(parent, {:nex_ai_chunk, payload})
              :stream_finish -> send(parent, :nex_ai_done)
              _ -> :ok
            end
          end, :custom)
        end)
      end,
      fn pid ->
        receive do
          {:nex_ai_chunk, chunk} -> {[chunk], pid}
          :nex_ai_done -> {:halt, pid}
        after
          timeout -> {:halt, pid}
        end
      end,
      fn _pid -> :ok end
    )
  end

  # --- Internal Recursive AI Engine ---

  defp do_stream_text(model, messages, tools, max_steps, send, step, opts, adapter_type) do
    if step >= max_steps do
      :ok
    else
      provider = model || OpenAI
      # Initial state for accumulation
      state = %{tool_calls: %{}, last_usage: nil, full_text: ""}
      
      final_state = Enum.reduce(provider.stream_text(messages, Keyword.merge(opts, [tools: tools])), state, fn chunk, acc ->
        process_chunk(chunk, send, acc, opts, adapter_type)
      end)
      
      if step + 1 < max_steps and map_size(final_state.tool_calls) > 0 do
        tool_results_messages = execute_tools(final_state.tool_calls, tools, send, opts, adapter_type)
        
        assistant_msg = %{
          "role" => "assistant",
          "content" => nil,
          "tool_calls" => Enum.map(final_state.tool_calls, fn {_, v} -> 
            %{id: v.id, type: "function", function: %{name: v.name, arguments: v.args}}
          end)
        }
        
        new_messages = messages ++ [assistant_msg] ++ tool_results_messages

        if opts[:on_step_finish], do: opts[:on_step_finish].(%{text: final_state.full_text, toolCalls: final_state.tool_calls, toolResults: tool_results_messages})
        
        do_stream_text(model, new_messages, tools, max_steps, send, step + 1, opts, adapter_type)
      else
        full_content = final_state.full_text
        send_via_adapter(send, :stream_finish, %{revisionId: "final"}, adapter_type)
        
        assistant_message = %{role: "assistant", content: full_content}
        all_messages = messages ++ [assistant_message]

        if opts[:on_finish] do
          opts[:on_finish].(%{
            text: full_content, 
            usage: final_state.last_usage, 
            finishReason: "stop", 
            messages: all_messages,
            toolCalls: final_state.tool_calls,
            toolResults: [] 
          })
        end
      end
    end
  end

  defp process_chunk(%{"choices" => [%{"delta" => delta} | _]}, send, acc, opts, adapter_type) do
    acc = if content = delta["content"] do
      new_full = acc.full_text <> content
      if opts[:on_token], do: opts[:on_token].(content)
      
      event_type = if opts[:output_mode] == :object, do: :object_delta, else: :text
      send_via_adapter(send, event_type, content, adapter_type)
      
      %{acc | full_text: new_full}
    else
      acc
    end

    if tool_calls = delta["tool_calls"] do
      updated_tool_calls = Enum.reduce(tool_calls, acc.tool_calls, fn tc, inner_acc ->
        idx = tc["index"]
        existing = inner_acc[idx] || %{id: nil, name: nil, args: ""}
        
        # Detect start
        if is_nil(existing.id) and not is_nil(tc["id"]) do
          send_via_adapter(send, :tool_call_start, %{toolCallId: tc["id"], toolName: tc["function"]["name"]}, adapter_type)
        end

        # Detect delta
        if arg_delta = tc["function"]["arguments"] do
          send_via_adapter(send, :tool_call_delta, %{toolCallId: tc["id"] || existing.id, inputTextDelta: arg_delta}, adapter_type)
        end

        updated = %{
          id: tc["id"] || existing.id,
          name: tc["function"]["name"] || existing.name,
          args: existing.args <> (tc["function"]["arguments"] || "")
        }
        Map.put(inner_acc, idx, updated)
      end)
      %{acc | tool_calls: updated_tool_calls}
    else
      acc
    end
  end

  defp process_chunk(%{"usage" => usage}, _send, acc, _opts, _adapter), do: %{acc | last_usage: format_usage(usage)}
  defp process_chunk(_, _send, acc, _opts, _adapter), do: acc

  defp execute_tools(tool_calls, tools, send, _opts, adapter_type) do
    Enum.map(tool_calls, fn {_, tc} ->
      send_via_adapter(send, :tool_call, %{toolCallId: tc.id, toolName: tc.name, args: Jason.decode!(tc.args)}, adapter_type)
      tool_def = Enum.find(tools, &(&1.name == tc.name))
      result = if tool_def && tool_def.execute do
        try do
          tool_def.execute.(Jason.decode!(tc.args)) |> Jason.encode!()
        rescue e -> "Error: #{inspect(e)}" end
      else
        "Tool not found"
      end
      send_via_adapter(send, :tool_result, %{toolCallId: tc.id, result: result}, adapter_type)
      %{"role" => "tool", "tool_call_id" => tc.id, "content" => result}
    end)
  end

  defp handle_output_config(opts) do
    case opts[:output] do
      %{mode: mode, schema: schema} = config when mode in [:object, :array, :enum, :json] ->
        system_instruction = "You must return a JSON object matching this schema: #{Jason.encode!(schema)}"
        opts = opts
          |> Keyword.put(:response_format, %{type: "json_object"})
          |> Keyword.update(:system, system_instruction, fn existing -> "#{existing}\n\n#{system_instruction}" end)
        {opts, config}
      _ ->
        {opts, nil}
    end
  end

  defp process_generated_result({:ok, %{text: text} = res}, %{mode: mode} = _config) when mode in [:object, :array, :enum, :json] do
    # Strip Markdown code blocks
    clean_text = text
      |> String.replace(~r/^```json\s*/, "")
      |> String.replace(~r/\s*```$/, "")
      |> String.trim()

    case Jason.decode(clean_text) do
      {:ok, object} -> {:ok, Map.put(res, :object, object)}
      _ -> {:error, :invalid_json}
    end
  end
  defp process_generated_result(result, _), do: result

  defp send_via_adapter(send_fn, type, payload, :data_protocol), do: send_fn.(Protocol.encode(type, payload))
  defp send_via_adapter(send_fn, type, payload, :datastar), do: send_fn.(type, payload)

  defp normalize_opts(opts) do
    mapping = [
      {:maxSteps, :max_steps}, 
      {:onFinish, :on_finish}, 
      {:onToken, :on_token},
      {:onStepFinish, :on_step_finish},
      {:messagesSignal, :messages_signal},
      {:statusSignal, :status_signal}
    ]
    Enum.reduce(mapping, opts, fn {camel, snake}, acc ->
      if val = acc[camel], do: Keyword.put(acc, snake, val), else: acc
    end)
  end

  defp format_usage(u), do: %{promptTokens: u["prompt_tokens"], completionTokens: u["completion_tokens"], totalTokens: u["total_tokens"]}
  
  def generate_text(opts) when is_list(opts) do
    opts = normalize_opts(opts)
    
    # Handle output parameter for structured generation
    {opts, output_config} = handle_output_config(opts)
    
    system = opts[:system]
    messages = convert_to_core_messages(opts[:messages] || [])
    
    messages = if system do
      [%{"role" => "system", "content" => system} | messages]
    else
      messages
    end

    model = opts[:model] || OpenAI
    
    case model.generate_text(messages, opts) do
      {:ok, result} -> process_generated_result(result, output_config)
      error -> error
    end
  end

  def generate_text(messages, opts) do
    generate_text(Keyword.put(opts, :messages, messages))
  end

  @doc """
  Converts UI messages or simple message lists to Core Messages.
  Handles normalizing roles and content formats.
  """
  def convert_to_core_messages(messages) when is_list(messages) do
    Enum.map(messages, fn
      %{"role" => role, "content" => content} = msg ->
        %{
          "role" => to_string(role),
          "content" => format_content(content),
          "tool_calls" => msg["tool_calls"],
          "tool_call_id" => msg["tool_call_id"]
        }
        |> Enum.reject(fn {_, v} -> is_nil(v) end)
        |> Map.new()

      %{role: role, content: content} = msg ->
        %{
          "role" => to_string(role),
          "content" => format_content(content),
          "tool_calls" => msg[:tool_calls],
          "tool_call_id" => msg[:tool_call_id]
        }
        |> Enum.reject(fn {_, v} -> is_nil(v) end)
        |> Map.new()
      
      other -> other
    end)
  end

  defp format_content(content) when is_list(content) do
    Enum.map(content, fn
      %{"type" => "text", "text" => text} -> %{type: "text", text: text}
      %{type: "text", text: text} -> %{type: "text", text: text}
      %{"type" => "image", "image" => img} = part -> 
        %{type: "image", image: img, mime_type: part["mime_type"] || part["mimeType"] || part[:mime_type] || part[:mimeType]}
      %{type: "image", image: img} = part ->
        %{type: "image", image: img, mime_type: part[:mime_type] || part[:mimeType] || part["mime_type"] || part["mimeType"]}
      other -> other
    end)
  end
  defp format_content(content), do: content

  def tool(opts), do: NexAI.Tool.new(opts)

  defp response_module do
    case Code.ensure_compiled(Nex.Response) do
      {:module, mod} -> mod
      _ -> nil
    end
  end
end
