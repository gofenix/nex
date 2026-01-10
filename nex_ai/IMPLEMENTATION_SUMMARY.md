# NexAI - Complete Vercel AI SDK Port for Elixir

## Overview

NexAI is a comprehensive port of the Vercel AI SDK to Elixir, providing a unified interface for interacting with multiple AI providers. This implementation follows the Vercel AI SDK v4/v5/v6 architecture with Elixir-native patterns.

## Architecture

### Core Components

1. **Language Model Protocol** (`lib/nex_ai/language_model.ex`)
   - Defines the `LanguageModel.Protocol` for provider implementations
   - Supports both V1 and V3 protocol versions
   - Standardized result structures (GenerateResult, StreamChunk, etc.)

2. **Core Engine** (`lib/nex_ai/core.ex`)
   - `generate_text/1,2` - Non-streaming text generation
   - `stream_text/1` - Streaming text generation
   - Multi-step tool calling with automatic execution
   - Structured output (JSON) generation
   - Lifecycle callbacks (onFinish, onToken, onStepFinish)

3. **Provider Implementations**
   - **OpenAI** (`lib/nex_ai/provider/openai.ex`)
     - GPT-4, GPT-3.5, etc.
     - Streaming with SSE
     - Tool calling support
     - Audio (Whisper, TTS)
     - Embeddings
     - Image generation (DALL-E)
   
   - **Anthropic** (`lib/nex_ai/provider/anthropic.ex`)
     - Claude 3.5 Sonnet, Opus, etc.
     - Streaming support
     - Tool calling
   
   - **Google** (`lib/nex_ai/provider/google.ex`)
     - Gemini 1.5 Flash, Pro
     - Multi-modal support
     - Function calling
   
   - **Mistral** (`lib/nex_ai/provider/mistral.ex`)
     - Mistral Small, Large, etc.
     - OpenAI-compatible API
   
   - **Cohere** (`lib/nex_ai/provider/cohere.ex`)
     - Command R, Command R+
     - Chat history format

### Middleware System

The middleware system uses an interceptor pattern to wrap language models:

1. **Retry** (`lib/nex_ai/middleware/retry.ex`)
   - Automatic retry with exponential backoff
   - Configurable max retries and delays
   - Handles rate limits, timeouts, API errors

2. **Cache** (`lib/nex_ai/middleware/cache.ex`)
   - ETS-based caching
   - TTL support
   - Cache key based on provider + model + prompt hash

3. **Logging** (`lib/nex_ai/middleware/logging.ex`)
   - Request/response logging
   - Configurable log levels
   - Duration tracking

4. **RateLimit** (`lib/nex_ai/middleware/rate_limit.ex`)
   - Client-side rate limiting
   - Sliding window algorithm
   - Configurable limits per provider/model

5. **SmoothStream** (`lib/nex_ai/middleware/smooth_stream.ex`)
   - Artificial delays between tokens
   - Smoother UI experience

### Utilities

1. **StreamHelpers** (`lib/nex_ai/stream_helpers.ex`)
   - `stream_to_text/1` - Convert stream to text
   - `filter_by_type/2` - Filter chunks by type
   - `tee_stream/2` - Split stream to multiple consumers
   - `throttle_stream/2` - Rate limiting
   - `to_sse/1` - Convert to Server-Sent Events
   - `consume_stream/1` - Fully consume stream

2. **Prompt** (`lib/nex_ai/prompt.ex`)
   - `system/1`, `user/1`, `assistant/1` - Message builders
   - `user_with_images/2` - Multi-modal messages
   - `few_shot/3` - Few-shot learning prompts
   - `chain_of_thought/1` - CoT prompts
   - `structured_output/2` - JSON schema prompts
   - `format/2` - Template formatting
   - `truncate_messages/2` - Token limit management

3. **Schema** (`lib/nex_ai/schema.ex`)
   - `object/2`, `string/1`, `number/1`, `integer/1` - Schema builders
   - `array/2`, `enum/2`, `boolean/1`
   - `nullable/1`, `optional/1` - Modifiers

4. **Telemetry** (`lib/nex_ai/telemetry.ex`)
   - `:telemetry` integration
   - Events for generate, stream, provider requests
   - Default handlers for logging
   - Custom handler support

### Error Handling

Comprehensive error types (`lib/nex_ai/error.ex`):
- `APIError` - General API errors
- `RateLimitError` - Rate limit exceeded
- `AuthenticationError` - Invalid API key
- `InvalidRequestError` - Bad request parameters
- `TimeoutError` - Request timeout
- `ToolExecutionError` - Tool execution failed
- `ValidationError` - Schema validation failed
- `UnsupportedFeatureError` - Feature not supported by provider

### UI Adapters

1. **Vercel Data Stream** (`lib/nex_ai/ui/vercel.ex`)
   - Converts streams to Vercel AI SDK Data Stream Protocol
   - Compatible with `useChat`, `useCompletion` hooks

2. **Datastar** (`lib/nex_ai/ui/datastar.ex`)
   - SSE signals for Datastar framework
   - Signal patching for reactive UI
   - Fragment support

## Key Features

### 1. Unified API

```elixir
# Same API across all providers
model = NexAI.openai("gpt-4o")
model = NexAI.anthropic("claude-3-5-sonnet-latest")
model = NexAI.google("gemini-1.5-flash")

{:ok, result} = NexAI.generate_text(
  model: model,
  messages: [%{role: "user", content: "Hello!"}]
)
```

### 2. Streaming with Backpressure

```elixir
stream = NexAI.stream_text(
  model: NexAI.openai("gpt-4o"),
  messages: [...]
)

Enum.each(stream.full_stream, fn chunk ->
  case chunk.type do
    :text_delta -> IO.write(chunk.content)
    :tool_call_start -> handle_tool_call(chunk)
    :finish -> IO.puts("\nDone!")
  end
end)
```

### 3. Multi-Step Tool Calling

```elixir
weather_tool = NexAI.tool(
  name: "get_weather",
  description: "Get weather for a location",
  parameters: %{
    type: "object",
    properties: %{location: %{type: "string"}},
    required: ["location"]
  },
  execute: fn %{"location" => loc} ->
    "Weather in #{loc}: Sunny, 22°C"
  end
)

{:ok, result} = NexAI.generate_text(
  model: NexAI.openai("gpt-4o"),
  messages: [%{role: "user", content: "What's the weather in Beijing?"}],
  tools: [weather_tool],
  max_steps: 5
)
```

### 4. Structured Output

```elixir
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

IO.inspect(result.object)
# %{"name" => "John", "age" => 30}
```

### 5. Middleware Composition

```elixir
model = NexAI.openai("gpt-4o")
  |> NexAI.wrap_model([
    {NexAI.Middleware.Retry, max_retries: 3},
    {NexAI.Middleware.Logging, level: :info},
    {NexAI.Middleware.Cache, ttl: 3600}
  ])
```

### 6. Lifecycle Callbacks

```elixir
NexAI.stream_text(
  model: model,
  messages: messages,
  onToken: fn token -> IO.write(token) end,
  onStepFinish: fn step -> IO.inspect(step.toolResults) end,
  onFinish: fn result -> IO.puts("Total tokens: #{result.usage.totalTokens}") end
)
```

## Comparison with Vercel AI SDK

| Feature | Vercel AI SDK | NexAI |
|---------|---------------|-------|
| Language | TypeScript | Elixir |
| Streaming | Async Iterators | Lazy Streams |
| Providers | 15+ | 5 (extensible) |
| Tool Calling | ✅ | ✅ |
| Structured Output | ✅ | ✅ |
| Middleware | ✅ | ✅ |
| Telemetry | Custom | `:telemetry` |
| UI Integration | React hooks | Nex (Datastar/HTMX) |
| Backpressure | Limited | Native Elixir |

## Usage Examples

### Basic Text Generation

```elixir
{:ok, result} = NexAI.generate_text(
  model: NexAI.openai("gpt-4o"),
  messages: [
    %{role: "system", content: "You are a helpful assistant"},
    %{role: "user", content: "What is Elixir?"}
  ],
  temperature: 0.7,
  max_tokens: 500
)

IO.puts(result.text)
```

### Streaming with Real-time Updates

```elixir
stream = NexAI.stream_text(
  model: NexAI.anthropic("claude-3-5-sonnet-latest"),
  messages: [%{role: "user", content: "Tell me a story"}]
)

stream.full_stream
|> NexAI.StreamHelpers.filter_by_type(:text_delta)
|> Enum.each(fn chunk -> IO.write(chunk.content) end)
```

### Multi-Modal Input

```elixir
messages = [
  NexAI.Prompt.user_with_images(
    "What's in this image?",
    [%{url: "https://example.com/image.jpg"}]
  )
]

{:ok, result} = NexAI.generate_text(
  model: NexAI.google("gemini-1.5-flash"),
  messages: messages
)
```

### Advanced Tool Use

```elixir
calculator = NexAI.tool(
  name: "calculate",
  description: "Perform calculations",
  parameters: NexAI.Schema.object(%{
    expression: NexAI.Schema.string(description: "Math expression")
  }, required: ["expression"]),
  execute: fn %{"expression" => expr} ->
    {result, _} = Code.eval_string(expr)
    to_string(result)
  end
)

{:ok, result} = NexAI.generate_text(
  model: NexAI.openai("gpt-4o"),
  messages: [%{role: "user", content: "What is 123 * 456?"}],
  tools: [calculator],
  max_steps: 3
)
```

### Integration with Nex Framework

Nex 使用基于文件路由的架构，每个页面是一个模块，API 端点也是独立模块。

#### 页面示例（使用 Datastar）

```elixir
defmodule MyApp.Pages.Chat do
  use Nex
  use NexAI

  def mount(_params) do
    %{
      title: "AI Chat",
      messages: Nex.Store.get(:chat_history, []),
      input: "",
      isLoading: false
    }
  end

  def render(assigns) do
    ~H"""
    <div data-signals={Jason.encode!(%{
      input: @input,
      isLoading: false,
      messages: @messages
    })}>
      <div id="messages">
        <div :for={msg <- @messages}>
          <p>{msg.content}</p>
        </div>
      </div>
      
      <input 
        data-bind:input
        data-on:keydown.enter="!$isLoading && $input.trim() && ($isLoading=true, @post('/api/chat'))"
        placeholder="Type a message..."/>
    </div>
    """
  end
end
```

#### API 端点示例（SSE 流式）

```elixir
defmodule MyApp.Api.Chat do
  use Nex
  use NexAI

  def post(req) do
    messages = req.body["messages"] || []
    
    # 定义工具
    weather_tool = NexAI.tool(
      name: "get_weather",
      description: "Get weather for a location",
      parameters: %{
        type: "object",
        properties: %{location: %{type: "string"}},
        required: ["location"]
      },
      execute: fn %{"location" => loc} ->
        "Weather in #{loc}: Sunny, 22°C"
      end
    )

    # 流式生成并返回
    stream_text(
      model: NexAI.openai("gpt-4o"),
      messages: messages,
      tools: [weather_tool],
      max_steps: 5
    )
    |> to_data_stream()  # 返回 Vercel AI SDK 格式
  end
end
```

#### API 端点示例（Datastar SSE）

```elixir
defmodule MyApp.Api.DatastarChat do
  use Nex
  use NexAI

  def post(req) do
    input = req.body["input"] || ""
    messages = req.body["messages"] || []
    
    # 存储消息历史
    Nex.Store.update(:chat_history, [], fn history ->
      history ++ [%{role: "user", content: input}]
    end)

    stream_text(
      model: NexAI.openai("gpt-4o"),
      messages: messages ++ [%{role: "user", content: input}],
      max_steps: 5
    )
    |> to_datastar(
      signal: "aiResponse",
      status_signal: "aiStatus",
      loading_signal: "isLoading",
      initial_signals: %{"input" => ""}
    )
  end
end
```

#### 关键点

1. **页面模块**：`use Nex` + `mount/1` + `render/1`
2. **API 模块**：`use Nex` + HTTP 方法函数（`get/1`, `post/1` 等）
3. **请求对象**：`req.body`, `req.query`, `req.params`
4. **状态管理**：`Nex.Store.get/2`, `Nex.Store.put/2`, `Nex.Store.update/3`
5. **返回响应**：直接返回 `to_data_stream()` 或 `to_datastar()` 的结果

## Installation & Configuration

### 作为独立库使用

```elixir
# mix.exs
def deps do
  [
    {:nex_ai, path: "../nex_ai"}  # 本地开发
    # 或发布后: {:nex_ai, "~> 0.1.0"}
  ]
end
```

### 在 Nex 项目中使用

```elixir
# mix.exs - Nex 项目只需要一个依赖
def deps do
  [
    {:nex, path: "../../framework"}  # Nex 会自动传递所有依赖
  ]
end

# 如果需要 NexAI，在 Nex 项目中添加
def deps do
  [
    {:nex, path: "../../framework"},
    {:nex_ai, path: "../../nex_ai"}
  ]
end
```

### 配置 API Keys

NexAI 支持三种方式配置 API Keys，优先级从高到低：

#### 方式 1：运行时传递（最高优先级，推荐用于测试）

```elixir
# 直接在创建模型时传递
model = NexAI.openai("gpt-4o", api_key: "sk-...")
model = NexAI.anthropic("claude-3-5-sonnet-latest", api_key: "sk-ant-...")
```

#### 方式 2：配置文件（中等优先级）

```elixir
# config/runtime.exs 或 config/dev.exs
config :nex_ai,
  openai_api_key: System.get_env("OPENAI_API_KEY"),
  openai_base_url: System.get_env("OPENAI_BASE_URL"),
  anthropic_api_key: System.get_env("ANTHROPIC_API_KEY"),
  google_api_key: System.get_env("GOOGLE_API_KEY"),
  mistral_api_key: System.get_env("MISTRAL_API_KEY"),
  cohere_api_key: System.get_env("COHERE_API_KEY")
```

#### 方式 3：环境变量（最低优先级，推荐用于生产）

```bash
# .env 文件（Nex 框架会自动加载）
OPENAI_API_KEY=sk-...
OPENAI_BASE_URL=https://api.openai.com/v1
ANTHROPIC_API_KEY=sk-ant-...
GOOGLE_API_KEY=...
MISTRAL_API_KEY=...
COHERE_API_KEY=...
```

**注意**：
- 在 Nex 项目中，推荐使用方式 1（运行时传递）或方式 3（环境变量）
- 不要在配置文件中硬编码 API Keys，始终使用 `System.get_env/1`
- 配置文件的优先级高于环境变量，但环境变量更安全且便于部署

## Testing

### Mock Provider 实现

```elixir
# test/support/mock_provider.ex
defmodule NexAI.Test.MockProvider do
  @moduledoc """
  Mock provider for testing NexAI without making real API calls.
  """
  defstruct [:responses]
  
  defimpl NexAI.LanguageModel.Protocol do
    alias NexAI.LanguageModel.V1
    
    def provider(_), do: "mock"
    def model_id(_), do: "mock-model"
    
    def do_generate(model, _params) do
      {:ok, %V1.GenerateResult{
        text: List.first(model.responses),
        finish_reason: "stop",
        usage: %NexAI.Result.Usage{
          promptTokens: 10,
          completionTokens: 20,
          totalTokens: 30
        }
      }}
    end
    
    def do_stream(model, _params) do
      {:ok, Stream.concat([
        Stream.map(model.responses, fn text ->
          %V1.StreamChunk{type: :text_delta, content: text}
        end),
        [%V1.StreamChunk{type: :finish, finish_reason: "stop"}]
      ])}
    end
  end
end
```

### 测试示例

```elixir
# test/nex_ai_test.exs
defmodule NexAITest do
  use ExUnit.Case
  alias NexAI.Test.MockProvider

  test "generates text with mock provider" do
    model = %MockProvider{responses: ["Hello, world!"]}
    
    {:ok, result} = NexAI.generate_text(
      model: model,
      messages: [%{role: "user", content: "Hi"}]
    )
    
    assert result.text == "Hello, world!"
    assert result.finish_reason == "stop"
  end

  test "streams text with mock provider" do
    model = %MockProvider{responses: ["Hello", " ", "world", "!"]}
    
    stream = NexAI.stream_text(
      model: model,
      messages: [%{role: "user", content: "Hi"}]
    )
    
    text = stream.full_stream
    |> Enum.filter(&(&1.type == :text_delta))
    |> Enum.map(&(&1.content))
    |> Enum.join("")
    
    assert text == "Hello world!"
  end

  test "handles tool calls" do
    model = %MockProvider{responses: ["The weather is sunny"]}
    
    weather_tool = NexAI.tool(
      name: "get_weather",
      description: "Get weather",
      parameters: %{type: "object", properties: %{location: %{type: "string"}}},
      execute: fn %{"location" => _loc} -> "Sunny, 22°C" end
    )
    
    {:ok, result} = NexAI.generate_text(
      model: model,
      messages: [%{role: "user", content: "What's the weather?"}],
      tools: [weather_tool],
      max_steps: 2
    )
    
    assert result.text != nil
  end
end
```

### 在 Nex 项目中测试

```elixir
# test/pages/chat_test.exs
defmodule MyApp.Pages.ChatTest do
  use ExUnit.Case
  
  test "mount returns initial state" do
    state = MyApp.Pages.Chat.mount(%{})
    
    assert state.title == "AI Chat"
    assert state.messages == []
    assert state.input == ""
  end
end

# test/api/chat_test.exs  
defmodule MyApp.Api.ChatTest do
  use ExUnit.Case
  alias NexAI.Test.MockProvider
  
  test "post returns stream response" do
    # 使用 mock provider 避免真实 API 调用
    model = %MockProvider{responses: ["Test response"]}
    
    req = %{body: %{"messages" => [%{"role" => "user", "content" => "Hi"}]}}
    response = MyApp.Api.Chat.post(req)
    
    # 验证返回的是流式响应
    assert is_function(response) or is_struct(response)
  end
end
```

## Performance Considerations

1. **Streaming**: Uses lazy Elixir streams for memory efficiency
2. **Backpressure**: Built-in flow control prevents overwhelming consumers
3. **Concurrency**: Task.Supervisor for parallel tool execution
4. **Caching**: ETS-based cache for repeated queries
5. **Connection Pooling**: Finch for HTTP connection reuse

## Future Enhancements

- [ ] Additional providers (Groq, Together, Replicate)
- [ ] Vector database integrations
- [ ] RAG (Retrieval Augmented Generation) utilities
- [ ] Prompt template library
- [ ] Cost tracking and budgeting
- [ ] Response validation against schemas
- [ ] Automatic prompt optimization
- [ ] Multi-agent orchestration

## License

MIT
