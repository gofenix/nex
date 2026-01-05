defmodule NexAIDemo.Api.NexAI.Chat do
  use Nex
  # nex_ai is a standalone dependency
  
  def post(req) do
    messages = req.body["messages"] || []
    input = req.body["input"] || ""
    
    # Use the standalone NexAI library
    NexAI.stream_text(
      messages: messages ++ [%{role: "user", content: input}],
      model: NexAI.openai("gpt-4o")
    )
    |> NexAI.to_datastar()
  end
end
