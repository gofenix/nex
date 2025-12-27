# Chatbot SSE

SSE (Server-Sent Events) 流式响应聊天机器人示例。

## 特点

- 使用 SSE 进行实时流式响应
- 字符逐字显示，模拟打字效果
- 简单易用的 Elixir + HTMX 架构

## 启动

```bash
cd examples/chatbot_sse
mix nex.dev
```

访问 http://localhost:4000

## 配置

在 `.env` 文件中配置：

```env
OPENAI_API_KEY=your_api_key_here
OPENAI_BASE_URL=https://api.openai.com/v1
```

未配置时使用模拟响应。
