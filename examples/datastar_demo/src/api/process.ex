defmodule DatastarDemo.Api.Process do
  use Nex

  def post(req) do
    text = req.body["text"] || ""
    escaped = text |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    upper = text |> String.upcase() |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    reversed = text |> String.reverse() |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()

    Nex.html("""
    <div id="result" data-testid="datastar-result" class="p-4 bg-base-200 rounded-lg">
      <div class="font-mono text-sm space-y-1">
        <div><span class="text-base-content/50">Original:</span> #{escaped}</div>
        <div><span class="text-base-content/50">Uppercase:</span> <span class="font-bold text-primary">#{upper}</span></div>
        <div><span class="text-base-content/50">Length:</span> #{String.length(text)} characters</div>
        <div><span class="text-base-content/50">Reversed:</span> #{reversed}</div>
      </div>
    </div>
    """)
  end
end
