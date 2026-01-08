defmodule NexAI do
  @moduledoc """
  NexAI - The Standalone AI SDK for Elixir, inspired by Vercel AI SDK.
  
  Provides a unified facade for text, audio, image and embedding operations.
  """

  alias NexAI.Core
  alias NexAI.Provider.OpenAI
  alias NexAI.Provider.Anthropic

  @doc "Minimalist macro for core functions."
  defmacro __using__(_opts) do
    quote do
      import NexAI, only: [stream_text: 1, generate_text: 1, generate_text: 2, to_data_stream: 1, to_datastar: 1, to_datastar: 2]
    end
  end

  # --- Factory Functions ---
  def openai(model_id, opts \\ []), do: OpenAI.chat(model_id, opts)
  def anthropic(model_id, opts \\ []), do: Anthropic.claude(model_id, opts)

  # --- Core Text API ---
  defdelegate generate_text(opts), to: Core
  defdelegate generate_text(messages, opts), to: Core
  defdelegate stream_text(opts), to: Core

  # --- Protocol Adapters ---
  # Delegated to specialized UI implementations for better separation of concerns.
  
  @doc "Converts a stream to Vercel AI Data Stream Protocol."
  defdelegate to_data_stream(result), to: NexAI.UI.Vercel

  @doc "Converts a stream to Datastar SSE signals."
  defdelegate to_datastar(result), to: NexAI.UI.Datastar
  defdelegate to_datastar(result, opts), to: NexAI.UI.Datastar

  # --- Specialized APIs ---
  defdelegate transcribe(opts), to: NexAI.Audio
  defdelegate generate_speech(opts), to: NexAI.Audio
  defdelegate embed(opts), to: NexAI.Embed
  defdelegate embed_many(opts), to: NexAI.Embed
  defdelegate cosine_similarity(v1, v2), to: NexAI.Embed
  defdelegate generate_image(opts), to: NexAI.Image

  # --- Utilities ---
  def tool(opts), do: NexAI.Tool.new(opts)
  def json_schema(s), do: NexAI.Schema.json_schema(s)
  def zod_schema(s), do: NexAI.Schema.json_schema(s)
  def generate_id, do: :crypto.strong_rand_bytes(5) |> Base.encode32(case: :lower, padding: false) |> binary_part(0, 7)

end
