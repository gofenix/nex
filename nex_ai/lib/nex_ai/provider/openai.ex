defmodule NexAI.Provider.OpenAI do
  @moduledoc """
  OpenAI Provider for NexAI.
  """
  @behaviour NexAI.Model
  
  defstruct [:api_key, :base_url, model: "gpt-4o"]
  
  require Logger

  @default_base_url "https://api.openai.com/v1"

  @doc "Factory function to create an OpenAI model instance"
  def chat(model_id, opts \\ []) do
    %__MODULE__{
      model: model_id,
      api_key: opts[:api_key],
      base_url: opts[:base_url]
    }
  end

  def stream_text(messages, opts \\ []) do
    model_instance = opts[:model]
    
    api_key = opts[:api_key] || (is_struct(model_instance, __MODULE__) && model_instance.api_key) || System.get_env("OPENAI_API_KEY")
    
    if !api_key do
      raise "OPENAI_API_KEY is not configured"
    end

    base_url = opts[:base_url] || (is_struct(model_instance, __MODULE__) && model_instance.base_url) || System.get_env("OPENAI_BASE_URL") || @default_base_url
    model_name = (is_struct(model_instance, __MODULE__) && model_instance.model) || (is_binary(model_instance) && model_instance) || opts[:model_id] || "gpt-4o"
    tools = opts[:tools]

    body = %{
      model: model_name,
      messages: Enum.map(messages, &format_openai_message/1),
      stream: true
    }

    body = if tools && length(tools) > 0, do: Map.put(body, :tools, format_tools(tools)), else: body
    body = if tc = opts[:tool_choice] || opts[:toolChoice], do: Map.put(body, :tool_choice, tc), else: body

    parent = self()

    receive_timeout = opts[:receive_timeout] || 60_000
    stream_timeout = opts[:stream_timeout] || 30_000

    Stream.resource(
      fn ->
        Task.async(fn ->
          Req.post(base_url <> "/chat/completions",
            json: body,
            headers: [
              {"authorization", "Bearer #{api_key}"},
              {"content-type", "application/json"}
            ],
            into: fn {:data, data}, acc ->
              send(parent, {:stream_data, data})
              {:cont, acc}
            end,
            receive_timeout: receive_timeout
          )
          send(parent, :stream_done)
        end)
      end,
      fn task ->
        receive do
          {:stream_data, data} ->
            chunks = 
              data
              |> String.split("\n")
              |> Enum.map(&String.trim/1)
              |> Enum.filter(&(&1 != "" and &1 != "data: [DONE]"))
              |> Enum.map(fn 
                "data: " <> json -> 
                  case Jason.decode(json) do
                    {:ok, decoded} -> decoded
                    {:error, _} -> %{}
                  end
                _ -> %{}
              end)
              |> Enum.filter(&(&1 != %{}))
            
            {chunks, task}
          
          :stream_done ->
            {:halt, task}
        after
          stream_timeout -> 
            Logger.warning("OpenAI stream timeout after #{stream_timeout}ms")
            {:halt, task}
        end
      end,
      fn task -> 
        case Task.yield(task, 0) || Task.shutdown(task) do
          nil -> :ok
          _ -> :ok
        end
      end
    )
  end

  def generate_text(messages, opts \\ []) do
    model_instance = opts[:model]
    api_key = opts[:api_key] || (is_struct(model_instance, __MODULE__) && model_instance.api_key) || System.get_env("OPENAI_API_KEY")
    base_url = opts[:base_url] || (is_struct(model_instance, __MODULE__) && model_instance.base_url) || System.get_env("OPENAI_BASE_URL") || @default_base_url
    model_name = (is_struct(model_instance, __MODULE__) && model_instance.model) || (is_binary(model_instance) && model_instance) || opts[:model_id] || "gpt-4o"
    
    case Req.post(base_url <> "/chat/completions",
      json: %{model: model_name, messages: messages},
      headers: [
        {"authorization", "Bearer #{api_key}"}
      ]
    ) do
      {:ok, %{status: 200, body: body}} ->
        content = get_in(body, ["choices", Access.at(0), "message", "content"])
        usage = format_usage(body["usage"])
        {:ok, %{text: content, usage: usage, raw: body}}
      {:ok, response} -> {:error, response}
      {:error, error} -> {:error, error}
    end
  end

  def embed_many(values, opts \\ []) do
    model_instance = opts[:model]
    api_key = opts[:api_key] || (is_struct(model_instance, __MODULE__) && model_instance.api_key) || System.get_env("OPENAI_API_KEY")
    base_url = opts[:base_url] || (is_struct(model_instance, __MODULE__) && model_instance.base_url) || System.get_env("OPENAI_BASE_URL") || @default_base_url
    model_name = (is_struct(model_instance, __MODULE__) && model_instance.model) || (is_binary(model_instance) && model_instance) || opts[:model_id] || "text-embedding-3-small"

    case Req.post(base_url <> "/embeddings",
      json: %{model: model_name, input: values},
      headers: [
        {"authorization", "Bearer #{api_key}"}
      ]
    ) do
      {:ok, %{status: 200, body: body}} ->
        embeddings = body["data"] 
          |> Enum.sort_by(& &1["index"])
          |> Enum.map(& &1["embedding"])
        {:ok, embeddings}
      {:ok, response} -> {:error, response}
      {:error, error} -> {:error, error}
    end
  end

  def generate_image(prompt, opts \\ []) do
    model_instance = opts[:model]
    api_key = opts[:api_key] || (is_struct(model_instance, __MODULE__) && model_instance.api_key) || System.get_env("OPENAI_API_KEY")
    base_url = opts[:base_url] || (is_struct(model_instance, __MODULE__) && model_instance.base_url) || System.get_env("OPENAI_BASE_URL") || @default_base_url
    model_name = (is_struct(model_instance, __MODULE__) && model_instance.model) || (is_binary(model_instance) && model_instance) || opts[:model_id] || "dall-e-3"

    body = %{
      model: model_name,
      prompt: prompt,
      n: opts[:n] || 1,
      size: opts[:size] || "1024x1024",
      response_format: opts[:response_format] || "b64_json"
    }

    case Req.post(base_url <> "/images/generations",
      json: body,
      headers: [
        {"authorization", "Bearer #{api_key}"}
      ]
    ) do
      {:ok, %{status: 200, body: body}} ->
        images = Enum.map(body["data"], fn item -> 
          item["b64_json"] || item["url"]
        end)
        {:ok, %{images: images, raw: body}}
      {:ok, response} -> {:error, response}
      {:error, error} -> {:error, error}
    end
  end

  def generate_speech(text, opts \\ []) do
    model_instance = opts[:model]
    api_key = opts[:api_key] || (is_struct(model_instance, __MODULE__) && model_instance.api_key) || System.get_env("OPENAI_API_KEY")
    base_url = opts[:base_url] || (is_struct(model_instance, __MODULE__) && model_instance.base_url) || System.get_env("OPENAI_BASE_URL") || @default_base_url
    model_name = (is_struct(model_instance, __MODULE__) && model_instance.model) || (is_binary(model_instance) && model_instance) || opts[:model_id] || "tts-1"

    body = %{
      model: model_name,
      input: text,
      voice: opts[:voice] || "alloy",
      response_format: opts[:response_format] || "mp3",
      speed: opts[:speed] || 1.0
    }

    case Req.post(base_url <> "/audio/speech",
      json: body,
      headers: [
        {"authorization", "Bearer #{api_key}"}
      ]
    ) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, %{audio: body}}
      {:ok, response} -> {:error, response}
      {:error, error} -> {:error, error}
    end
  end

  def transcribe(file_content, opts \\ []) do
    model_instance = opts[:model]
    api_key = opts[:api_key] || (is_struct(model_instance, __MODULE__) && model_instance.api_key) || System.get_env("OPENAI_API_KEY")
    base_url = opts[:base_url] || (is_struct(model_instance, __MODULE__) && model_instance.base_url) || System.get_env("OPENAI_BASE_URL") || @default_base_url
    model_name = (is_struct(model_instance, __MODULE__) && model_instance.model) || (is_binary(model_instance) && model_instance) || opts[:model_id] || "whisper-1"

    # We need to construct a multipart request manually or use Req's support if available.
    # For simplicity, we assume file_content is the binary data.
    # NOTE: Req doesn't handle multipart form-data for file uploads automatically with simple params.
    # We will use a basic Multipart builder approach or rely on Req's :form option if it supports file upload directly.
    # However, Req's :form often expects basic key-values.
    # For robustness, we'll assume the user might provide a path or binary.
    
    # A simplified implementation using Req's :form support for multipart which might handle files if formatted correctly
    # But usually "audio/transcriptions" expects a file part named "file".
    
    # NOTE: As of Req 0.5+, we can just pass a list of parts or a map.
    # We will assume simple usage for now.

    # This is a bit complex in pure Elixir without a robust Multipart library, 
    # but let's try to map it to what Req expects for multipart.
    
    # We will assume the user passes binary content for now.
    multipart = 
      Multipart.new()
      |> Multipart.add_part(Multipart.Part.file_content_field("file", file_content, "audio.mp3", filename: "audio.mp3"))
      |> Multipart.add_part(Multipart.Part.text_field(model_name, :model))

    content_type = Multipart.content_type(multipart, "multipart/form-data")
    body = Multipart.body_binary(multipart)
    content_length = byte_size(body)

    case Req.post(base_url <> "/audio/transcriptions",
      body: body,
      headers: [
        {"authorization", "Bearer #{api_key}"},
        {"content-type", content_type},
        {"content-length", to_string(content_length)}
      ]
    ) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, %{text: body["text"], raw: body}}
      {:ok, response} -> {:error, response}
      {:error, error} -> {:error, error}
    end
  end

  def rerank(_query, _documents, _opts) do
    {:error, :not_implemented_by_openai}
  end

  defp format_openai_message(msg) do
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
  end

  defp format_usage(u) when is_map(u), do: %{promptTokens: u["prompt_tokens"], completionTokens: u["completion_tokens"], totalTokens: u["total_tokens"]}
  defp format_usage(_), do: nil

  defp format_tools(tools) do
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
end
