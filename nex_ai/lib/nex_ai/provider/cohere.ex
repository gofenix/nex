defmodule NexAI.Provider.Cohere do
  @moduledoc """
  Cohere Provider for NexAI.
  Implements the LanguageModel protocol for Cohere's models.
  """
  alias NexAI.LanguageModel.Protocol, as: ModelProtocol
  alias NexAI.Result.{Usage, ToolCall}
  alias NexAI.LanguageModel.{GenerateResult, StreamResult, StreamPart, ResponseMetadata}

  defstruct [:api_key, :base_url, model: "command-r-plus", config: %{}]

  @default_base_url "https://api.cohere.ai/v1"

  def chat(model_id, opts \\ []) do
    %__MODULE__{
      model: model_id,
      api_key: opts[:api_key] || Application.get_env(:nex_ai, :cohere_api_key) || System.get_env("COHERE_API_KEY"),
      base_url: opts[:base_url] || Application.get_env(:nex_ai, :cohere_base_url) || System.get_env("COHERE_BASE_URL") || @default_base_url,
      config: Map.new(opts)
    }
  end

  defimpl ModelProtocol do
    alias NexAI.Provider.Cohere

    def provider(_model), do: "cohere"
    def model_id(model), do: model.model

    def do_generate(model, params) do
      url = model.base_url <> "/chat"
      {message, chat_history} = Cohere.format_messages(params.prompt)

      body = %{
        model: model.model,
        message: message,
        chat_history: chat_history
      }

      body = if params.tools && length(params.tools) > 0 do
        Map.put(body, :tools, Cohere.format_tools(params.tools))
      else
        body
      end

      body = Map.merge(body, model.config)

      finch_name = model.config[:finch] || NexAI.Finch
      case Req.post(url, json: body, auth: {:bearer, model.api_key}, finch: finch_name) do
        {:ok, %{status: 200, body: body, headers: headers}} ->
          {:ok, %GenerateResult{
            content: [%{type: "text", text: body["text"]}],
            tool_calls: Cohere.extract_tool_calls(body["tool_calls"]),
            finish_reason: Cohere.map_finish_reason(body["finish_reason"]),
            usage: Cohere.format_usage(body["meta"]),
            response: %ResponseMetadata{
              id: body["generation_id"],
              model_id: model.model,
              timestamp: System.system_time(:second),
              headers: Map.new(headers)
            },
            raw_call: %{model_id: model.model, provider: "cohere", params: options},
            raw_response: body
          }}

        {:ok, %{status: 429, body: body}} ->
          {:error, %NexAI.Error.RateLimitError{message: body["message"] || "Rate limit reached"}}

        {:ok, %{status: status, body: body}} ->
          {:error, %NexAI.Error.APIError{message: body["message"], status: status, raw: body}}

        {:error, reason} ->
          {:error, reason}
      end
    end

    def do_stream(model, params) do
      url = model.base_url <> "/chat"
      {message, chat_history} = Cohere.format_messages(params.prompt)

      body = %{
        model: model.model,
        message: message,
        chat_history: chat_history,
        stream: true
      }

      body = if params.tools && length(params.tools) > 0 do
        Map.put(body, :tools, Cohere.format_tools(params.tools))
      else
        body
      end

      body = Map.merge(body, model.config)

      parent = self()
      receive_timeout = params.config[:receive_timeout] || 30_000

      Stream.resource(
        fn ->
          task = Task.Supervisor.async_nolink(NexAI.TaskSupervisor, fn ->
            finch_name = model.config[:finch] || NexAI.Finch
            Req.post(url,
              json: body,
              auth: {:bearer, model.api_key},
              finch: finch_name,
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
          %{task: task, buffer: "", done: false, response_sent: false}
        end,
        fn
          %{done: true} = state -> {:halt, state}
          state ->
            receive do
              {:stream_data, pid, data} ->
                {lines, new_buffer} = Cohere.process_line_buffer(state.buffer <> data)
                raw_chunks = Cohere.parse_lines(lines)
                send(pid, :ack)
                {parts, state} = Cohere.map_to_stream_parts(raw_chunks, state)
                {parts, %{state | buffer: new_buffer}}

              :stream_done ->
                {lines, _} = Cohere.process_line_buffer(state.buffer, true)
                raw_chunks = Cohere.parse_lines(lines)
                {parts, state} = Cohere.map_to_stream_parts(raw_chunks, state)
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
    end
  end

  def format_messages(messages) do
    messages = NexAI.Message.normalize(messages)

    last_msg = List.last(messages)
    message = if last_msg && last_msg.role == "user" do
      if is_struct(last_msg), do: last_msg.content, else: last_msg["content"]
    else
      ""
    end

    chat_history = messages
    |> Enum.slice(0..-2//1)
    |> Enum.map(fn msg ->
      role = if is_struct(msg), do: msg.role, else: msg["role"] || msg[:role]
      content = if is_struct(msg), do: msg.content, else: msg["content"] || msg[:content]

      %{
        role: if(to_string(role) == "assistant", do: "CHATBOT", else: "USER"),
        message: to_string(content)
      }
    end)

    {message, chat_history}
  end

  def format_tools(tools) do
    Enum.map(tools, fn tool ->
      %{
        name: tool.name,
        description: tool.description,
        parameter_definitions: convert_parameters(tool.parameters)
      }
    end)
  end

  defp convert_parameters(%{"properties" => props, "required" => required}) do
    Enum.into(props, %{}, fn {name, schema} ->
      {name, %{
        description: schema["description"],
        type: String.upcase(schema["type"] || "string"),
        required: name in (required || [])
      }}
    end)
  end
  defp convert_parameters(_), do: %{}

  def extract_tool_calls(nil), do: []
  def extract_tool_calls(calls) do
    Enum.map(calls, fn tc ->
      %ToolCall{
        toolCallId: :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower),
        toolName: tc["name"],
        args: tc["parameters"] || %{}
      }
    end)
  end

  def map_finish_reason("COMPLETE"), do: "stop"
  def map_finish_reason("MAX_TOKENS"), do: "length"
  def map_finish_reason("TOOL_CALL"), do: "tool-calls"
  def map_finish_reason(_), do: "unknown"

  def format_usage(%{"tokens" => tokens}) do
    %Usage{
      promptTokens: tokens["input_tokens"] || 0,
      completionTokens: tokens["output_tokens"] || 0,
      totalTokens: (tokens["input_tokens"] || 0) + (tokens["output_tokens"] || 0)
    }
  end
  def format_usage(_), do: nil

  def process_line_buffer(buffer, final \\ false) do
    if String.contains?(buffer, "\n") do
      parts = String.split(buffer, ~r/\r?\n/)
      {complete, [rest]} = Enum.split(parts, length(parts) - 1)
      {complete, rest}
    else
      if final and buffer != "", do: {[buffer], ""}, else: {[], buffer}
    end
  end

  def parse_lines(lines) do
    lines
    |> Enum.map(&String.trim/1)
    |> Enum.filter(&(&1 != ""))
    |> Enum.flat_map(fn line ->
      case Jason.decode(line) do
        {:ok, decoded} -> [decoded]
        _ -> []
      end
    end)
  end

  def map_to_stream_parts(raw_chunks, state) do
    Enum.reduce(raw_chunks, {[], state}, fn chunk, {acc, st} ->
      {new_parts, st} = do_map_chunk_to_part(chunk, st)
      {acc ++ new_parts, st}
    end)
  end

  defp do_map_chunk_to_part(chunk, state) do
    chunks = []

    {chunks, state} = if not state.response_sent and chunk["generation_id"] do
      meta = %ResponseMetadata{
        id: chunk["generation_id"],
        model_id: chunk["model"],
        timestamp: System.system_time(:second)
      }
      {chunks ++ [%StreamPart{type: :response_metadata, response: meta}], %{state | response_sent: true}}
    else
      {chunks, state}
    end

    chunks = case chunk["event_type"] do
      "text-generation" ->
        if text = chunk["text"] do
          chunks ++ [%StreamPart{type: :text_delta, text: text}]
        else
          chunks
        end

      "tool-calls-generation" ->
        if tool_calls = chunk["tool_calls"] do
          Enum.reduce(tool_calls, chunks, fn tc, acc ->
            id = :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
            acc ++ [
              %StreamPart{type: :tool_call_start, tool_call_id: id, tool_name: tc["name"]},
              %StreamPart{type: :tool_call_delta, tool_call_id: id, args_delta: Jason.encode!(tc["parameters"] || %{})}
            ]
          end)
        else
          chunks
        end

      "stream-end" ->
        finish_reason = map_finish_reason(chunk["finish_reason"])
        usage = format_usage(chunk["response"])
        chunks = chunks ++ [%StreamPart{type: :finish, finish_reason: finish_reason}]
        if usage, do: chunks ++ [%StreamPart{type: :usage, usage: usage}], else: chunks

      _ -> chunks
    end

    {chunks, state}
  end
end
