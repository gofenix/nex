# NexAgent vs Nanobot 深度对比分析

## 概述

| 维度 | NexAgent (Elixir) | Nanobot (Python) |
|------|-------------------|------------------|
| 语言 | Elixir / OTP | Python / asyncio |
| 定位 | 自进化 AI Agent 平台 | 轻量级 AI Agent 框架 |
| 核心代码量 | ~62 个 .ex 文件 | ~58 个 .py 文件, ~4000 行核心 |
| 运行模式 | Gateway 服务 | CLI + Gateway 双模式 |
| 并发模型 | Actor (GenServer/Process) | asyncio + 全局锁串行 |
| 自进化 | 核心特性 (hot reload) | 不支持 |

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

## 1. 架构对比

### Agent Loop

| | NexAgent | Nanobot |
|--|---------|--------|
| 入口 | `Runner.run/3` | `AgentLoop._run_agent_loop()` |
| 迭代限制 | default 10, hard 50, auto-expand | default 40, fixed |
| 工具执行 | **并行** (`Task.async_stream`) | **串行** (逐个 await) |
| 消息处理 | 每个 session 独立进程 | **全局锁串行** (`_processing_lock`) |
| 错误处理 | try/rescue/catch + 重试 | try/except + 不持久化错误消息 |
| 进度回调 | `on_progress` (thinking + tool_hint) | progress streaming (thinking blocks) |

**关键差异**: NexAgent 利用 Elixir 进程模型实现 **session 级别的真并发** — 多个用户同时对话互不阻塞。Nanobot 用全局锁，同一时刻只能处理一个消息。

### LLM Provider

| | NexAgent | Nanobot |
|--|---------|--------|
| 抽象层 | `LLM.Behaviour` (Elixir behaviour) | `LLMProvider` base class |
| 提供商数量 | 4 (Anthropic, OpenAI, OpenRouter, Ollama) | **20+** (via LiteLLM + 自定义 registry) |
| 默认 | Anthropic Claude | 可配置 |
| Prompt 缓存 | Anthropic ephemeral cache | Anthropic cache_control |
| 消息格式转换 | 手动 (per provider) | LiteLLM 统一 |
| JSON 修复 | `JsonRepair` 模块 | 类似的 fallback 解析 |
| 思考/推理 | `reasoning_content` 字段 | `reasoning_content` + `thinking_blocks` |

**关键差异**: Nanobot 通过 LiteLLM 轻松接入 20+ 提供商，NexAgent 手写每个 provider 适配器，更可控但工作量大。

### Tool System

| | NexAgent | Nanobot |
|--|---------|--------|
| 注册方式 | GenServer Registry (动态) | Dict-based registry |
| 默认工具 | 16 个 | 9 个 |
| 工具热更新 | 支持 (hot_swap) | 不支持 |
| MCP 支持 | 有 (mcp.ex) | 有 (MCPToolWrapper) |
| 安全限制 | workspace 沙箱 + 命令黑名单 | `restrict_to_workspace` + deny patterns |
| 执行超时 | 60s per tool (Task.async_stream) | 30s default (MCP) |

**共有工具**: read, write, edit, bash/exec, web_search, web_fetch, message, spawn
**NexAgent 独有**: evolve, reflect, soul_update, skill_create/list/search/install, list_dir
**Nanobot 独有**: cron tool

**关键差异**: NexAgent 的 Registry 是 GenServer，支持运行时动态注册/卸载/热替换工具模块。Nanobot 的工具在启动时静态注册。NexAgent 工具并行执行，Nanobot 串行。

---

## 2. 核心特性对比

### 自进化 (Self-Evolution) — NexAgent 独有

NexAgent 最大的差异化特性：
- **Evolution.ex**: 版本化的热代码重载引擎，支持 backup → validate → compile → load → health check
- **Evolve Tool**: Agent 可以通过工具调用修改自己的任何模块代码
- **Reflect Tool**: Agent 可以读取自己的源码、查看版本历史、比较 diff
- **Harness**: 每 15 分钟自动收集工具执行结果 → LLM 反思 → 生成改进建议 → 自动应用
- **建议类型**: new_skill, soul_update, memory_entry, strategy_change
- **回滚**: 支持按版本 ID 回滚

Nanobot **完全没有**自进化能力 — 它的代码是静态的，只能通过 skills (markdown 文件) 和配置来扩展行为。

### 并发模型

```
NexAgent (Elixir/OTP):
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Session A    │  │ Session B    │  │ Session C    │
│ (独立进程)   │  │ (独立进程)   │  │ (独立进程)   │
│ tool1 ──┐   │  │ tool1 ──┐   │  │ tool1 ──┐   │
│ tool2 ──┤   │  │ tool2 ──┤   │  │ tool2 ──┤   │
│ tool3 ──┘   │  │ tool3 ──┘   │  │ tool3 ──┘   │
└──────────────┘  └──────────────┘  └──────────────┘
        ▲ 真并行: session 之间 + 工具之间

Nanobot (Python/asyncio):
┌──────────────────────────────────────────────┐
│ Global Lock  (_processing_lock)              │
│ ┌───────┐ → ┌───────┐ → ┌───────┐          │
│ │ Msg A │   │ Msg B │   │ Msg C │  串行     │
│ │ tool1 │   │ wait  │   │ wait  │          │
│ │ tool2 │   │  ...  │   │  ...  │          │
│ │ tool3 │   │       │   │       │          │
│ └───────┘   └───────┘   └───────┘          │
└──────────────────────────────────────────────┘
        ▲ 串行: 一次只处理一个消息
```

**影响**: 多用户场景下 NexAgent 性能远优于 Nanobot。Nanobot 在高并发下会出现消息排队。

### Session & Memory

| | NexAgent | Nanobot |
|--|---------|--------|
| 持久化 | JSONL (per session) | JSONL (per session) |
| SessionManager | GenServer 缓存 | 内存缓存 + 懒加载 |
| Memory 层级 | 2 层 (MEMORY.md + HISTORY.md) | **2 层** (MEMORY.md + HISTORY.md) |
| 合并触发 | 100 条未合并消息 | `memory_window` 配置 |
| 合并方式 | 异步 Task.start | 异步 asyncio.create_task |
| 历史窗口 | 100 条 | 500 条 |

两者现在都采用双层 memory 架构 — MEMORY.md 存长期事实，HISTORY.md 存时间线事件日志。

### 多渠道支持

| | NexAgent | Nanobot |
|--|---------|--------|
| 渠道数量 | **6** (Telegram, Feishu, Discord, Slack, DingTalk, HTTP) | **11** (Telegram, Discord, Slack, WhatsApp, Feishu, DingTalk, QQ, Matrix, Email, Mochat, CLI) |
| 架构 | Bus PubSub 解耦 | MessageBus + ChannelManager |
| Session 策略 | `channel:chat_id` | `channel:chat_id` (相同) |

NexAgent 现已支持 6 个渠道，覆盖主流平台。

### Skills 系统

| | NexAgent | Nanobot |
|--|---------|--------|
| 类型 | Elixir, Script, MCP, Markdown | Markdown only |
| 存储 | `~/.nex/agent/skills/` 目录 | `~/.nanobot/skills/` 目录 |
| 注入 LLM | 作为动态 tool definition | 注入 system prompt |
| 创建工具 | skill_create tool | skill-creator skill |
| 搜索/安装 | skill_search/install (ClawHub) | clawhub skill |
| always 模式 | 支持 (always=true 始终加载) | 支持 (always 标记) |

**关键差异**: NexAgent 的 skills 更强大 — 支持编译型 Elixir 模块和脚本，Nanobot 只支持 Markdown 文档型 skills。

### Subagent

| | NexAgent | Nanobot |
|--|---------|--------|
| 实现 | GenServer (Subagent.ex) | SubagentManager class |
| 工具限制 | base category only | 无 message/spawn/cron |
| 迭代限制 | 15 次 | 同主 agent |
| 取消 | 按 task_id 或 session | 按 task tracking |
| 结果通知 | Bus 广播 | message tool 回复 |

基本一致，NexAgent 通过 category filter 限制更清晰。

---

## 3. NexAgent 优势

1. **自进化能力** — 唯一真正支持运行时代码修改 + 热重载的 agent 框架
2. **真并发** — Elixir Actor 模型天然支持 session 级隔离和工具并行执行
3. **容错性** — OTP 的 supervisor/monitor/link 机制，进程崩溃不影响整体
4. **工具热替换** — Registry GenServer 支持运行时增删改工具
5. **Harness 自反思** — 自动收集执行数据、LLM 反思、生成改进建议
6. **工具并行执行** — Task.async_stream 并行跑多个工具调用
7. **安全沙箱** — 命令黑名单 + 路径限制 + 危险模式检测

## 4. Nanobot 优势

1. **渠道丰富** — 11 个平台 vs 6 个，生态覆盖更广
2. **LLM 覆盖** — 20+ provider 开箱即用 (via LiteLLM)，接入成本极低
3. **CLI 模式** — 支持交互式 CLI，方便开发调试
4. **简单易懂** — Python + asyncio，上手门槛低，社区更大
5. **MCP 集成更成熟** — 支持 stdio + HTTP 两种传输，配置简洁

---

## 5. 总结

NexAgent 和 Nanobot 在核心架构上高度相似 (Bus PubSub 解耦、JSONL session、tool registry、context builder、subagent)，说明 NexAgent 参考了 Nanobot 的设计。

**NexAgent 的核心差异化**在于 Elixir/OTP 带来的 **并发能力** 和 **自进化系统** — 这是 Python 生态很难复制的。

**Nanobot 的核心优势**在于 **生态广度** — 更多渠道、更多 LLM provider、CLI 模式。

如果目标是打造一个 **能自我进化、高并发** 的生产级 agent，NexAgent 的方向是对的。

From a repository perspective, the current recommendation is also clear: keep NexAgent inside `nex` until the product boundary becomes independently stable.
