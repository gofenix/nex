defmodule NexValidatorExample.Layouts do
  @moduledoc """Simple HTML layout helpers for the Nex Validator example"""

  def render(page_html) when is_binary(page_html) do
    ~S"""
    <!doctype html>
    <html lang="en">
    <head>
      <meta charset="utf-8"/>
      <title>Nex Validator Example</title>
      <meta name="viewport" content="width=device-width, initial-scale=1"/>
      <script src="https://unpkg.com/htmx.org@1.9.2"></script>
      <style>
        body { font-family: system-ui, -apple-system, Segoe UI, Roboto; padding: 2rem; }
        .field { margin: 1rem 0; }
        label { display: block; font-weight: 600; margin-bottom: .25rem; }
        input { padding: .5rem; width: 360px; max-width: 100%; }
        .error { color: #d00; font-size: .9em; margin-top: .25rem; }
        .form { display: grid; grid-template-columns: 1fr; gap: .75rem; }
        .form-actions { margin-top: 1rem; }
      </style>
    </head>
    <body>
      #{page_html}
    </body>
    </html>
    """
  end
end
