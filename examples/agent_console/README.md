# Agent Console

A web-based control panel example with chat UI, session management, and real-time interaction.

## Features

- 💬 **Real-time Chat** - WebSocket-based messaging with streaming responses
- 📋 **Session Management** - Create, view, and delete conversation sessions
- 🛠️ **Runner Feedback** - Follow prompt/response flow through the local example runner
- 🧠 **Session Tracking** - Inspect and reset in-memory conversation sessions
- 🎨 **Modern UI** - Clean Tailwind CSS interface

## Quick Start

1. **Install dependencies**:
```bash
cd examples/agent_console
mix deps.get
```

2. **Configure environment**:
```bash
cp .env.example .env
# Edit .env with your API keys
```

3. **Start the server**:
```bash
mix nex.dev
```

4. **Open browser**:
Navigate to `http://localhost:4000`

## Configuration

Edit `.env` file:

```bash
# LLM Provider
LLM_PROVIDER=anthropic  # or openai
ANTHROPIC_API_KEY=sk-ant-api03-xxx
# or
OPENAI_API_KEY=sk-xxx
```

## Architecture

```
Browser (WebSocket)
    ↓
AgentConsole.WebSocketHandler
    ↓
AgentConsole.Channels.AgentSocket
    ↓
AgentConsole.SessionTracker (GenServer)
    ↓
Nex.Agent.SessionManager
    ↓
Nex.Agent.Runner → example runner
```

## Project Structure

```
examples/agent_console/
├── src/
│   ├── application.ex          # OTP Application
│   ├── layouts.ex              # HTML layouts
│   ├── pages/
│   │   ├── index.ex           # Chat interface
│   │   └── sessions/
│   │       └── index.ex       # Session management
│   ├── api/
│   │   └── sessions.ex        # API endpoints
│   ├── channels/
│   │   └── agent_socket.ex    # WebSocket channel logic
│   └── lib/
│       ├── session_tracker.ex # Agent instance manager
│       └── websocket_handler.ex # WebSocket handler
├── lib/
│   └── nex/agent.ex           # Local example agent runtime
├── .env                        # Environment variables
└── mix.exs
```

## License

MIT
