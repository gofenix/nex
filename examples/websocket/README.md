# Nex.WebSocket Example

Demonstrates real-time WebSocket communication with Nex 0.4.

## Features

- WebSocket connection with `handle_connect/1`, `handle_message/2`, `handle_disconnect/1`
- Room-based broadcasting with `Nex.WebSocket.broadcast/2`
- Topic subscriptions with `Nex.WebSocket.subscribe/1`
- Real-time chat interface

## Run

```bash
cd examples/websocket
mix deps.get
mix nex.dev
```

Visit http://localhost:4000

## Structure

- `src/api/chat.ex` - WebSocket handler module
- `src/pages/index.ex` - Chat UI page
