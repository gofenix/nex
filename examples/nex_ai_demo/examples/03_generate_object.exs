# 示例 3: 非流式结构化对象生成 (generate_object)
# 运行方式: mix run examples/03_generate_object.exs

require Dotenvy
env = Dotenvy.source!([".env", System.get_env()])
Enum.each(env, fn {k, v} -> System.put_env(k, v) end)
if key = System.get_env("OPENAI_API_KEY"), do: Application.put_env(:nex_ai, :openai_api_key, key)

alias NexAI.Message.User

IO.puts "\n#{String.duplicate("=", 60)}"
IO.puts "示例 3: 非流式结构化对象生成 (generate_object)"
IO.puts "#{String.duplicate("=", 60)}\n"

IO.puts "使用 NexAI.generate_object/1 生成符合 JSON Schema 的结构化数据:\n"

case NexAI.generate_object(
  model: NexAI.openai("gpt-4o"),
  messages: [%User{content: "从以下文本提取信息: 张明，25岁，软件工程师，邮箱 zhangming@email.com"}],
  output: %{
    mode: :object,
    schema: %{
      type: "object",
      properties: %{
        name: %{type: "string", description: "人名"},
        age: %{type: "integer", description: "年龄"},
        profession: %{type: "string", description: "职业"},
        email: %{type: "string", description: "邮箱"}
      },
      required: ["name", "age", "profession", "email"]
    }
  }
) do
  {:ok, result} ->
    IO.puts "提取结果:"
    IO.puts "  #{Jason.encode!(result.object, pretty: true)}"
  {:error, reason} ->
    IO.puts "错误: #{inspect(reason)}"
end

IO.puts "\n代码示例:"
IO.puts """
  {:ok, result} = NexAI.generate_object(
    model: NexAI.openai("gpt-4o"),
    messages: [%User{content: "提取用户信息"}],
    output: %{
      mode: :object,
      schema: %{
        type: "object",
        properties: %{
          name: %{type: "string"},
          age: %{type: "integer"}
        },
        required: ["name", "age"]
      }
    }
  )

  IO.puts Jason.encode!(result.object, pretty: true)
"""
