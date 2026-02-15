defmodule AiSaga.Layouts do
  use Nex

  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="zh-CN" data-theme="light">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>{@title}</title>
        <script src="https://cdn.tailwindcss.com?plugins=forms,typography,aspect-ratio"></script>
        <link href="https://cdn.jsdelivr.net/npm/daisyui@4.12.23/dist/full.min.css" rel="stylesheet" type="text/css" />
        <script src="https://unpkg.com/htmx.org@2.0.4"></script>
        <script src="https://unpkg.com/htmx-ext-sse@2.2.2/sse.js"></script>
        <link rel="preconnect" href="https://fonts.googleapis.com">
        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;900&family=Space+Mono:wght@400;700&display=swap" rel="stylesheet">
        <style>
          :root {
            --md-bg: rgb(244, 239, 234);
            --md-yellow: rgb(255, 222, 0);
            --md-dark: rgb(56, 56, 56);
            --md-black: rgb(0, 0, 0);
            --md-blue: rgb(111, 194, 255);
          }
          body {
            background-color: var(--md-bg);
            font-family: 'Inter', sans-serif;
            color: var(--md-dark);
          }
          .md-shadow { box-shadow: var(--md-dark) -8px 8px 0px 0px; }
          .md-shadow-sm { box-shadow: var(--md-dark) -4px 4px 0px 0px; }
          .md-shadow-yellow { box-shadow: var(--md-yellow) -6px 6px 0px 0px; }
          .md-border { border: 2px solid var(--md-black); }
          .md-border-sm { border: 1px solid var(--md-black); }
          .font-mono { font-family: 'Space Mono', monospace; }
        </style>
      </head>
      <body class="min-h-screen">
        <nav class="sticky top-0 z-50 bg-[rgb(244,239,234)] border-b-2 border-black">
          <div class="max-w-4xl mx-auto w-full px-6 py-4 flex items-center justify-between">
            <a href="/" class="text-2xl font-black tracking-tight hover:underline">🤖 AiSaga</a>
            <div class="flex gap-6 text-sm font-medium">
              <a href="/" class="hover:underline">首页</a>
              <a href="/paper" class="hover:underline">论文</a>
              <a href="/paradigm" class="hover:underline">范式</a>
              <a href="/timeline" class="hover:underline">时间线</a>
              <a href="/author" class="hover:underline">人物</a>
              <a href="/search" class="hover:underline">搜索</a>
            </div>
          </div>
        </nav>
        <main class="max-w-4xl mx-auto px-6 py-8">
          {raw(@inner_content)}
        </main>
        <footer class="border-t-2 border-black mt-16 py-8 text-center text-sm">
          <p class="font-mono opacity-60">理解 AI 的起点</p>
        </footer>
      </body>
    </html>
    """
  end
end
