# Nex 样式与 UI 指南

Nex 采用 **CDN-first** 的策略来处理样式。默认情况下，框架推荐并预配置了 Tailwind CSS 和 DaisyUI。

## 目录

- [快速开始](#快速开始)
- [核心理念](#核心理念)
- [配置说明](#配置说明)
- [离线/生产环境构建](#离线生产环境构建)

---

## 快速开始

新创建的 Nex 项目已经包含所有必要配置。打开 `src/layouts.ex`，你会看到：

```elixir
<script src="https://cdn.tailwindcss.com?plugins=forms,typography,aspect-ratio"></script>
<link href="https://cdn.jsdelivr.net/npm/daisyui@4.12.23/dist/full.min.css" rel="stylesheet" type="text/css" />
```

这意味着你可以立即在 HEEx 模板中使用任何 Tailwind 类名或 DaisyUI 组件：

```elixir
<button class="btn btn-primary">
  Click me
</button>

<div class="card bg-base-100 shadow-xl">
  <div class="card-body">
    <h2 class="card-title">Card Title</h2>
    <p>Using DaisyUI components without installation!</p>
  </div>
</div>
```

---

## 核心理念

Nex 旨在简化开发流程，移除了复杂的构建工具链（如 Webpack, Esbuild, npm 等）。

1.  **无 `node_modules`**：不需要 `npm install`。
2.  **无构建步骤**：CSS 和 JS 通过 CDN 即时加载。
3.  **即时预览**：Tailwind 的 CDN 脚本会在浏览器端实时编译 CSS。

这种方式非常适合快速原型开发、内部工具和中小型应用。

---

## 配置说明

### 修改 Tailwind 配置

如果你需要自定义 Tailwind 配置（例如扩展颜色、字体），可以在 HTML `<head>` 中添加 `tailwind.config` 对象：

```html
<script src="https://cdn.tailwindcss.com"></script>
<script>
  tailwind.config = {
    theme: {
      extend: {
        colors: {
          clifford: '#da373d',
        }
      }
    }
  }
</script>
```

### 切换 DaisyUI 主题

在 `<html>` 标签上设置 `data-theme` 属性即可切换主题：

```html
<html lang="en" data-theme="dark">
```

或者动态切换：

```elixir
# src/layouts.ex
def render(assigns) do
  ~H"""
  <html lang="en" data-theme={@theme || "light"}>
  ...
  """
end
```

---

## 离线/生产环境构建

虽然 CDN 方式对开发非常方便，但在某些生产环境中（如内网环境），你可能需要本地 CSS 文件。

1.  **下载 CSS 文件**：直接下载 DaisyUI 和 Tailwind 的 CSS 文件，放入 `priv/static`（需自行配置静态文件服务）。
2.  **使用 Tailwind CLI**：如果你需要性能优化，可以单独安装 Tailwind CLI 工具来生成精简的 CSS 文件，但这超出了 Nex 框架的核心范畴。

对于大多数 Nex 的目标场景，CDN 方式已经足够高效且稳定。
