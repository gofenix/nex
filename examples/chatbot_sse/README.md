# Chatbot SSE

SSE (Server-Sent Events) streaming response chatbot example.

## Features

- Uses SSE for real-time streaming responses
- Character-by-character display, simulating typing effect
- Simple and easy-to-use Elixir + HTMX architecture

## Getting Started

```bash
cd examples/chatbot_sse
mix nex.dev
```

Visit http://localhost:4000

## Configuration

Configure in `.env` file:

```env
OPENAI_API_KEY=your_api_key_here
OPENAI_BASE_URL=https://api.openai.com/v1
```

Uses mock responses when not configured.
