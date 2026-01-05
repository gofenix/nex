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

  @doc """
  The LanguageModel protocol defines the interface for all AI providers.
  
  ### Implementation Guide
  To add a new provider (e.g., Mistral):
  1. Define a struct for your provider.
  2. Implement this protocol for your struct.
  3. Map your provider's API response to OpenAI-compatible delta maps for `do_stream`.
  
  Example:
  ```elixir
  defimpl NexAI.LanguageModel.Protocol, for: MyProvider do
    def do_generate(model, params), do: ...
    def do_stream(model, params), do: ...
  end
  ```
  """
  defprotocol Protocol do
    @doc "Generates a complete response."
    def do_generate(model, params)

    @doc "Generates a streaming response (Lazy Enumerable)."
    def do_stream(model, params)
  end
end
