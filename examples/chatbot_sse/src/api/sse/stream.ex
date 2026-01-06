defmodule ChatbotSse.Api.Sse.Stream do
  use Nex
  use NexAI

  @moduledoc """
  SSE (Server-Sent Events) endpoint for streaming AI responses from OpenAI.
  Supports full conversation history via POST.
  """
  require Logger

  def post(req) do
    # Get messages from body
    messages = req.body["messages"] || []
    
    # If messages is empty, try to get from query (fallback)
    messages = if Enum.empty?(messages) do
      case req.query["message"] do
        nil -> [%{"role" => "user", "content" => "Hello"}]
        msg -> [%{"role" => "user", "content" => msg}]
      end
    else
      messages
    end

    # Define some fun tools for demonstration
    tools = [
      NexAI.tool(%{
        name: "getWeather",
        description: "Get the current weather in a location",
        parameters: NexAI.zod_schema(%{
          type: "object",
          properties: %{
            location: %{type: "string", description: "The city and state, e.g. San Francisco, CA"}
          },
          required: ["location"]
        }),
        execute: fn %{"location" => loc} ->
          # Simulate API call
          %{location: loc, temperature: 22, unit: "celsius", condition: "Sunny"}
        end
      }),
      NexAI.tool(%{
        name: "getStockPrice",
        description: "Get the current stock price of a company",
        parameters: NexAI.zod_schema(%{
          type: "object",
          properties: %{
            symbol: %{type: "string", description: "The stock symbol, e.g. AAPL"}
          },
          required: ["symbol"]
        }),
        execute: fn %{"symbol" => symbol} ->
          %{symbol: symbol, price: 150.0 + :rand.uniform(50), currency: "USD"}
        end
      })
    ]

    # Clean SDK Style with model and tools
    stream_text(
      model: NexAI.openai("gpt-4o"),
      messages: messages,
      tools: tools,
      max_steps: 5
    )
    |> to_data_stream()
  end
end
