
alias NexAI.Core

defmodule TestModel do
  defstruct []
  defimpl NexAI.LanguageModel.Protocol do
    def do_generate(_, _), do: {:ok, %{text: "Hello", tool_calls: [], usage: %{}, finish_reason: "stop"}}
    def do_stream(_, _) do
      Stream.from_enumerable([
        %{"choices" => [%{"delta" => %{"content" => "Hello"}}]},
        %{"choices" => [%{"delta" => %{"content" => " world"}}]}
      ])
    end
  end
end

res = NexAI.stream_text(
  model: %TestModel{},
  messages: [%{role: "user", content: "hi"}]
)

# Mock the send function
send_fn = fn data ->
  IO.inspect(data, label: "SENT SSE")
end

response = NexAI.to_datastar(res)
# response.body is the body_fn
response.body.(send_fn)
