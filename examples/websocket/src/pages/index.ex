defmodule NexWebsocketExample.Pages.Index do
  use Nex

  def mount(_params) do
    %{title: "WebSocket Chat Demo"}
  end

  def render(assigns) do
    ~H"""
    <div data-testid="websocket-page" class="max-w-2xl mx-auto">
      <h1 class="text-3xl font-bold mb-4">WebSocket Chat Demo</h1>
      
      <div class="bg-white rounded-lg shadow p-4 mb-4">
        <div class="flex gap-2 mb-4">
          <input type="text" id="username" data-testid="websocket-username" placeholder="Your name" class="border p-2 rounded" />
          <select id="room" data-testid="websocket-room" class="border p-2 rounded">
            <option value="lobby">Lobby</option>
            <option value="tech">Tech</option>
            <option value="random">Random</option>
          </select>
          <button onclick="connect()" data-testid="websocket-connect" class="bg-blue-500 text-white px-4 py-2 rounded">Connect</button>
        </div>

        <div id="messages" data-testid="websocket-messages" class="border rounded p-4 mb-4 bg-gray-50"></div>

        <div class="flex gap-2">
          <input type="text" id="message" data-testid="websocket-message" placeholder="Type a message..." class="flex-1 border p-2 rounded" disabled />
          <button onclick="sendMessage()" id="sendBtn" data-testid="websocket-send" class="bg-green-500 text-white px-4 py-2 rounded" disabled>Send</button>
        </div>
      </div>

      <div class="text-sm text-gray-600">
        <p>Open multiple browser tabs to test real-time broadcasting!</p>
      </div>
    </div>

    <script>
      let ws;
      
      function connect() {
        const username = document.getElementById('username').value || 'Anonymous';
        const room = document.getElementById('room').value;
        
        ws = new WebSocket(`ws://${location.host}/ws/chat?username=${username}&room=${room}`);
        
        ws.onopen = () => {
          addMessage('System', `Connected to ${room} as ${username}`);
          document.getElementById('message').disabled = false;
          document.getElementById('sendBtn').disabled = false;
        };
        
        ws.onmessage = (event) => {
          const data = JSON.parse(event.data);
          addMessage(data.user, data.text);
        };
        
        ws.onclose = () => {
          addMessage('System', 'Disconnected');
          document.getElementById('message').disabled = true;
          document.getElementById('sendBtn').disabled = true;
        };
      }
      
      function sendMessage() {
        const input = document.getElementById('message');
        if (input.value.trim()) {
          ws.send(input.value);
          input.value = '';
        }
      }
      
      function addMessage(user, text) {
        const div = document.getElementById('messages');
        const msg = document.createElement('div');
        msg.className = 'mb-2';
        msg.innerHTML = `<strong>${user}:</strong> ${text}`;
        div.appendChild(msg);
        div.scrollTop = div.scrollHeight;
      }
    </script>
    """
  end
end
