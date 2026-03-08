# NexAgent vs Nanobot Deep Comparison

## Overview

| Dimension | NexAgent (Elixir) | Nanobot (Python) |
|-----------|-------------------|------------------|
| Language | Elixir / OTP | Python / asyncio |
| Positioning | Self-evolving AI agent platform | Lightweight AI agent framework |
| Core code size | ~62 `.ex` files | ~58 `.py` files, ~4000 core lines |
| Runtime mode | Gateway service | CLI + Gateway dual mode |
| Concurrency model | Actor model (GenServer/Process) | asyncio + global serialized lock |
| Self-evolution | Core feature (hot reload + canary) | Not supported |

---

## Repository Strategy

NexAgent will remain inside the `nex` repository for now.

Current coupling is real, but still moderate:

- Ecosystem coupling already exists through examples, showcase apps, and root-level release notes.
- Product positioning also benefits from staying close to the broader Nex narrative while the agent runtime is still being defined.
- Technical dependency coupling is still limited, which means the project can be extracted later without a painful rewrite.

This leads to a pragmatic decision:

- Keep NexAgent in the monorepo while its runtime boundaries, self-evolution model, and public positioning are still evolving.
- Revisit a split only after release cadence, documentation entry points, and product identity become clearly independent.

---

## 1. Architecture Comparison

### Agent Loop

| | NexAgent | Nanobot |
|--|---------|--------|
| Entry point | `Runner.run/3` | `AgentLoop._run_agent_loop()` |
| Iteration limit | default 10, hard 50, auto-expand | default 40, fixed |
| Tool execution | **Parallel** (`Task.async_stream`, 60s timeout) | **Serial** (await one by one) |
| Message handling | Independent process per session | **Globally serialized** (`_processing_lock`) |
| Error handling | Multi-level: transient retry → error analysis → recovery | try/except, errors not persisted |
| Error recovery | Tool def error → skip skills; context too long → trim messages | None |
| JSON repair | `JsonRepair` for malformed tool args | Similar fallback parsing |
| Loop detection | Same tool pattern 3x → auto break | None (relies on LLM) |
| Progress callbacks | `on_progress` (thinking + tool_hint) | progress streaming (thinking blocks) |

**Key difference**: NexAgent uses Elixir's process model to deliver **true session-level concurrency**. Multiple users can interact simultaneously without blocking each other. Nanobot uses a global lock, so only one message can be processed at a time. NexAgent also has built-in resilience: transient retries, error-driven recovery, JSON repair, and loop detection — none of which exist in Nanobot.

### LLM Provider

| | NexAgent | Nanobot |
|--|---------|--------|
| Abstraction | `LLM.Behaviour` (Elixir behaviour) | `LLMProvider` base class |
| Provider count | 3 (Anthropic, OpenAI, OpenRouter) | **20+** (via LiteLLM + custom registry) |
| Default | Anthropic Claude | Configurable |
| Prompt caching | Anthropic ephemeral + chunked cache | Anthropic `cache_control` |
| Message format conversion | Manual per provider | Unified through LiteLLM |
| JSON repair | `JsonRepair` module | Similar fallback parsing |
| Thinking / reasoning | `reasoning_content` field extraction | `reasoning_content` + `thinking_blocks` |

**Key difference**: Nanobot connects to 20+ providers easily through LiteLLM. NexAgent implements each provider adapter manually, which provides more control (prompt caching, message merging) but requires more work.

### Tool System

| | NexAgent | Nanobot |
|--|---------|--------|
| Registration model | GenServer registry (dynamic) | Dict-based registry |
| Default tools | 18+ | 9 + MCP tools |
| Tool hot reload | Supported (`hot_swap`) | Not supported |
| Auto-discovery | Filesystem scan for evolved tools | None |
| MCP support | Yes (`browser_mcp.ex`) | Yes (`MCPToolWrapper`, stdio + HTTP) |
| Categories | `:base \| :evolution \| :skill` | None |
| Category filtering | `:all \| :base \| :subagent \| :cron` | None |
| Safety restrictions | Workspace sandbox + command blacklist | `restrict_to_workspace` + deny patterns |
| Execution timeout | 60s per tool (`Task.async_stream`) | 30s default (MCP) |
| Tool name validation | Regex `^[a-zA-Z][a-zA-Z0-9_-]*$` | Provider-validated |

**Shared tools**: read, write, edit, bash/exec, web_search, web_fetch, message, spawn, cron
**NexAgent-only**: evolve, reflect, soul_update, skill_create/list/search/install, list_dir, memory_search
**Nanobot-only**: MCP tool wrapper (broader MCP integration)

**Key difference**: NexAgent uses a GenServer-based registry that supports dynamic runtime registration, unloading, and hot replacement of tool modules. Nanobot registers tools statically at startup. NexAgent executes tools in parallel; Nanobot executes them serially. NexAgent auto-discovers evolved tools on restart.

---

## 2. Core Feature Comparison

### Self-Evolution — Unique to NexAgent

NexAgent's biggest differentiator:

- **Evolution.ex**: Versioned hot-code reload engine — backup → validate → compile → load → health check → persist
- **Surgeon.ex**: Safe surgery orchestrator with canary monitoring
  - Core modules (Runner, Session, ContextBuilder, etc.): 10-second canary window with auto-rollback on crash
  - Limb modules (tools, skills): direct evolution without canary
  - Monitors InboundWorker + Subagent processes during canary
  - Git persistence: auto-commit + push after successful evolution
- **Evolve Tool**: Lets the agent modify any of its own module code through a tool call
- **Reflect Tool**: Lets the agent read its own source, inspect version history, and compare diffs
- **Harness**: Collects tool execution results → reflects with the LLM → generates improvement suggestions → auto-applies approved suggestions
  - Exponential backoff when no suggestions found (15min → 30min → 1h → 2h → 4h max)
  - Suggestion types: `new_skill`, `soul_update`, `memory_entry`, `strategy_change`
  - Daily memory review with automatic pruning of outdated sections
- **Rollback**: Supports rollback by version ID

Nanobot has **no self-evolution capability at all**. Its code is static and can only be extended through skills (Markdown files) and configuration.

### Concurrency Model

```
NexAgent (Elixir/OTP):
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Session A    │  │ Session B    │  │ Session C    │
│ (process)    │  │ (process)    │  │ (process)    │
│ tool1 ──┐   │  │ tool1 ──┐   │  │ tool1 ──┐   │
│ tool2 ──┤   │  │ tool2 ──┤   │  │ tool2 ──┤   │
│ tool3 ──┘   │  │ tool3 ──┘   │  │ tool3 ──┘   │
└──────────────┘  └──────────────┘  └──────────────┘
        ▲ True parallelism: across sessions + across tools

Nanobot (Python/asyncio):
┌──────────────────────────────────────────────┐
│ Global Lock  (_processing_lock)              │
│ ┌───────┐ → ┌───────┐ → ┌───────┐          │
│ │ Msg A │   │ Msg B │   │ Msg C │  serial   │
│ │ tool1 │   │ wait  │   │ wait  │          │
│ │ tool2 │   │  ...  │   │  ...  │          │
│ │ tool3 │   │       │   │       │          │
│ └───────┘   └───────┘   └───────┘          │
└──────────────────────────────────────────────┘
        ▲ Serial: only one message at a time
```

**Impact**: In multi-user scenarios, NexAgent performs far better than Nanobot. Nanobot will queue messages under high concurrency.

### Session & Memory

| | NexAgent | Nanobot |
|--|---------|--------|
| Persistence | JSONL (per session) | JSONL (per session) |
| SessionManager | GenServer cache | In-memory cache + lazy loading |
| Memory layers | `MEMORY.md` + `HISTORY.md` | `MEMORY.md` + `HISTORY.md` |
| Memory search | **BM25 index** (GenServer, 100ms timeout) | External grep only |
| Memory in system prompt | Truncated to 3KB | Full (unbounded) |
| Consolidation trigger | 500 unmerged messages | `memory_window` configuration |
| Consolidation method | Async `Task.Supervisor` (non-blocking) | Async `asyncio.create_task` (lock-based) |
| Consolidation optimization | 80 msg cap, 200/100 char truncation, 2KB memory cap | Full messages, 500 char truncation |
| Preference extraction | Yes (language, code style via LLM) | No |
| Memory review | Daily LLM-driven pruning | No |
| History window | 500 messages (configurable per call) | 500 messages |
| History alignment | Aligned to user turn start | Aligned to user turn start |
| Tool pair validation | Strict orphan detection + warning log | Relies on context builder |
| Session TTL | 1 hour inactive (checked every 10min) | Manual cleanup only |

### Multi-Channel Support

| | NexAgent | Nanobot |
|--|---------|--------|
| Channel count | **6** (Telegram, Feishu, Discord, Slack, DingTalk, HTTP) | **11** (Telegram, Discord, Slack, WhatsApp, Feishu, DingTalk, QQ, Matrix, Email, Mochat, CLI) |
| Architecture | DynamicSupervisor + Bus PubSub | MessageBus + ChannelManager |
| Session strategy | `channel:chat_id` | `channel:chat_id` (same) |
| Gateway control | Start/stop channels dynamically | Manual instantiation |
| Telegram polling | Async via TaskSupervisor | Synchronous blocking |

NexAgent covers the major platforms. Nanobot has broader reach with 11 channels.

### Skills System

| | NexAgent | Nanobot |
|--|---------|--------|
| Types | Elixir, Script, MCP, Markdown | Markdown only |
| Storage | `~/.nex/agent/skills/` directory | `~/.nanobot/skills/` directory |
| LLM injection | As dynamic tool definitions | Into system prompt as documentation |
| Execution model | Direct: `Skills.execute(name, input)` | Progressive: agent reads SKILL.md with read_file |
| Creation method | `skill_create` tool | `skill-creator` skill |
| Search / install | `skill_search` / `skill_install` (ClawHub) | `clawhub` skill |
| Always mode | Supported (`always=true` always loaded) | Supported (`always` marker) |
| Skip in lightweight mode | Yes (cron skips skills) | No |

**Key difference**: NexAgent skills are more powerful — they support compiled Elixir modules and scripts, while Nanobot only supports Markdown-based skills. NexAgent skills are callable as LLM tools; Nanobot requires the agent to read documentation first.

### Subagent

| | NexAgent | Nanobot |
|--|---------|--------|
| Implementation | GenServer (`Subagent.ex`) | `SubagentManager` class |
| Tool restrictions | `:subagent` filter (base-category only) | No `message` / `spawn` / `cron` |
| Iteration limit | 15 | Same as main agent |
| Cancellation | By `task_id` or by session | By task tracking |
| Result notification | Bus broadcast as inbound message | Reply through message tool |
| Session isolation | Independent ephemeral session | Independent session |

### Cron Scheduling

| | NexAgent | Nanobot |
|--|---------|--------|
| Scheduling | every, at, cron expression modes | APScheduler (cron expressions) |
| Implementation | GenServer with timer management | APScheduler + asyncio |
| Tool filtering | `:cron` filter (6 safe tools only) | None (all tools available) |
| Token efficiency | history=0, skip_consolidation, skip_skills, max 3 iterations | None |
| Session isolation | Ephemeral session (no user session pollution) | Shared session |
| Output suppression | Cron output suppressed from outbound | No suppression |
| State tracking | last_run, next_run, last_status, last_error, enabled | last_run, next_run, enabled |

**Key difference**: NexAgent has aggressive token optimization for cron (~85% savings per execution) and session isolation to prevent cron messages from polluting user conversations. Nanobot runs cron with full context and no optimization.

---

## 3. Token Cost Optimization (NexAgent)

NexAgent has extensive token cost controls that Nanobot lacks entirely:

| Optimization | Details | Savings |
|---|---|---|
| Cron lightweight mode | history=0, 6 tools only, skip skills/consolidation | ~85% per cron call |
| Cron session isolation | Ephemeral session, no SessionManager save | Prevents consolidation cascade |
| Memory consolidation backoff | Window 500 (vs 100), 80 msg cap, 200/100 char truncation | ~95% consolidation cost |
| MEMORY.md truncation | 3KB cap in system prompt, 2KB cap in consolidation | ~2K tokens/request |
| Tool result truncation | 500 chars max in history | 300-500 tokens/request |
| Harness reflection backoff | Exponential backoff (15min → 4h), disabled by default | Up to 500K tokens/day |
| Memory search skip | Skipped for lightweight calls (cron) | 200 tokens/request |
| Skills skip | Skipped for cron and error recovery | Variable |

---

## 4. Resilience & Safety (NexAgent)

### Error Recovery Pipeline

```
LLM Error
  ├── Transient (429, 500-504, timeout, connection)?
  │     → Retry after 2s (1 attempt)
  │
  ├── 400 + tool definition error?
  │     → Retry without skill tools
  │
  ├── 400 + context too long?
  │     → Trim messages (keep first 2 + last half)
  │
  └── Other → Return error
```

### Loop Detection

Same tool call pattern repeated 3 consecutive times → auto-break with user-facing message. Prevents runaway iterations that waste tokens.

### Tool Call Pair Validation

- Orphaned tool_calls (no matching result) are stripped with `Logger.warning`
- Orphaned tool results (no matching call) are dropped
- History alignment ensures no mid-turn fragments

### Surgeon Safety

- Core module upgrades go through 10-second canary window
- InboundWorker and Subagent processes monitored during canary
- Automatic rollback on crash detection (restores old beam binary)
- Git commit + push for persistence after successful evolution

Nanobot has **none** of these resilience features.

---

## 5. NexAgent Strengths

1. **Self-evolution** — the only agent framework here that truly supports runtime code changes plus hot reload with safety canary
2. **True concurrency** — Elixir's actor model naturally supports session isolation and parallel tool execution
3. **Fault tolerance** — OTP supervisor/monitor/link mechanisms prevent process crashes from taking down the whole system
4. **Error recovery** — multi-level retry, error analysis, context trimming, JSON repair
5. **Loop detection** — prevents runaway iterations from wasting tokens
6. **Token optimization** — cron lightweight mode, consolidation backoff, memory truncation
7. **Tool hot replacement** — the registry GenServer supports runtime tool add/remove/update
8. **Memory search** — built-in BM25 index with daily logs and preference extraction
9. **Session hygiene** — TTL cleanup, tool pair validation, history alignment

## 6. Nanobot Strengths

1. **Broader channel coverage** — 11 platforms vs 6, with a wider ecosystem reach
2. **Broader LLM coverage** — 20+ providers available out of the box through LiteLLM, with a very low integration cost
3. **CLI mode** — supports interactive CLI workflows, which is convenient for development and debugging
4. **Simplicity** — Python + asyncio is easier to approach and has a larger community
5. **More mature MCP integration** — supports both stdio and HTTP transport with simpler configuration

---

## 7. Summary

NexAgent and Nanobot are architecturally similar in their foundations: Bus-based decoupling, JSONL sessions, tool registries, context builders, memory layers, and subagents.

**NexAgent's core differentiation** lies in three areas:
1. **Self-evolution** — hot reload with canary safety, version rollback, and autonomous improvement via Harness
2. **Concurrency & resilience** — Erlang/OTP actor model, multi-level error recovery, loop detection
3. **Cost efficiency** — aggressive token optimization for cron, consolidation, and system prompts

**Nanobot's core strength** lies in **ecosystem breadth**: more channels, more LLM providers, CLI mode, and simpler Python codebase.

### Feature Matrix

| Feature | NexAgent | Nanobot | Winner |
|---------|----------|---------|--------|
| Fault Tolerance | Erlang/OTP supervision | Manual error handling | NexAgent |
| Self-Evolution | Hot reload + canary + rollback | None | NexAgent |
| Concurrency | Actor-based (thousands) | Event-loop + global lock | NexAgent |
| Error Recovery | Transient retry + analysis + recovery | None | NexAgent |
| Loop Detection | 3x pattern detection | None | NexAgent |
| Token Optimization | Cron/consolidation/memory optimization | None | NexAgent |
| Memory System | BM25 search + daily logs + pruning | Basic MEMORY.md + grep | NexAgent |
| Tool System | Dynamic registry + hot swap + categories | Static dict | NexAgent |
| Session Hygiene | TTL + pair validation + alignment | Manual cleanup | NexAgent |
| Channel Support | 6 channels | 11 channels | Nanobot |
| Provider Support | 3 (manual adapters) | 20+ (LiteLLM) | Nanobot |
| CLI Mode | None | Interactive CLI | Nanobot |
| Code Simplicity | Complex (Elixir/OTP) | Simple (Python) | Nanobot |
| MCP Integration | Basic | Mature (stdio + HTTP) | Nanobot |

If the goal is a production-grade agent that can **self-evolve**, handle **high concurrency**, and control **LLM costs**, NexAgent is the right choice. If the goal is rapid prototyping with **broad provider/channel coverage**, Nanobot wins.
