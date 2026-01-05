defmodule NexAI.LanguageModel do
  @moduledoc """
  The LanguageModel protocol defines the interface for all AI providers.
  Inspired by Vercel AI SDK LanguageModelV3.
  """

  @type message :: %{role: String.t(), content: any()}
  
  @type params :: %{
    prompt: [message()],
    mode: :text | :object | :tool_use,
    tools: [map()] | nil,
    tool_choice: any(),
    response_format: map() | nil,
    config: map()
  }

  defprotocol Protocol do
    @doc "Generates a complete response."
    def do_generate(model, params)

    @doc "Generates a streaming response."
    def do_stream(model, params)
  end
end
