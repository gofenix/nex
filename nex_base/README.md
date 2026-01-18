# NexBase

**Elixir 版的 Supabase 客户端** - 一个流畅的 PostgreSQL 查询构建器，灵感来自 Supabase 的 JavaScript 客户端。

用简洁、可链式的 API 构建类型安全的数据库查询。

## ✨ 特性

- 🔗 **流畅 API** - 链式调用，代码可读性强
- 🛡️ **类型安全** - 基于 Ecto，完全类型安全
- 📝 **PostgreSQL 优先** - 针对 PostgreSQL 优化
- 🎯 **极简设计** - 无魔法，直观易用
- 🚀 **生产就绪** - 基于久经考验的 Ecto
- � **Schema-less** - 支持无 schema 的动态表查询

## 📦 安装

在 `mix.exs` 中添加依赖：

```elixir
def deps do
  [
    {:nex_base, "~> 0.1.0"}
  ]
end
```

运行 `mix deps.get`。

## 🚀 快速开始

### 1. 初始化客户端

假设你已经有一个 Ecto Repo（如 `MyApp.Repo`），只需创建客户端：

```elixir
# 在模块属性中初始化客户端
@client = NexBase.client(repo: MyApp.Repo)
```

### 2. 构建查询

```elixir
# 查询
{:ok, users} = @client
|> NexBase.from("users")
|> NexBase.select(["id", "name", "email"])
|> NexBase.eq(:active, true)
|> NexBase.order(:created_at, :desc)
|> NexBase.limit(10)
|> NexBase.run()

# 插入
{:ok, result} = @client
|> NexBase.from("users")
|> NexBase.insert(%{name: "John", email: "john@example.com"})
|> NexBase.run()

# 更新
{:ok, result} = @client
|> NexBase.from("users")
|> NexBase.eq(:id, 123)
|> NexBase.update(%{name: "Jane"})
|> NexBase.run()

# 删除
{:ok, result} = @client
|> NexBase.from("users")
|> NexBase.eq(:id, 123)
|> NexBase.delete()
|> NexBase.run()
```

## 📚 API 参考

### 基础操作

| 方法 | 说明 | 示例 |
|------|------|------|
| `from(table)` | 指定表名 | `.from("users")` |
| `select(fields)` | 选择字段 | `.select(["id", "name"])` |
| `insert(data)` | 插入数据 | `.insert(%{name: "John"})` |
| `update(data)` | 更新数据 | `.update(%{name: "Jane"})` |
| `delete()` | 删除数据 | `.delete()` |
| `run()` | 执行查询 | `.run()` |

### 过滤器

| 方法 | 说明 | 示例 |
|------|------|------|
| `eq(col, val)` | 等于 | `.eq(:status, "active")` |
| `neq(col, val)` | 不等于 | `.neq(:status, "deleted")` |
| `gt(col, val)` | 大于 | `.gt(:score, 90)` |
| `gte(col, val)` | 大于等于 | `.gte(:age, 18)` |
| `lt(col, val)` | 小于 | `.lt(:price, 100)` |
| `lte(col, val)` | 小于等于 | `.lte(:quantity, 50)` |
| `like(col, pattern)` | 模糊匹配（区分大小写） | `.like(:name, "%john%")` |
| `ilike(col, pattern)` | 模糊匹配（不区分大小写） | `.ilike(:email, "%@gmail%")` |
| `in(col, values)` | 包含在列表中 | `.in(:status, ["active", "pending"])` |
| `is(col, val)` | IS NULL / IS TRUE / IS FALSE | `.is(:deleted_at, nil)` |

### 排序和分页

| 方法 | 说明 | 示例 |
|------|------|------|
| `order(col, direction)` | 排序 | `.order(:created_at, :desc)` |
| `limit(n)` | 限制结果数 | `.limit(10)` |
| `offset(n)` | 跳过前 N 条 | `.offset(20)` |

### 原始 SQL

```elixir
# 执行原始 SQL 查询
{:ok, result} = @client |> NexBase.query("SELECT * FROM users WHERE id = $1", [1])

# 使用 query!（失败时抛出异常）
result = @client |> NexBase.query!("SELECT version()", [])
```

## 💡 使用示例

### 完整的 CRUD 示例

```elixir
# 初始化客户端
client = NexBase.client(repo: MyApp.Repo)

# CREATE - 创建新用户
{:ok, user} = client
|> NexBase.from("users")
|> NexBase.insert(%{
  name: "Alice",
  email: "alice@example.com",
  age: 25
})
|> NexBase.run()

# READ - 查询用户
{:ok, users} = client
|> NexBase.from("users")
|> NexBase.eq(:age, 25)
|> NexBase.order(:created_at, :desc)
|> NexBase.run()

# users 是一个列表，每个元素是一个 Map
# [
#   %{"id" => 1, "name" => "Alice", "email" => "alice@example.com", "age" => 25},
#   %{"id" => 2, "name" => "Bob", "email" => "bob@example.com", "age" => 25}
# ]

# 获取第一个用户
[first_user | _] = users
first_user["name"]  # => "Alice"
first_user["email"] # => "alice@example.com"

# 或者使用 Enum 遍历
Enum.each(users, fn user ->
  IO.puts("#{user["name"]}: #{user["email"]}")
end)

# UPDATE - 更新用户
{:ok, _} = client
|> NexBase.from("users")
|> NexBase.eq(:email, "alice@example.com")
|> NexBase.update(%{age: 26})
|> NexBase.run()

# DELETE - 删除用户
{:ok, _} = client
|> NexBase.from("users")
|> NexBase.eq(:email, "alice@example.com")
|> NexBase.delete()
|> NexBase.run()
```

### 复杂查询

```elixir
# 多条件查询
{:ok, results} = client
|> NexBase.from("orders")
|> NexBase.eq(:status, "completed")
|> NexBase.gt(:total, 100)
|> NexBase.lt(:created_at, DateTime.utc_now())
|> NexBase.in(:category, ["electronics", "books"])
|> NexBase.order(:created_at, :desc)
|> NexBase.limit(20)
|> NexBase.run()

# 模糊搜索
{:ok, results} = client
|> NexBase.from("products")
|> NexBase.ilike(:name, "%laptop%")
|> NexBase.gte(:price, 500)
|> NexBase.run()

# 分页
{:ok, page1} = client
|> NexBase.from("users")
|> NexBase.order(:id, :asc)
|> NexBase.limit(10)
|> NexBase.offset(0)
|> NexBase.run()

{:ok, page2} = client
|> NexBase.from("users")
|> NexBase.order(:id, :asc)
|> NexBase.limit(10)
|> NexBase.offset(10)
|> NexBase.run()
```

## 🏗️ 架构设计

### 客户端模式

NexBase 采用 **客户端模式**，类似于 Supabase：

```elixir
# 在模块属性中初始化客户端
defmodule MyApp.Pages.Users do
  use Nex
  
  @client NexBase.client(repo: MyApp.Repo)
  
  def mount(_params) do
    {:ok, users} = @client
    |> NexBase.from("users")
    |> NexBase.run()
    
    %{users: users}
  end
end
```

### Query 结构体

内部使用 `NexBase.Query` 结构体存储查询状态：

```elixir
%NexBase.Query{
  table: "users",
  select: ["id", "name"],
  filters: [
    {:eq, :status, "active"},
    {:gt, :age, 18}
  ],
  order_by: [{:desc, :created_at}],
  limit: 10,
  offset: 0,
  repo: MyApp.Repo
}
```

## 🔒 错误处理

所有操作都返回 `{:ok, result}` 或 `{:error, reason}`：

```elixir
case client
|> NexBase.from("users")
|> NexBase.eq(:id, 123)
|> NexBase.update(%{name: "Updated"})
|> NexBase.run() do
  {:ok, result} ->
    IO.puts("更新成功")
  {:error, reason} ->
    IO.puts("更新失败: #{inspect(reason)}")
end
```

使用 `query!` 和 `run!` 在失败时抛出异常：

```elixir
# 失败时抛出异常
result = client
|> NexBase.from("users")
|> NexBase.eq(:id, 123)
|> NexBase.run!()
```

## 🎯 最佳实践

### 1. 在模块属性中初始化客户端

```elixir
defmodule MyApp.Users do
  @client NexBase.client(repo: MyApp.Repo)
  
  def list_active do
    @client
    |> NexBase.from("users")
    |> NexBase.eq(:active, true)
    |> NexBase.run()
  end
end
```

### 2. 使用原子作为列名

```elixir
# ✅ 推荐
.eq(:status, "active")

# ❌ 避免
.eq("status", "active")
```

### 3. 链式调用保持可读性

```elixir
# ✅ 好
{:ok, users} = client
|> NexBase.from("users")
|> NexBase.eq(:active, true)
|> NexBase.order(:created_at, :desc)
|> NexBase.limit(10)
|> NexBase.run()

# ❌ 差
{:ok, users} = client |> NexBase.from("users") |> NexBase.eq(:active, true) |> NexBase.order(:created_at, :desc) |> NexBase.limit(10) |> NexBase.run()
```

### 4. 处理错误

```elixir
# ✅ 推荐
case client |> NexBase.from("users") |> NexBase.run() do
  {:ok, users} -> users
  {:error, reason} -> handle_error(reason)
end

# ❌ 避免（除非确定不会失败）
{:ok, users} = client |> NexBase.from("users") |> NexBase.run()
```

## 🔄 高级功能

### RPC 调用（存储过程）

```elixir
# 调用数据库函数
{:ok, result} = NexBase.rpc("my_function", %{param1: "value1", param2: 123}, repo: MyApp.Repo)
```

### 批量操作

```elixir
# 批量插入
data = [
  %{name: "Alice", email: "alice@example.com"},
  %{name: "Bob", email: "bob@example.com"},
  %{name: "Charlie", email: "charlie@example.com"}
]

{:ok, result} = client
|> NexBase.from("users")
|> NexBase.insert(data)
|> NexBase.run()

# Upsert（插入或更新）
{:ok, result} = client
|> NexBase.from("users")
|> NexBase.upsert(data)
|> NexBase.run()
```

### 事务处理

```elixir
# 使用 Ecto 事务
Ecto.Multi.new()
|> Ecto.Multi.insert(:user, %User{name: "Alice"})
|> Ecto.Multi.insert(:post, %Post{user_id: {:user, :id}, title: "Hello"})
|> MyApp.Repo.transaction()
```

## 🆚 Supabase 对比

### API 相似性

| 操作 | Supabase JS | NexBase Elixir |
|------|-------------|----------------|
| 初始化 | `supabase.from('table')` | `client \|> NexBase.from("table")` |
| 查询 | `.select()` | `.select(fields)` |
| 过滤 | `.eq('col', val)` | `.eq(:col, val)` |
| 排序 | `.order('col', {ascending: true})` | `.order(:col, :asc)` |
| 分页 | `.range(0, 9)` | `.limit(10).offset(0)` |
| 插入 | `.insert({...})` | `.insert(%{...})` |
| 更新 | `.update({...})` | `.update(%{...})` |
| 删除 | `.delete()` | `.delete()` |
| 执行 | `.then()` | `.run()` |

### 主要差异

| 特性 | Supabase | NexBase |
|------|----------|---------|
| 语言 | JavaScript | Elixir |
| 类型系统 | 动态 | 静态（Elixir） |
| 错误处理 | Promise/async | {:ok, result} / {:error, reason} |
| 实时订阅 | 支持 | 通过 Nex.stream/SSE |
| 认证 | 内置 | 通过 Nex 框架 |
| 存储 | 内置 | 通过 S3 集成 |

## 🔌 与 Nex 框架集成

### 在 Page 中使用

```elixir
defmodule MyApp.Pages.Products do
  use Nex
  
  @client NexBase.client(repo: MyApp.Repo)
  
  # 初始化页面数据
  def mount(_params) do
    {:ok, products} = @client
    |> NexBase.from("products")
    |> NexBase.eq(:active, true)
    |> NexBase.order(:created_at, :desc)
    |> NexBase.run()
    
    %{products: products}
  end
  
  # 处理表单提交（Page Action）
  def create(%{"name" => name, "price" => price}) do
    {:ok, product} = @client
    |> NexBase.from("products")
    |> NexBase.insert(%{
      name: name,
      price: String.to_float(price),
      active: true
    })
    |> NexBase.run()
    
    # 返回 HTML 片段
    product_item(%{product: product})
  end
  
  # 更新产品
  def update(%{"id" => id, "name" => name}) do
    {:ok, _} = @client
    |> NexBase.from("products")
    |> NexBase.eq(:id, String.to_integer(id))
    |> NexBase.update(%{name: name})
    |> NexBase.run()
    
    :empty
  end
  
  # 删除产品
  def delete(%{"id" => id}) do
    {:ok, _} = @client
    |> NexBase.from("products")
    |> NexBase.eq(:id, String.to_integer(id))
    |> NexBase.delete()
    |> NexBase.run()
    
    :empty
  end
  
  # 私有组件
  defp product_item(assigns) do
    ~H"""
    <div id={"product-#{@product["id"]}"}>
      <h3><%= @product["name"] %></h3>
      <p>¥<%= @product["price"] %></p>
    </div>
    """
  end
end
```

### 在 API 中使用

```elixir
defmodule MyApp.Api.Products do
  use Nex
  
  @client NexBase.client(repo: MyApp.Repo)
  
  def get(req) do
    id = req.query["id"]
    
    case @client
    |> NexBase.from("products")
    |> NexBase.eq(:id, String.to_integer(id))
    |> NexBase.run() do
      {:ok, [product]} ->
        Nex.json(%{data: product})
      {:ok, []} ->
        Nex.json(%{error: "Not found"}, status: 404)
      {:error, reason} ->
        Nex.json(%{error: inspect(reason)}, status: 500)
    end
  end
  
  def post(req) do
    {:ok, product} = @client
    |> NexBase.from("products")
    |> NexBase.insert(req.body)
    |> NexBase.run()
    
    Nex.json(%{data: product}, status: 201)
  end
end
```

## 📊 性能优化

### 1. 连接池配置

```elixir
# config/config.exs
config :my_app, MyApp.Repo,
  url: System.get_env("DATABASE_URL"),
  pool_size: 10,
  queue_target: 5000,
  queue_interval: 1000
```

### 2. 查询优化

```elixir
# ❌ 不好：N+1 查询
{:ok, users} = client |> NexBase.from("users") |> NexBase.run()
Enum.map(users, fn user ->
  {:ok, posts} = client
  |> NexBase.from("posts")
  |> NexBase.eq(:user_id, user["id"])
  |> NexBase.run()
  
  Map.put(user, "posts", posts)
end)

# ✅ 好：使用 JOIN（通过原始 SQL）
{:ok, result} = client
|> NexBase.query("""
  SELECT u.*, json_agg(p.*) as posts
  FROM users u
  LEFT JOIN posts p ON p.user_id = u.id
  GROUP BY u.id
""", [])
```

### 3. 索引建议

```sql
-- 常用查询字段
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);

-- 复合索引
CREATE INDEX idx_orders_user_status ON orders(user_id, status);
```

### 4. 选择字段优化

```elixir
# ❌ 不好：查询所有字段
{:ok, users} = client
|> NexBase.from("users")
|> NexBase.run()

# ✅ 好：只查询需要的字段
{:ok, users} = client
|> NexBase.from("users")
|> NexBase.select(["id", "name", "email"])
|> NexBase.run()
```

## ❓ 常见问题

### Q: 如何处理 NULL 值？

```elixir
# 查询 NULL
{:ok, results} = client
|> NexBase.from("users")
|> NexBase.is(:deleted_at, nil)
|> NexBase.run()

# 查询非 NULL
{:ok, results} = client
|> NexBase.from("users")
|> NexBase.neq(:deleted_at, nil)
|> NexBase.run()
```

### Q: 如何进行 LIKE 搜索？

```elixir
# 区分大小写
{:ok, results} = client
|> NexBase.from("products")
|> NexBase.like(:name, "%laptop%")
|> NexBase.run()

# 不区分大小写（推荐）
{:ok, results} = client
|> NexBase.from("products")
|> NexBase.ilike(:name, "%laptop%")
|> NexBase.run()
```

### Q: 如何处理日期范围查询？

```elixir
start_date = Date.new!(2024, 1, 1)
end_date = Date.new!(2024, 12, 31)

{:ok, results} = client
|> NexBase.from("orders")
|> NexBase.gte(:created_at, start_date)
|> NexBase.lte(:created_at, end_date)
|> NexBase.run()
```

### Q: 如何进行分组和聚合？

```elixir
# 使用原始 SQL
{:ok, result} = client
|> NexBase.query("""
  SELECT category, COUNT(*) as count, AVG(price) as avg_price
  FROM products
  GROUP BY category
  HAVING COUNT(*) > 5
  ORDER BY count DESC
""", [])
```

### Q: 如何处理事务？

```elixir
# 使用 Ecto.Multi
result = Ecto.Multi.new()
|> Ecto.Multi.run(:insert_user, fn _repo, _changes ->
  client
  |> NexBase.from("users")
  |> NexBase.insert(%{name: "Alice"})
  |> NexBase.run()
end)
|> Ecto.Multi.run(:insert_post, fn _repo, %{insert_user: {:ok, user}} ->
  client
  |> NexBase.from("posts")
  |> NexBase.insert(%{user_id: user["id"], title: "Hello"})
  |> NexBase.run()
end)
|> MyApp.Repo.transaction()
```

### Q: 如何处理大数据集？

```elixir
# 使用分页
page_size = 100
total_pages = 10

Enum.each(1..total_pages, fn page ->
  offset = (page - 1) * page_size
  
  {:ok, results} = client
  |> NexBase.from("large_table")
  |> NexBase.order(:id, :asc)
  |> NexBase.limit(page_size)
  |> NexBase.offset(offset)
  |> NexBase.run()
  
  process_batch(results)
end)
```

## � 安全最佳实践

### 1. 参数化查询

```elixir
# ✅ 安全：使用参数化查询
{:ok, result} = client
|> NexBase.query("SELECT * FROM users WHERE id = $1", [user_id])
|> NexBase.run()

# ❌ 不安全：字符串插值
{:ok, result} = client
|> NexBase.query("SELECT * FROM users WHERE id = #{user_id}")
|> NexBase.run()
```

### 2. 行级安全 (RLS)

```sql
-- 启用 RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- 创建策略
CREATE POLICY "Users can view their own data"
ON users FOR SELECT
USING (auth.uid() = id);
```

### 3. 权限管理

```elixir
# 在 Page Action 中检查权限
def update(%{"id" => id} = params) do
  current_user_id = get_current_user_id()
  
  case @client
  |> NexBase.from("posts")
  |> NexBase.eq(:id, String.to_integer(id))
  |> NexBase.eq(:user_id, current_user_id)
  |> NexBase.run() do
    {:ok, [_post]} ->
      # 用户有权限，执行更新
      @client
      |> NexBase.from("posts")
      |> NexBase.eq(:id, String.to_integer(id))
      |> NexBase.update(params)
      |> NexBase.run()
    
    {:ok, []} ->
      # 用户无权限
      {:error, "Unauthorized"}
  end
end
```

## �� 完整示例

查看 [nex_base_demo](../examples/nex_base_demo) 获取完整的 SSR 应用示例。

## 🔗 相关资源

- [Nex 框架文档](https://github.com/gofenix/nex)
- [Ecto 文档](https://hexdocs.pm/ecto)
- [PostgreSQL 文档](https://www.postgresql.org/docs/)
- [Supabase 文档](https://supabase.com/docs)

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT

