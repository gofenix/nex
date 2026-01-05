defmodule NexAI.Provider.OpenAI do
  @moduledoc """
  OpenAI Provider for NexAI.
  Implements the LanguageModel protocol.
  """
  alias NexAI.Result.{Usage, Response, ToolCall}
  alias NexAI.LanguageModel.Protocol, as: ModelProtocol

  defstruct [:api_key, :base_url, model: "gpt-4o", config: %{}]

  require Logger

  @default_base_url "https://api.openai.com/v1"

  @doc "Factory function to create an OpenAI model instance"
  def chat(model_id, opts \\ []) do
    %__MODULE__{
      model: model_id,
      api_key: opts[:api_key] || System.get_env("OPENAI_API_KEY"),
      base_url: opts[:base_url] || System.get_env("OPENAI_BASE_URL") || @default_base_url,
      config: Map.new(opts)
    }
  end

  defimpl ModelProtocol do
    alias NexAI.Provider.OpenAI
    alias NexAI.Result.{Usage, Response, ToolCall}

    def do_generate(model, params) do
      url = model.base_url <> "/chat/completions"
      body = %{
        model: model.model,
        messages: OpenAI.format_messages(params.prompt),
        stream: false
      }
      
      body = if params.tools && length(params.tools) > 0, do: Map.put(body, :tools, OpenAI.format_tools(params.tools)), else: body
      body = if tc = params.tool_choice, do: Map.put(body, :tool_choice, tc), else: body
      body = if rf = params.response_format, do: Map.put(body, :response_format, rf), else: body
      
      # Merge model config (temperature, etc)
      body = Map.merge(body, model.config)

      case Req.post(url, json: body, auth: {:bearer, model.api_key}) do
        {:ok, %{status: 200, body: body, headers: headers}} ->
          message = get_in(body, ["choices", Access.at(0), "message"])
          
          {:ok, %{
            text: message["content"],
            tool_calls: OpenAI.extract_tool_calls(message["tool_calls"]),
            finish_reason: OpenAI.map_finish_reason(get_in(body, ["choices", Access.at(0), "finish_reason"])),
            usage: OpenAI.format_usage(body["usage"]),
            response: %Response{
              id: body["id"],
              modelId: body["model"],
              timestamp: body["created"],
              headers: Map.new(headers)
            },
            raw: body
          }}
        {:ok, %{status: status, body: body}} ->
          {:error, "OpenAI Error #{status}: #{inspect(body)}"}
        {:error, reason} ->
          {:error, reason}
      end
    end

    def do_stream(model, params) do
      url = model.base_url <> "/chat/completions"
      body = %{
        model: model.model,
        messages: OpenAI.format_messages(params.prompt),
        stream: true,
        stream_options: %{include_usage: true}
      }

      body = if params.tools && length(params.tools) > 0, do: Map.put(body, :tools, OpenAI.format_tools(params.tools)), else: body
      body = if tc = params.tool_choice, do: Map.put(body, :tool_choice, tc), else: body
      body = if rf = params.response_format, do: Map.put(body, :response_format, rf), else: body
      
      body = Map.merge(body, model.config)

      parent = self()
      
      Stream.resource(
        fn ->
          Task.async(fn ->
            Req.post(url,
              json: body,
              auth: {:bearer, model.api_key},
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
            {:stream_data, data} ->
              chunks = OpenAI.parse_sse(data)
              {chunks, task}
            :stream_done ->
              {:halt, task}
          after
            30_000 -> {:halt, task}
          end
        end,
        fn task -> Task.shutdown(task) end
      )
    end
  end

  # --- Internal Helpers for Protocol Implementation ---

  def format_messages(messages) do
    Enum.map(messages, fn msg ->
      content = case msg["content"] do
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
      msg |> Map.put("content", content)
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
      %ToolCall{
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

  def parse_sse(data) do
    data
    |> String.split("\n")
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

  # ... embed_many and generate_image remain similar but should use standard headers
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
    end
  end
end
