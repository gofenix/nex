# NexAI 示例项目

基于 Vercel AI SDK v6 规范的 Elixir AI SDK 演示项目。

## 运行方式

```bash
# 运行单个示例
mix run examples/01_generate_text.exs

# 运行所有示例
bash run_all_examples.sh

# 查看示例概览
mix run demo.exs
```

## 示例列表

### 核心功能

| 文件 | 功能 | API |
|-----|------|-----|
| `01_generate_text.exs` | 基础文本生成 | `NexAI.generate_text/1` |
| `02_stream_text.exs` | 流式文本生成 | `NexAI.stream_text/1` |
| `03_generate_object.exs` | 非流式结构化输出 | `NexAI.generate_object/1` |
| `04_stream_object.exs` | 流式结构化输出 | `NexAI.stream_text/1` + `output` |

### 工具调用

| 文件 | 功能 | API |
|-----|------|-----|
| `05_tool_calling.exs` | 自动工具调用 | `NexAI.tool/1` |
| `06_multi_step.exs` | 多步生成（工具链） | `max_steps` |

### 中间件

| 文件 | 功能 | API |
|-----|------|-----|
| `07_smoothing.exs` | 平滑流中间件 | `NexAI.Middleware.SmoothStream` |
| `08_logging.exs` | 日志中间件 | `NexAI.Middleware.Logging` |
| `09_rate_limit.exs` | 速率限制中间件 | `NexAI.Middleware.RateLimit` |
| `18_retry.exs` | 重试中间件 | `NexAI.Middleware.Retry` |

### 高级功能

| 文件 | 功能 | API |
|-----|------|-----|
| `10_provider.exs` | 多 Provider 对比 | `NexAI.openai/1`, `NexAI.anthropic/1` |
| `11_advanced_params.exs` | 高级参数 | `temperature`, `max_tokens`, `stop` |
| `12_lifecycle.exs` | 生命周期钩子 | `on_finish`, `on_step_finish` |
| `13_system_prompt.exs` | 系统提示词 | `system` 参数 |
| `14_images.exs` | 图像生成 | `NexAI.generate_image/1` |
| `15_embed.exs` | 文本嵌入 | `NexAI.embed/1`, `NexAI.cosine_similarity/2` |
| `16_reasoning.exs` | 推理内容提取 | `NexAI.Middleware.ExtractReasoning` |
| `17_ui_protocols.exs` | UI 协议适配 | `NexAI.to_data_stream/1`, `NexAI.to_datastar/2` |

## 环境变量

复制 `.env.example` 到 `.env` 并配置 API Key：

```bash
cp .env.example .env
```

## 参考

- [Vercel AI SDK Examples](https://github.com/vercel/ai/tree/main/examples/ai-core/src)
- [NexAI 文档](../../nex_ai/README.md)
