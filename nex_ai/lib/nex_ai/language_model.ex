defmodule NexAI.LanguageModel do
  @moduledoc """
  The LanguageModel definitions for NexAI.
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
end

defprotocol NexAI.LanguageModel.Protocol do
  @moduledoc """
  The LanguageModel protocol defines the interface for all AI providers.
  
  ### Implementation Guide
  To add a new provider (e.g., Mistral):
  1. Define a struct for your provider.
  2. Implement this protocol for your struct.
  3. Map your provider's API response to OpenAI-compatible delta maps for `do_stream`.
  """

  @doc "Generates a complete response."
  def do_generate(model, params)

  @doc "Generates a streaming response (Lazy Enumerable)."
  def do_stream(model, params)
end
