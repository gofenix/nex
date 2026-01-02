defmodule AlpineShowcase.Layouts do
  use Nex

  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <title>{@title}</title>
        <!-- Import DaisyUI & Tailwind -->
        <link href="https://cdn.jsdelivr.net/npm/daisyui@4.4.19/dist/full.min.css" rel="stylesheet" type="text/css" />
        <script src="https://cdn.tailwindcss.com"></script>

        <!-- Import HTMX -->
        <script src="https://unpkg.com/htmx.org@1.9.10"></script>

        <!-- Import Alpine.js (defer is required) -->
        <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.13.3/dist/cdn.min.js"></script>
      </head>
      <!--
         hx-boost="true": Enables SPA-like navigation
         x-data: Initialize theme, watch for changes and persist to localStorage
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
        <!-- Theme toggle button -->
        <div class="absolute top-4 right-4">
           <button class="btn btn-circle btn-ghost" x-on:click="theme = theme === 'light' ? 'dark' : 'light'">
             <span class="text-2xl" x-text="theme === 'light' ? '🌙' : '☀️'"></span>
           </button>
        </div>

        {raw(@inner_content)}

        <!-- Global Toast Container (Listens for Alpine events) -->
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
