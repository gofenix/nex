#!/bin/bash

# 运行所有 NexAI 示例
# 按类别分组运行，便于查看

echo "========================================"
echo "NexAI 示例集合"
echo "========================================"
echo ""

# 检查 .env 文件
if [ ! -f .env ]; then
  echo "❌ 错误: .env 文件不存在"
  echo "请复制 .env.example 到 .env 并配置 API Key"
  exit 1
fi

# 核心功能示例
echo "📦 核心功能示例"
echo "----------------------------------------"

echo "1. 基础文本生成..."
mix run examples/01_generate_text.exs
echo ""

echo "2. 流式文本生成..."
mix run examples/02_stream_text.exs
echo ""

echo "3. 非流式结构化输出..."
mix run examples/03_generate_object.exs
echo ""

echo "4. 流式结构化输出..."
mix run examples/04_stream_object.exs
echo ""

# 工具调用示例
echo ""
echo "📦 工具调用示例"
echo "----------------------------------------"

echo "5. 自动工具调用..."
mix run examples/05_tool_calling.exs
echo ""

echo "6. 多步生成..."
mix run examples/06_multi_step.exs
echo ""

# 中间件示例
echo ""
echo "📦 中间件示例"
echo "----------------------------------------"

echo "7. 平滑流中间件..."
mix run examples/07_smoothing.exs
echo ""

echo "8. 日志中间件..."
mix run examples/08_logging.exs
echo ""

echo "9. 速率限制中间件..."
mix run examples/09_rate_limit.exs
echo ""

echo "18. 重试中间件..."
mix run examples/18_retry.exs
echo ""

# 高级功能示例
echo ""
echo "📦 高级功能示例"
echo "----------------------------------------"

echo "10. 多 Provider 对比..."
mix run examples/10_provider.exs
echo ""

echo "11. 高级参数..."
mix run examples/11_advanced_params.exs
echo ""

echo "12. 生命周期钩子..."
mix run examples/12_lifecycle.exs
echo ""

echo "13. 系统提示词..."
mix run examples/13_system_prompt.exs
echo ""

echo "14. 图像生成..."
mix run examples/14_images.exs
echo ""

echo "15. 文本嵌入..."
mix run examples/15_embed.exs
echo ""

echo "16. 推理内容提取..."
mix run examples/16_reasoning.exs
echo ""

echo "17. UI 协议适配..."
mix run examples/17_ui_protocols.exs
echo ""

echo "========================================"
echo "✅ 所有示例运行完成!"
echo "========================================"
