defmodule DatastarDemo.Api.Process do
  use Nex

  def post(req) do
    text = req.body["text"] || ""

    Nex.html("""
    <div id="result" data-testid="datastar-result" class="p-4 bg-base-200 rounded-lg">
      <div class="font-mono text-sm space-y-1">
        <div><span class="text-base-content/50">Original:</span> #{html_escape(text)}</div>
        <div><span class="text-base-content/50">Uppercase:</span> <span class="font-bold text-primary">#{html_escape(String.upcase(text))}</span></div>
        <div><span class="text-base-content/50">Length:</span> #{String.length(text)} characters</div>
        <div><span class="text-base-content/50">Reversed:</span> #{html_escape(String.reverse(text))}</div>
      </div>
    </div>
    """)
  end

  defp html_escape(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
  end
end
