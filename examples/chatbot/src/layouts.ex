defmodule Chatbot.Layouts do
  use Nex

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
      <body class="bg-gray-900 min-h-screen" hx-boost="true">
        <div class="container mx-auto px-4 py-8 max-w-3xl h-screen flex flex-col">
          {raw(@inner_content)}
        </div>
      </body>
    </html>
    """
  end
end
