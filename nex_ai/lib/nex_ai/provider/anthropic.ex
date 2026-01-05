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

      case Req.post(model.base_url <> "/messages",
        json: body,
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
        {:ok, res} -> {:error, res.body}
        {:error, reason} -> {:error, reason}
      end
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

      Stream.resource(
        fn ->
          Task.async(fn ->
            Req.post(model.base_url <> "/messages",
              json: body,
              headers: [
                {"x-api-key", model.api_key},
                {"anthropic-version", Anthropic.api_version()}
              ],
              into: fn {:data, data}, acc ->
                send(parent, {:stream_data, data})
                {:cont, acc}
              end
            )
            send(parent, :stream_done)
          end)
        end,
        fn task ->
          receive do
            {:stream_data, data} -> {Anthropic.parse_sse(data), task}
            :stream_done -> {:halt, task}
          after 30_000 -> {:halt, task}
          end
        end,
        fn task -> Task.shutdown(task) end
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

  def parse_sse(data) do
    # Anthropic SSE is slightly different (event/data lines)
    data
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.flat_map(fn
      "data: " <> json ->
        case Jason.decode(json) do
          {:ok, %{"type" => "content_block_delta", "delta" => %{"text" => text}}} -> 
            # Map to OpenAI style for the Facade to consume easily
            [%{"choices" => [%{"delta" => %{"content" => text}}]}]
          {:ok, %{"type" => "message_delta", "usage" => usage}} ->
            [%{"usage" => %{"prompt_tokens" => 0, "completion_tokens" => usage["output_tokens"], "total_tokens" => 0}}]
          _ -> []
        end
      _ -> []
    end)
  end
end
