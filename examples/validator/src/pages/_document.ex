defmodule NexValidatorExample.Pages.Document do
  use Nex

  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <title>{@title}</title>
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <script src="https://unpkg.com/htmx.org@2.0.4"></script>
        <script src="https://cdn.tailwindcss.com"></script>
      </head>
      <body class="bg-slate-50 text-slate-900">
        <main class="mx-auto max-w-2xl px-6 py-12">
          {raw(@inner_content)}
        </main>
      </body>
    </html>
    """
  end
end
