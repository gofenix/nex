defmodule NexAI.Provider.Anthropic do
  @moduledoc """
  Anthropic (Claude) Provider for NexAI.
  """
  alias NexAI.LanguageModel.Protocol, as: ModelProtocol
  alias NexAI.Result.{Usage, Response, ToolCall}

  defstruct [:api_key, :base_url, model: "claude-3-5-sonnet-latest", config: %{}]

  @default_base_url "https://api.anthropic.com/v1"
  @api_version "2023-06-01"

  def claude(model_id, opts \\ []) do
    %__MODULE__{
      model: model_id,
      api_key: opts[:api_key] || System.get_env("ANTHROPIC_API_KEY"),
      base_url: opts[:base_url] || System.get_env("ANTHROPIC_BASE_URL") || @default_base_url,
      config: Map.new(opts)
    }
  end

  defimpl ModelProtocol do
    alias NexAI.Provider.Anthropic
    alias NexAI.Result.{Usage, Response, ToolCall}

    def do_generate(model, params) do
      {system, messages} = Anthropic.extract_system(params.prompt)
      
      body = %{
        model: model.model,
        messages: Anthropic.format_messages(messages),
        system: system,
        max_tokens: model.config[:max_tokens] || 4096,
        stream: false
      }

      body = if params.tools, do: Map.put(body, :tools, Anthropic.format_tools(params.tools)), else: body

      metadata = %{model: model.model, provider: :anthropic}
      :telemetry.span([:nex_ai, :provider, :request], metadata, fn ->
        finch_name = model.config[:finch] || NexAI.Finch
        res = case Req.post(model.base_url <> "/messages",
          json: body,
          finch: finch_name,
          headers: [
            {"x-api-key", model.api_key},
            {"anthropic-version", Anthropic.api_version()}
          ]
        ) do
          {:ok, %{status: 200, body: body, headers: headers}} ->
            content_block = Enum.find(body["content"], &(&1["type"] == "text"))
            tool_blocks = Enum.filter(body["content"], &(&1["type"] == "tool_use"))

            {:ok, %{
              text: if(content_block, do: content_block["text"]),
              tool_calls: Anthropic.extract_tool_calls(tool_blocks),
              finish_reason: Anthropic.map_finish_reason(body["stop_reason"]),
              usage: Anthropic.format_usage(body["usage"]),
              response: %Response{
                id: body["id"],
                modelId: body["model"],
                timestamp: System.system_time(:second),
                headers: Map.new(headers)
              },
              raw: body
            }}
          {:ok, %{status: 429, body: body}} ->
            {:error, %NexAI.Error.RateLimitError{message: get_in(body, ["error", "message"]) || "Rate limit reached"}}
          {:ok, %{status: status, body: body}} ->
            {:error, %NexAI.Error.APIError{message: get_in(body, ["error", "message"]), status: status, type: get_in(body, ["error", "type"]), raw: body}}
          {:error, reason} ->
            {:error, reason}
        end
        {res, Map.put(metadata, :result, res)}
      end)
    end

    def do_stream(model, params) do
      {system, messages} = Anthropic.extract_system(params.prompt)
      
      body = %{
        model: model.model,
        messages: Anthropic.format_messages(messages),
        system: system,
        max_tokens: model.config[:max_tokens] || 4096,
        stream: true
      }

      body = if params.tools, do: Map.put(body, :tools, Anthropic.format_tools(params.tools)), else: body
      parent = self()
      receive_timeout = params.config[:receive_timeout] || 30_000

      Stream.resource(
        fn ->
          task = Task.Supervisor.async_nolink(NexAI.TaskSupervisor, fn ->
            finch_name = model.config[:finch] || NexAI.Finch
            Req.post(model.base_url <> "/messages",
              json: body,
              finch: finch_name,
              headers: [
                {"x-api-key", model.api_key},
                {"anthropic-version", Anthropic.api_version()}
              ],
              into: fn {:data, data}, acc ->
                send(parent, {:stream_data, self(), data})
                receive do
                  :ack -> {:cont, acc}
                after
                  receive_timeout -> {:halt, acc}
                end
              end
            )
            send(parent, :stream_done)
          end)
          %{task: task, buffer: "", done: false}
        end,
        fn 
          %{done: true} = state -> {:halt, state}
          state ->
            receive do
              {:stream_data, pid, data} ->
                {lines, new_buffer} = Anthropic.process_line_buffer(state.buffer <> data)
                chunks = Anthropic.parse_lines(lines)
                send(pid, :ack)
                {chunks, %{state | buffer: new_buffer}}

              :stream_done ->
                {lines, _} = Anthropic.process_line_buffer(state.buffer, true)
                {Anthropic.parse_lines(lines), %{state | done: true, buffer: ""}}
            after
              receive_timeout ->
                Task.shutdown(state.task)
                err = %NexAI.Error.TimeoutError{message: "NexAI Streaming Timeout (Anthropic) after #{receive_timeout}ms", timeout_ms: receive_timeout}
                {[%{"error" => err}], %{state | done: true}}
            end
        end,
        fn state -> Task.shutdown(state.task) end
      )
    end
  end

  # --- Helpers ---

  def api_version, do: @api_version

  def extract_system(messages) do
    system = messages |> Enum.filter(&(&1["role"] == "system")) |> Enum.map(& &1["content"]) |> Enum.join("\n")
    messages = messages |> Enum.filter(&(&1["role"] != "system"))
    {if(system == "", do: nil, else: system), messages}
  end

  def format_messages(messages) do
    Enum.map(messages, fn msg ->
      %{
        "role" => if(msg["role"] == "assistant", do: "assistant", else: "user"),
        "content" => format_content(msg["content"], msg["tool_calls"])
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

  def extract_tool_calls(blocks) do
    Enum.map(blocks, fn b -> 
      %ToolCall{toolCallId: b["id"], toolName: b["name"], args: b["input"]}
    end)
  end

  def map_finish_reason("end_turn"), do: "stop"
  def map_finish_reason("max_tokens"), do: "length"
  def map_finish_reason("tool_use"), do: "tool-calls"
  def map_finish_reason(_), do: "unknown"

  def format_usage(%{"input_tokens" => i, "output_tokens" => o}) do
    %Usage{promptTokens: i, completionTokens: o, totalTokens: i + o}
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
