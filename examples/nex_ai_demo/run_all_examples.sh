#!/bin/bash

# 运行所有 NexAI 示例脚本

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

echo "3. 结构化输出..."
mix run examples/03_generate_object.exs
echo ""

echo "4. 流式结构化输出..."
mix run examples/04_stream_object.exs
echo ""

echo "5. 工具调用..."
mix run examples/05_tool_calling.exs
echo ""

echo "6. 多步生成..."
mix run examples/06_multi_step.exs
echo ""

# Provider 示例
echo ""
echo "📦 Provider 示例"
echo "----------------------------------------"

echo "10. Anthropic Claude..."
mix run examples/10_anthropic.exs 2>/dev/null || echo "  (跳过 - 需要配置 ANTHROPIC_API_KEY)"
echo ""

# 高级功能示例
echo ""
echo "📦 高级功能示例"
echo "----------------------------------------"

echo "20. 平滑流中间件..."
mix run examples/20_middleware_smooth.exs
echo ""

echo "21. 日志中间件..."
mix run examples/21_middleware_log.exs
echo ""

echo "22. 限流中间件..."
mix run examples/22_middleware_rate_limit.exs
echo ""

echo "23. 推理内容..."
mix run examples/23_reasoning.exs 2>/dev/null || echo "  (跳过 - 需要 o1 模型访问权限)"
echo ""

echo "24. 图像生成..."
mix run examples/24_images.exs
echo ""

echo "25. 文本嵌入..."
mix run examples/25_embed.exs
echo ""

echo "========================================"
echo "✅ 所有示例运行完成!"
echo "========================================"
