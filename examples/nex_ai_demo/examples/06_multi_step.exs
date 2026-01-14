# 示例 6: 多步生成 (Multi-step Generation)
# 运行方式: mix run examples/06_multi_step.exs

require Dotenvy
env = Dotenvy.source!([".env", System.get_env()])
Enum.each(env, fn {k, v} -> System.put_env(k, v) end)
if key = System.get_env("OPENAI_API_KEY"), do: Application.put_env(:nex_ai, :openai_api_key, key)

alias NexAI.Message.User

IO.puts "\n#{String.duplicate("=", 60)}"
IO.puts "示例 6: 多步生成 (Multi-step Generation)"
IO.puts "#{String.duplicate("=", 60)}\n"

IO.puts "多步生成允许 AI 在单次请求中多次调用工具，形成工具链:\n"

# 定义搜索工具
search_tool = NexAI.tool(%{
  name: "search",
  description: "搜索信息",
  parameters: %{
    type: "object",
    properties: %{
      query: %{type: "string"}
    },
    required: ["query"]
  },
  execute: fn %{"query" => query} ->
    "搜索结果: 关于「#{query}」的信息..."
  end
})

# 定义翻译工具
translate_tool = NexAI.tool(%{
  name: "translate",
  description: "翻译文本",
  parameters: %{
    type: "object",
    properties: %{
      text: %{type: "string"},
      target_lang: %{type: "string"}
    },
    required: ["text", "target_lang"]
  },
  execute: fn %{"text" => text, "target_lang" => lang} ->
    "翻译成 #{lang}: #{text}"
  end
})

IO.puts "执行搜索 -> 翻译 的工具链...\n"

{:ok, res} = NexAI.generate_text(
  model: NexAI.openai("gpt-4o"),
  tools: [search_tool, translate_tool],
  max_steps: 5,
  messages: [%User{content: "搜索 Elixir 的介绍，然后翻译成英文"}]
)

IO.puts "\n最终回答: #{res.text}"
IO.puts "执行步骤数: #{length(res.steps)}"

IO.puts "\n代码示例:"
IO.puts ~S"""
  {:ok, result} = NexAI.generate_text(
    model: NexAI.openai("gpt-4o"),
    tools: [search_tool, translate_tool],
    max_steps: 5,  # 最多执行 5 步
    messages: [%User{content: "搜索信息并翻译"}]
  )

  IO.puts result.text
  IO.puts "Steps: #{length(result.steps)}"
"""
