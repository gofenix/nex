# Nex 路由与文件结构指南

Nex 采用基于文件系统的路由机制（File-system Routing），你的文件结构直接决定了应用的 URL 结构。

## 目录

- [基本规则](#基本规则)
- [动态路由](#动态路由)
- [嵌套路由](#嵌套路由)
- [API 路由](#api-路由)
- [路由优先级](#路由优先级)
- [模块名映射规则](#模块名映射规则)

---

## 基本规则

所有页面路由文件都放在 `src/pages/` 目录下。

| 文件路径 | URL 路径 | 模块名 (示例) |
| :--- | :--- | :--- |
| `src/pages/index.ex` | `/` | `MyApp.Pages.Index` |
| `src/pages/about.ex` | `/about` | `MyApp.Pages.About` |
| `src/pages/contact.ex` | `/contact` | `MyApp.Pages.Contact` |

---

## 动态路由

Nex 支持三种类型的路由段：

### 1. 静态段
普通的文件名或目录名。
*   `src/pages/users/list.ex` -> `/users/list`

### 2. 动态段 `[param]`
匹配单个 URL 路径段。参数名在方括号中定义。
*   **文件**: `src/pages/users/[id].ex`
*   **匹配**: `/users/123`, `/users/alice`
*   **参数获取**: 在 `mount/1` 或 Action 函数的 params 中通过 `"id"` 获取。

```elixir
# src/pages/users/[id].ex
defmodule MyApp.Pages.Users.Id do
  use Nex

  def mount(params) do
    # params = %{"id" => "123"}
    %{user_id: params["id"]}
  end
end
```

### 3. Catch-all 段 `[...param]`
匹配剩余的所有路径段。必须放在路径的最后。
*   **文件**: `src/pages/docs/[...path].ex`
*   **匹配**: `/docs/guide`, `/docs/api/v1`, `/docs/a/b/c`
*   **参数获取**: `params["path"]` 将是一个包含路径段的**列表**。

```elixir
# src/pages/docs/[...path].ex
defmodule MyApp.Pages.Docs.Path do
  use Nex

  def mount(params) do
    # 访问 /docs/api/v1
    # params = %{"path" => ["api", "v1"]}
    %{path_segments: params["path"]}
  end
end
```

---

## 嵌套路由

你可以混合使用目录和文件来创建深层嵌套的路由。

| 文件路径 | URL 匹配 | 说明 |
| :--- | :--- | :--- |
| `src/pages/posts/[year]/[month].ex` | `/posts/2024/01` | 多层动态参数 |
| `src/pages/files/[category]/[...path].ex` | `/files/images/2024/logo.png` | 混合动态和 catch-all |
| `src/pages/users/[id]/profile.ex` | `/users/123/profile` | 动态路径下的静态子路径 |

---

## API 路由

API 路由遵循相同的规则，但文件放在 `src/api/` 目录下，且 URL 以前缀 `/api/` 开头。

| 文件路径 | URL 路径 |
| :--- | :--- |
| `src/api/users.ex` | `/api/users` |
| `src/api/posts/[id].ex` | `/api/posts/123` |

API 模块使用 `Nex.Api` 或 `Nex.SSE`，而不是 `Nex.Page`。

---

## 路由优先级

当多个路由模式匹配同一个 URL 时，Nex 按照以下优先级（从高到低）决定使用哪个文件：

1.  **静态段优先**: `users/profile.ex` 优先于 `users/[id].ex`。
2.  **动态段次之**: `posts/[id].ex` 优先于 `posts/[...slug].ex`。
3.  **Catch-all 最低**: `[...path].ex` 只有在没有其他匹配时才会被选中。
4.  **深度优先**: 更长的路径（段数更多）通常更具体，优先级更高。

**示例场景**:
假设有以下文件：
1. `src/pages/posts/new.ex`
2. `src/pages/posts/[id].ex`
3. `src/pages/posts/[...slug].ex`

请求 `/posts/new`:
*   匹配 1 (静态完全匹配) - **选中**

请求 `/posts/123`:
*   不匹配 1
*   匹配 2 (动态段匹配) - **选中**

请求 `/posts/2024/01/01`:
*   不匹配 1
*   不匹配 2 (段数不同)
*   匹配 3 (Catch-all 匹配) - **选中**

---

## 模块名映射规则

Nex 根据文件路径自动推断模块名。为了让框架能找到你的模块，你需要遵循命名约定：

### 映射逻辑
1.  **静态段**: 首字母大写 (PascalCase)。
    *   `users` -> `Users`
2.  **动态段 `[param]`**: 映射为 `Id` (如果是数字/ID格式) 或 参数名的 PascalCase。
    *   **注意**: 实际上框架在解析时，对于路径中的动态值（如 `123`），会尝试将其映射为模块名的 `Id` 部分。
    *   **推荐**: 动态路由文件的模块名建议统一使用对应的参数名或 `Id`。
    *   `src/pages/users/[id].ex` -> `MyApp.Pages.Users.Id`
3.  **Catch-all 段 `[...path]`**: 映射为参数名的 PascalCase。
    *   `src/pages/docs/[...path].ex` -> `MyApp.Pages.Docs.Path`

### 示例对照表

假设 App Module 为 `MyApp`:

| 文件路径 | 推荐模块定义 |
| :--- | :--- |
| `src/pages/index.ex` | `defmodule MyApp.Pages.Index` |
| `src/pages/users/[id].ex` | `defmodule MyApp.Pages.Users.Id` |
| `src/pages/docs/[...path].ex` | `defmodule MyApp.Pages.Docs.Path` |
| `src/pages/posts/[year]/[month].ex` | `defmodule MyApp.Pages.Posts.Year.Month` |

**重要提示**: 框架在分发请求时，会根据 URL 尝试查找模块。对于动态参数（如 `/users/123`），框架会将 `123` 识别为动态 ID，并尝试加载 `MyApp.Pages.Users.Id` 模块。因此，**动态路由文件的模块名最后一段通常应该是 `Id` (针对 `[id]`) 或对应的参数名**。
