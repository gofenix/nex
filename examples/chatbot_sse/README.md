# Chatbot Demo

AI Chatbot example demonstrating two different interaction modes: SSE streaming and HTMX polling.

## Features

### SSE Streaming Mode (`/sse`)
- Real-time Server-Sent Events (SSE) streaming
- Character-by-character display, simulating typing effect
- Better user experience with instant feedback
- Persistent connection for streaming responses

### Synchronous Mode (`/polling`)
- Traditional synchronous request-response
- Server waits for AI response before returning
- Simplest possible implementation
- Single HTTP request per message

### Multi-page Routing Demo
- **Home page** (`/`) - Choose between two modes
- **SSE page** (`/sse`) - Streaming chat with SSE
- **Polling page** (`/polling`) - Traditional polling chat
- Demonstrates Nex's multi-page routing and action resolution
- Each page has its own `chat` action, showing context-aware routing

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

## What This Demo Shows

1. **Multi-page routing**: Three pages in one app (`/`, `/sse`, `/polling`)
2. **Action resolution**: Both `/sse` and `/polling` have their own `chat` action
3. **Referer-based routing**: Framework automatically routes actions to the correct page
4. **SSE streaming**: Real-time server-to-client communication
5. **Synchronous mode**: Traditional request-response pattern
