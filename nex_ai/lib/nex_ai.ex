defmodule NexAI do
  @moduledoc """
  NexAI - The Standalone AI SDK for Elixir, inspired by Vercel AI SDK.

  Provides a unified interface for AI operations including:
  - Text generation (streaming and non-streaming)
  - Structured object generation
  - Multi-step tool calling
  - Audio transcription and speech synthesis
  - Image generation
  - Text embeddings
  - Multiple provider support (OpenAI, Anthropic, Google, Mistral, Cohere)

  ## Quick Start

      # Generate text
      {:ok, result} = NexAI.generate_text(
        model: NexAI.openai("gpt-4o"),
        messages: [%{role: "user", content: "Hello!"}]
      )

      # Stream text
      stream = NexAI.stream_text(
        model: NexAI.openai("gpt-4o"),
        messages: [%{role: "user", content: "Tell me a story"}]
      )

      # Generate structured objects
      {:ok, result} = NexAI.generate_object(
        model: NexAI.openai("gpt-4o"),
        messages: [%{role: "user", content: "Extract: John is 30"}],
        schema: %{
          type: "object",
          properties: %{
            name: %{type: "string"},
            age: %{type: "number"}
          }
        }
      )

  ## Providers

  - `openai/2` - OpenAI (GPT-4, GPT-3.5, etc.)
  - `anthropic/2` - Anthropic (Claude)
  - `google/2` - Google (Gemini)
  - `mistral/2` - Mistral AI
  - `cohere/2` - Cohere

  ## Middleware

  Wrap models with middleware for enhanced functionality:

      model = NexAI.openai("gpt-4o")
        |> NexAI.wrap_model([
          {NexAI.Middleware.Retry, max_retries: 3},
          {NexAI.Middleware.Logging, level: :info},
          {NexAI.Middleware.Cache, ttl: 3600}
        ])

  """

  alias NexAI.Core
  alias NexAI.Provider.{OpenAI, Anthropic, Google, Mistral, Cohere}

  @doc """
  Import commonly used functions into your module.

  ## Example

      defmodule MyApp do
        use NexAI

        def chat(message) do
          generate_text(
            model: openai("gpt-4o"),
            messages: [%{role: "user", content: message}]
          )
        end
      end
  """
  defmacro __using__(_opts) do
    quote do
      import NexAI, only: [
        stream_text: 1,
        generate_text: 1,
        generate_text: 2,
        generate_object: 1,
        stream_object: 1,
        to_data_stream: 1,
        to_datastar: 1,
        to_datastar: 2
      ]

      alias NexAI.{Prompt, StreamHelpers, Tool}
    end
  end

  # --- Provider Factory Functions ---

  @doc """
  Creates an OpenAI model instance.

  ## Examples

      model = NexAI.openai("gpt-4o")
      model = NexAI.openai("gpt-4o", api_key: "sk-...")
      model = NexAI.openai("gpt-4o", temperature: 0.7, max_tokens: 1000)
  """
  def openai(model_id, opts \\ []), do: OpenAI.chat(model_id, opts)

  @doc """
  Creates an Anthropic (Claude) model instance.

  ## Examples

      model = NexAI.anthropic("claude-3-5-sonnet-latest")
      model = NexAI.anthropic("claude-3-opus-latest", api_key: "sk-ant-...")
  """
  def anthropic(model_id, opts \\ []), do: Anthropic.claude(model_id, opts)

  @doc """
  Creates a Google (Gemini) model instance.

  ## Examples

      model = NexAI.google("gemini-1.5-flash")
      model = NexAI.google("gemini-1.5-pro", api_key: "...")
  """
  def google(model_id, opts \\ []), do: Google.gemini(model_id, opts)

  @doc """
  Creates a Mistral AI model instance.

  ## Examples

      model = NexAI.mistral("mistral-small-latest")
      model = NexAI.mistral("mistral-large-latest", api_key: "...")
  """
  def mistral(model_id, opts \\ []), do: Mistral.chat(model_id, opts)

  @doc """
  Creates a Cohere model instance.

  ## Examples

      model = NexAI.cohere("command-r-plus")
      model = NexAI.cohere("command-r", api_key: "...")
  """
  def cohere(model_id, opts \\ []), do: Cohere.chat(model_id, opts)

  @doc """
  Wraps a language model with middleware for enhanced functionality.

  ## Examples

      # Single middleware
      model = openai("gpt-4o") |> wrap_model(NexAI.Middleware.Retry)

      # Multiple middlewares with options
      model = openai("gpt-4o")
        |> wrap_model([
          {NexAI.Middleware.Retry, max_retries: 3},
          {NexAI.Middleware.Logging, level: :info},
          {NexAI.Middleware.Cache, ttl: 3600}
        ])
  """
  def wrap_model(model, middleware), do: NexAI.Middleware.wrap_model(model, middleware)

  # --- Core Text API ---

  @doc """
  Generates text using the specified model.

  ## Options

  - `:model` - The language model to use (required)
  - `:messages` - List of messages (required)
  - `:system` - System prompt
  - `:temperature` - Sampling temperature (0.0 to 2.0)
  - `:max_tokens` - Maximum tokens to generate
  - `:tools` - List of tools for function calling
  - `:max_steps` - Maximum number of tool call steps (default: 1)

  ## Examples

      {:ok, result} = generate_text(
        model: openai("gpt-4o"),
        messages: [%{role: "user", content: "Hello!"}],
        temperature: 0.7
      )

      IO.puts(result.text)
  """
  defdelegate generate_text(opts), to: Core

  @doc """
  Generates text with messages as first argument.

  ## Examples

      {:ok, result} = generate_text(
        [%{role: "user", content: "Hello!"}],
        model: openai("gpt-4o")
      )
  """
  defdelegate generate_text(messages, opts), to: Core

  @doc """
  Streams text generation.

  ## Examples

      stream = stream_text(
        model: openai("gpt-4o"),
        messages: [%{role: "user", content: "Tell me a story"}]
      )

      Enum.each(stream.full_stream, fn chunk ->
        if chunk.type == :text_delta do
          IO.write(chunk.content)
        end
      end)
  """
  defdelegate stream_text(opts), to: Core

  # --- Core Object API ---

  @doc """
  Generates a structured object matching the provided schema.

  ## Examples

      {:ok, result} = generate_object(
        model: openai("gpt-4o"),
        messages: [%{role: "user", content: "Extract: John is 30"}],
        schema: %{
          type: "object",
          properties: %{
            name: %{type: "string"},
            age: %{type: "number"}
          }
        }
      )

      IO.inspect(result.object)
  """
  def generate_object(opts) when is_list(opts) do
    opts = Keyword.update(opts, :output, nil, fn
      nil -> %{mode: :object, schema: opts[:schema]}
      existing -> existing
    end)
    Core.generate_text(opts)
  end

  @doc """
  Streams a structured object.

  ## Examples

      stream = stream_object(
        model: openai("gpt-4o"),
        messages: [%{role: "user", content: "Generate user profile"}],
        schema: %{type: "object", properties: %{name: %{type: "string"}}}
      )
  """
  def stream_object(opts) when is_list(opts) do
    opts = Keyword.update(opts, :output, nil, fn
      nil -> %{mode: :object, schema: opts[:schema]}
      existing -> existing
    end)
    Core.stream_text(opts)
  end

  # --- Protocol Adapters ---

  @doc """
  Converts a stream to Vercel AI Data Stream Protocol.

  ## Examples

      stream = stream_text(model: openai("gpt-4o"), messages: [...])
      response = to_data_stream(stream)
  """
  defdelegate to_data_stream(result), to: NexAI.UI.Vercel

  @doc """
  Converts a stream to Datastar SSE signals.

  ## Examples

      stream = stream_text(model: openai("gpt-4o"), messages: [...])
      response = to_datastar(stream, signal: "aiResponse")
  """
  defdelegate to_datastar(result), to: NexAI.UI.Datastar
  defdelegate to_datastar(result, opts), to: NexAI.UI.Datastar

  # --- Specialized APIs ---

  @doc """
  Transcribes audio to text.

  ## Examples

      {:ok, text} = transcribe(
        file: audio_binary,
        model: openai("whisper-1")
      )
  """
  defdelegate transcribe(opts), to: NexAI.Audio

  @doc """
  Generates speech from text.

  ## Examples

      {:ok, audio_binary} = generate_speech(
        text: "Hello, world!",
        model: openai("tts-1"),
        voice: "alloy"
      )
  """
  defdelegate generate_speech(opts), to: NexAI.Audio

  @doc """
  Generates an embedding for a single value.

  ## Examples

      {:ok, %{embedding: vector}} = embed(
        value: "Hello, world!",
        model: openai("text-embedding-3-small")
      )
  """
  defdelegate embed(opts), to: NexAI.Embed

  @doc """
  Generates embeddings for multiple values.

  ## Examples

      {:ok, %{embeddings: vectors}} = embed_many(
        values: ["Hello", "World"],
        model: openai("text-embedding-3-small")
      )
  """
  defdelegate embed_many(opts), to: NexAI.Embed

  @doc """
  Calculates cosine similarity between two vectors.

  ## Examples

      similarity = cosine_similarity([1.0, 2.0, 3.0], [1.0, 2.0, 3.0])
  """
  defdelegate cosine_similarity(v1, v2), to: NexAI.Embed

  @doc """
  Generates an image from a prompt.

  ## Examples

      {:ok, %{images: [base64_image]}} = generate_image(
        prompt: "A beautiful sunset",
        model: openai("dall-e-3")
      )
  """
  defdelegate generate_image(opts), to: NexAI.Image

  # --- Utilities ---

  @doc """
  Creates a tool definition for function calling.

  ## Examples

      weather_tool = tool(
        name: "get_weather",
        description: "Get the weather for a location",
        parameters: %{
          type: "object",
          properties: %{
            location: %{type: "string"}
          },
          required: ["location"]
        },
        execute: fn %{"location" => loc} ->
          "The weather in \#{loc} is sunny"
        end
      )
  """
  def tool(opts), do: NexAI.Tool.new(opts)

  @doc """
  Converts a schema to JSON Schema format.
  """
  def json_schema(s), do: NexAI.Schema.json_schema(s)

  @doc """
  Alias for json_schema (Zod-style naming).
  """
  def zod_schema(s), do: NexAI.Schema.json_schema(s)

  @doc """
  Generates a unique ID.

  ## Examples

      id = generate_id()
  """
  def generate_id, do: :crypto.strong_rand_bytes(5) |> Base.encode32(case: :lower, padding: false) |> binary_part(0, 7)

  @doc """
  Returns the current version of NexAI.
  """
  def version, do: "0.1.0"
end
