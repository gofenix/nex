defmodule ChatbotSse.Api.Datastar.Chat do
  use Nex
  use NexAI

  def post(req) do
    messages = req.body["messages"] || []
    input = req.body["input"] || ""
    
    # 0. Server-side Deduplication
    history = Nex.Store.get(:datastar_chat_history, [])
    last_msg = List.last(history)

    if last_msg && last_msg.role == "user" && last_msg.content == input do
      # Duplicate request detected (User message exists but AI hasn't responded yet)
      # Just reset loading state and do nothing
      Nex.text("""
      event: datastar-patch-signals
      data: signals {"isLoading": false}

      """, status: 200, headers: %{"content-type" => "text/event-stream"})
    else
      # 1. Prepare fragments for User message and AI placeholder
      timestamp = format_time()
    
    user_content = """
    <div class="flex w-full gap-x-3 mb-6 flex-row-reverse">
      <div class="flex-shrink-0">
        <div class="w-9 h-9 rounded-xl flex items-center justify-center font-bold text-sm shadow-lg border border-white/10 bg-primary-600 text-white">U</div>
      </div>
      <div class="chat-bubble flex-1 flex flex-col items-end">
        <div class="max-w-[85%] px-4 py-2.5 rounded-2xl text-[15px] leading-relaxed shadow-sm border transition-all duration-300 bg-primary-600 border-primary-500 text-white rounded-tr-none">
          <p class="whitespace-pre-wrap text-left">#{input}</p>
        </div>
        <div class="flex items-center mt-1.5 px-1 opacity-40">
          <span class="text-[10px] uppercase font-medium">#{timestamp}</span>
        </div>
      </div>
    </div>
    """ |> String.replace("\n", "")

    msg_id = System.unique_integer([:positive])
    ai_content_id = "ai-response-#{msg_id}"

    ai_content = """
    <div id="#{ai_content_id}" class="flex w-full gap-x-3 mb-6" data-show="$aiResponse || $aiReasoning">
      <div class="flex-shrink-0">
        <div class="w-9 h-9 rounded-xl flex items-center justify-center font-bold text-sm shadow-lg border border-white/10 bg-[#1f2937] text-emerald-400">AI</div>
      </div>
      <div class="chat-bubble flex-1 flex flex-col items-start">
        <div class="max-w-[85%] px-4 py-2.5 rounded-2xl text-[15px] leading-relaxed shadow-sm border transition-all duration-300 bg-[#1f2937] border-gray-700 text-gray-200 rounded-tl-none">
          <!-- Reasoning -->
          <div data-show="$aiReasoning" class="mb-3 p-3 bg-white/5 border border-white/10 rounded-xl text-xs text-gray-400 font-serif italic">
            <div class="flex items-center gap-2 mb-2 opacity-60">
              <span class="w-1.5 h-1.5 rounded-full bg-purple-500 animate-pulse"></span>
              <span>Thinking...</span>
            </div>
            <p class="whitespace-pre-wrap" data-text="$aiReasoning"></p>
          </div>
          <!-- Content -->
          <p class="whitespace-pre-wrap text-left" data-text="$aiResponse"></p>
          <!-- Status -->
          <div class="flex items-center mt-3 pt-2 border-t border-white/5 space-x-2 text-primary-400">
            <span class="text-[9px] uppercase font-bold tracking-widest opacity-70" data-text="$aiStatus"></span>
          </div>
        </div>
      </div>
    </div>
    """ |> String.replace("\n", "")

    # 2. Logic & Automatic Signal Syncing
    
    # Store message history (user message first)
    Nex.Store.update(:datastar_chat_history, [], fn history ->
      history ++ [%{role: "user", content: input}]
    end)

    stream_text(
      model: NexAI.openai("gpt-4o"),
      messages: messages ++ [%{role: "user", content: input}],
      max_steps: 5
    )
    |> to_datastar(
      fragments: [
        {"#messages-box", user_content, "append"},
        {"#messages-box", ai_content, "append"}
      ],
      initial_signals: %{"input" => ""},
      final_fragments_fn: fn final_text ->
        # Store AI response in history
        Nex.Store.update(:datastar_chat_history, [], fn history ->
          history ++ [%{role: "assistant", content: final_text}]
        end)
        
        # Replace the dynamic AI placeholder with a static one (no data-text)
        static_ai_content = """
        <div id="#{ai_content_id}" class="flex w-full gap-x-3 mb-6">
          <div class="flex-shrink-0">
            <div class="w-9 h-9 rounded-xl flex items-center justify-center font-bold text-sm shadow-lg border border-white/10 bg-[#1f2937] text-emerald-400">AI</div>
          </div>
          <div class="chat-bubble flex-1 flex flex-col items-start">
            <div class="max-w-[85%] px-4 py-2.5 rounded-2xl text-[15px] leading-relaxed shadow-sm border transition-all duration-300 bg-[#1f2937] border-gray-700 text-gray-200 rounded-tl-none">
              <p class="whitespace-pre-wrap text-left">#{final_text}</p>
              <div class="flex items-center mt-3 pt-2 border-t border-white/5 space-x-2 text-primary-400">
                <span class="text-[9px] uppercase font-bold tracking-widest opacity-70">Ready</span>
              </div>
            </div>
          </div>
        </div>
        """ |> String.replace("\n", "")
        
        [{"##{ai_content_id}", static_ai_content, "replace"}]
      end,
      signal: "aiResponse",
      reasoning_signal: "aiReasoning",
      status_signal: "aiStatus"
    )
  end
  end

  defp format_time do
    {{year, month, day}, {hour, minute, _}} = :erlang.localtime()
    "#{year}-#{pad(month)}-#{pad(day)} #{pad(hour)}:#{pad(minute)}"
  end
  defp pad(n) when n < 10, do: "0#{n}"
  defp pad(n), do: "#{n}"
end
