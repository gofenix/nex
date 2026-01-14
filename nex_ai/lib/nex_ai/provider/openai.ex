defmodule NexAI.Provider.OpenAI do
  @moduledoc """
  OpenAI Provider for NexAI.
  Implements the LanguageModel protocol (Vercel AI SDK v6).
  """
  alias NexAI.Result.Usage
  alias NexAI.LanguageModel.Protocol, as: ModelProtocol
  alias NexAI.LanguageModel.{GenerateResult, StreamResult, StreamPart, ResponseMetadata}

  defstruct [:api_key, :base_url, model: "gpt-4o", config: %{}]

  require Logger

  @default_base_url "https://api.openai.com/v1"

  @doc "Factory function to create an OpenAI model instance"
  def chat(model_id, opts \\ []) do
    %__MODULE__{
      model: model_id,
      api_key: opts[:api_key] || Application.get_env(:nex_ai, :openai_api_key) || System.get_env("OPENAI_API_KEY"),
      base_url: opts[:base_url] || Application.get_env(:nex_ai, :openai_base_url) || System.get_env("OPENAI_BASE_URL") || @default_base_url,
      config: Map.new(opts)
    }
  end

  defimpl ModelProtocol do
    alias NexAI.Provider.OpenAI
    alias NexAI.LanguageModel.{GenerateResult, StreamResult, StreamPart, ResponseMetadata}

    def provider(_model), do: "openai"
    def model_id(model), do: model.model

    def do_generate(model, options) do
      url = model.base_url <> "/chat/completions"
      messages = options.prompt |> NexAI.Message.normalize() |> OpenAI.format_messages()

      body = %{
        model: model.model,
        messages: messages,
        stream: false
      }

      body = if options.tools && length(options.tools) > 0, do: Map.put(body, :tools, OpenAI.format_tools(options.tools)), else: body
      body = if tc = options.tool_choice, do: Map.put(body, :tool_choice, tc), else: body
      body = if rf = options.response_format, do: Map.put(body, :response_format, rf), else: body
      body = Map.merge(body, model.config)

      metadata = %{model: model.model, provider: :openai}
      :telemetry.span([:nex_ai, :provider, :request], metadata, fn ->
        finch_name = model.config[:finch] || NexAI.Finch
        res = case Req.post(url,
          json: body,
          auth: {:bearer, model.api_key},
          finch: finch_name
        ) do
          {:ok, %{status: 200, body: body, headers: headers}} ->
            message = get_in(body, ["choices", Access.at(0), "message"])
            content = build_content(message)

            {:ok, %GenerateResult{
              content: content,
              finish_reason: OpenAI.map_finish_reason(get_in(body, ["choices", Access.at(0), "finish_reason"])),
              usage: OpenAI.format_usage(body["usage"]),
              raw_call: %{model_id: model.model, provider: "openai", params: options},
              raw_response: body,
              response: %ResponseMetadata{
                id: body["id"],
                model_id: body["model"],
                timestamp: body["created"],
                headers: Map.new(headers)
              }
            }}
          {:ok, %{status: 401, body: body}} ->
            {:error, %NexAI.Error.AuthenticationError{message: get_in(body, ["error", "message"]) || "Invalid API Key", status: 401, raw: body}}
          {:ok, %{status: 429, body: body}} ->
            {:error, %NexAI.Error.RateLimitError{message: get_in(body, ["error", "message"]) || "Rate limit reached"}}
          {:ok, %{status: 400, body: body}} ->
            {:error, %NexAI.Error.InvalidRequestError{message: get_in(body, ["error", "message"]), status: 400, raw: body}}
          {:ok, %{status: status, body: body}} ->
            {:error, %NexAI.Error.APIError{message: get_in(body, ["error", "message"]), status: status, type: get_in(body, ["error", "type"]), raw: body}}
          {:error, reason} ->
            {:error, reason}
        end
        {res, Map.put(metadata, :result, res)}
      end)
    end

    def do_stream(model, options) do
      url = model.base_url <> "/chat/completions"
      messages = options.prompt |> NexAI.Message.normalize() |> OpenAI.format_messages()

      body = %{
        model: model.model,
        messages: messages,
        stream: true,
        stream_options: %{include_usage: true}
      }

      body = if options.tools && length(options.tools) > 0, do: Map.put(body, :tools, OpenAI.format_tools(options.tools)), else: body
      body = if tc = options.tool_choice, do: Map.put(body, :tool_choice, tc), else: body
      body = if rf = options.response_format, do: Map.put(body, :response_format, rf), else: body
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
                {lines, new_buffer} = OpenAI.process_line_buffer(state.buffer <> data)
                raw_chunks = OpenAI.parse_lines(lines)
                send(producer_pid, :ack)

                {parts, state} = OpenAI.map_to_stream_parts(raw_chunks, state)
                {parts, %{state | buffer: new_buffer}}

              :stream_done ->
                {lines, _} = OpenAI.process_line_buffer(state.buffer, true)
                raw_chunks = OpenAI.parse_lines(lines)
                {parts, state} = OpenAI.map_to_stream_parts(raw_chunks, state)
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
        raw_call: %{model_id: model.model, provider: "openai", params: options}
      }}
    end

    defp build_content(message) do
      content = message["content"] || ""
      tool_calls = OpenAI.extract_tool_calls(message["tool_calls"])

      result = [%{type: "text", text: content}]

      result = if length(tool_calls) > 0 do
        result ++ Enum.map(tool_calls, fn tc ->
          %{
            type: "tool-call",
            toolCallId: tc.toolCallId,
            toolName: tc.toolName,
            args: tc.args
          }
        end)
      else
        result
      end

      result
    end
  end

  # --- Internal Helpers ---

  def process_line_buffer(buffer, final \\ false) do
    if String.contains?(buffer, "\n") do
      parts = String.split(buffer, ~r/\r?\n/)
      {complete, [rest]} = Enum.split(parts, length(parts) - 1)
      {complete, rest}
    else
      if final and buffer != "", do: {[buffer], ""}, else: {[], buffer}
    end
  end

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
        timestamp: chunk["created"]
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

    parts = case delta && delta["reasoning_content"] do
      nil -> parts
      reasoning -> parts ++ [%StreamPart{type: :reasoning_delta, content: reasoning}]
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

  def format_messages(messages) do
    Enum.map(messages, fn msg ->
      role = if is_struct(msg), do: msg.role, else: msg["role"] || msg[:role]
      content = if is_struct(msg), do: msg.content, else: msg["content"] || msg[:content]

      formatted_content = case content do
        list when is_list(list) ->
          Enum.map(list, fn
            %{type: "text", text: text} -> %{type: "text", text: text}
            %{type: "image", image: img, mime_type: mime} ->
              url = if String.starts_with?(img, "http"), do: img, else: "data:#{mime};base64,#{img}"
              %{type: "image_url", image_url: %{url: url}}
            other -> other
          end)
        other -> other
      end

      payload = %{"role" => to_string(role), "content" => formatted_content}

      # Add assistant-specific fields
      payload = if role == "assistant" or role == :assistant do
        tc = if is_struct(msg), do: Map.get(msg, :tool_calls), else: msg["tool_calls"] || msg[:tool_calls]
        if tc, do: Map.put(payload, "tool_calls", tc), else: payload
      else
        payload
      end

      # Add tool-specific fields
      payload = if role == "tool" or role == :tool do
        id = if is_struct(msg), do: Map.get(msg, :tool_call_id), else: msg["tool_call_id"] || msg[:tool_call_id]
        if id, do: Map.put(payload, "tool_call_id", id), else: payload
      else
        payload
      end

      payload
    end)
  end

  def format_tools(tools) do
    Enum.map(tools, fn tool ->
      %{
        type: "function",
        function: %{
          name: tool.name,
          description: tool.description,
          parameters: tool.parameters
        }
      }
    end)
  end

  def extract_tool_calls(nil), do: []
  def extract_tool_calls(calls) do
    Enum.map(calls, fn tc ->
      %NexAI.Result.ToolCall{
        toolCallId: tc["id"],
        toolName: tc["function"]["name"],
        args: Jason.decode!(tc["function"]["arguments"])
      }
    end)
  end

  def map_finish_reason("stop"), do: "stop"
  def map_finish_reason("length"), do: "length"
  def map_finish_reason("tool_calls"), do: "tool-calls"
  def map_finish_reason("content_filter"), do: "content-filter"
  def map_finish_reason(_), do: "unknown"

  def format_usage(%{"prompt_tokens" => p, "completion_tokens" => c, "total_tokens" => t}) do
    %Usage{promptTokens: p, completionTokens: c, totalTokens: t}
  end
  def format_usage(_), do: nil

  def parse_lines(lines) do
    lines
    |> Enum.map(&String.trim/1)
    |> Enum.filter(&(&1 != "" and &1 != "data: [DONE]"))
    |> Enum.flat_map(fn
      "data: " <> json ->
        case Jason.decode(json) do
          {:ok, decoded} -> [decoded]
          _ -> []
        end
      _ -> []
    end)
  end

  # --- Legacy / Helper functions for other tasks ---

  def generate_speech(text, opts \\ []) do
    model_id = opts[:model_id] || "tts-1"
    api_key = opts[:api_key] || System.get_env("OPENAI_API_KEY")
    url = (opts[:base_url] || @default_base_url) <> "/audio/speech"

    body = %{
      model: model_id,
      input: text,
      voice: opts[:voice] || "alloy",
      response_format: opts[:response_format] || "mp3"
    }

    # Return raw binary
    case Req.post(url, json: body, auth: {:bearer, api_key}) do
      {:ok, %{status: 200, body: binary}} -> {:ok, binary}
      {:ok, res} -> {:error, res.body}
      {:error, reason} -> {:error, reason}
    end
  end

  def transcribe(file_content, opts \\ []) do
    model_id = opts[:model_id] || "whisper-1"
    api_key = opts[:api_key] || System.get_env("OPENAI_API_KEY")
    url = (opts[:base_url] || @default_base_url) <> "/audio/transcriptions"

    # Use Req's multipart support
    case Req.post(url,
      auth: {:bearer, api_key},
      form: [
        file: {"audio.mp3", file_content},
        model: model_id
      ]
    ) do
      {:ok, %{status: 200, body: body}} -> {:ok, body["text"]}
      {:ok, res} -> {:error, res.body}
      {:error, reason} -> {:error, reason}
    end
  end

  def embed_many(values, opts \\ []) do
    api_key = opts[:api_key] || System.get_env("OPENAI_API_KEY")
    url = (opts[:base_url] || @default_base_url) <> "/embeddings"
    model = opts[:model_id] || "text-embedding-3-small"

    case Req.post(url, json: %{model: model, input: values}, auth: {:bearer, api_key}) do
      {:ok, %{status: 200, body: body}} ->
        embeddings = body["data"] |> Enum.sort_by(& &1["index"]) |> Enum.map(& &1["embedding"])
        {:ok, embeddings}
      {:error, reason} -> {:error, reason}
      {:ok, res} -> {:error, res.body}
    end
  end

  def generate_image(prompt, opts \\ []) do
    api_key = opts[:api_key] || System.get_env("OPENAI_API_KEY")
    url = (opts[:base_url] || @default_base_url) <> "/images/generations"

    body = %{
      prompt: prompt,
      model: opts[:model_id] || "dall-e-3",
      n: 1,
      size: opts[:size] || "1024x1024",
      response_format: "b64_json"
    }

    case Req.post(url, json: body, auth: {:bearer, api_key}) do
      {:ok, %{status: 200, body: body}} ->
        images = Enum.map(body["data"], &(&1["b64_json"] || &1["url"]))
        {:ok, %{images: images, raw: body}}
      {:ok, res} -> {:error, res.body}
      {:error, reason} -> {:error, reason}
    end
  end
end
