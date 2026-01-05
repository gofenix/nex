defmodule ChatbotSse.Api.Datastar.Chat do
  use Nex
  use NexAI

  def post(req) do
    messages = req.body["messages"] || []
    input = req.body["input"] || ""
    
    # Decoupled SDK Flow:
    # 1. Logic (Pure SDK Options)
    # 2. explicit conversion to agnostic stream
    stream_text(
      messages: messages ++ [%{role: "user", content: input}],
      max_steps: 5,
      on_finish: fn %{text: content} ->
        # Persist history
        new_msgs = messages ++ [%{role: "user", content: input}, %{role: "assistant", content: content}]
        Nex.Store.put(:datastar_chat_history, new_msgs)
      end
    )
    |> to_datastar() # Auto-detects 'messages' signal from opts
  end
end
