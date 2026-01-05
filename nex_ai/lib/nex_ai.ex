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
      import NexAI, only: [stream_text: 1, generate_text: 1, generate_text: 2]
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
  def to_data_stream(%{full_stream: stream}) do
    body_fn = fn send ->
      Enum.each(stream, fn event ->
        send.(NexAI.Protocol.encode(event.type, event.payload))
      end)
      send.("[DONE]")
    end
    wrap_response(body_fn, "text/event-stream", %{"x-vercel-ai-data-stream" => "v1"})
  end

  def to_datastar(%{full_stream: stream}, opts \\ []) do
    opts = Core.normalize_opts(opts)
    signal_name = to_string(opts[:signal] || "aiResponse")
    
    body_fn = fn send ->
      Enum.reduce(stream, "", fn event, acc ->
        if event.type == :text do
          new_acc = acc <> event.payload
          send.(%{event: "datastar-patch-signals", data: "signals {#{Jason.encode!(signal_name)}: #{Jason.encode!(new_acc)}}"})
          new_acc
        else
          acc
        end
      end)
      :ok
    end
    wrap_response(body_fn, "text/event-stream; charset=utf-8", %{"cache-control" => "no-cache"})
  end

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

  defp wrap_response(body_fn, content_type, extra_headers) do
    case if(Code.ensure_compiled(Nex.Response) == {:module, Nex.Response}, do: Nex.Response, else: nil) do
      nil -> body_fn
      mod ->
        Kernel.struct(mod, [
          status: 200,
          content_type: content_type,
          headers: Map.merge(%{"cache-control" => "no-cache, no-transform", "connection" => "keep-alive"}, extra_headers),
          body: body_fn
        ])
    end
  end
end
