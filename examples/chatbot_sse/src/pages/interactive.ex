defmodule ChatbotSse.Pages.Interactive do
  @moduledoc """
  Interactive Tool Calling - Manual Approval Mode.
  
  Demonstrates how to intercept tool calls and require manual user approval 
  before execution, using pure HTMX and Nex.Store.
  """
  use Nex
  import ChatbotSse.Components.Chat.ChatMessage

  def mount(_params) do
    %{
      title: "Interactive AI",
      messages: Nex.Store.get(:interactive_messages, [])
    }
  end

  def render(assigns) do
    ~H"""
    <div class="flex-1 flex flex-col max-w-4xl mx-auto w-full py-8 px-4 overflow-hidden">
      <header class="flex items-center justify-between mb-8 shrink-0">
        <div class="flex items-center gap-4">
          <a href="/" class="w-10 h-10 flex items-center justify-center rounded-xl bg-white/5 border border-white/10 hover:bg-white/10 transition-colors">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="12.707 5.293a1 1 0 010 1.414L9.414 10l3.293 3.293a1 1 0 01-1.414 1.414l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 0z" clip-rule="evenodd" />
            </svg>
          </a>
          <div>
            <h1 class="text-xl font-bold text-white">Interactive</h1>
            <p class="text-xs text-gray-500 font-medium tracking-wider uppercase">Human-in-the-loop Pattern</p>
          </div>
        </div>
        <div class="px-3 py-1 rounded-full bg-yellow-500/10 border border-yellow-500/20 text-yellow-400 text-[10px] font-bold uppercase tracking-tighter">
          Manual Approval
        </div>
      </header>

      <!-- Messages Viewport -->
      <div id="chat-viewport" 
           class="flex-1 overflow-y-auto pr-2 mb-6 space-y-6 scrollbar-hide"
           hx-on::after-settle="this.scrollTop = this.scrollHeight">
        <div :if={length(@messages) == 0} class="h-full flex flex-col items-center justify-center text-center opacity-40 py-20">
          <div class="w-16 h-16 rounded-3xl bg-white/5 border border-white/10 flex items-center justify-center text-3xl mb-6">✋</div>
          <h3 class="text-lg font-bold text-white mb-2">Manual Approval Mode</h3>
          <p class="max-w-xs text-sm">Experience safety-first AI. Approve or reject tool calls before they execute.</p>
        </div>
        
        <.chat_message :for={msg <- Enum.reverse(@messages)} message={msg} />
      </div>

      <!-- Input Form -->
      <div class="shrink-0 relative">
        <form hx-post="/interactive/chat"
              hx-target="#chat-viewport"
              hx-swap="beforeend"
              hx-indicator="#loading-indicator"
              hx-on::after-request="this.reset()"
              class="relative group">
          <div class="absolute -inset-1 bg-gradient-to-r from-yellow-500/20 to-orange-500/20 rounded-[26px] blur opacity-0 group-focus-within:opacity-100 transition duration-500"></div>
          <input 
            type="text"
            name="message"
            required
            class="relative w-full bg-[#161b22] text-white border border-white/10 rounded-[22px] px-6 py-4 pr-16 focus:border-yellow-500 focus:outline-none transition-all disabled:opacity-50 shadow-2xl placeholder-gray-600"
            placeholder="e.g. 'What is the weather in Paris?'"
            autocomplete="off">
          <button 
            type="submit" 
            class="absolute right-3 top-3 bg-yellow-600 hover:bg-yellow-500 text-white w-11 h-11 flex items-center justify-center rounded-xl transition-all shadow-lg active:scale-95">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
              <path d="M10.894 2.553a1 1 0 00-1.788 0l-7 14a1 1 0 001.169 1.409l5-1.429A1 1 0 009 15.571V11a1 1 0 112 0v4.571a1 1 0 00.725.962l5 1.428a1 1 0 001.17-1.408l-7-14z" />
            </svg>
          </button>
        </form>

        <!-- Loading Indicator -->
        <div id="loading-indicator" class="htmx-indicator absolute -top-12 left-0 right-0 flex justify-center">
          <div class="bg-[#1f2937] border border-gray-700 px-4 py-2 rounded-full flex items-center gap-2 shadow-xl">
            <span class="flex gap-1">
              <span class="animate-bounce w-1.5 h-1.5 bg-yellow-500 rounded-full"></span>
              <span class="animate-bounce w-1.5 h-1.5 bg-yellow-500 rounded-full" style="animation-delay: 0.1s"></span>
              <span class="animate-bounce w-1.5 h-1.5 bg-yellow-500 rounded-full" style="animation-delay: 0.2s"></span>
            </span>
            <span class="text-[10px] text-gray-400 font-bold uppercase tracking-widest">Checking Policy</span>
          </div>
        </div>

        <p class="text-[10px] text-center text-gray-600 mt-4 tracking-tight uppercase font-medium">
          Pure HTMX Human-in-the-loop Implementation
        </p>
      </div>
    </div>
    """
  end

  # --- Actions ---

  def chat(%{"message" => content}) do
    msg_id = System.unique_integer([:positive])
    user_msg = %{id: msg_id, role: :user, content: content, timestamp: format_time()}
    Nex.Store.update(:interactive_messages, [], &[user_msg | &1])

    # Call AI non-streaming to detect tool calls
    response = Nex.AI.generate_text([
      %{role: "user", content: content}
    ], tools: weather_tools())

    handle_ai_response(user_msg, response)
  end

  # User approved the tool execution
  def approve_tool(%{"tool_id" => call_id, "name" => name, "args" => args_json}) do
    args = Jason.decode!(args_json)
    
    # 1. Execute the tool
    result = execute_weather_tool(name, args)
    
    # 2. Get final answer from AI
    user_messages = Nex.Store.get(:interactive_messages, []) |> Enum.reverse() |> Enum.map(&%{role: &1.role, content: &1.content})
    
    # Simulate the tool result message
    tool_msg = %{
      role: "assistant",
      content: nil,
      tool_calls: [%{id: call_id, type: "function", function: %{name: name, arguments: args_json}}]
    }
    
    result_msg = %{
      role: "tool",
      tool_call_id: call_id,
      content: Jason.encode!(result)
    }

    final_resp = Nex.AI.generate_text(user_messages ++ [tool_msg, result_msg])
    
    case final_resp do
      {:ok, %{status: 200, body: %{"choices" => [%{"message" => %{"content" => content}} | _]}}} ->
        ai_msg = %{id: System.unique_integer([:positive]), role: :assistant, content: content, timestamp: format_time()}
        Nex.Store.update(:interactive_messages, [], &[ai_msg | &1])
        
        assigns = %{ai_msg: ai_msg}
        ~H"""
        <div hx-swap-oob={"delete:#ai-approval-#{call_id}"}></div>
        <.chat_message message={@ai_msg} />
        """
      _ ->
        Nex.html("<p class='text-red-500'>Error getting final response</p>")
    end
  end

  # --- Helpers ---

  defp handle_ai_response(user_msg, {:ok, %{status: 200, body: body}}) do
    message = List.first(body["choices"])["message"]
    
    cond do
      tool_calls = message["tool_calls"] ->
        # Found a tool call! Ask for approval
        tool_call = List.first(tool_calls)
        call_id = tool_call["id"]
        name = tool_call["function"]["name"]
        args = tool_call["function"]["arguments"]

        assigns = %{user_msg: user_msg, call_id: call_id, name: name, args: args}
        ~H"""
        <.chat_message message={@user_msg} />
        <div id={"ai-approval-#{@call_id}"} class="relative overflow-hidden bg-[#1f2937]/50 backdrop-blur-md border border-yellow-500/30 rounded-2xl p-6 my-6 shadow-2xl">
          <div class="absolute top-0 right-0 p-3">
             <div class="w-2 h-2 rounded-full bg-yellow-500 animate-ping"></div>
          </div>
          <div class="flex items-start gap-4">
            <div class="w-10 h-10 rounded-xl bg-yellow-500/10 border border-yellow-500/20 flex items-center justify-center text-xl">
              ⚖️
            </div>
            <div class="flex-1">
              <h4 class="text-sm font-bold text-yellow-400 uppercase tracking-widest mb-1">Approval Required</h4>
              <p class="text-xs text-gray-400 mb-4">The AI is requesting permission to access external data.</p>
              
              <div class="bg-black/20 rounded-xl p-3 mb-4 font-mono text-xs border border-white/5">
                <div class="flex items-center gap-2 mb-2">
                  <span class="text-gray-500">Tool:</span>
                  <span class="text-emerald-400">{@name}</span>
                </div>
                <div class="flex items-start gap-2">
                  <span class="text-gray-500">Args:</span>
                  <span class="text-gray-300 break-all">{@args}</span>
                </div>
              </div>

              <div class="flex gap-3">
                <button hx-post="/interactive/approve"
                        hx-vals={Jason.encode!(%{tool_id: @call_id, name: @name, args: @args})}
                        hx-target="closest div"
                        hx-swap="outerHTML"
                        class="bg-yellow-600 hover:bg-yellow-500 px-4 py-2 rounded-lg text-xs font-bold text-white transition-all shadow-lg active:scale-95">
                  Approve & Execute
                </button>
                <button onclick="this.closest('#ai-approval-{@call_id}').remove()" class="text-gray-500 hover:text-white text-xs font-medium transition-colors">
                  Reject
                </button>
              </div>
            </div>
          </div>
        </div>
        """

      content = message["content"] ->
        ai_msg = %{id: System.unique_integer([:positive]), role: :assistant, content: content, timestamp: format_time()}
        Nex.Store.update(:interactive_messages, [], &[ai_msg | &1])
        assigns = %{user_msg: user_msg, ai_msg: ai_msg}
        ~H"""
        <.chat_message message={@user_msg} />
        <.chat_message message={@ai_msg} />
        """

      true ->
        Nex.html("<p class='text-red-500'>Empty AI response</p>")
    end
  end

  defp weather_tools do
    [
      %{
        type: "function",
        function: %{
          name: "get_weather",
          description: "Get current weather",
          parameters: %{
            type: "object",
            properties: %{
              location: %{type: "string"}
            },
            required: ["location"]
          }
        }
      }
    ]
  end

  defp execute_weather_tool("get_weather", %{"location" => loc}) do
    # Real logic here
    %{location: loc, temperature: 25, condition: "Sunny"}
  end

  defp format_time do
    {{year, month, day}, {hour, minute, _}} = :erlang.localtime()
    "#{year}-#{pad(month)}-#{pad(day)} #{pad(hour)}:#{pad(minute)}"
  end

  defp pad(n) when n < 10, do: "0#{n}"
  defp pad(n), do: "#{n}"
end
