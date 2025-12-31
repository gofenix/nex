defmodule AlpineShowcase.Layouts do
  use Nex.Page

  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <title>{@title}</title>
        <!-- 引入 DaisyUI & Tailwind -->
        <link href="https://cdn.jsdelivr.net/npm/daisyui@4.4.19/dist/full.min.css" rel="stylesheet" type="text/css" />
        <script src="https://cdn.tailwindcss.com"></script>
        
        <!-- 引入 HTMX -->
        <script src="https://unpkg.com/htmx.org@1.9.10"></script>
        
        <!-- 引入 Alpine.js (必须加 defer) -->
        <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.13.3/dist/cdn.min.js"></script>
      </head>
      <!-- 
         hx-boost="true": 开启类似 SPA 的导航体验
         x-data: 初始化主题，监听变化并写入 localStorage
      -->
      <body 
        hx-boost="true" 
        class="bg-base-200 min-h-screen p-8"
        x-data="{ 
          theme: localStorage.getItem('theme') || 'light' 
        }"
        x-init="$watch('theme', val => localStorage.setItem('theme', val))"
        x-bind:data-theme="theme"
      >
        <!-- 主题切换按钮 -->
        <div class="absolute top-4 right-4">
           <button class="btn btn-circle btn-ghost" x-on:click="theme = theme === 'light' ? 'dark' : 'light'">
             <span class="text-2xl" x-text="theme === 'light' ? '🌙' : '☀️'"></span>
           </button>
        </div>

        {raw(@inner_content)}

        <!-- 全局 Toast 容器 (Alpine 监听事件) -->
        <div 
          x-data="{ show: false, message: '' }"
          x-on:show-toast.window="show = true; message = $event.detail; setTimeout(() => show = false, 3000)"
          x-show="show"
          x-transition.opacity.duration.500ms
          class="toast toast-end z-50"
          style="display: none;"
        >
          <div class="alert alert-success">
            <span x-text="message"></span>
          </div>
        </div>
      </body>
    </html>
    """
  end
end
