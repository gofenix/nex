# NexAI 示例项目

基于 Vercel AI SDK v6 规范的 Elixir AI SDK 演示项目。

## 示例列表

### 核心功能示例

| 示例文件 | 功能 | 对应 vendor/ai 示例 |
|---------|------|-------------------|
| `01_generate_text.exs` | 基础文本生成 | `generate-text/openai.ts` |
| `02_stream_text.exs` | 流式文本生成 | `stream-text/openai.ts` |
| `03_generate_object.exs` | 结构化输出 | `generate-object/openai.ts` |
| `04_stream_object.exs` | 流式结构化输出 | `stream-object/openai.ts` |
| `05_tool_calling.exs` | 工具调用 | `generate-text/openai-tool-call.ts` |
| `06_multi_step.exs` | 多步生成（工具链） | `generate-text/openai-multi-step.ts` |
| `07_chatbot.exs` | 多轮对话聊天机器人 | `stream-text/openai-chatbot.ts` |

### Provider 示例

| 示例文件 | 功能 | 对应 vendor/ai 示例 |
|---------|------|-------------------|
| `10_anthropic.exs` | Anthropic Claude | `generate-text/anthropic.ts` |

> 注：NexAI 主要支持 OpenAI 和 Anthropic 两个核心 provider。其他 provider（Google、Mistral、Cohere）可根据需要添加。

### 高级功能示例

| 示例文件 | 功能 | 对应 vendor/ai 示例 |
|---------|------|-------------------|
| `20_middleware_smooth.exs` | 平滑流中间件 | `middleware/simulate-streaming-example.ts` |
| `21_middleware_log.exs` | 日志中间件 | `middleware/generate-text-log-middleware-example.ts` |
| `22_middleware_rate_limit.exs` | 限流中间件 | `middleware/your-cache-middleware.ts` |
| `23_reasoning.exs` | 推理内容 | `generate-text/openai-reasoning.ts` |
| `24_images.exs` | 图像生成 | `generate-image/` |
| `25_embed.exs` | 文本嵌入 | `embed/` |

## 运行方式

```bash
# 运行单个示例
mix run examples/01_generate_text.exs

# 运行所有示例（使用脚本）
bash run_all_examples.sh
```

## 环境变量

复制 `.env.example` 到 `.env` 并配置 API Key：

```bash
cp .env.example .env
```

## 参考

- [Vercel AI SDK Examples](https://github.com/vercel/ai/tree/main/examples/ai-core/src)
- [NexAI 文档](../../nex_ai/README.md)
