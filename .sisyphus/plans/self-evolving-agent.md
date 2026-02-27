# 自进化 Agent

## 简介

> 在 Nex Agent 基础上构建自进化 Agent，集成 MCP、Skills 注册表、OpenClaw 风格 Memory（Markdown + BM25）、反思层和运行时代码进化。

> **交付物**：
> - MCP Client 模块（连接 MCP 服务器）
> - Skills 注册表模块（技能管理）
> - Memory 系统（Markdown 文件 + BM25 搜索）
> - 反思层（运行时自适应）
> - 代码进化引擎（运行时代码修改）

> **预估工作量**：大
> **并行执行**：是 - 3 个阶段
> **关键路径**：MCP → Skills → Memory → Reflection → Code Evolution

---

## 背景

### 原始需求
构建类似 OpenClaw 的自进化 Agent，具有：
1. 运行时进化（动态策略调整）
2. 代码层面进化（运行时代码修改）
3. 知识积累（记忆系统）

### 需求确认
- **Memory**：OpenClaw 风格 - Markdown 文件，BM25 搜索（无向量）
- **MCP**：完整 MCP 客户端集成
- **Skills**：技能注册和执行
- **Evolution**：运行时反思 + 代码修改
- **存储**：基于文件（无外部数据库）

### 调研发现
- OpenClaw 使用 `MEMORY.md` + `memory/YYYY-MM-DD.md` 结构
- BM25 关键词搜索足够，无需向量
- Elixir 有运行时代码加载能力（`Code.eval_quoted`、`Module.create`）
- MCP 支持 stdio 和 HTTP (SSE) 传输

---

## 工作目标

### 核心目标
构建可自进化的 Agent，能够：
1. 连接 MCP 服务器获取外部工具
2. 注册和执行 Skills
3. 用 Markdown 文件 + BM25 搜索记录经验
4. 反思执行结果并调整策略
5. 运行时修改自身代码

### 具体交付物
- `Nex.Agent.MCP` - MCP 客户端模块
- `Nex.Agent.Skills` - Skills 注册表模块
- `Nex.Agent.Memory` - 带 BM25 的 Memory 系统
- `Nex.Agent.Reflection` - 反思层
- `Nex.Agent.Evolution` - 代码进化引擎
- 扩展 `Nex.Agent.Runner` 加上进化循环

### 完成定义
- [ ] Agent 能连接 MCP 服务器并调用工具
- [ ] Agent 能注册和执行 Skills
- [ ] Agent 能写记忆到 Markdown 文件
- [ ] Agent 能通过 BM25 搜索记忆
- [ ] Agent 反思执行并调整策略
- [ ] Agent 能修改自身代码并重载

### 必须有
- MCP stdio 和 HTTP 传输支持
- BM25 搜索实现
- 运行时模块重载
- 基于文件的记忆持久化

### 禁止有
- 向量搜索 / embeddings
- 外部数据库依赖
- 云服务

---

## 验证策略

### 测试决策
- **基础设施存在**：否（新模块）
- **自动化测试**：是（之后测试）
- **框架**：Elixir ExUnit

### QA 策略
每个任务包含 Agent 执行的 QA 场景：
- **CLI/TUI**：使用 interactive_bash — 运行命令，验证输出
- **集成**：使用 mock LLM 的完整 Agent 循环测试

---

## 执行策略

### 并行执行阶段

```
第一阶段（基础）：
├── 任务 1：MCP Client - 核心协议（stdio 传输）
├── 任务 2：MCP Client - HTTP 传输支持
├── 任务 3：Skills 注册表 - 核心结构
└── 任务 4：Skills 注册表 - 执行引擎

第二阶段（Memory + 集成）：
├── 任务 5：Memory - Markdown 文件存储
├── 任务 6：Memory - BM25 搜索实现
├── 任务 7：集成 MCP + Skills 到 Runner
└── 任务 8：Memory - 每日日志自动创建

第三阶段（进化）：
├── 任务 9：反思层 - 策略调整
├── 任务 10：反思层 - 错误模式学习
├── 任务 11：代码进化 - 动态模块加载
└── 任务 12：代码进化 - 自我修改
```

### 依赖矩阵
- **1-4**：—（第一阶段独立）
- **5-8**：1, 2, 3, 4（依赖于 MCP + Skills）
- **9-12**：5, 6, 7, 8（依赖于 Memory 集成）

---

## 任务列表

- [ ] 1. MCP Client - STDIO 传输

  **要做的事**：
  - 创建 `Nex.Agent.MCP` 模块
  - 实现 MCP 服务器的 STDIO 传输
  - 解析 MCP JSON-RPC 消息
  - 添加工具发现和执行

  **禁止做的事**：
  - 暂不包含 HTTP 传输

  **参考**：
  - MCP 规范：`https://modelcontextprotocol.io/`
  - `nex_agent/lib/nex/agent/tool/bash.ex` - 进程执行模式

  **验收标准**：
  - [ ] 能启动 MCP 服务器进程
  - [ ] 能发送初始化请求
  - [ ] 能列出可用工具
  - [ ] 能调用工具并接收结果

  **QA 场景**：
  ```
  场景：连接到 filesystem MCP 服务器
    工具：interactive_bash
    步骤：
      1. 启动 Nex.Agent.MCP，使用 filesystem server 命令
      2. 发送 initialize
      3. 调用工具 "read_file"，路径 "/tmp/test.txt"
    预期结果：返回文件内容
    证据：.sisyphus/evidence/task-1-mcp-stdio.txt
  ```

  **提交**：是
  - 消息：`feat(agent): add MCP client with stdio transport`
  - 文件：`nex_agent/lib/nex/agent/mcp.ex`

- [ ] 2. MCP Client - HTTP 传输

  **要做的事**：
  - 添加 HTTP SSE 传输支持
  - 处理流式响应
  - 连接池

  **禁止做的事**：
  - 无 WebSocket（MCP 规范中没有）

  **参考**：
  - `nex_agent/lib/nex/agent/llm/anthropic.ex` - HTTP 客户端模式

  **验收标准**：
  - [ ] 能连接到 HTTP MCP 服务器
  - [ ] 能处理 SSE 流式传输
  - [ ] 能自动重连

  **QA 场景**：
  ```
  场景：连接到 HTTP MCP 服务器
    工具：interactive_bash
    步骤：
      1. 启动 HTTP MCP 服务器
      2. 使用 HTTP 传输连接
      3. 调用工具
    预期结果：返回工具结果
    证据：.sisyphus/evidence/task-2-mcp-http.txt
  ```

  **提交**：是
  - 消息：`feat(agent): add HTTP transport for MCP`
  - 文件：`nex_agent/lib/nex/agent/mcp/http.ex`

- [ ] 3. Skills 注册表 - 核心结构

  **要做的事**：
  - 创建 `Nex.Agent.Skills` 模块
  - 定义技能结构（name, description, parameters, handler）
  - 添加从文件加载技能
  - 添加技能持久化

  **参考**：
  - OpenClaw skills 格式
  - `nex_agent/lib/nex/agent/tool/behaviour.ex` - 工具模式

  **验收标准**：
  - [ ] 能定义技能结构
  - [ ] 能从目录加载技能
  - [ ] 能将技能持久化到文件

  **提交**：是
  - 消息：`feat(agent): add skills registry`
  - 文件：`nex_agent/lib/nex/agent/skills.ex`

- [ ] 4. Skills 注册表 - 执行引擎

  **要做的事**：
  - 实现技能执行
  - 添加参数验证
  - 添加技能输出格式化

  **参考**：
  - `nex_agent/lib/nex/agent/runner.ex` - 工具执行模式

  **验收标准**：
  - [ ] 能执行已加载的技能
  - [ ] 根据 schema 验证参数
  - [ ] 返回格式化输出

  **提交**：是
  - 消息：`feat(agent): add skill execution engine`
  - 文件：`nex_agent/lib/nex/agent/skills.ex`

- [ ] 5. Memory - Markdown 文件存储

  **要做的事**：
  - 创建 `Nex.Agent.Memory` 模块
  - 实现 MEMORY.md 管理
  - 实现每日日志（memory/YYYY-MM-DD.md）
  - 添加写操作

  **参考**：
  - OpenClaw memory 结构
  - `nex_agent/lib/nex/agent/session.ex` - 文件写入模式

  **验收标准**：
  - [ ] 创建工作区目录结构
  - [ ] 追加写入 MEMORY.md
  - [ ] 自动创建每日日志文件

  **提交**：是
  - 消息：`feat(agent): add memory markdown storage`
  - 文件：`nex_agent/lib/nex/agent/memory.ex`

- [ ] 6. Memory - BM25 搜索

  **要做的事**：
  - 实现 BM25 排序算法
  - 添加跨记忆文件搜索
  - 添加相关性评分

  **参考**：
  - BM25 算法：`https://en.wikipedia.org/wiki/Okapi_BM25`

  **验收标准**：
  - [ ] 能索引记忆文件
  - [ ] 能用关键词搜索
  - [ ] 返回排序结果

  **提交**：是
  - 消息：`feat(agent): add BM25 search to memory`
  - 文件：`nex_agent/lib/nex/agent/memory/search.ex`

- [ ] 7. 集成 MCP + Skills 到 Runner

  **要做的事**：
  - 修改 Runner 支持 MCP 工具
  - 添加 Skills 作为可用工具
  - 更新工具执行分发

  **参考**：
  - `nex_agent/lib/nex/agent/runner.ex` - 当前执行循环

  **验收标准**：
  - [ ] Runner 能调用 MCP 工具
  - [ ] Runner 能调用 Skills
  - [ ] 工具出现在 LLM 函数调用中

  **提交**：是
  - 消息：`feat(agent): integrate MCP and skills into runner`
  - 文件：`nex_agent/lib/nex/agent/runner.ex`

- [ ] 8. Memory - 每日日志自动创建

  **要做的事**：
  - 添加每日日志自动创建
  - 添加条目时间戳
  - 添加日志轮转

  **验收标准**：
  - [ ] 每天创建新日志文件
  - [ ] 条目有时间戳
  - [ ] 保留旧日志

  **提交**：是
  - 消息：`feat(agent): add daily memory log auto-creation`
  - 文件：`nex_agent/lib/nex/agent/memory.ex`

- [ ] 9. 反思层 - 策略调整

  **要做的事**：
  - 创建 `Nex.Agent.Reflection` 模块
  - 分析工具执行结果
  - 检测成功/失败模式
  - 调整下次迭代的策略

  **参考**：
  - Reflexion 模式
  - `nex_agent/lib/nex/agent/runner.ex` - 循环结构

  **验收标准**：
  - [ ] 分析执行结果
  - [ ] 根据成功/失败更新策略
  - [ ] 将反思注入下次迭代

  **提交**：是
  - 消息：`feat(agent): add reflection layer for strategy`
  - 文件：`nex_agent/lib/nex/agent/reflection.ex`

- [ ] 10. 反思层 - 错误模式学习

  **要做的事**：
  - 跟踪错误模式
  - 在记忆中存储解决方案
  - 主动应用已学习的解决方案

  **验收标准**：
  - [ ] 记录带上下文的错误
  - [ ] 存储解决方案
  - [ ] 在重复错误时应用解决方案

  **提交**：是
  - 消息：`feat(agent): add error pattern learning`
  - 文件：`nex_agent/lib/nex/agent/reflection.ex`

- [ ] 11. 代码进化 - 动态模块加载

  **要做的事**：
  - 创建 `Nex.Agent.Evolution` 模块
  - 实现运行时模块加载
  - 添加模块重载能力
  - 添加版本管理

  **参考**：
  - Elixir `Code.eval_quoted`、`Module.create`
  - `framework/lib/nex/reloader.ex` - 热重载模式

  **验收标准**：
  - [ ] 能在运行时加载新模块
  - [ ] 能重载现有模块
  - [ ] 维护版本历史

  **提交**：是
  - 消息：`feat(agent): add runtime code evolution`
  - 文件：`nex_agent/lib/nex/agent/evolution.ex`

- [ ] 12. 代码进化 - 自我修改

  **要做的事**：
  - 允许 Agent 修改代码文件
  - 解析和验证修改
  - 应用修改并重载
  - 添加回滚能力

  **参考**：
  - OpenClaw 系统提示作为编译输出的概念

  **验收标准**：
  - [ ] 能修改源文件
  - [ ] 能编译并重载
  - [ ] 能回滚失败

  **提交**：是
  - 消息：`feat(agent): add self-modification capability`
  - 文件：`nex_agent/lib/nex/agent/evolution.ex`

---

## 最终验证阶段

- [ ] F1. **计划合规审计** — 验证所有交付物存在
- [ ] F2. **集成测试** — 使用 mock LLM 的完整 Agent 循环
- [ ] F3. **Memory 测试** — 写入和搜索记忆
- [ ] F4. **进化测试** — 修改代码并重载

---

## 提交策略

- 每个任务单独提交（见 TODO 部分）
- 最终阶段提交：集成、测试

---

## 成功标准

### 验证命令
```bash
# 运行 Agent 测试
cd nex_agent && mix test

# 集成测试（使用 mock）
mix test --trace
```

### 最终检查清单
- [ ] MCP 能连接到服务器
- [ ] Skills 能加载和执行
- [ ] Memory 写入 Markdown 文件
- [ ] BM25 搜索返回结果
- [ ] 反思调整策略
- [ ] 代码能在运行时修改
