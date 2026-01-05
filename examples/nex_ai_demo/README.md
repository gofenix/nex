# NexAI Demo & Integration Test

这是一个专门为 `NexAI` SDK 设计的演示项目，旨在展示其核心能力并作为集成测试的场所。

## 项目结构

- `src/api/nex_ai/` - 演示如何在 API 路由中使用 NexAI。
- `src/pages/` - 包含一个基于 Datastar 的 AI 聊天 UI。
- `demo.exs` - 独立的命令行演示脚本。

## 快速开始

### 1. 配置环境

将 `.env.example` 复制为 `.env` 并填写你的 API Key 和 Base URL（如果需要中转）：

```bash
cp .env.example .env
```

### 2. 运行命令行 Demo

如果你只想在终端查看 NexAI 的核心功能（文本生成、流式输出、工具调用）：

```bash
mix run demo.exs
```

### 3. 启动 Web 聊天 Demo

如果你想体验基于 `Nex` 框架和 `Datastar` 的可视化实时聊天：

```bash
mix nex.dev
```

然后访问控制台提示的地址（默认 `http://localhost:4000`）。

## 演示内容

- **真正流式响应**：利用 `LineBuffer` 处理 TCP 分片，首字节极速响应。
- **自动工具调用**：AI 自动执行本地 Elixir 函数并总结结果。
- **推理过程提取**：使用中间件实时分离 AI 的思考过程与正式回复。
- **跨 Provider 切换**：在代码中无缝切换 OpenAI 与 Anthropic。
