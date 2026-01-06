defmodule ChatbotSse.Api.Chat.Completions do
  use Nex

  def post(req) do
    # Simulate OpenAI Response
    stream = req.body["stream"] || false
    
    if stream do
      Nex.stream(fn send ->
        # Send thinking/reasoning if requested (deepseek style or tag style)
        send_chunk(send, %{"choices" => [%{"delta" => %{"reasoning_content" => "Let me think... "}}]})
        Process.sleep(100)
        send_chunk(send, %{"choices" => [%{"delta" => %{"reasoning_content" => "I will check the weather."}}]})
        Process.sleep(100)
        
        # Send content
        send_chunk(send, %{"choices" => [%{"delta" => %{"content" => "The weather "}}]})
        Process.sleep(50)
        send_chunk(send, %{"choices" => [%{"delta" => %{"content" => "is sunny today."}}]})
        
        # Send usage
        send_chunk(send, %{"usage" => %{"prompt_tokens" => 10, "completion_tokens" => 20, "total_tokens" => 30}})
        
        send.("data: [DONE]\n\n")
      end)
    else
      Nex.json(%{
        "id" => "mock-123",
        "model" => "gpt-4o",
        "created" => 123456789,
        "choices" => [
          %{
            "message" => %{"role" => "assistant", "content" => "This is a mock response."},
            "finish_reason" => "stop"
          }
        ],
        "usage" => %{"prompt_tokens" => 10, "completion_tokens" => 20, "total_tokens" => 30}
      })
    end
  end

  defp send_chunk(send, data) do
    send.("data: #{Jason.encode!(data)}\n\n")
  end
end
