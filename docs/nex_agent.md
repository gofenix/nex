# Nex.Agent 技术文档

## 概述

Nex.Agent 是 Nex 框架内置的 AI 编程 Agent，采用 Elixir 语言实现。它是一个**自进化（Self-Evolving）** Agent，能够在运行时修改自己的代码，具备记忆系统、技能系统、MCP 集成等高级功能。

---

## 缘起

### 设计灵感

Nex.Agent 的设计深受 [pi-coding-agent](https://github.com/anthropics/pi-coding-agent)。

### 核心洞察

从 pi-coding-agent 分析中得出的关键设计原则：

1. **仅 4 个核心工具** - read, bash, edit, write。更多工具 = 更多复杂度 = 更差的 LLM 决策
2. **树形结构的会话** - 每个条目有 `id`/`parentId`，支持分支而不丢失数据
3. **JSONL 存储** - 每行一个 JSON 对象，易于解析和追加
4. **极简系统提示词** - 约 200 行，包含工具描述
5. **上下文压缩** - 总结旧消息以保持在 token 限制内
6. **会话中可切换模型** - 可在对话中间更改 provider/model
7. **项目上下文文件** - AGENTS.md, SYSTEM.md 用于项目特定指令
8. **技能即 Markdown** - 按需加载的提示词模板

---

## 架构设计

```
┌─────────────────────────────────────────────────────────────────────┐
│                          Nex.Agent                                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐        │
│  │    用户     │───▶│  Nex.Agent   │───▶│   Session    │        │
│  │   (API)     │    │    (API)     │    │  (树形)      │        │
│  └──────────────┘    └──────────────┘    └──────────────┘        │
│         │                    │                    │                 │
│         │                    ▼                    ▼                 │
│         │            ┌──────────────┐    ┌──────────────┐        │
│         │            │   Runner     │    │   Entry      │        │
│         │            │  (循环)      │◀──▶│  (id/parentId)│        │
│         │            └──────────────┘    └──────────────┘        │
│         │                    │                                   │
│         │                    ▼                                   │
│         │            ┌──────────────┐    ┌──────────────┐        │
│         │            │     LLM     │    │    Tools     │        │
│         │            │  (Provider)  │    │  (执行器)    │        │
│         │            └──────────────┘    └──────────────┘        │
│         │                                                       │
│         ▼                                                       │
│  ┌──────────────┐                                               │
│  │   输出结果   │◀───────────────────────────────────────────  │
│  └──────────────┘                                               │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 核心模块

### 1. Nex.Agent — 主 API

```elixir
# 启动 Agent
{:ok, agent} = Nex.Agent.start(
  provider: :anthropic,
  api_key: "sk-..."
)

# 发送提示词
{:ok, result, agent} = Nex.Agent.prompt(agent, "创建一个 hello.ex 文件")

# 分支会话
{:ok, forked_agent} = Nex.Agent.fork(agent)
```

### 2. Nex.Agent.Session — 树形会话

会话采用树形结构存储，支持分支：

```
[用户消息] ─── [助手回复] ─── [用户消息] ─── [助手回复] ──┬─ [用户消息] ← 当前叶
                                                          │
                                                          └─ [用户消息] ── [助手回复] ← 分支
```

存储格式为 JSONL（每行一个 JSON）：

```jsonl
{"type":"session","id":"abc123","version":3,"timestamp":"..."}
{"type":"message","id":"a1b2c3d4","parentId":"abc123","message":{"role":"user","content":"创建用户模块"}}
{"type":"message","id":"b2c3d4e5","parentId":"a1b2c3d4","message":{"role":"assistant","content":"好的..."}}
```

### 3. Nex.Agent.Runner — Agent 循环

核心执行循环：

```elixir
defp run_loop(session, messages, iteration, max_iterations, opts) do
  if iteration >= max_iterations do
    {:error, :max_iterations_exceeded, session}
  else
    case call_llm(messages, opts) do
      {:ok, response} ->
        content = response.content
        tool_calls = Map.get(response, :tool_calls)

        if tool_calls && tool_calls != [] do
          # 执行工具
          {new_messages, _results} = execute_tools(session, messages, tool_calls, opts)
          run_loop(session, new_messages, iteration + 1, max_iterations, opts)
        else
          {:ok, content, session}
        end
    end
  end
end
```

### 4. 核心工具（4个）

| 工具 | 功能 | 参数 |
|------|------|------|
| `read` | 读取文件内容 | `path` |
| `write` | 创建/覆盖文件 | `path`, `content` |
| `edit` | 精确替换文本 | `path`, `search`, `replace` |
| `bash` | 执行 Shell 命令 | `command` |

---

## 特色功能

### 1. Memory — 记忆系统

每日日志 + BM25 搜索：

```elixir
# 保存记忆
Nex.Agent.Memory.append("修复登录 bug", "SUCCESS", %{issue: "123"})

# 搜索记忆
results = Nex.Agent.Memory.search("登录 bug")

# 获取今日记忆
entries = Nex.Agent.Memory.today()
```

存储结构：
```
~/.nex/agent/workspace/
└── memory/
    ├── 2026-02-27/
    │   └── log.md
    └── 2026-02-28/
        └── log.md
```

### 2. Skills — 技能系统

技能以 Markdown 格式存储在 `~/.nex/agent/skills/`：

```yaml
---
name: deploy
description: Deploy the application to production
allowed-tools: Bash
---

Deploy to production:

1. Run tests: mix test
2. Build: mix release
3. Deploy to host
```

使用：
```elixir
# 加载技能
Nex.Agent.Skills.load()

# 列出技能
skills = Nex.Agent.Skills.list()

# 执行技能
{:ok, result} = Nex.Agent.Skills.execute("deploy", "production")
```

### 3. MCP — Model Context Protocol

支持连接外部 MCP 服务器：

```elixir
# 启动 MCP 服务器
{:ok, conn} = Nex.Agent.MCP.start_link(
  command: "npx",
  args: ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/data"]
)

# 初始化
Nex.Agent.MCP.initialize(conn)

# 调用工具
{:ok, result} = Nex.Agent.MCP.call_tool(conn, "read_file", %{path: "file.txt"})
```

### 4. Evolution — 自进化

**核心亮点**：Agent 可以**修改自己的代码**并在运行时热加载：

```elixir
# 修改模块代码
{:ok, version} = Nex.Agent.Evolution.upgrade_module(
  Nex.Agent.Runner,
  new_code_string
)

# 回滚到上一版本
:ok = Nex.Agent.Evolution.rollback(Nex.Agent.Runner)

# 查看版本历史
versions = Nex.Agent.Evolution.list_versions(Nex.Agent.Runner)
```

安全机制：
- 所有更改版本化
- 编译失败自动回滚
- 保留历史版本用于恢复

### 5. Reflection — 反思

分析执行结果并生成改进建议：

```elixir
# 分析结果
analysis = Nex.Agent.Reflection.analyze(results)

# 生成建议
suggestions = Nex.Agent.Reflection.suggest(analysis)
```

---

## 多 Provider 支持

### Anthropic（默认）

```elixir
Nex.Agent.start(provider: :anthropic, model: "claude-sonnet-4-20250514")
```

### OpenAI

```elixir
Nex.Agent.start(provider: :openai, model: "gpt-4o")
```

### Ollama（本地）

```elixir
Nex.Agent.start(provider: :ollama, model: "llama3.1", base_url: "http://localhost:11434/v1")
```

---

## 项目上下文文件

### AGENTS.md

项目特定的 Agent 指令：

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
```

### SYSTEM.md

系统级指令：

```markdown
# Elixir Guidelines

- Use pipe operator (|>)
- Prefer pattern matching over conditionals
- Add typespecs for public APIs
```

---

## 安全机制

### 路径验证

所有文件操作都经过路径验证，防止目录穿越攻击：

```elixir
def validate_path(path) do
  # 解析并规范化路径
  # 检查是否在允许的目录内
end
```

### 命令白名单

bash 工具只允许执行白名单命令：

```elixir
@allowed_commands ~w(
  git mix elixir iex curl wget grep find ls cat head tail
  rm cp mv mkdir touch chmod chown sed awk sort uniq
  npm node yarn pnpm bun docker docker-compose
)a
```

### Atom 安全

使用 `String.to_existing_atom/1` 防止原子耗尽。

---

## 文件结构

```
nex_agent/
├── lib/
│   ├── nex_agent.ex              # 主 API (Nex.Agent)
│   └── nex/
│       └── agent/
│           ├── agent.ex          # Agent 主模块
│           ├── session.ex       # 树形会话
│           ├── entry.ex         # 会话条目
│           ├── runner.ex        # Agent 循环
│           ├── memory.ex        # 记忆系统
│           ├── skills.ex        # 技能系统
│           ├── evolution.ex     # 自进化引擎
│           ├── reflection.ex    # 反思模块
│           ├── mcp.ex           # MCP 客户端
│           ├── security.ex      # 安全模块
│           ├── system_prompt.ex # 系统提示词
│           ├── tool/
│           │   ├── behaviour.ex
│           │   ├── read.ex
│           │   ├── write.ex
│           │   ├── edit.ex
│           │   └── bash.ex
│           ├── llm/
│           │   ├── behaviour.ex
│           │   ├── anthropic.ex
│           │   ├── openai.ex
│           │   └── ollama.ex
│           ├── skills/
│           │   └── loader.ex
│           └── mcp/
│               ├── discovery.ex
│               └── server_manager.ex
└── test/
```

---

## 使用示例

```elixir
defmodule MyAgent do
  def run(prompt) do
    # 1. 创建会话
    {:ok, session} = Nex.Agent.Session.create(project_id: "demo")

    # 2. 加载技能
    :ok = Nex.Agent.Skills.load()

    # 3. 运行 Agent
    case Nex.Agent.Runner.run(session, prompt) do
      {:ok, result, session} ->
        # 4. 保存到记忆
        Nex.Agent.Memory.append(prompt, "SUCCESS", %{})
        {:ok, result}

      {:error, reason, _session} ->
        Nex.Agent.Memory.append(prompt, "FAILURE", %{error: reason})
        {:error, reason}
    end
  end
end

# 使用
MyAgent.run("创建一个计数器模块")
```

---

## 总结

Nex.Agent 是一个功能完备的 AI 编程 Agent，具有以下特点：

| 特性 | 描述 |
|------|------|
| **自进化** | 运行时修改和热加载自己的代码 |
| **记忆系统** | 每日日志 + BM25 搜索 |
| **技能系统** | Markdown 格式的可复用技能 |
| **MCP 集成** | 连接外部工具服务器 |
| **反思能力** | 分析执行结果并改进 |
| **树形会话** | 支持分支和会话历史 |
| **多 Provider** | Anthropic / OpenAI / Ollama |
| **安全设计** | 路径验证、命令白名单、Atom 安全 |

**核心设计哲学**：极简而强大 — 仅 4 个核心工具，通过组合和扩展实现丰富功能。
