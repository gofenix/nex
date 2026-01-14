# NexAI 完整功能演示脚本
# 运行方式: mix run demo.exs
#
# 此文件包含所有示例的概览，运行单个示例使用:
#   mix run examples/01_generate_text.exs
#   bash run_all_examples.sh  # 运行所有示例

# 1. 加载环境变量
require Dotenvy
env = Dotenvy.source!([".env", System.get_env()])
Enum.each(env, fn {k, v} -> System.put_env(k, v) end)

# 确保 nex_ai 能够读取到配置
if key = System.get_env("OPENAI_API_KEY"), do: Application.put_env(:nex_ai, :openai_api_key, key)
if url = System.get_env("OPENAI_BASE_URL"), do: Application.put_env(:nex_ai, :openai_base_url, url)
if anthropic_key = System.get_env("ANTHROPIC_API_KEY"), do: Application.put_env(:nex_ai, :anthropic_api_key, anthropic_key)

IO.puts "🔧 已加载配置:"
IO.puts "   - OpenAI: #{System.get_env("OPENAI_BASE_URL") || "默认 endpoint"}"
IO.puts "   - Anthropic: #{System.get_env("ANTHROPIC_BASE_URL") || "默认 endpoint"}"

IO.puts "\n#{String.duplicate("=", 60)}"
IO.puts "                    NexAI 完整功能演示"
IO.puts "#{String.duplicate("=", 60)}\n"

IO.puts "📚 可用的独立示例 (examples/ 目录下):\n"

IO.puts "  核心功能:"
IO.puts "    01_generate_text.exs   - 基础文本生成"
IO.puts "    02_stream_text.exs     - 流式文本生成"
IO.puts "    03_generate_object.exs - 非流式结构化输出"
IO.puts "    04_stream_object.exs   - 流式结构化输出"
IO.puts ""
IO.puts "  工具调用:"
IO.puts "    05_tool_calling.exs    - 自动工具调用"
IO.puts "    06_multi_step.exs      - 多步生成（工具链）"
IO.puts ""
IO.puts "  中间件:"
IO.puts "    07_smoothing.exs       - 平滑流中间件"
IO.puts "    08_logging.exs         - 日志中间件"
IO.puts "    09_rate_limit.exs      - 速率限制中间件"
IO.puts "    18_retry.exs           - 重试中间件"
IO.puts ""
IO.puts "  高级功能:"
IO.puts "    10_provider.exs        - 多 Provider 对比"
IO.puts "    11_advanced_params.exs - 高级参数"
IO.puts "    12_lifecycle.exs       - 生命周期钩子"
IO.puts "    13_system_prompt.exs   - 系统提示词"
IO.puts "    14_images.exs          - 图像生成"
IO.puts "    15_embed.exs           - 文本嵌入"
IO.puts "    16_reasoning.exs       - 推理内容提取"
IO.puts "    17_ui_protocols.exs    - UI 协议适配"

IO.puts "\n#{String.duplicate("=", 60)}"
IO.puts "要运行特定示例，请执行:"
IO.puts "  mix run examples/01_generate_text.exs"
IO.puts ""
IO.puts "要运行所有示例，请执行:"
IO.puts "  bash run_all_examples.sh"
IO.puts "#{String.duplicate("=", 60)}\n"
