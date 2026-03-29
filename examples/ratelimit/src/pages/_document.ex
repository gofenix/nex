defmodule RatelimitExample.Pages.Document do
  use Nex

  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8" />
      <title>{@title}</title>
      <script src="https://cdn.tailwindcss.com"></script>
    </head>
    <body class="bg-gray-100 p-8">
      {raw(@inner_content)}
    </body>
    </html>
    """
  end
end
