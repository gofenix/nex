defmodule NexAI.Model do
  @moduledoc """
  Behavior for AI Model Providers.
  """

  @type message :: %{role: String.t(), content: any()}
  @type tool :: map()
  
  @callback stream_text(messages :: [message()], opts :: keyword()) :: Enumerable.t()
  @callback generate_text(messages :: [message()], opts :: keyword()) :: {:ok, map()} | {:error, any()}
  @callback generate_image(prompt :: String.t(), opts :: keyword()) :: {:ok, map()} | {:error, any()}
  @callback generate_speech(text :: String.t(), opts :: keyword()) :: {:ok, map()} | {:error, any()}
  @callback transcribe(file_content :: binary(), opts :: keyword()) :: {:ok, map()} | {:error, any()}
  @callback rerank(query :: String.t(), documents :: [String.t() | map()], opts :: keyword()) :: {:ok, map()} | {:error, any()}
  @callback embed_many(values :: [String.t()], opts :: keyword()) :: {:ok, [[float()]]} | {:error, any()}
end
