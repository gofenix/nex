# Nex Styling and UI Guide

Nex adopts a **CDN-first** strategy for handling styles. By default, the framework recommends and pre-configures Tailwind CSS and DaisyUI.

## Table of Contents

- [Quick Start](#quick-start)
- [Core Philosophy](#core-philosophy)
- [Configuration](#configuration)
- [Offline/Production Build](#offlineproduction-build)

---

## Quick Start

A newly created Nex project already contains all necessary configurations. Open `src/layouts.ex` and you will see:

```elixir
<script src="https://cdn.tailwindcss.com?plugins=forms,typography,aspect-ratio"></script>
<link href="https://cdn.jsdelivr.net/npm/daisyui@4.12.23/dist/full.min.css" rel="stylesheet" type="text/css" />
```

This means you can immediately use any Tailwind class names or DaisyUI components in your HEEx templates:

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

## Core Philosophy

Nex aims to simplify the development process by removing complex build toolchains (like Webpack, Esbuild, npm, etc.).

1.  **No `node_modules`**: No `npm install` needed.
2.  **No Build Step**: CSS and JS are loaded instantly via CDN.
3.  **Instant Preview**: Tailwind's CDN script compiles CSS in real-time in the browser.

This approach is perfect for rapid prototyping, internal tools, and small to medium-sized applications.

---

## Configuration

### Modifying Tailwind Config

If you need to customize Tailwind configuration (e.g., extending colors, fonts), you can add a `tailwind.config` object in the HTML `<head>`:

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

### Switching DaisyUI Themes

Set the `data-theme` attribute on the `<html>` tag to switch themes:

```html
<html lang="en" data-theme="dark">
```

Or switch dynamically:

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

## Offline/Production Build

While the CDN approach is very convenient for development, in some production environments (like intranets), you might need local CSS files.

1.  **Download CSS Files**: Directly download DaisyUI and Tailwind CSS files and place them in `priv/static` (you need to configure static file serving yourself).
2.  **Use Tailwind CLI**: If you need performance optimization, you can install the Tailwind CLI tool separately to generate minified CSS files, but this is outside the core scope of the Nex framework.

For most Nex target scenarios, the CDN approach is efficient and stable enough.
