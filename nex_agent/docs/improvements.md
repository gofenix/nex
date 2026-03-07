# NexAgent 改进实施记录

基于 NexAgent vs Nanobot 对比分析，实施的改进清单。

---

## Repository Strategy

- Keep `nex_agent` inside the `nex` monorepo for now.
- Current coupling is mainly at the ecosystem level: examples, showcase apps, and shared release narrative.
- Technical extraction is still feasible later because direct package-level coupling remains limited.
- Re-evaluate a repository split only when release cadence, documentation entry points, and product identity become independently stable.

---

## 已完成的改进

### 高优先级

#### 1. 工具安全加固 — Bash 命令黑名单

**文件**: `lib/nex/agent/tool/bash.ex`

**改动**: Bash 工具执行命令前调用 `Security.validate_command()` 进行安全校验。

```elixir
def execute(%{"command" => command}, ctx) do
  case Security.validate_command(command) do
    :ok -> do_execute(command, ctx)
    {:error, reason} -> {:error, "Security: #{reason}"}
  end
end
```

被拦截的危险模式包括：
- 系统目录删除 (`rm -rf /usr`, `rm ~/`)
- 磁盘操作 (`dd if=/dev/`, `mkfs`, `fdisk`)
- 系统控制 (`shutdown`, `reboot`, `poweroff`)
- Fork bombs (`:(){:|:&};:`)
- 无限循环 (`while true...done`)
- 远程代码执行 (`curl | sh`, `eval $(curl`)
- 凭证窃取 (`cat ~/.ssh/`, `cat .env`, `cat *.pem`)
- 网络外泄 (`curl -d @file`, `nc -l`)
- 计划任务篡改 (`crontab -`)

#### 2. Workspace 沙箱 — 文件读写路径限制

**文件**: `lib/nex/agent/tool/read.ex`, `lib/nex/agent/tool/write.ex`, `lib/nex/agent/tool/edit.ex`

**改动**: 所有文件操作工具在执行前调用 `Security.validate_path()`, 路径必须在以下允许范围内：
- 项目目录 (`File.cwd!()`)
- Agent workspace (`~/.nex/agent`)
- 临时目录 (`/tmp`)

可通过 `NEX_ALLOWED_ROOTS` 环境变量扩展。

#### 3. Security.ex 危险模式增强

**文件**: `lib/nex/agent/security.ex`

**改动**:
- 危险命令模式从 8 个增加到 30+
- 命令白名单从 ~40 个增加到 ~80 个，覆盖更多开发工具
- 新增: `bun`, `deno`, `go`, `ruby`, `gem`, `java`, `gradle`, `mvn`, `jq`, `yq`, `tar`, `zip`, `base64` 等

#### 4. 新增渠道 — Discord

**文件**: `lib/nex/agent/channel/discord.ex`

**实现**:
- WebSocket Gateway API (v10) 接入
- 心跳维持 + identify/resume 机制
- 支持 DM 和群组 @mention 两种触发方式
- 2000 字符消息分片
- Rate limit 自动重试
- `allow_from` 频道白名单

**配置**:
```json
{
  "discord": {
    "enabled": true,
    "token": "Bot MTIz...",
    "allow_from": [],
    "guild_id": null
  }
}
```

#### 5. 新增渠道 — Slack

**文件**: `lib/nex/agent/channel/slack.ex`

**实现**:
- Socket Mode (WebSocket) 接收事件
- Web API 发送消息
- 支持 `message` 和 `app_mention` 事件
- 线程回复 (thread_ts)
- Bot 身份自动检测

**配置**:
```json
{
  "slack": {
    "enabled": true,
    "app_token": "xapp-...",
    "bot_token": "xoxb-...",
    "allow_from": []
  }
}
```

#### 6. 新增渠道 — DingTalk (钉钉)

**文件**: `lib/nex/agent/channel/dingtalk.ex`

**实现**:
- Stream Mode API 接收机器人消息
- OAuth2 access token 管理 + 自动刷新
- Session webhook 优先回复，Robot API 兜底
- 支持单聊和群聊

**配置**:
```json
{
  "dingtalk": {
    "enabled": true,
    "app_key": "ding...",
    "app_secret": "...",
    "robot_code": "ding...",
    "allow_from": []
  }
}
```

#### 7. 新增工具 — ListDir

**文件**: `lib/nex/agent/tool/list_dir.ex`

**实现**:
- 列出目录内容，显示文件类型、大小、修改时间
- 支持递归列出 (`recursive: true`)
- 路径通过 Security 沙箱校验

**工具定义**:
```json
{
  "name": "list_dir",
  "parameters": {
    "path": "目录路径",
    "recursive": "是否递归 (default: false)"
  }
}
```

### 集成变更

#### Config.ex 扩展

**文件**: `lib/nex/agent/config.ex`

新增 `discord`, `slack`, `dingtalk` 三个配置段，包含：
- struct 字段定义
- 默认值
- getter/setter 方法
- 配置校验 (`valid?/1`)
- 序列化/反序列化

#### Gateway.ex 扩展

**文件**: `lib/nex/agent/gateway.ex`

- 新增 `ensure_discord_channel_started/1`
- 新增 `ensure_slack_channel_started/1`
- 新增 `ensure_dingtalk_channel_started/1`
- 新增对应的 `stop_*_channel/0`
- `status/0` 返回新渠道状态

#### Tool Registry 扩展

**文件**: `lib/nex/agent/tool/registry.ex`

- `@default_tools` 新增 `Nex.Agent.Tool.ListDir`
- 默认工具数从 15 增加到 16

---

## 未来改进方向

### 中优先级

| # | 改进 | 说明 |
|---|------|------|
| 1 | **LiteLLM 集成** | 考虑引入 LiteLLM 的 HTTP bridge 扩展 provider 覆盖 |
| 2 | **Provider Registry** | 统一的 provider 元数据 (API key 前缀检测, 模型名映射) |

### 低优先级

| # | 改进 | 说明 |
|---|------|------|
| 3 | **Cron Tool** | 让 agent 通过工具自主创建定时任务 (Cron GenServer 已存在) |
| 4 | **更多渠道** | WhatsApp, QQ, Matrix, Email |
