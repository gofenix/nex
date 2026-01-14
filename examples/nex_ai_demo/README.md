# NexAI Demo & Integration Test

这是一个专门为 `NexAI` SDK 设计的演示项目，旨在展示其核心能力并作为集成测试的场所。

## 项目结构

- `src/api/nex_ai/` - 演示如何在 API 路由中使用 NexAI。
- `src/pages/` - 包含一个基于 Datastar 的 AI 聊天 UI。
- `demo.exs` - 独立的命令行演示脚本（包含所有 API 的完整演示）。
- `run_all_examples.sh` - 一键运行所有演示的脚本。

## 快速开始

### 1. 配置环境

将 `.env.example` 复制为 `.env` 并填写你的 API Key：

```bash
cp .env.example .env
```

### 2. 运行命令行 Demo

运行 `demo.exs` 查看 NexAI 的所有核心功能：

```bash
bash run_all_examples.sh
# 或直接运行
mix run demo.exs
```

### 3. 启动 Web 聊天 Demo

体验基于 `Nex` 框架和 `Datastar` 的可视化实时聊天：

```bash
mix nex.dev
```

然后访问 `http://localhost:4000`。

## 演示内容

- **真正流式响应** - TCP 分片处理，首字节极速响应
- **自动工具调用** - AI 自动执行本地 Elixir 函数
- **推理过程提取** - 中间件实时分离思考过程与回复
- **跨 Provider 切换** - OpenAI 与 Anthropic 无缝切换
- **平滑流输出** - Token 级别的流式平滑
- **结构化输出** - JSON Schema 约束的生成
- **Vercel/DataStar 协议** - 前端 SDK 完美兼容
