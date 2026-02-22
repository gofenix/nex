defmodule Upload.Layouts do
  use Nex

  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="UTF-8" />
        <title>File Upload Demo</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <script src="https://unpkg.com/htmx.org@2"></script>
      </head>
      <body hx-boost="true" class="bg-gray-100 min-h-screen">
        <div class="max-w-md mx-auto py-12 px-4">
          {raw(@inner_content)}
        </div>
      </body>
    </html>
    """
  end
end
