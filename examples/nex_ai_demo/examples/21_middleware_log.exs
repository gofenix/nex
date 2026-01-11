# 示例 21: 日志中间件 (Log Middleware)
# 对应 vendor/ai/examples/ai-core/src/middleware/generate-text-log-middleware-example.ts

require Dotenvy
env = Dotenvy.source!([".env", System.get_env()])
Enum.each(env, fn {k, v} -> System.put_env(k, v) end)

if key = System.get_env("OPENAI_API_KEY"), do: Application.put_env(:nex_ai, :openai_api_key, key)

alias NexAI.Message.User

IO.puts "🚀 示例 21: 日志中间件 (Log Middleware)"
IO.puts "----------------------------------------"

# 自定义日志中间件
defmodule LogMiddleware do
  @behaviour NexAI.Middleware

  def wrap_generate(model, params, _opts, next) do
    IO.puts "\n[LOG] Starting generate_text..."
    IO.puts "[LOG] Model: #{inspect(model)}"
    IO.puts "[LOG] Messages: #{length(params.prompt)}"

    result = next.(model, params)

    case result do
      {:ok, res} ->
        IO.puts "[LOG] Success! Tokens: #{res.usage.totalTokens}"
      {:error, err} ->
        IO.puts "[LOG] Error: #{inspect(err)}"
    end

    result
  end

  def wrap_stream(model, params, _opts, next) do
    IO.puts "\n[LOG] Starting stream_text..."
    IO.puts "[LOG] Model: #{inspect(model)}"
    IO.puts "[LOG] Messages: #{length(params.prompt)}"

    stream = next.(model, params)

    Stream.transform(stream, fn -> 0 end, fn event, count ->
      new_count = case event.type do
        :text_delta -> count + String.length(event.text || "")
        :finish ->
          IO.puts "[LOG] Stream finished! Total chars: #{count}"
          count
        _ -> count
      end
      {[event], new_count}
    end, fn _ -> :ok end)
  end
end

log_model = NexAI.wrap_model(
  NexAI.openai("gpt-4o"),
  [LogMiddleware]
)

case NexAI.generate_text(
  model: log_model,
  messages: [%User{content: "What cities are in the United States?"}]
) do
  {:ok, result} ->
    IO.puts "\n📝 Content:"
    IO.puts result.text
  {:error, reason} ->
    IO.puts "❌ Error: #{inspect(reason)}"
end
