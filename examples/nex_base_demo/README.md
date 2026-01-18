# NexBase Demo - SSR 任务管理应用

一个完整的服务端渲染 (SSR) 示例，展示 **Nex 框架** 与 **NexBase 数据库查询构建器** 的完美集成。

## 🎯 核心特性

- **SSR 模式** - 服务端直接渲染完整数据，无需 API 层
- **HTMX 交互** - 无刷新的流畅用户体验
- **NexBase 客户端模式** - Supabase 风格的简洁数据库 API
- **完整 CRUD** - 创建、读取、更新、删除任务
- **极简架构** - 一个页面搞定所有功能

## 🚀 快速开始

### 1. 配置环境

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑 .env，设置 DATABASE_URL
# 示例: postgresql://postgres:password@localhost:5432/nex_base_demo
```

### 2. 创建数据库表

```bash
# 使用提供的 schema.sql
psql $DATABASE_URL -f schema.sql
```

### 3. 启动服务器

```bash
mix deps.get
mix nex.dev
```

访问 http://localhost:4000

## 📚 NexBase 框架介绍

NexBase 是一个 **Elixir 版的 Supabase 客户端**，提供流畅的 PostgreSQL 查询构建器。

### 核心概念

**1. 初始化客户端**
```elixir
@client = NexBase.client(repo: MyApp.Repo)
```

**2. 构建查询**
```elixir
# 查询
{:ok, tasks} = @client
|> NexBase.from("tasks")
|> NexBase.order(:inserted_at, :desc)
|> NexBase.limit(10)
|> NexBase.run()

# 插入
@client
|> NexBase.from("tasks")
|> NexBase.insert(%{title: "New Task", completed: false})
|> NexBase.run()

# 更新
@client
|> NexBase.from("tasks")
|> NexBase.eq(:id, 1)
|> NexBase.update(%{completed: true})
|> NexBase.run()

# 删除
@client
|> NexBase.from("tasks")
|> NexBase.eq(:id, 1)
|> NexBase.delete()
|> NexBase.run()
```

### 支持的过滤器

| 方法 | 说明 | 示例 |
|------|------|------|
| `eq` | 等于 | `.eq(:status, "active")` |
| `neq` | 不等于 | `.neq(:status, "deleted")` |
| `gt` | 大于 | `.gt(:score, 90)` |
| `gte` | 大于等于 | `.gte(:age, 18)` |
| `lt` | 小于 | `.lt(:price, 100)` |
| `lte` | 小于等于 | `.lte(:quantity, 50)` |
| `like` | 模糊匹配 | `.like(:name, "%john%")` |
| `ilike` | 不区分大小写匹配 | `.ilike(:email, "%@gmail%")` |
| `in` | 包含 | `.in(:status, ["active", "pending"])` |
| `is` | IS NULL | `.is(:deleted_at, nil)` |

### 原始 SQL 查询

```elixir
# 执行原始 SQL
{:ok, result} = @client |> NexBase.query("SELECT version()", [])
[[version]] = result.rows
```

## 📁 项目结构

```
nex_base_demo/
├── src/
│   ├── application.ex    # 启动 Repo（极简）
│   ├── repo.ex          # Ecto Repo 配置
│   ├── layouts.ex       # 页面布局
│   └── pages/
│       └── index.ex     # 主页面（包含完整 CRUD）
├── schema.sql           # 数据库 schema
├── .env                 # 环境变量
├── .env.example         # 环境变量模板
└── mix.exs
```

## 🏗️ 架构设计

### SSR 模式（推荐）

```elixir
defmodule NexBaseDemo.Pages.Index do
  use Nex

  @client NexBase.client(repo: NexBaseDemo.Repo)

  # 1. 服务端加载数据
  def mount(_params) do
    {:ok, tasks} = @client
    |> NexBase.from("tasks")
    |> NexBase.run()
    
    %{tasks: tasks}
  end

  # 2. 渲染完整 HTML
  def render(assigns) do
    ~H"""
    <%= for task <- @tasks do %>
      <div><%= task["title"] %></div>
    <% end %>
    """
  end

  # 3. Page Actions 处理交互
  def create(%{"title" => title}) do
    @client
    |> NexBase.from("tasks")
    |> NexBase.insert(%{title: title})
    |> NexBase.run()
    
    # 返回 HTML 片段
    task_item(%{task: new_task})
  end
end
```

### 关键原则

- ✅ **一个页面** - 所有 CRUD 在同一个 Page 模块
- ✅ **Page Actions** - 使用 `def action_name(params)` 处理表单提交
- ✅ **HTMX** - 表单提交到 Page Actions，返回 HTML 片段
- ✅ **无 API 层** - SSR 模式不需要单独的 REST API
- ✅ **极简 Application** - 只启动基础设施（Repo）

## 🔧 Nex 框架特性

### 文件路由

```
src/pages/index.ex       → GET /
src/pages/tasks.ex       → GET /tasks
src/pages/tasks/edit.ex  → GET /tasks/edit
```

### Page Actions

```elixir
# POST /create
def create(params) do
  # 处理表单提交
  # 返回 HTML 片段或 :empty
end

# POST /toggle?id=1
def toggle(params) do
  # 处理 HTMX 请求
end
```

### 自动 CSRF 保护

Nex 自动为所有表单和 HTMX 请求添加 CSRF 令牌，无需手动配置。

## 📊 数据库 Schema

```sql
CREATE TABLE tasks (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  completed BOOLEAN DEFAULT FALSE,
  inserted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## 🎓 学习资源

- [Nex 官方文档](https://github.com/gofenix/nex)
- [NexBase 查询构建器](https://github.com/gofenix/nex/tree/main/nex_base)
- [SSR vs SPA 对比](https://htmx.org/)

## 📝 示例代码

### 完整的 CRUD 操作

```elixir
# 初始化客户端
client = NexBase.client(repo: MyApp.Repo)

# CREATE
client
|> NexBase.from("tasks")
|> NexBase.insert(%{title: "Learn Elixir", completed: false})
|> NexBase.run()

# READ
{:ok, tasks} = client
|> NexBase.from("tasks")
|> NexBase.order(:inserted_at, :desc)
|> NexBase.limit(20)
|> NexBase.run()

# UPDATE
client
|> NexBase.from("tasks")
|> NexBase.eq(:id, 1)
|> NexBase.update(%{completed: true})
|> NexBase.run()

# DELETE
client
|> NexBase.from("tasks")
|> NexBase.eq(:id, 1)
|> NexBase.delete()
|> NexBase.run()

# 复杂查询
{:ok, results} = client
|> NexBase.from("tasks")
|> NexBase.eq(:completed, false)
|> NexBase.gt(:created_at, DateTime.add(DateTime.utc_now(), -7, :day))
|> NexBase.order(:priority, :desc)
|> NexBase.limit(10)
|> NexBase.run()
```

## 🚀 部署

### 生产环境

```bash
mix nex.start
```

### 环境变量

确保设置以下环境变量：
- `DATABASE_URL` - PostgreSQL 连接字符串
- `POOL_SIZE` - 连接池大小（默认 10）

## 📄 许可证

MIT

## 👨‍💻 贡献

欢迎提交 Issue 和 Pull Request！
