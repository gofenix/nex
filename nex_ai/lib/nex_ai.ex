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
  def to_data_stream({:error, reason}) do
    body_fn = fn send ->
      send.(NexAI.Protocol.encode(:error, inspect(reason)))
    end
    wrap_response(body_fn, "text/event-stream", %{"x-vercel-ai-data-stream" => "v1"})
  end

  def to_data_stream(%{full_stream: stream}) do
    body_fn = fn send ->
      Enum.each(stream, fn event ->
        send.(NexAI.Protocol.encode(event.type, event.payload))
      end)
      send.("[DONE]")
    end
    wrap_response(body_fn, "text/event-stream", %{"x-vercel-ai-data-stream" => "v1"})
  end

  def to_datastar(result, opts \\ [])

  def to_datastar({:error, reason}, opts) do
    opts = Core.normalize_opts(opts)
    loading_signal = to_string(opts[:loading_signal] || "isLoading")
    
    body_fn = fn send ->
      json = Jason.encode!(%{loading_signal => false, "error" => inspect(reason)})
      send.(~s"""
      event: datastar-patch-signals
      data: signals #{json}

      """)
    end
    wrap_response(body_fn, "text/event-stream; charset=utf-8", %{"cache-control" => "no-cache"})
  end

  def to_datastar(%{full_stream: stream, opts: original_opts}, opts) do
    opts = Core.normalize_opts(opts)
    text_signal = to_string(opts[:signal] || "aiResponse")
    reasoning_signal = to_string(opts[:reasoning_signal] || "aiReasoning")
    status_signal = to_string(opts[:status_signal] || "aiStatus")
    loading_signal = to_string(opts[:loading_signal] || "isLoading")
    messages_signal = to_string(opts[:messages_signal] || "messages")
    
    body_fn = fn send ->
      # Helper to send Datastar signal patch
      send_signals = fn signals_map ->
        json = Jason.encode!(signals_map)
        send.(%{event: "datastar-patch-signals", data: "signals #{json}"})
      end

      # 0. Initial Fragments (Elements)
      if fragments = opts[:fragments] do
        Enum.each(fragments, fn f ->
          # Support raw HTML, {selector, html}, and {selector, html, mode}
          case f do
            {selector, html, mode} ->
              send.(%{event: "datastar-patch-elements", data: "selector #{selector}\nmode #{mode}\nelements #{html}"})
            {selector, html} -> 
              send.(%{event: "datastar-patch-elements", data: "selector #{selector}\nelements #{html}"})
            html when is_binary(html) ->
              send.(%{event: "datastar-patch-elements", data: "elements #{html}"})
          end
        end)
      end

      # 1. Initial State: Set loading and clear current response
      initial_signals = opts[:initial_signals] || %{}
      
      base_signals = %{
        loading_signal => true, 
        status_signal => "Thinking...", 
        text_signal => "", 
        reasoning_signal => ""
      }
      
      send_signals.(Map.merge(base_signals, initial_signals))

      # 2. Stream Loop
      final_acc = Enum.reduce(stream, %{text: "", reasoning: ""}, fn event, acc ->
        IO.inspect(event, label: "DATASTAR STREAM EVENT")
        case event.type do
          :text ->
            new_text = acc.text <> event.payload
            send_signals.(%{text_signal => new_text})
            %{acc | text: new_text}
            
          :reasoning ->
            new_reasoning = acc.reasoning <> event.payload
            send_signals.(%{reasoning_signal => new_reasoning})
            %{acc | reasoning: new_reasoning}

          :tool_call_start ->
            status = "Calling #{event.payload.toolName}..."
            send_signals.(%{status_signal => status})
            acc

          :tool_result ->
            status = "Tool #{event.payload.toolName} executed"
            send_signals.(%{status_signal => status})
            acc

          _ -> acc
        end
      end)

      # 3. Final State: Clear signals and add to messages list
      if original_messages = original_opts[:messages] do
        assistant_msg = %{role: "assistant", content: final_acc.text}
        new_messages = original_messages ++ [assistant_msg]
        
        # Check if caller provided a function to generate final fragments based on result
        if final_fragments_fn = opts[:final_fragments_fn] do
          final_fragments = final_fragments_fn.(final_acc.text)
          Enum.each(final_fragments, fn f ->
            case f do
              {selector, html, mode} ->
                send.(%{event: "datastar-patch-elements", data: "selector #{selector}\nmode #{mode}\nelements #{html}"})
              {selector, html} -> 
                send.(%{event: "datastar-patch-elements", data: "selector #{selector}\nelements #{html}"})
              html when is_binary(html) ->
                send.(%{event: "datastar-patch-elements", data: "elements #{html}"})
            end
          end)
        end

        send_signals.(%{
          loading_signal => false, 
          status_signal => "Ready", 
          text_signal => "", 
          reasoning_signal => "", 
          messages_signal => new_messages
        })
      else
        send_signals.(%{
          loading_signal => false, 
          status_signal => "Ready", 
          text_signal => "", 
          reasoning_signal => ""
        })
      end
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
