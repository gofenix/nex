# Counter Example

A simple counter application demonstrating Nex framework fundamentals: state management, HTMX interactivity, and server-side rendering.

## Features

- Increment counter with + button
- Decrement counter with - button (won't go below 0)
- Reset counter to 0
- Server-side state management using Nex.Store
- HTMX-powered partial updates without page reload
- Beautiful Tailwind CSS styling with gradient backgrounds

## Getting Started

```bash
mix deps.get
mix nex.dev
```

Open http://localhost:4000

## How It Works

This example demonstrates:

1. **State Management** - Uses `Nex.Store` to persist counter value across requests
2. **HTMX Integration** - Buttons use `hx-post` to send requests without page reload
3. **Partial Updates** - Only the counter display updates, not the entire page
4. **Server-side Rendering** - All logic runs on the server, no JavaScript needed

## Code Structure

- `src/pages/index.ex` - Main page with counter display and button handlers
- `src/layouts.ex` - HTML layout with Tailwind and HTMX scripts
- `src/application.ex` - Application supervisor setup

## Deployment

Deploy with Docker:

```bash
docker build -t counter .
docker run -p 4000:4000 counter
```
