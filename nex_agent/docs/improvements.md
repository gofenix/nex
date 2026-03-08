# NexAgent Improvement Implementation Log

Implementation checklist based on the NexAgent vs Nanobot comparison analysis.

---

## Repository Strategy

- Keep `nex_agent` inside the `nex` monorepo for now.
- Current coupling is mainly at the ecosystem level: examples, showcase apps, and shared release narrative.
- Technical extraction is still feasible later because direct package-level coupling remains limited.
- Re-evaluate a repository split only when release cadence, documentation entry points, and product identity become independently stable.

---

## Completed Improvements

### High Priority

#### 1. Tool hardening — Bash command blacklist

**File**: `lib/nex/agent/tool/bash.ex`

**Change**: The Bash tool now calls `Security.validate_command()` before executing commands.

```elixir
def execute(%{"command" => command}, ctx) do
  case Security.validate_command(command) do
    :ok -> do_execute(command, ctx)
    {:error, reason} -> {:error, "Security: #{reason}"}
  end
end
```

Blocked dangerous patterns include:
- System directory deletion (`rm -rf /usr`, `rm ~/`)
- Disk operations (`dd if=/dev/`, `mkfs`, `fdisk`)
- System control (`shutdown`, `reboot`, `poweroff`)
- Fork bombs (`:(){:|:&};:`)
- Infinite loops (`while true...done`)
- Remote code execution (`curl | sh`, `eval $(curl`)
- Credential theft (`cat ~/.ssh/`, `cat .env`, `cat *.pem`)
- Network exfiltration (`curl -d @file`, `nc -l`)
- Cron tampering (`crontab -`)

#### 2. Workspace sandbox — file read/write path restrictions

**Files**: `lib/nex/agent/tool/read.ex`, `lib/nex/agent/tool/write.ex`, `lib/nex/agent/tool/edit.ex`

**Change**: All file operation tools now call `Security.validate_path()` before execution, and the path must be inside one of the following allowed roots:
- Project directory (`File.cwd!()`)
- Agent workspace (`~/.nex/agent`)
- Temporary directory (`/tmp`)

The allowed roots can be extended via the `NEX_ALLOWED_ROOTS` environment variable.

#### 3. Enhanced dangerous-pattern coverage in `Security.ex`

**File**: `lib/nex/agent/security.ex`

**Changes**:
- Dangerous command patterns increased from 8 to 30+
- The command allowlist increased from about 40 to about 80, covering more developer tools
- Added support for `bun`, `deno`, `go`, `ruby`, `gem`, `java`, `gradle`, `mvn`, `jq`, `yq`, `tar`, `zip`, `base64`, and more

#### 4. New channel — Discord

**File**: `lib/nex/agent/channel/discord.ex`

**Implementation**:
- WebSocket Gateway API (v10) integration
- Heartbeat maintenance plus identify/resume flow
- Supports both DM and group `@mention` triggers
- 2000-character message chunking
- Automatic rate-limit retry
- `allow_from` channel allowlist

#### 5. New channel — Slack

**File**: `lib/nex/agent/channel/slack.ex`

**Implementation**:
- Receives events via Socket Mode (WebSocket)
- Sends messages through the Web API
- Supports `message` and `app_mention` events
- Thread replies via `thread_ts`
- Automatic bot identity detection

#### 6. New channel — DingTalk

**File**: `lib/nex/agent/channel/dingtalk.ex`

**Implementation**:
- Receives bot messages through the Stream Mode API
- OAuth2 access-token management with automatic refresh
- Session webhook preferred for replies, Robot API as fallback
- Supports both direct chat and group chat

#### 7. New tool — ListDir

**File**: `lib/nex/agent/tool/list_dir.ex`

**Implementation**:
- Lists directory contents including file type, size, and modification time
- Supports recursive listing with `recursive: true`
- Paths are validated by the Security sandbox

#### 8. Token cost optimization — Cron lightweight mode

**Files**: `inbound_worker.ex`, `agent.ex`, `runner.ex`, `tool/registry.ex`, `context_builder.ex`

**Changes**:
- Cron calls use `history_limit: 0` (zero history), `tools_filter: :cron` (6 tools only), `skip_consolidation: true`, `skip_skills: true`, `max_iterations: 3`
- Cron uses ephemeral session (not saved to SessionManager, no user session pollution)
- `:cron` tool filter allows only: bash, read, message, memory_search, web_search, web_fetch
- `context_builder.ex` skips skills section when `skip_skills: true`

**Impact**: ~85% token reduction per cron call. Prevents consolidation cascade from frequent cron execution.

#### 9. Token cost optimization — Memory consolidation

**Files**: `runner.ex`, `memory.ex`, `context_builder.ex`

**Changes**:
- `@memory_window` raised from 100 → 500 (consolidation frequency reduced 5x)
- Consolidation capped at 80 messages (head 10 + tail 70)
- Message truncation: 200 chars for user/assistant, 100 chars for tool results (down from 500)
- MEMORY.md truncated to 2KB in consolidation prompt
- MEMORY.md truncated to 3KB in system prompt
- `@max_tool_result_length` reduced from 2000 → 500

**Impact**: ~95% consolidation cost reduction. System prompt stays bounded regardless of MEMORY.md growth.

#### 10. Token cost optimization — Harness reflection backoff

**File**: `harness.ex`

**Changes**:
- Auto-reflection disabled by default (`@default_reflection_interval :disabled`)
- Exponential backoff when enabled: no suggestions → double interval (15min → 30min → 1h → 2h → 4h max)
- Suggestions found → reset to base interval
- Manual reflection still available via `Harness.trigger_reflection()`
- Daily memory review (LLM-driven pruning of outdated sections) still runs

**Impact**: When enabled, reflection calls reduced from 96/day to ~10/day. When disabled, zero automatic LLM calls from Harness.

#### 11. Agent loop resilience — Error recovery

**File**: `runner.ex`

**Changes**:
- Multi-level error recovery pipeline:
  - Transient errors (429, 500-504, timeout, connection) → retry after 2s
  - 400 + tool definition error → retry without skill tools
  - 400 + context too long → trim messages (keep first 2 + last half)
- Single recovery attempt per request (`__recovered` flag prevents infinite loops)
- `JsonRepair` module for malformed LLM tool arguments

#### 12. Agent loop resilience — Loop detection

**File**: `runner.ex`

**Changes**:
- Tracks tool call patterns across iterations via `_tool_history`
- Same tool name pattern repeated 3 consecutive times → auto-break
- Returns user-facing message suggesting different approach

**Impact**: Prevents runaway iterations that waste tokens and confuse the user.

#### 13. Session hygiene — Tool pair validation

**File**: `session.ex`

**Changes**:
- `sanitize_tool_pairs/1` ensures every tool_use has matching tool_result
- Orphaned tool_calls stripped with `Logger.warning` (no longer silent)
- Orphaned tool results dropped
- History alignment drops leading mid-turn fragments (tool/assistant without preceding user)

**Impact**: Prevents malformed history from causing LLM API errors.

### Integration Changes

#### `Config.ex` expansion

**File**: `lib/nex/agent/config.ex`

Added `discord`, `slack`, and `dingtalk` configuration sections, including:
- Struct fields
- Default values
- Getter/setter methods
- Configuration validation via `valid?/1`
- Serialization and deserialization

#### `Gateway.ex` expansion

**File**: `lib/nex/agent/gateway.ex`

- Added `ensure_discord_channel_started/1`
- Added `ensure_slack_channel_started/1`
- Added `ensure_dingtalk_channel_started/1`
- Added matching `stop_*_channel/0` functions
- `status/0` now returns the new channel statuses

#### Tool registry expansion

**File**: `lib/nex/agent/tool/registry.ex`

- Added `Nex.Agent.Tool.ListDir` to `@default_tools`
- Added `:cron` tool filter (bash, read, message, memory_search, web_search, web_fetch)
- Added `normalize_definition/1` for OpenAI-style nested tool definitions
- Default tool count increased from 15 to 18+

---

## Future Improvement Directions

### Medium Priority

| # | Improvement | Notes |
|---|------|------|
| 1 | **LiteLLM Integration** | Consider using LiteLLM's HTTP bridge to expand provider coverage beyond 3 |
| 2 | **Streaming in Runner** | Streaming exists in llm/anthropic.ex but is not used in the main runner loop |
| 3 | **More channels** | WhatsApp, QQ, Matrix, Email — Nanobot supports 11 vs NexAgent's 6 |
| 4 | **MCP enhancement** | browser_mcp.ex is minimal; Nanobot has more mature MCP with stdio + HTTP transport |

### Low Priority

| # | Improvement | Notes |
|---|------|------|
| 5 | **Telemetry/metrics** | Add tool execution latency, error rates, token usage tracking |
| 6 | **Oscillation detection** | Detect not just identical repeats but oscillating patterns (A→B→A→B) |
| 7 | **Recovery retry improvement** | Allow 1 transient retry during recovery attempts (currently 0) |
| 8 | **Provider plugin architecture** | Make it easier to add new LLM providers without writing full adapter |
