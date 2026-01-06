# NexAI

The Standalone AI SDK for Elixir, inspired by Vercel AI SDK.

NexAI provides a unified interface for interacting with various AI providers (OpenAI, Anthropic), supporting text generation, streaming, tool calling, embeddings, audio, and more.

## Features

- **Unified API**: Single interface for multiple AI providers
- **Streaming Support**: Efficient lazy streams with backpressure control
- **Tool Calling**: Multi-step agentic workflows with automatic tool execution
- **Structured Output**: Generate JSON responses with schema validation
- **Middleware System**: Extensible interceptor pattern for logging, monitoring, etc.
- **Protocol Adapters**: Built-in support for Vercel AI SDK Data Stream and DataStar formats
- **Telemetry**: Comprehensive telemetry with `:telemetry` integration

## Installation

Add `nex_ai` to your mix.exs:

```elixir
def deps do
  [
    {:nex_ai, "~> 0.1.0"}
  ]
end
```

Configure your API keys:

```elixir
# In config/config.exs
config :nex_ai, :openai_api_key, System.get_env("OPENAI_API_KEY")
config :nex_ai, :anthropic_api_key, System.get_env("ANTHROPIC_API_KEY")
```

## Quick Start

```elixir
alias NexAI.Message.User

# Generate text (non-streaming)
{:ok, result} = NexAI.generate_text(
  model: NexAI.openai("gpt-4o"),
  messages: [%User{content: "Hello, world!"}]
)
IO.puts(result.text)

# Stream text with real-time token handling
{:ok, stream} = NexAI.stream_text(
  model: NexAI.openai("gpt-4o"),
  messages: [%User{content: "Tell me a story."}]
)

Enum.each(stream.full_stream, fn event ->
  if event.type == :text, do: IO.write(event.payload)
end)
```

## Providers

### OpenAI

```elixir
model = NexAI.openai("gpt-4o")
model = NexAI.openai("gpt-4o", api_key: "your-key", base_url: "https://api.openai.com/v1")
```

### Anthropic (Claude)

```elixir
model = NexAI.anthropic("claude-3-5-sonnet-latest")
model = NexAI.anthropic("claude-3-5-sonnet-latest", api_key: "your-key")
```

## Tool Calling

Define tools and let AI decide when to use them:

```elixir
weather_tool = NexAI.tool(%{
  name: "get_current_weather",
  description: "Get current weather for a location",
  parameters: %{
    type: "object",
    properties: %{
      location: %{type: "string", description: "City name"}
    },
    required: ["location"]
  },
  execute: fn %{"location" => loc} ->
    "#{loc} is sunny, 22°C."
  end
})

{:ok, result} = NexAI.generate_text(
  model: NexAI.openai("gpt-4o"),
  messages: [%User{content: "What's the weather in Beijing?"}],
  tools: [weather_tool],
  max_steps: 5
)

IO.puts(result.text)
```

## Streaming with Event Types

The stream returns various event types:

```elixir
{:ok, stream} = NexAI.stream_text(
  model: NexAI.openai("gpt-4o"),
  messages: [%User{content: "Explain quantum physics."}]
)

Enum.each(stream.full_stream, fn event ->
  case event.type do
    :text -> IO.write(event.payload)           # Regular text delta
    :reasoning -> IO.write(event.payload)       # Reasoning content (OpenAI)
    :tool_call_start -> :ok                     # Tool call initiated
    :tool_call_delta -> :ok                     # Tool call arguments streaming
    :tool_result -> :ok                         # Tool execution result
    :metadata -> :ok                            # Token usage, etc.
    :stream_finish -> :ok                       # Stream completed
    :error -> IO.inspect(event.payload)         # Error occurred
  end
end)
```

## Structured Output (JSON)

Generate structured JSON responses:

```elixir
{:ok, result} = NexAI.generate_text(
  model: NexAI.openai("gpt-4o"),
  messages: [%User{content: "Extract user info from: John, 25, engineer"}],
  output: %{
    mode: :object,
    schema: %{
      type: "object",
      properties: %{
        name: %{type: "string"},
        age: %{type: "integer"},
        profession: %{type: "string"}
      },
      required: ["name", "age", "profession"]
    }
  }
)

IO.inspect(result.object)  # %{name: "John", age: 25, profession: "engineer"}
```

## Middleware

Extend behavior with middleware:

```elixir
defmodule MyLoggingMiddleware do
  def do_generate(model, params, _opts) do
    IO.inspect(params, label: "AI Request")
    NexAI.LanguageModel.Protocol.do_generate(model, params)
  end
end

smart_model = NexAI.Middleware.wrap_model(
  NexAI.openai("gpt-4o"),
  {MyLoggingMiddleware, []}
)
```

Built-in middleware:
- `NexAI.Middleware.DefaultSettings` - Apply default settings to requests
- `NexAI.Middleware.ExtractReasoning` - Extract reasoning content from responses
- `NexAI.Middleware.SimulateStreaming` - Convert non-streaming to streaming

## Protocol Adapters

### Vercel AI SDK Data Stream

```elixir
stream = NexAI.stream_text(
  model: NexAI.openai("gpt-4o"),
  messages: [%User{content: "Hello"}]
)

NexAI.to_data_stream(stream)
```

### DataStar

```elixir
NexAI.to_datastar(stream, signal: "aiResponse")
```

## Other Capabilities

### Embeddings

```elixir
{:ok, result} = NexAI.embed(value: "Hello world")
{:ok, result} = NexAI.embed_many(values: ["Hello", "World"])
similarity = NexAI.cosine_similarity(embedding1, embedding2)
```

### Audio

```elixir
{:ok, audio} = NexAI.generate_speech(text: "Hello!", voice: "alloy")
{:ok, text} = NexAI.transcribe(audio_data)
```

### Image Generation

```elixir
{:ok, result} = NexAI.generate_image(prompt: "A cute cat", size: "1024x1024")
```

## Error Handling

```elixir
case NexAI.generate_text(model: model, messages: msgs) do
  {:ok, result} -> IO.puts(result.text)
  {:error, %NexAI.Error.APIError{message: msg, status: status}} ->
    IO.puts("API Error: #{msg} (status: #{status})")
  {:error, %NexAI.Error.RateLimitError{}} ->
    IO.puts("Rate limited. Please retry later.")
  {:error, %NexAI.Error.TimeoutError{}} ->
    IO.puts("Request timed out.")
end
```

## Configuration Options

| Option | Type | Description |
|--------|------|-------------|
| `model` | any | AI model (from provider factory) |
| `messages` | list | Conversation messages |
| `system` | string | System prompt |
| `temperature` | float | Sampling temperature (0-2) |
| `top_p` | float | Top-p sampling (0-1) |
| `max_tokens` | integer | Max tokens to generate |
| `max_steps` | integer | Max tool use steps (default: 1) |
| `tools` | list | Available tools |
| `tool_choice` | any | Force tool usage |
| `output` | map | Structured output config |

## Integration with Nex Framework

In Nex LiveViews, use `use NexAI` for shorthand:

```elixir
defmodule MyApp.Pages.AIChat do
  use Nex
  use NexAI

  def mount(_params, _session, socket) do
    {:ok, assign(socket, messages: [], input: "")}
  end

  def render(assigns) do
    ~H"""
    <div>
      <input type="text" phx-change="update_input" phx-submit="send" />
      <button phx-click="send">Send</button>
      
      <div :for={msg <- @messages}>
        <%= msg.content %>
      </div>
    </div>
    """
  end

  def update_input(socket, %{"value" => value}) do
    assign(socket, input: value)
  end

  def send(socket) do
    input = socket.assigns.input
    
    stream = stream_text(
      model: NexAI.openai("gpt-4o"),
      messages: [%Message.User{content: input}]
    )
    
    socket
    |> assign(messages: [..., %Message.User{content: input}])
    |> stream_to_socket(:message_stream, stream)
  end
end
```

## License

MIT
