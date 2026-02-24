# Nex.Agent Design Specification (Revised)

> Elixir-native AI Coding Agent for Nex Framework
> Based on deep analysis of pi-coding-agent (pi-mono)

---

## 1. Key Insights from Pi-Coding-Agent

After analyzing pi-coding-agent (14K+ stars, the engine behind OpenClaw), here are the critical design principles:

1. **Exactly 4 tools** - read, bash, edit, write (not 5). More tools = more complexity without benefit.
2. **Tree-structured sessions** - Each entry has `id`/`parentId`, enabling branching without data loss
3. **JSONL storage** - One JSON object per line, easy to parse and append
4. **Versioned sessions** - Current v3, with migration support
5. **Minimal system prompt** - ~200 lines, including tool descriptions
6. **Context compaction** - Summarize old messages to stay within token limits
7. **Mid-session model switching** - Can change provider/model mid-conversation
8. **Project context files** - AGENTS.md, SYSTEM.md for project-specific instructions
9. **Extensions as lifecycle hooks** - TypeScript modules with events (not custom DSL)
10. **Skills as Markdown** - Prompt templates loaded on-demand

---

## 2. Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                            Nex.Agent                                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐            │
│  │    User     │───▶│  Nex.Agent   │───▶│   Session    │            │
│  │   (API)     │    │    (API)     │    │  (Tree)      │            │
│  └──────────────┘    └──────────────┘    └──────────────┘            │
│         │                    │                    │                       │
│         │                    ▼                    ▼                       │
│         │            ┌──────────────┐    ┌──────────────┐            │
│         │            │   Runner     │    │   Entry      │            │
│         │            │  (Loop)      │◀──▶│  (id/parentId)│            │
│         │            └──────────────┘    └──────────────┘            │
│         │                    │                                       │
│         │                    ▼                                       │
│         │            ┌──────────────┐    ┌──────────────┐            │
│         │            │     LLM     │    │    Tools     │            │
│         │            │  (Provider)  │    │  (Executor)   │            │
│         │            └──────────────┘    └──────────────┘            │
│         │                    │                    │                       │
│         │                    ▼                    ▼                       │
│         │            ┌─────────────────────────────────────┐           │
│         │            │      Tool Definitions (4 core)      │           │
│         │            │   read | bash | edit | write       │           │
│         │            └─────────────────────────────────────┘           │
│         │                                                       │
│         ▼                                                       │
│  ┌──────────────┐                                               │
│  │   Output     │◀───────────────────────────────────────────      │
│  │  (SSE/Stream)│   Real-time streaming                        │
│  └──────────────┘                                               │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Layered Architecture (Like Pi)

```
┌─────────────────────────────────────────┐
│           Nex.Agent (User API)           │
├─────────────────────────────────────────┤
│  Nex.Agent.Session (State + Tree)       │
├─────────────────────────────────────────┤
│  Nex.Agent.Runner (Agent Loop)          │
├─────────────────────┬───────────────────┤
│   Nex.Agent.LLM   │  Nex.Agent.Tools  │
│  (Multi-Provider)  │  (4 Core Tools)   │
└─────────────────────┴───────────────────┘
```

---

## 3. Module Structure

```
nex_agent/
├── lib/
│   ├── nex_agent.ex              # Main API (Nex.Agent)
│   ├── nex/
│   │   ├── agent/
│   │   │   ├── session.ex        # Session (tree-structured)
│   │   │   ├── entry.ex          # Session entry (id/parentId)
│   │   │   ├── runner.ex         # Agent loop
│   │   │   ├── system_prompt.ex  # Dynamic system prompt builder
│   │   │   ├── compaction.ex     # Context summarization
│   │   │   ├── tool/
│   │   │   │   ├── behaviour.ex  # Tool behaviour
│   │   │   │   ├── registry.ex   # Tool registry
│   │   │   │   ├── read.ex       # File read tool
│   │   │   │   ├── write.ex      # File write tool
│   │   │   │   ├── edit.ex       # File edit tool
│   │   │   │   └── bash.ex       # Shell execution
│   │   │   ├── llm/
│   │   │   │   ├── behaviour.ex  # LLM behaviour
│   │   │   │   ├── client.ex      # HTTP client
│   │   │   │   ├── openai.ex      # OpenAI provider
│   │   │   │   ├── anthropic.ex   # Anthropic provider
│   │   │   │   └── ollama.ex      # Ollama provider
│   │   │   └── config.ex          # Configuration
│   │   └── agent.ex               # Main module (Nex.Agent)
│   └── mix.exs
```

---

## 4. Session Design (Tree-Structured JSONL)

### Entry Format

```elixir
# Each entry is a map with type, id, parentId, timestamp
%{
  type: "message",           # message | model_change | thinking_level_change | compaction | custom | label | session_info
  id: "a1b2c3d4",           # 8-char hex
  parentId: "prev1234",      # nil for first entry, otherwise parent entry id
  timestamp: "2024-12-03T14:00:01.000Z",
  message: %{
    role: "user" | "assistant" | "tool_result",
    content: [...],
    toolCallId: "..."
  }
}
```

### Session File

```
~/.nex/agent/sessions/<project-id>/<session-id>.jsonl
```

Each line is a JSON entry:
```jsonl
{"type":"session","id":"abc123","version":3,"timestamp":"..."}
{"type":"message","id":"a1b2c3d4","parentId":"abc123","timestamp":"...","message":{"role":"user","content":"Create a user module"}}
{"type":"message","id":"b2c3d4e5","parentId":"a1b2c3d4","timestamp":"...","message":{"role":"assistant","content":"I'll create..."}}
{"type":"message","id":"c3d4e5f6","parentId":"b2c3d4e5","timestamp":"...","message":{"role":"tool_result","toolCallId":"...","content":"..."}}
```

### Tree Navigation

```
[user msg] ─── [assistant] ─── [user msg] ─── [assistant] ──┬─ [user msg] ← current leaf
                                                             │
                                                             └─ [user msg] ── [assistant] ← branch
```

- Each entry points to parent via `parentId`
- Current leaf = latest entry
- Branch = fork from any historical entry

### Session Operations

```elixir
# Create new session
{:ok, session} = Nex.Agent.Session.create(project: "my-app")

# Fork (branch) from current point
{:ok, forked_session} = Nex.Agent.Session.fork(session)

# Navigate to different branch
{:ok, session} = Nex.Agent.Session.navigate(session, entry_id: "a1b2c3d4")

# List all branches
branches = Nex.Agent.Session.branches(session)

# Get current leaf path
path = Nex.Agent.Session.current_path(session)
```

---

## 5. Core Tools (Exactly 4)

### Tool Definitions (JSON Schema for LLM)

```elixir
# 1. read - Read file contents
%{
  name: "read",
  description: "Read file contents",
  parameters: %{
    path: %{type: "string", description: "Absolute path to file"}
  }
}

# 2. bash - Execute shell commands
%{
  name: "bash",
  description: "Execute bash commands (ls, grep, find, etc.)",
  parameters: %{
    command: %{type: "string", description: "Command to execute"}
  }
}

# 3. edit - Make surgical edits (find + replace)
%{
  name: "edit",
  description: "Make surgical edits to files (find exact text and replace)",
  parameters: %{
    path: %{type: "string", description: "Absolute path to file"},
    search: %{type: "string", description: "Exact text to find"},
    replace: %{type: "string", description: "Text to replace with"}
  }
}

# 4. write - Create or overwrite files
%{
  name: "write",
  description: "Create or overwrite files",
  parameters: %{
    path: %{type: "string", description: "Absolute path to file"},
    content: %{type: "string", description: "Content to write"}
  }
}
```

### Why Only 4 Tools?

Pi's experience shows:
- More tools = more complexity = worse LLM decisions
- These 4 are sufficient for any coding task
- Extensions can add more if needed

---

## 6. System Prompt

### Dynamic Construction

```elixir
defmodule Nex.Agent.SystemPrompt do
  def build(opts \\ []) do
    """
    #{date_header()}
    #{project_context()}
    #{tool_descriptions()}
    #{guidelines()}
    #{append_prompt()}
    """
  end

  defp date_header do
    "Date: #{Date.utc_now() |> Calendar.strftime("%A, %B %d, %Y")}"
  end

  defp project_context do
    # Load AGENTS.md if exists
    # Load SYSTEM.md if exists
  end

  defp tool_descriptions do
    """
    ## Tools

    read: Read file contents
    bash: Execute bash commands (ls, grep, find, etc.)
    edit: Make surgical edits to files (find exact text and replace)
    write: Create or overwrite files
    """
  end

  defp guidelines do
    """
    ## Guidelines

    - Use the least invasive tool possible
    - Prefer read over edit, edit over write
    - Always verify after writing/editing
    - Keep changes focused and minimal
    """
  end
end
```

---

## 7. Context Compaction

When token limit approaches, summarize old messages:

```elixir
defmodule Nex.Agent.Compaction do
  # Compact when > 80% of context used
  def should_compact?(session, max_tokens) do
    current_tokens = count_tokens(session)
    current_tokens > max_tokens * 0.8
  end

  # Summarize and replace old entries with summary
  def compact(session, opts \\ []) do
    threshold = Keyword.get(opts, :threshold, 10000)

    # Get entries to compact
    entries = take_old_entries(session, threshold)

    # Ask LLM to summarize
    summary = summarize_with_llm(entries)

    # Replace with compaction entry
    insert_compaction_entry(session, summary, entries)
  end
end
```

---

## 8. Core API Design

### Starting an Agent

```elixir
# Start with default config (.env)
{:ok, agent} = Nex.Agent.start()

# Start with custom config
{:ok, agent} = Nex.Agent.start(
  provider: :anthropic,
  model: "claude-sonnet-4-20250514"
)

# Start with Ollama (local)
{:ok, agent} = Nex.Agent.start(
  provider: :ollama,
  model: "llama3.1"
)

# Start with project context
{:ok, agent} = Nex.Agent.start(project: "my-app")
```

### Sending Prompts

```elixir
# Synchronous (waits for completion)
{:ok, response, agent} = Nex.Agent.prompt(agent, "Create a user module")

# Streaming (callback for each chunk)
Nex.Agent.prompt_stream(agent, "Create a user module", fn chunk ->
  IO.write(chunk)
end)

# With file context
Nex.Agent.prompt(agent, "Write tests", files: ["lib/user.ex"])
```

### Session Management

```elixir
# Get session ID
session_id = Nex.Agent.session_id(agent)

# Fork session (create branch)
{:ok, forked_agent} = Nex.Agent.fork(agent)

# Navigate to different branch
{:ok, agent} = Nex.Agent.navigate(agent, to: "entry-id")

# List branches
branches = Nex.Agent.branches(agent)

# Switch model mid-session
{:ok, agent} = Nex.Agent.switch_model(agent, model: "gpt-4o")

# Abort running agent
:ok = Nex.Agent.abort(agent)

# Save/Load
:ok = Nex.Agent.save(agent)
{:ok, agent} = Nex.Agent.load("session-id")
```

---

## 9. Extension System

### Lifecycle Events

```elixir
# Hook into agent events
defmodule MyExtension do
  use Nex.Agent.Extension

  # Called before each LLM call
  def on_context(messages, ctx) do
    # Can modify messages
    messages
  end

  # Called after tool execution
  def on_tool_result(result, ctx) do
    # Can log, modify, etc.
    result
  end

  # Called after agent completes
  def on_complete(response, ctx) do
    # Can cleanup, notify, etc.
    :ok
  end
end

# Register extension
Nex.Agent.Extensions.register(MyExtension)
```

### Custom Tools

```elixir
defmodule MyExtension do
  use Nex.Agent.Extension

  def tool_deinitions do
    [
      %{
        name: "deploy",
        description: "Deploy the application",
        parameters: %{
          env: %{type: "string", enum: ["staging", "prod"]}
        }
      }
    ]
  end

  def execute("deploy", %{"env" => env}, ctx) do
    # Execute deployment
    {:ok, %{deployed: true, url: "https://..."}}
  end
end
```

---

## 10. Skills (Markdown Prompt Templates)

### Skill Format

```markdown
# deploy-skill.md

## Description
Deploy the application to staging or production

## Instructions
- Always run tests before deploying
- Use blue-green deployment
- Notify Slack after deployment

## Tools
- bash (for running deployment commands)
```

### Loading Skills

```elixir
# Skills loaded on-demand
Nex.Agent.Skill.load("deploy")
Nex.Agent.Skill.unload("deploy")

# In prompt
Nex.Agent.prompt(agent, "Deploy to staging", skills: ["deploy"])
```

---

## 11. Project Context Files

### AGENTS.md

Project-specific instructions for the agent:

```markdown
# Project Instructions

## Tech Stack
- Phoenix 1.7
- Elixir 1.15
- PostgreSQL

## Conventions
- Use Context pattern
- Tests in test/<module>_test.exs
- Follow Elixir formatter

## Common Tasks
- Run tests: mix test
- Start dev: mix phx.server
```

### SYSTEM.md

System-wide instructions:

```markdown
# Elixir Guidelines

- Use pipe operator (|>)
- Prefer pattern matching over conditionals
- Add typespecs for public APIs
- Use descriptive names
```

---

## 12. Provider Support

### Configuration

```elixir
# Anthropic (default)
config = %{
  provider: :anthropic,
  model: "claude-sonnet-4-20250514",
  api_key: System.get_env("ANTHROPIC_API_KEY")
}

# OpenAI
config = %{
  provider: :openai,
  model: "gpt-4o",
  api_key: System.get_env("OPENAI_API_KEY")
}

# Ollama (local)
config = %{
  provider: :ollama,
  model: "llama3.1",
  base_url: "http://localhost:11434/v1"
}

# OpenRouter (multiple providers)
config = %{
  provider: :openrouter,
  model: "anthropic/claude-3.5-sonnet",
  api_key: System.get_env("OPENROUTER_API_KEY")
}
```

### Mid-Session Switching

```elixir
# Switch model mid-conversation
{:ok, agent} = Nex.Agent.switch_model(agent,
  provider: :openai,
  model: "gpt-4o"
)
```

---

## 13. Usage Examples

### Basic Usage

```elixir
{:ok, agent} = Nex.Agent.start()

{:ok, result, agent} = Nex.Agent.prompt(agent, """
Create a module that handles user authentication.
Include login/2, logout/1 functions.
""")

IO.puts(result)
```

### In Nex Page (SSE Streaming)

```elixir
defmodule MyApp.Pages.Agent do
  use Nex

  def mount(_params) do
    %{response: ""}
  end

  def render(assigns) do
    ~H"""
    <form hx-post="/agent/ask" hx-target="#response" hx-swap="innerHTML">
      <input type="text" name="prompt" placeholder="What to build?" />
    </form>
    <div id="response">{raw(@response)}</div>
    """
  end

  def post(req) do
    prompt = req.body["prompt"]

    # Stream response to client
    Nex.stream(fn send ->
      {:ok, agent} = Nex.Agent.start()

      Nex.Agent.prompt_stream(agent, prompt, fn chunk ->
        send.(%{event: "message", data: chunk})
      end)

      send.(%{event: "done", data: "complete"})
    end)
  end
end
```

---

## 14. Key Differences from Original Design

| Aspect | Original | Revised (Pi-aligned) |
|--------|----------|---------------------|
| Tools | 5 (added grep) | 4 (exact match) |
| Session | Linear | Tree-structured (id/parentId) |
| Storage | Not specified | JSONL (one entry per line) |
| Versioning | None | Versioned (v1→v2→v3) |
| Model switching | Per-request | Mid-session |
| Extensions | Custom DSL | Lifecycle hooks + custom tools |
| Skills | Not included | Markdown-based templates |
| Context files | Not included | AGENTS.md, SYSTEM.md |
| Compaction | Not included | Summarization when near limit |

---

## 15. Dependencies

```elixir
def deps do
  [
    {:req, "~> 0.5"},           # HTTP client
    {:jason, "~> 1.4"},         # JSON parsing
    {:websockex, "~> 0.4"},     # WebSocket/SSE
    # Optional:
    {:bcrypt_elixir, "~> 3.0"}, # For tool security
  ]
end
```

---

## 16. Summary

This design is heavily inspired by pi-coding-agent, with adaptations for Elixir:

| Component | Purpose |
|-----------|---------|
| `Nex.Agent` | Main API - start, prompt, fork |
| `Nex.Agent.Session` | Tree-structured session with JSONL storage |
| `Nex.Agent.Entry` | Session entry with id/parentId |
| `Nex.Agent.Runner` | Agent loop with tool execution |
| `Nex.Agent.SystemPrompt` | Dynamic system prompt builder |
| `Nex.Agent.Compaction` | Context summarization |
| `Nex.Agent.Tools` | 4 core tools (read, bash, edit, write) |
| `Nex.Agent.LLM` | Multi-provider LLM integration |
| `Nex.Agent.Extension` | Lifecycle hooks for extensibility |
| `Nex.Agent.Skill` | Markdown-based prompt templates |
