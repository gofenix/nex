defmodule ChatbotSse.Layouts do
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
        <script>
          tailwind.config = {
            theme: {
              extend: {
                colors: {
                  primary: {"50":"#eff6ff","100":"#dbeafe","200":"#bfdbfe","300":"#93c5fd","400":"#60a5fa","500":"#3b82f6","600":"#2563eb","700":"#1d4ed8","800":"#1e40af","900":"#1e3a8a","950":"#172554"}
                }
              }
            }
          }
        </script>
        <style type="text/css">
          @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');
          body { font-family: 'Inter', sans-serif; }
          .glass-effect { background: rgba(31, 41, 55, 0.7); backdrop-filter: blur(10px); }
          .scrollbar-hide::-webkit-scrollbar { display: none; }
          .chat-bubble { max-width: 85%; }
        </style>
        <script src="https://unpkg.com/htmx.org@2.0.4"></script>
        <script src="https://unpkg.com/htmx-ext-sse@2.2.1/sse.js"></script>
        <script src="https://unpkg.com/alpinejs" defer></script>
        <script type="module" src="https://cdn.jsdelivr.net/gh/starfederation/datastar@v1.0.0-RC.7/bundles/datastar.js"></script>
      </head>
      <body class="bg-[#0b0f19] text-gray-100 min-h-screen">
        <div class="max-w-screen-xl mx-auto h-screen flex flex-col">
          {raw(@inner_content)}
        </div>
      </body>
    </html>
    """
  end
end
