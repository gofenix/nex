# Nex Routing and File Structure Guide

Nex uses a **file-system routing** mechanism where your file structure directly determines your application's URL structure.

## Table of Contents

- [Basic Rules](#basic-rules)
- [Dynamic Routing](#dynamic-routing)
- [Nested Routing](#nested-routing)
- [API Routing](#api-routing)
- [Route Priority](#route-priority)
- [Module Name Mapping Rules](#module-name-mapping-rules)

---

## Basic Rules

All page route files are located in the `src/pages/` directory.

| File Path | URL Path | Module Name (Example) |
| :--- | :--- | :--- |
| `src/pages/index.ex` | `/` | `MyApp.Pages.Index` |
| `src/pages/about.ex` | `/about` | `MyApp.Pages.About` |
| `src/pages/contact.ex` | `/contact` | `MyApp.Pages.Contact` |

---

## Dynamic Routing

Nex supports three types of route segments:

### 1. Static Segments
Ordinary filenames or directory names.
*   `src/pages/users/list.ex` -> `/users/list`

### 2. Dynamic Segments `[param]`
Matches a single URL path segment. The parameter name is defined inside brackets.
*   **File**: `src/pages/users/[id].ex`
*   **Matches**: `/users/123`, `/users/alice`
*   **Accessing Params**: Retrieved via `"id"` in the `params` of `mount/1` or Action functions.

```elixir
# src/pages/users/[id].ex
defmodule MyApp.Pages.Users.Id do
  use Nex.Page

  def mount(params) do
    # params = %{"id" => "123"}
    %{user_id: params["id"]}
  end
end
```

### 3. Catch-all Segments `[...param]`
Matches all remaining path segments. Must be placed at the end of the path.
*   **File**: `src/pages/docs/[...path].ex`
*   **Matches**: `/docs/guide`, `/docs/api/v1`, `/docs/a/b/c`
*   **Accessing Params**: `params["path"]` will be a **list** of path segments.

```elixir
# src/pages/docs/[...path].ex
defmodule MyApp.Pages.Docs.Path do
  use Nex.Page

  def mount(params) do
    # Visiting /docs/api/v1
    # params = %{"path" => ["api", "v1"]}
    %{path_segments: params["path"]}
  end
end
```

---

## Nested Routing

You can mix directories and files to create deeply nested routes.

| File Path | URL Match | Description |
| :--- | :--- | :--- |
| `src/pages/posts/[year]/[month].ex` | `/posts/2024/01` | Multi-level dynamic parameters |
| `src/pages/files/[category]/[...path].ex` | `/files/images/2024/logo.png` | Mixed dynamic and catch-all |
| `src/pages/users/[id]/profile.ex` | `/users/123/profile` | Static sub-path under dynamic path |

---

## API Routing

API routes follow the same rules, but files are located in the `src/api/` directory, and URLs start with the `/api/` prefix.

| File Path | URL Path |
| :--- | :--- |
| `src/api/users.ex` | `/api/users` |
| `src/api/posts/[id].ex` | `/api/posts/123` |

API modules use `Nex.Api` or `Nex.SSE` instead of `Nex.Page`.

---

## Route Priority

When multiple route patterns match the same URL, Nex decides which file to use based on the following priority (highest to lowest):

1.  **Static Segments First**: `users/profile.ex` takes precedence over `users/[id].ex`.
2.  **Dynamic Segments Next**: `posts/[id].ex` takes precedence over `posts/[...slug].ex`.
3.  **Catch-all Last**: `[...path].ex` is selected only when there are no other matches.
4.  **Depth First**: Longer paths (more segments) are generally more specific and have higher priority.

**Example Scenario**:
Assume the following files exist:
1. `src/pages/posts/new.ex`
2. `src/pages/posts/[id].ex`
3. `src/pages/posts/[...slug].ex`

Request `/posts/new`:
*   Matches 1 (Static exact match) - **Selected**

Request `/posts/123`:
*   Does not match 1
*   Matches 2 (Dynamic segment match) - **Selected**

Request `/posts/2024/01/01`:
*   Does not match 1
*   Does not match 2 (Different segment count)
*   Matches 3 (Catch-all match) - **Selected**

---

## Module Name Mapping Rules

Nex automatically infers the module name based on the file path. To ensure the framework can find your module, you need to follow naming conventions:

### Mapping Logic
1.  **Static Segments**: Capitalize first letter (PascalCase).
    *   `users` -> `Users`
2.  **Dynamic Segments `[param]`**: Mapped to `Id` (if it's a numeric/ID format) or the PascalCase of the parameter name.
    *   **Note**: In practice, when the framework resolves dynamic values in the path (like `123`), it attempts to map them to the `Id` part of the module name.
    *   **Recommendation**: Module names for dynamic route files should generally use `Id` or the corresponding parameter name.
    *   `src/pages/users/[id].ex` -> `MyApp.Pages.Users.Id`
3.  **Catch-all Segments `[...path]`**: Mapped to the PascalCase of the parameter name.
    *   `src/pages/docs/[...path].ex` -> `MyApp.Pages.Docs.Path`

### Example Lookup Table

Assuming App Module is `MyApp`:

| File Path | Recommended Module Definition |
| :--- | :--- |
| `src/pages/index.ex` | `defmodule MyApp.Pages.Index` |
| `src/pages/users/[id].ex` | `defmodule MyApp.Pages.Users.Id` |
| `src/pages/docs/[...path].ex` | `defmodule MyApp.Pages.Docs.Path` |
| `src/pages/posts/[year]/[month].ex` | `defmodule MyApp.Pages.Posts.Year.Month` |

**Important Note**: When dispatching requests, the framework attempts to look up the module based on the URL. For dynamic parameters (like `/users/123`), the framework recognizes `123` as a dynamic ID and attempts to load the `MyApp.Pages.Users.Id` module. Therefore, **the last segment of a dynamic route file's module name should typically be `Id` (for `[id]`) or the corresponding parameter name**.
