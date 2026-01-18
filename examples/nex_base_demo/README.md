# NexBase Demo

演示 Nex Web 框架与 NexBase 数据库包的集成。

## 特性

- **任务管理**: 创建、查看、标记完成、删除任务
- **实时更新**: 使用 HTMX 实现无刷新交互
- **数据库集成**: 演示 NexBase 查询构建器的完整 CRUD 操作

## 快速开始

### 1. 配置环境变量

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑 .env 文件，设置 DATABASE_URL
# 示例: postgresql://postgres:password@localhost:5432/nex_base_demo
```

### 2. 安装依赖并编译

```bash
mix deps.get
mix compile
```

### 3. 启动服务器

```bash
mix nex.dev
```

访问 http://localhost:4000

> **注意**: 应用启动时会自动创建 `tasks` 表（如果不存在）。

## NexBase API 使用示例

```elixir
# 查询所有任务
{:ok, tasks} = NexBase.from("tasks") |> NexBase.run()

# 条件查询
{:ok, tasks} = NexBase.from("tasks")
               |> NexBase.eq(:completed, false)
               |> NexBase.run()

# 插入任务
NexBase.from("tasks")
|> NexBase.insert(%{title: "学习 Elixir", completed: false})
|> NexBase.run()

# 更新任务
NexBase.from("tasks")
|> NexBase.eq(:id, 1)
|> NexBase.update(%{completed: true})
|> NexBase.run()

# 删除任务
NexBase.from("tasks")
|> NexBase.eq(:id, 1)
|> NexBase.delete()
|> NexBase.run()
```

## 项目结构

```
nex_base_demo/
├── src/
│   ├── application.ex     # 应用入口，初始化数据库
│   ├── layouts.ex         # 布局组件
│   └── pages/
│       └── index.ex       # 首页 + API (任务 CRUD)
├── .env                   # 环境变量 (需从 .env.example 复制)
├── .env.example           # 环境变量模板
├── mix.exs                # 项目配置
└── setup.sh               # 设置脚本 (可选)
```

## 依赖

- Elixir ~> 1.18
- Nex Core (框架)
- Nex Base (数据库查询构建器)
