defmodule AgentConsole.Pages.Sessions do
  use Nex

  def mount(_params) do
    sessions = fetch_sessions()

    %{
      title: "Sessions - Agent Console",
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
          <a href="/" class="block px-3 py-2 rounded hover:bg-gray-800 mb-1">
            💬 Chat
          </a>
          <a href="/sessions" class="block px-3 py-2 rounded hover:bg-gray-800 mb-1 bg-gray-800">
            📋 Sessions
          </a>
        </div>
      </div>
      
      <!-- Main Content -->
      <div class="flex-1 flex flex-col">
        <div class="bg-white border-b px-6 py-4">
          <h2 class="text-xl font-semibold">Session Management</h2>
        </div>
        
        <div class="flex-1 overflow-y-auto p-6">
          <div class="bg-white rounded-lg shadow">
            <div class="p-4 border-b flex justify-between items-center">
              <h3 class="font-semibold">All Sessions</h3>
              <span class="text-sm text-gray-500">{length(@sessions)} sessions</span>
            </div>
            
            <div class="divide-y">
              <div :if={@sessions == []} class="p-8 text-center text-gray-500">
                No sessions yet. Start a chat to create one.
              </div>
              
              <div :for={session <- @sessions} class="p-4 flex items-center justify-between hover:bg-gray-50">
                <div>
                  <p class="font-medium">{session.key}</p>
                  <p class="text-sm text-gray-500">
                    Updated: {format_time(session.updated_at)}
                  </p>
                </div>
                <div class="flex gap-2">
                  <a 
                    href={"/chat/" <> session.key}
                    class="px-3 py-1 text-sm bg-blue-100 text-blue-700 rounded hover:bg-blue-200"
                  >
                    Open
                  </a>
                  <button 
                    phx-click="delete_session"
                    phx-value-key={session.key}
                    class="px-3 py-1 text-sm bg-red-100 text-red-700 rounded hover:bg-red-200"
                  >
                    Delete
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    """
  end

  def delete_session(req) do
    key = req.params["key"]

    if key do
      Nex.Agent.SessionManager.invalidate(key)
      Nex.Agent.SessionManager.save(Nex.Agent.Session.new(key))
    end

    # Redirect back to sessions page
    Nex.redirect("/sessions")
  end

  defp fetch_sessions do
    Nex.Agent.SessionManager.list()
  end

  defp format_time(nil), do: "Unknown"

  defp format_time(time) when is_binary(time) do
    time
  end

  defp format_time(_), do: "Unknown"
end
