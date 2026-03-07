# Nex Agent

Nex Agent is the agent product line in this monorepo: an Elixir runtime for building coding agents with tools, memory, MCP integration, skills, reflection, and self-evolution workflows.

If you are looking for the HTMX-first web framework, start at the repository root `README.md`. If you are looking for the agent product, start here.

## Why Nex Agent

Nex Agent is designed for developers who want an agent runtime they can script, inspect, extend, and integrate into real systems.

- **Tool-using agents** — file, edit, command, and other runtime tools
- **Memory support** — save, search, and reuse prior lessons
- **Skills system** — reusable task-specific instruction packs
- **MCP integration** — discover and call Model Context Protocol servers
- **Session-based execution** — run work inside persistent sessions
- **Self-evolution workflows** — modify, version, and roll back agent code

## What It Is and Is Not

Nex Agent is a good fit for:

- coding assistants
- autonomous dev workflows
- tool-using agents in Elixir systems
- agent consoles and operator-facing control panels
- experimentation with memory, skills, and MCP tooling

Nex Agent is not trying to be:

- a hosted no-code agent builder
- a generic chat UI product
- a replacement for every orchestration framework

## Quick Example

```elixir
{:ok, session} = Nex.Agent.Session.create(project_id: "my-project")

{:ok, result, session} = Nex.Agent.Runner.run(
  session,
  "Create a hello.ex file with IO.puts(\"Hello World\")"
)
```

## Core Concepts

### Sessions

A session represents the running context for an agent workflow.

```elixir
{:ok, session} = Nex.Agent.Session.create(project_id: "demo")
```

### Tools

Agents can use built-in tools for common coding actions.

```text
Agent: "read the file mix.exs"
Agent: "write to hello.txt with content 'Hello World'"
Agent: "edit mix.exs, replace 'defp' with 'def'"
Agent: "run mix test"
```

### Memory

Store useful lessons and search them later.

```elixir
Nex.Agent.Memory.append("Fixed login bug", "SUCCESS", %{issue: "123"})
results = Nex.Agent.Memory.search("login bug")
```

Or invoke memory behavior through the agent interface:

```text
Agent: "Remember this lesson: always validate input"
Agent: "Search previous memory about database issues"
```

### Skills

Skills are reusable, task-specific instruction packs.

Create `~/.nex/agent/skills/deploy/SKILL.md`:

```yaml
---
name: deploy
description: Deploy the application to production
disable-model-invocation: true
---

Deploy the application to production:

1. Run tests: mix test
2. Build: mix release
3. Deploy to host
```

Then call it with:

```text
Agent: /deploy production
```

### MCP

Nex Agent can discover and call MCP servers.

```elixir
servers = Nex.Agent.MCP.Discovery.scan()

{:ok, server_id} = Nex.Agent.MCP.ServerManager.start("filesystem",
  command: "npx",
  args: ["-y", "@modelcontextprotocol/server-filesystem", "/Users/xxx/data"]
)

{:ok, result} = Nex.Agent.MCP.ServerManager.call_tool(server_id, "read_file", %{path: "..."})
```

Or through the agent interface:

```text
Agent: "Discover available MCP servers"
Agent: "Start the filesystem server"
Agent: "Use MCP to read /Users/xxx/data/file.txt"
```

### Evolution

One of the distinctive ideas in Nex Agent is that the agent can modify and version parts of its own codebase.

```text
Agent: "Modify Nex.Agent.Runner to add logging"
Agent: "Show version history for Nex.Agent.Runner"
Agent: "Rollback to the previous version"
```

Direct API usage:

```elixir
{:ok, version} = Nex.Agent.Evolution.upgrade_module(
  Nex.Agent.Runner,
  "def run(...) do\n  IO.puts(\"Modified!\")\nend"
)

:ok = Nex.Agent.Evolution.rollback(Nex.Agent.Runner)
versions = Nex.Agent.Evolution.list_versions(Nex.Agent.Runner)
```

### Reflection

Agents can reflect on prior execution and error patterns.

```text
Agent: "Reflect on the last execution and suggest improvements"
Agent: "Analyze recent failure patterns"
```

## Configuration

### MCP Configuration

Create `~/.nex/agent/mcp.json`:

```json
{
  "servers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/Users/xxx/data"]
    },
    "github": {
      "command": "/path/to/mcp-server-github",
      "env": {
        "GITHUB_TOKEN": "xxx"
      }
    }
  }
}
```

### Environment Variables

```bash
export ANTHROPIC_API_KEY="sk-..."
export OPENAI_API_KEY="sk-..."
```

Keep API keys out of the repository and inject them through environment variables.

## End-to-End Example

```elixir
defmodule MyAgent do
  def run(prompt) do
    {:ok, session} = Nex.Agent.Session.create(project_id: "demo")
    :ok = Nex.Agent.Skills.load()

    case Nex.Agent.Runner.run(session, prompt) do
      {:ok, result, _session} ->
        IO.puts("Result: #{result}")
        Nex.Agent.Memory.append(prompt, "SUCCESS", %{})
        {:ok, result}

      {:error, reason, _session} ->
        IO.puts("Error: #{reason}")
        {:error, reason}
    end
  end
end
```

## Product Positioning

This repository contains two product lines:

- **Nex** — the HTMX-first Elixir web framework and related tooling
- **Nex Agent** — the agent runtime and tooling line

Nex Agent should be evaluated on its own use cases, documentation, and launch narrative.
