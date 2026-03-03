defmodule AgentConsole.Pages.Index do
  use Nex

  @session_id "main"

  def mount(_params) do
    sessions = list_sessions()

    %{
      title: "Agent Console",
      session_id: @session_id,
      sessions: sessions
    }
  end

  def render(assigns) do
    ~H"""
    <div class="flex h-screen">
      <!-- Sidebar -->
      <div class="w-64 bg-gray-900 text-white flex flex-col">
        <div class="p-4 border-b border-gray-700">
          <h1 class="text-xl font-bold">🤖 Agent Console</h1>
        </div>
        
        <div class="flex-1 overflow-y-auto p-2">
          <a href="/" class="block px-3 py-2 rounded hover:bg-gray-800 mb-1 bg-gray-800">
            💬 Chat
          </a>
          <a href="/sessions" class="block px-3 py-2 rounded hover:bg-gray-800 mb-1">
            📋 Sessions
          </a>
        </div>
        
        <div class="p-4 border-t border-gray-700 text-sm text-gray-400">
          <p>Provider: {provider_name()}</p>
          <p>Model: {model_name()}</p>
        </div>
      </div>
      
      <!-- Main Content -->
      <div class="flex-1 flex flex-col">
        <!-- Chat Header -->
        <div class="bg-white border-b px-6 py-3 flex items-center justify-between">
          <h2 class="text-lg font-semibold">New Chat</h2>
          <button 
            onclick="resetSession()"
            class="text-sm text-gray-500 hover:text-red-500"
          >
            🗑️ Clear
          </button>
        </div>
        
        <!-- Messages -->
        <div id="messages" class="flex-1 overflow-y-auto p-6 space-y-4">
          <div class="text-center text-gray-400 mt-20">
            <p class="text-4xl mb-4">🤖</p>
            <p>Start a conversation with the agent</p>
            <p class="text-sm mt-2">Type a message below or use /help for commands</p>
          </div>
        </div>
        
        <!-- Input -->
        <div class="bg-white border-t p-4">
          <form id="chat-form" class="flex gap-2">
            <input
              type="text"
              name="message"
              id="message-input"
              class="flex-1 px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="Type your message... (Enter to send, Shift+Enter for new line)"
              autocomplete="off"
            />
            <button
              type="submit"
              id="send-btn"
              class="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              Send
            </button>
          </form>
          <p class="text-xs text-gray-400 mt-2">
            Press Enter to send • Shift+Enter for new line • Type /stop to interrupt
          </p>
        </div>
      </div>
    </div>

    <script>
      const sessionId = "#{@session_id}";
      const wsProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
      const ws = new WebSocket(wsProtocol + '//' + window.location.host + '/ws');
      
      let messageInput = document.getElementById('message-input');
      let sendBtn = document.getElementById('send-btn');
      let messagesDiv = document.getElementById('messages');
      
      ws.onopen = function() {
        console.log('WebSocket connected');
      };
      
      ws.onmessage = function(event) {
        const data = JSON.parse(event.data);
        
        if (data.type === 'start') {
          addMessage('assistant', 'Thinking...', true);
          sendBtn.disabled = true;
          sendBtn.textContent = '⏳';
          messageInput.disabled = true;
        } else if (data.type === 'message') {
          // Update the thinking message with actual response
          updateLastMessage(data.content);
          sendBtn.disabled = false;
          sendBtn.textContent = 'Send';
          messageInput.disabled = false;
          messageInput.value = '';
          messageInput.focus();
        } else if (data.type === 'error') {
          updateLastMessage('Error: ' + data.error);
          sendBtn.disabled = false;
          sendBtn.textContent = 'Send';
          messageInput.disabled = false;
        } else if (data.type === 'reset') {
          messagesDiv.innerHTML = '';
          addMessage('system', data.message || 'Session reset');
        } else if (data.type === 'stopped') {
          updateLastMessage('[Stopped by user]');
          sendBtn.disabled = false;
          sendBtn.textContent = 'Send';
          messageInput.disabled = false;
        }
      };
      
      ws.onerror = function(error) {
        console.error('WebSocket error:', error);
        addMessage('system', 'Connection error');
      };
      
      ws.onclose = function() {
        console.log('WebSocket closed');
        addMessage('system', 'Connection closed. Please refresh the page.');
      };
      
      document.getElementById('chat-form').addEventListener('submit', function(e) {
        e.preventDefault();
        
        const message = messageInput.value.trim();
        if (!message || !ws || ws.readyState !== WebSocket.OPEN) return;
        
        // Add user message immediately
        addMessage('user', message);
        
        // Send to WebSocket
        ws.send(JSON.stringify({
          type: 'prompt',
          content: message
        }));
      });
      
      messageInput.addEventListener('keydown', function(e) {
        if (e.key === 'Enter' && !e.shiftKey) {
          e.preventDefault();
          document.getElementById('chat-form').dispatchEvent(new Event('submit'));
        }
      });
      
      function addMessage(role, content, isTyping = false) {
        // Clear empty state
        if (messagesDiv.querySelector('.text-center')) {
          messagesDiv.innerHTML = '';
        }
        
        const div = document.createElement('div');
        div.className = role === 'user' 
          ? 'flex justify-end' 
          : 'flex justify-start';
        
        const bubble = document.createElement('div');
        
        if (role === 'user') {
          bubble.className = 'message-user max-w-lg px-4 py-2 rounded-lg border';
        } else if (role === 'system') {
          bubble.className = 'text-center text-gray-500 text-sm py-2';
        } else {
          bubble.className = 'message-ai max-w-lg px-4 py-2 rounded-lg border';
          if (isTyping) bubble.classList.add('typing-cursor');
        }
        
        bubble.textContent = content;
        div.appendChild(bubble);
        messagesDiv.appendChild(div);
        messagesDiv.scrollTop = messagesDiv.scrollHeight;
        
        return div;
      }
      
      function updateLastMessage(content) {
        const lastBubble = messagesDiv.querySelector('.typing-cursor');
        if (lastBubble) {
          lastBubble.classList.remove('typing-cursor');
          lastBubble.textContent = content;
        } else {
          // Find last assistant message and update
          const bubbles = messagesDiv.querySelectorAll('.message-ai');
          if (bubbles.length > 0) {
            bubbles[bubbles.length - 1].textContent = content;
          }
        }
        messagesDiv.scrollTop = messagesDiv.scrollHeight;
      }
      
      function resetSession() {
        if (ws && ws.readyState === WebSocket.OPEN) {
          ws.send(JSON.stringify({ type: 'reset' }));
        }
      }
    </script>
    """
  end

  defp list_sessions do
    []
  end

  defp provider_name do
    case Nex.Env.get(:llm_provider) || "anthropic" do
      "anthropic" -> "Anthropic"
      "openai" -> "OpenAI"
      p -> p
    end
  end

  defp model_name do
    case provider_name() do
      "Anthropic" -> Nex.Env.get(:anthropic_model) || "claude-sonnet-4-20250514"
      "OpenAI" -> Nex.Env.get(:openai_model) || "gpt-4o"
      _ -> "default"
    end
  end
end
