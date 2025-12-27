# 环境变量

Nex 提供简单的环境变量管理，自动加载 `.env` 文件。

## 配置文件

Nex 按以下顺序加载环境变量：

1. 系统环境变量
2. `.env` 文件
3. `.env.{MIX_ENV}` 文件（如 `.env.dev`、`.env.prod`）

后加载的会覆盖先加载的。

## 文件格式

```bash
# .env
PORT=4000
DATABASE_URL=postgres://localhost/myapp
SECRET_KEY=your-secret-key

# 支持注释
DEBUG=true
```

```bash
# .env.dev
PORT=3000
DEBUG=true
```

```bash
# .env.prod
PORT=80
DEBUG=false
```

## 使用环境变量

### Nex.Env.get/2

获取字符串值：

```elixir
# 获取值，不存在返回 nil
port = Nex.Env.get(:PORT)

# 获取值，不存在返回默认值
port = Nex.Env.get(:PORT, "4000")
host = Nex.Env.get(:HOST, "localhost")
```

### Nex.Env.get!/1

获取必需的值，不存在则抛出异常：

```elixir
secret = Nex.Env.get!(:SECRET_KEY)
# 如果 SECRET_KEY 未设置，会抛出异常
```

### Nex.Env.get_integer/2

获取整数值：

```elixir
port = Nex.Env.get_integer(:PORT, 4000)
timeout = Nex.Env.get_integer(:TIMEOUT, 30)
```

### Nex.Env.get_boolean/2

获取布尔值：

```elixir
debug = Nex.Env.get_boolean(:DEBUG, false)
```

支持的真值：`"true"`, `"1"`, `"yes"`, `"on"`
其他值都被视为 `false`。

## 示例

### 配置数据库

```bash
# .env
DATABASE_URL=postgres://user:pass@localhost/myapp_dev
```

```elixir
# lib/my_app/repo.ex
defmodule MyApp.Repo do
  def config do
    Nex.Env.get!(:DATABASE_URL)
  end
end
```

### 配置端口

```bash
# .env
PORT=4000
```

```elixir
# 框架自动使用 PORT 环境变量
mix nex.dev  # 监听 4000 端口
```

### 配置 API 密钥

```bash
# .env
STRIPE_API_KEY=sk_test_xxx
SENDGRID_API_KEY=SG.xxx
```

```elixir
defmodule MyApp.Payment do
  def stripe_key do
    Nex.Env.get!(:STRIPE_API_KEY)
  end
end
```

## 安全建议

### 不要提交敏感信息

将 `.env` 添加到 `.gitignore`：

```gitignore
# .gitignore
.env
.env.local
.env.*.local
```

### 提供示例文件

创建 `.env.example` 作为模板：

```bash
# .env.example
PORT=4000
DATABASE_URL=postgres://localhost/myapp
SECRET_KEY=change-me-in-production
```

### 生产环境

在生产环境中，使用系统环境变量而不是 `.env` 文件：

```bash
# 直接设置环境变量
export PORT=80
export DATABASE_URL=postgres://...
export SECRET_KEY=...

# 或在启动命令中设置
PORT=80 DATABASE_URL=... mix nex.start
```

## 开发服务器选项

`mix nex.dev` 支持以下选项：

```bash
# 指定端口
mix nex.dev --port 3000

# 指定主机
mix nex.dev --host 0.0.0.0
```

命令行选项优先于环境变量。

## API 参考

### Nex.Env.init/0

初始化环境变量（框架自动调用）：

```elixir
Nex.Env.init()
```

### Nex.Env.get/2

```elixir
@spec get(key :: atom() | String.t(), default :: String.t() | nil) :: String.t() | nil
```

### Nex.Env.get!/1

```elixir
@spec get!(key :: atom() | String.t()) :: String.t()
```

### Nex.Env.get_integer/2

```elixir
@spec get_integer(key :: atom() | String.t(), default :: integer()) :: integer()
```

### Nex.Env.get_boolean/2

```elixir
@spec get_boolean(key :: atom() | String.t(), default :: boolean()) :: boolean()
```

## 下一步

- [开发工具](./development.md) - 开发服务器
- [错误处理](./error-handling.md) - 错误页面
