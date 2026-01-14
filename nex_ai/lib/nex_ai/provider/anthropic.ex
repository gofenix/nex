defmodule NexAI.Provider.Anthropic do
  @moduledoc """
  Anthropic Provider for NexAI.
  Implements the LanguageModel protocol for Anthropic's Claude models.
  """
  alias NexAI.LanguageModel.Protocol, as: ModelProtocol
  alias NexAI.Result.Usage
  alias NexAI.LanguageModel.{GenerateResult, StreamResult, StreamPart, ResponseMetadata}

  defstruct [:api_key, :base_url, model: "claude-3-5-sonnet-latest", config: %{}]

  require Logger

  @default_base_url "https://api.anthropic.com/v1/messages"

  @doc "Factory function to create an Anthropic model instance"
  def claude(model_id, opts \\ []) do
    base_url = opts[:base_url] || Application.get_env(:nex_ai, :anthropic_base_url) || System.get_env("ANTHROPIC_BASE_URL") || @default_base_url

    %__MODULE__{
      model: model_id,
      api_key: opts[:api_key] || Application.get_env(:nex_ai, :anthropic_api_key) || System.get_env("ANTHROPIC_API_KEY"),
      base_url: base_url,
      config: Map.new(opts)
    }
  end

  defimpl ModelProtocol do
    alias NexAI.Provider.Anthropic
    alias NexAI.LanguageModel.{GenerateResult, StreamResult, StreamPart, ResponseMetadata}

    def provider(_model), do: "anthropic"
    def model_id(model), do: model.model

    def do_generate(model, options) do
      url = model.base_url
      {system_messages, messages} = Anthropic.extract_system(options.prompt)
      messages = Anthropic.format_messages(messages)

      body = %{
        model: model.model,
        messages: messages,
        stream: false
      }
      body = if system_messages != "", do: Map.put(body, :system, system_messages), else: body
      body = if options.tools && length(options.tools) > 0, do: Map.put(body, :tools, Anthropic.format_tools(options.tools)), else: body
      body = if tc = options.tool_choice, do: Map.put(body, :tool_choice, tc), else: body
      body = Map.merge(body, model.config)

      metadata = %{model: model.model, provider: :anthropic}
      :telemetry.span([:nex_ai, :provider, :request], metadata, fn ->
        finch_name = model.config[:finch] || NexAI.Finch
        res = case Req.post(url,
          json: body,
          auth: {:bearer, model.api_key},
          headers: %{"anthropic-version" => "2023-06-01"},
          finch: finch_name
        ) do
          {:ok, %{status: 200, body: body}} ->
            content = Anthropic.build_content(body)

            {:ok, %GenerateResult{
              content: content,
              finish_reason: Anthropic.map_finish_reason(body["stop_reason"]),
              usage: Anthropic.format_usage(body["usage"]),
              raw_call: %{model_id: model.model, provider: "anthropic", params: options},
              raw_response: body,
              response: %ResponseMetadata{
                id: body["id"],
                model_id: body["model"],
                timestamp: nil
              }
            }}
          {:ok, %{status: 401, body: body}} ->
            error_msg = case body do
              %{"error" => %{"message" => msg}} -> msg
              %{"message" => msg} -> msg
              msg when is_binary(msg) -> msg
              _ -> nil
            end
            {:error, %NexAI.Error.AuthenticationError{message: error_msg || "Invalid API Key", status: 401, raw: body}}
          {:ok, %{status: 429, body: body}} ->
            error_msg = case body do
              %{"error" => %{"message" => msg}} -> msg
              %{"message" => msg} -> msg
              msg when is_binary(msg) -> msg
              _ -> nil
            end
            {:error, %NexAI.Error.RateLimitError{message: error_msg || "Rate limit reached"}}
          {:ok, %{status: 400, body: body}} ->
            error_msg = case body do
              %{"error" => %{"message" => msg}} -> msg
              %{"message" => msg} -> msg
              msg when is_binary(msg) -> msg
              _ -> nil
            end
            {:error, %NexAI.Error.InvalidRequestError{message: error_msg, status: 400, raw: body}}
          {:ok, %{status: status, body: body}} ->
            error_msg = case body do
              %{"error" => %{"message" => msg}} -> msg
              %{"message" => msg} -> msg
              msg when is_binary(msg) -> msg
              _ -> nil
            end
            error_type = case body do
              %{"error" => %{"type" => t}} -> t
              _ -> nil
            end
            {:error, %NexAI.Error.APIError{message: error_msg, status: status, type: error_type, raw: body}}
          {:error, reason} ->
            {:error, reason}
        end
        {res, Map.put(metadata, :result, res)}
      end)
    end

    def do_stream(model, options) do
      url = model.base_url
      {system_messages, messages} = Anthropic.extract_system(options.prompt)
      messages = Anthropic.format_messages(messages)

      body = %{
        model: model.model,
        messages: messages,
        stream: true
      }
      body = if system_messages != "", do: Map.put(body, :system, system_messages), else: body
      body = if options.tools && length(options.tools) > 0, do: Map.put(body, :tools, Anthropic.format_tools(options.tools)), else: body
      body = if tc = options.tool_choice, do: Map.put(body, :tool_choice, tc), else: body
      body = Map.merge(body, model.config)

      parent = self()
      receive_timeout = options.config[:receive_timeout] || 30_000

      stream = Stream.resource(
        fn ->
          task = Task.Supervisor.async_nolink(NexAI.TaskSupervisor, fn ->
            finch_name = model.config[:finch] || NexAI.Finch
            Req.post(url,
              json: body,
              auth: {:bearer, model.api_key},
              headers: %{"anthropic-version" => "2023-06-01"},
              finch: finch_name,
              into: fn {:data, data}, acc ->
                send(parent, {:stream_data, self(), data})
                receive do :ack -> {:cont, acc} after receive_timeout -> {:halt, acc} end
              end
            )
            send(parent, :stream_done)
          end)

          %{task: task, buffer: "", done: false, response_sent: false}
        end,
        fn
          %{done: true} = state -> {:halt, state}
          state ->
            receive do
              {:stream_data, producer_pid, data} ->
                {lines, new_buffer} = Anthropic.process_line_buffer(state.buffer <> data)
                raw_chunks = Anthropic.parse_sse(lines)
                send(producer_pid, :ack)

                {parts, state} = Anthropic.map_to_stream_parts(raw_chunks, state)
                {parts, %{state | buffer: new_buffer}}

              :stream_done ->
                {lines, _} = Anthropic.process_line_buffer(state.buffer, true)
                raw_chunks = Anthropic.parse_sse(lines)
                {parts, state} = Anthropic.map_to_stream_parts(raw_chunks, state)
                {parts, %{state | done: true, buffer: ""}}

            after
              receive_timeout ->
                Task.shutdown(state.task)
                err = %NexAI.Error.TimeoutError{message: "NexAI Streaming Timeout after #{receive_timeout}ms", timeout_ms: receive_timeout}
                {[%StreamPart{type: :error, error: err}], %{state | done: true}}
            end
        end,
        fn state -> Task.shutdown(state.task) end
      )

      {:ok, %StreamResult{
        stream: stream,
        raw_call: %{model_id: model.model, provider: "anthropic", params: options}
      }}
    end
  end

  # --- Helpers ---

  def api_version, do: "2023-06-01"

  def build_content(body) do
    text_content = case extract_text(body) do
      nil -> []
      text -> [%{type: "text", text: text}]
    end

    tool_content = if tool_calls = extract_tool_calls(body["content"] || []) do
      Enum.map(tool_calls, fn tc ->
        %{
          type: "tool-call",
          toolCallId: tc.toolCallId,
          toolName: tc.toolName,
          args: tc.args
        }
      end)
    else
      []
    end

    text_content ++ tool_content
  end

  def extract_text(body) do
    case body["content"] do
      nil -> nil
      list when is_list(list) ->
        Enum.find_value(list, fn
          %{"type" => "text", "text" => text} -> text
          _ -> nil
        end)
      _ -> nil
    end
  end

  def extract_reasoning(_body), do: nil

  def map_to_stream_parts(raw_chunks, state) do
    Enum.reduce(raw_chunks, {[], state}, fn chunk, {acc, st} ->
      {new_parts, st} = do_map_chunk_to_part(chunk, st)
      {acc ++ new_parts, st}
    end)
  end

  defp do_map_chunk_to_part(chunk, state) do
    parts = []

    # 1. First chunk with ID/created usually contains response metadata
    {parts, state} = if not state.response_sent and chunk["id"] do
      meta = %ResponseMetadata{
        id: chunk["id"],
        model_id: chunk["model"],
        timestamp: nil
      }
      {parts ++ [%StreamPart{type: :response_metadata, response: meta}], %{state | response_sent: true}}
    else
      {parts, state}
    end

    # 2. Extract Delta
    delta = get_in(chunk, ["choices", Access.at(0), "delta"])

    parts = case delta && delta["content"] do
      nil -> parts
      content -> parts ++ [%StreamPart{type: :text_delta, text: content}]
    end

    # 3. Tool Calls
    parts = case delta && delta["tool_calls"] do
      nil -> parts
      tcs ->
        Enum.reduce(tcs, parts, fn tc, acc ->
          id = tc["id"]
          name = get_in(tc, ["function", "name"])
          args = get_in(tc, ["function", "arguments"])

          acc = if id, do: acc ++ [%StreamPart{type: :tool_call_start, tool_call_id: id, tool_name: name}], else: acc
          if args, do: acc ++ [%StreamPart{type: :tool_call_delta, tool_call_id: id, args_delta: args}], else: acc
        end)
    end

    # 4. Finish Reason
    finish_reason = get_in(chunk, ["choices", Access.at(0), "finish_reason"])
    parts = if finish_reason, do: parts ++ [%StreamPart{type: :finish, finish_reason: map_finish_reason(finish_reason)}], else: parts

    # 5. Usage
    parts = if usage = chunk["usage"], do: parts ++ [%StreamPart{type: :usage, usage: format_usage(usage)}], else: parts

    {parts, state}
  end

  def extract_system(messages) do
    system = messages |> Enum.filter(fn m -> m.role == "system" end) |> Enum.map(fn m -> m.content end) |> Enum.join("\n")
    messages = messages |> Enum.filter(fn m -> m.role != "system" end)
    {if(system == "", do: nil, else: system), messages}
  end

  def format_messages(messages) do
    Enum.map(messages, fn msg ->
      %{
        "role" => if(Map.get(msg, :role) == "assistant", do: "assistant", else: "user"),
        "content" => format_content(Map.get(msg, :content), Map.get(msg, :tool_calls))
      }
    end)
  end

  defp format_content(text, nil), do: text
  defp format_content(text, tool_calls) do
    blocks = if text, do: [%{type: "text", text: text}], else: []
    blocks ++ Enum.map(tool_calls, fn tc ->
      %{type: "tool_use", id: tc.toolCallId, name: tc.toolName, input: tc.args}
    end)
  end

  def format_tools(tools) do
    Enum.map(tools, fn tool ->
      %{
        name: tool.name,
        description: tool.description,
        input_schema: tool.parameters
      }
    end)
  end

  def extract_tool_calls(calls) do
    Enum.map(calls, fn tc ->
      %NexAI.Result.ToolCall{
        toolCallId: tc["id"],
        toolName: tc["name"],
        args: tc["input"]
      }
    end)
  end

  def map_finish_reason("end_turn"), do: "stop"
  def map_finish_reason("max_tokens"), do: "length"
  def map_finish_reason("tool_use"), do: "tool-calls"
  def map_finish_reason(_), do: "unknown"

  def format_usage(%{"input_tokens" => i, "output_tokens" => o}) do
    %Usage{promptTokens: i, completionTokens: o, totalTokens: i + o}
  end

  def parse_sse(lines) do
    parse_lines(lines)
  end

  def parse_lines(lines) do
    # Anthropic SSE is slightly different (event/data lines)
    lines
    |> Enum.map(&String.trim/1)
    |> Enum.flat_map(fn
      "data: " <> json ->
        case Jason.decode(json) do
          # 1. Text Delta
          {:ok, %{"type" => "content_block_delta", "index" => _idx, "delta" => %{"type" => "text_delta", "text" => text}}} ->
            [%{"choices" => [%{"index" => 0, "delta" => %{"content" => text}}]}]

          # 2. Tool Use Start
          {:ok, %{"type" => "content_block_start", "index" => idx, "content_block" => %{"type" => "tool_use", "id" => id, "name" => name}}} ->
            [%{"choices" => [%{"index" => 0, "delta" => %{"tool_calls" => [%{"index" => idx, "id" => id, "function" => %{"name" => name}}]}}]}]

          # 3. Tool Input Delta
          {:ok, %{"type" => "content_block_delta", "index" => idx, "delta" => %{"type" => "input_json_delta", "partial_json" => delta}}} ->
            [%{"choices" => [%{"index" => 0, "delta" => %{"tool_calls" => [%{"index" => idx, "function" => %{"arguments" => delta}}]}}]}]

          # 4. Usage / Message Delta
          {:ok, %{"type" => "message_delta", "usage" => usage}} ->
            [%{"usage" => %{"prompt_tokens" => 0, "completion_tokens" => usage["output_tokens"], "total_tokens" => 0}}]

          # 5. Error
          {:ok, %{"type" => "error", "error" => error}} ->
            [%{"error" => error}]

          _ -> []
        end
      _ -> []
    end)
  end

  def process_line_buffer(buffer, final \\ false) do
    if String.contains?(buffer, "\n") do
      parts = String.split(buffer, ~r/\r?\n/)
      {complete, [rest]} = Enum.split(parts, length(parts) - 1)
      {complete, rest}
    else
      if final and buffer != "", do: {[buffer], ""}, else: {[], buffer}
    end
  end
end
