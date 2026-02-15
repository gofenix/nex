defmodule AiSaga.Api.GeneratePaper do
  use Nex

  def post(_req) do
    token = System.unique_integer([:positive])

    Nex.html("""
    <div
      id="generate-result"
      hx-ext="sse"
      sse-connect="/api/generate_paper/stream?token=#{token}"
      sse-swap="message"
      sse-close="close"
      hx-swap="beforeend"
      class="mt-4 space-y-1"
    >
      <div class="text-sm opacity-60">⏳ 已启动生成任务，正在建立实时连接...</div>
    </div>
    """)
  end
end
