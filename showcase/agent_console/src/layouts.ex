defmodule AgentConsole.Layouts do
  use Nex

  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="zh-CN">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>Agent Console</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <script src="https://unpkg.com/htmx.org@2"></script>
        <script src="https://unpkg.com/htmx.org@1.9.10/dist/ext/ws.js"></script>
        <style>
          .typing-cursor::after {
            content: '▋';
            animation: blink 1s infinite;
          }
          @keyframes blink {
            0%, 50% { opacity: 1; }
            51%, 100% { opacity: 0; }
          }
          .message-ai {
            background: #f7f7f8;
          }
          .message-user {
            background: #ffffff;
          }
          .tool-call {
            border-left: 3px solid #10b981;
          }
          .tool-result {
            border-left: 3px solid #f59e0b;
          }
        </style>
      </head>
      <body class="bg-gray-100 h-screen overflow-hidden">
        {raw(@inner_content)}
      </body>
    </html>
    """
  end
end
