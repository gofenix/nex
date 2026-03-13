defmodule NexWsExample.Layouts do
  use Nex

  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8" />
      <title>WebSocket Chat</title>
      <script src="https://cdn.tailwindcss.com"></script>
      <style>
        #messages { height: 300px; overflow-y: auto; }
      </style>
    </head>
    <body class="bg-gray-100 p-8">
      {raw(@inner_content)}
    </body>
    </html>
    """
  end
end
