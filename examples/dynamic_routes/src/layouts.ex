defmodule DynamicRoutes.Layouts do
  use Nex.Page

  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="zh-CN">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>{@title}</title>
        <script src="https://cdn.tailwindcss.com?plugins=forms,typography,aspect-ratio"></script>
        <script src="https://unpkg.com/htmx.org@2.0.4"></script>
      </head>
      <body class="bg-gray-100 min-h-screen">
        <nav class="bg-white shadow-sm border-b">
          <div class="max-w-4xl mx-auto px-4 py-3">
            <div class="flex space-x-6">
              <a href="/" class="text-blue-600 hover:text-blue-800">首页</a>
              <a href="/users" class="text-blue-600 hover:text-blue-800">用户列表</a>
              <a href="/posts" class="text-blue-600 hover:text-blue-800">文章列表</a>
            </div>
          </div>
        </nav>
        <div class="max-w-4xl mx-auto px-4 py-8">
          {raw(@inner_content)}
        </div>
      </body>
    </html>
    """
  end
end
