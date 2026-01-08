defmodule NexAI.UI.Datastar do
  @moduledoc """
  UI Helper for converting NexAI streams to Datastar SSE responses.
  """
  
  alias NexAI.Core

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
        # IO.inspect(event, label: "DATASTAR STREAM EVENT")
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
