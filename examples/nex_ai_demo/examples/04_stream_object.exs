# 示例 4: 流式结构化输出 (stream_object)
# 运行方式: mix run examples/04_stream_object.exs

require Dotenvy
env = Dotenvy.source!([".env", System.get_env()])
Enum.each(env, fn {k, v} -> System.put_env(k, v) end)
if key = System.get_env("OPENAI_API_KEY"), do: Application.put_env(:nex_ai, :openai_api_key, key)

alias NexAI.Message.User

IO.puts "\n#{String.duplicate("=", 60)}"
IO.puts "示例 4: 流式结构化输出 (stream_object)"
IO.puts "#{String.duplicate("=", 60)}\n"

IO.puts "使用 stream_text + output schema 实现流式结构化输出:\n"

case NexAI.stream_text(
  model: NexAI.openai("gpt-4o"),
  messages: [%User{content: "生成一个用户信息 JSON，包含 name(字符串), age(数字), email(字符串)。"}],
  output: %{
    mode: :object,
    schema: %{
      type: "object",
      properties: %{
        name: %{type: "string"},
        age: %{type: "integer"},
        email: %{type: "string"}
      },
      required: ["name", "age", "email"]
    }
  },
  on_token: fn obj -> IO.puts("  [增量] #{Jason.encode!(obj)}") end
) do
  %{full_stream: stream} ->
    IO.write "解析进度: "
    Enum.each(stream, fn event ->
      if event.type == :object_delta, do: IO.write("█")
    end)
    IO.puts " ✓"
  error -> IO.puts "错误: #{inspect(error)}"
end

IO.puts "\n代码示例:"
IO.puts """
  stream = NexAI.stream_text(
    model: NexAI.openai("gpt-4o"),
    messages: [%User{content: "生成用户信息"}],
    output: %{
      mode: :object,
      schema: %{
        type: "object",
        properties: %{
          name: %{type: "string"},
          age: %{type: "integer"}
        }
      }
    }
  )

  # 使用 on_token 回调处理增量更新
  Enum.each(stream.full_stream, fn event ->
    if event.type == :object_delta do
      handle_partial_object(event.partial_object)
    end
  end)
"""
