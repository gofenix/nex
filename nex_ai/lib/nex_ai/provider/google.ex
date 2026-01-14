defmodule NexAI.Provider.Google do
  @moduledoc """
  Google Gemini Provider for NexAI.
  Implements the LanguageModel protocol (Vercel AI SDK v6).
  """
  alias NexAI.LanguageModel.Protocol, as: ModelProtocol
  alias NexAI.Result.Usage
  alias NexAI.LanguageModel.{GenerateResult, StreamResult, StreamPart, ResponseMetadata}

  defstruct [:api_key, :base_url, model: "gemini-1.5-flash", config: %{}]

  @default_base_url "https://generativelanguage.googleapis.com/v1beta"

  def gemini(model_id, opts \\ []) do
    %__MODULE__{
      model: model_id,
      api_key: opts[:api_key] || Application.get_env(:nex_ai, :google_api_key) || System.get_env("GOOGLE_API_KEY"),
      base_url: opts[:base_url] || Application.get_env(:nex_ai, :google_base_url) || System.get_env("GOOGLE_BASE_URL") || @default_base_url,
      config: Map.new(opts)
    }
  end

  defimpl ModelProtocol do
    alias NexAI.Provider.Google

    def provider(_model), do: "google"
    def model_id(model), do: model.model

    def do_generate(model, options) do
      url = "#{model.base_url}/models/#{model.model}:generateContent?key=#{model.api_key}"
      messages = Google.format_messages(options.prompt)

      body = %{
        contents: messages,
        generationConfig: build_generation_config(model.config)
      }

      body = if options.tools && length(options.tools) > 0 do
        Map.put(body, :tools, [%{functionDeclarations: Google.format_tools(options.tools)}])
      else
        body
      end

      finch_name = model.config[:finch] || NexAI.Finch
      case Req.post(url, json: body, finch: finch_name) do
        {:ok, %{status: 200, body: body, headers: _headers}} ->
          content = Google.extract_content(body)
          {:ok, %GenerateResult{
            content: content,
            finish_reason: Google.map_finish_reason(body["candidates"] && body["candidates"][0] && body["candidates"][0]["finishReason"]),
            usage: Google.format_usage(body["usageMetadata"]),
            raw_call: %{model_id: model.model, provider: "google", params: options},
            raw_response: body,
            response: %ResponseMetadata{
              id: nil,
              model_id: model.model,
              timestamp: nil
            }
          }}

        {:ok, %{status: 400, body: body}} ->
          {:error, %NexAI.Error.InvalidRequestError{message: get_in(body, ["error", "message"]), status: 400, raw: body}}

        {:ok, %{status: 429, body: body}} ->
          {:error, %NexAI.Error.RateLimitError{message: get_in(body, ["error", "message"]) || "Rate limit reached"}}

        {:ok, %{status: status, body: body}} ->
          {:error, %NexAI.Error.APIError{message: get_in(body, ["error", "message"]), status: status, raw: body}}

        {:error, reason} ->
          {:error, reason}
      end
    end

    def do_stream(model, options) do
      url = "#{model.base_url}/models/#{model.model}:streamGenerateContent?key=#{model.api_key}&alt=sse"
      messages = Google.format_messages(options.prompt)

      body = %{
        contents: messages,
        generationConfig: build_generation_config(model.config)
      }

      body = if options.tools && length(options.tools) > 0 do
        Map.put(body, :tools, [%{functionDeclarations: Google.format_tools(options.tools)}])
      else
        body
      end

      parent = self()
      receive_timeout = options.config[:receive_timeout] || 30_000

      stream = Stream.resource(
        fn ->
          task = Task.Supervisor.async_nolink(NexAI.TaskSupervisor, fn ->
            finch_name = model.config[:finch] || NexAI.Finch
            Req.post(url,
              json: body,
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
                {lines, new_buffer} = Google.process_line_buffer(state.buffer <> data)
                raw_chunks = Google.parse_lines(lines)
                send(pid, :ack)
                {parts, state} = Google.map_to_stream_parts(raw_chunks, state)
                {parts, %{state | buffer: new_buffer}}

              :stream_done ->
                {lines, _} = Google.process_line_buffer(state.buffer, true)
                raw_chunks = Google.parse_lines(lines)
                {parts, state} = Google.map_to_stream_parts(raw_chunks, state)
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
        raw_call: %{model_id: model.model, provider: "google", params: options}
      }}
    end

    defp build_generation_config(config) do
      %{}
      |> maybe_put(:temperature, config[:temperature])
      |> maybe_put(:topP, config[:top_p])
      |> maybe_put(:maxOutputTokens, config[:max_tokens])
      |> maybe_put(:stopSequences, config[:stop])
    end

    defp maybe_put(map, _key, nil), do: map
    defp maybe_put(map, key, value), do: Map.put(map, key, value)
  end

  def format_messages(messages) do
    Enum.map(messages, fn msg ->
      role = if is_struct(msg), do: msg.role, else: msg["role"] || msg[:role]
      content = if is_struct(msg), do: msg.content, else: msg["content"] || msg[:content]

      gemini_role = case to_string(role) do
        "user" -> "user"
        "assistant" -> "model"
        "system" -> "user"
        _ -> "user"
      end

      parts = case content do
        text when is_binary(text) -> [%{text: text}]
        list when is_list(list) ->
          Enum.map(list, fn
            %{type: "text", text: text} -> %{text: text}
            %{type: "image", image: img, mime_type: mime} ->
              data = if String.starts_with?(img, "http") do
                img
              else
                img
              end
              %{inlineData: %{mimeType: mime, data: data}}
            other -> other
          end)
        other -> [%{text: to_string(other)}]
      end

      %{role: gemini_role, parts: parts}
    end)
  end

  def format_tools(tools) do
    Enum.map(tools, fn tool ->
      %{
        name: tool.name,
        description: tool.description,
        parameters: tool.parameters
      }
    end)
  end

  def extract_content(body) do
    # Extract text content from Gemini response
    candidate = get_in(body, ["candidates", Access.at(0)])
    parts = get_in(candidate, ["content", "parts"]) || []

    text_parts = Enum.flat_map(parts, fn part ->
      if text = part["text"], do: [%{type: "text", text: text}], else: []
    end)

    if text_parts == [], do: [%{type: "text", text: ""}], else: text_parts
  end

  def extract_tool_calls(parts) do
    Enum.map(parts, fn p ->
      fc = p["functionCall"]
      %NexAI.Result.ToolCall{
        toolCallId: :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower),
        toolName: fc["name"],
        args: fc["args"] || %{}
      }
    end)
  end

  def map_finish_reason("STOP"), do: "stop"
  def map_finish_reason("MAX_TOKENS"), do: "length"
  def map_finish_reason("SAFETY"), do: "content-filter"
  def map_finish_reason(_), do: "unknown"

  def format_usage(%{"promptTokenCount" => p, "candidatesTokenCount" => c, "totalTokenCount" => t}) do
    %Usage{promptTokens: p, completionTokens: c, totalTokens: t}
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
    |> Enum.flat_map(fn
      "data: " <> json ->
        case Jason.decode(json) do
          {:ok, decoded} -> [decoded]
          _ -> []
        end
      _ -> []
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

    {chunks, state} = if not state.response_sent do
      meta = %ResponseMetadata{
        id: chunk["modelVersion"],
        model_id: chunk["modelVersion"],
        timestamp: System.system_time(:second)
      }
      {chunks ++ [%StreamPart{type: :response_metadata, response: meta}], %{state | response_sent: true}}
    else
      {chunks, state}
    end

    candidate = get_in(chunk, ["candidates", Access.at(0)])
    content_parts = get_in(candidate, ["content", "parts"]) || []

    chunks = Enum.reduce(content_parts, chunks, fn part, acc ->
      cond do
        text = part["text"] ->
          acc ++ [%StreamPart{type: :text_delta, text: text}]

        fc = part["functionCall"] ->
          id = :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
          acc ++ [
            %StreamPart{type: :tool_call_start, tool_call_id: id, tool_name: fc["name"]},
            %StreamPart{type: :tool_call_delta, tool_call_id: id, args_delta: Jason.encode!(fc["args"] || %{})}
          ]

        true -> acc
      end
    end)

    finish_reason = get_in(candidate, ["finishReason"])
    chunks = if finish_reason, do: chunks ++ [%StreamPart{type: :finish, finish_reason: map_finish_reason(finish_reason)}], else: chunks

    chunks = if usage = chunk["usageMetadata"], do: chunks ++ [%StreamPart{type: :usage, usage: format_usage(usage)}], else: chunks

    {chunks, state}
  end
end
