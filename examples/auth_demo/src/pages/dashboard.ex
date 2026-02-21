defmodule AuthDemo.Pages.Dashboard do
  use Nex

  def mount(_params) do
    user = Session.get(:user)
    flash = Flash.pop_all()
    visit_count = Session.update(:visit_count, 0, &(&1 + 1))
    %{user: user, flash: flash, visit_count: visit_count}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto mt-16 p-8">
      <div class="flex items-center justify-between mb-8">
        <h1 class="text-3xl font-bold">Dashboard</h1>
        <a href="/" class="text-blue-600 hover:underline text-sm">← Home</a>
      </div>

      <%= if @flash[:success] do %>
        <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-4">
          {@flash[:success]}
        </div>
      <% end %>

      <div class="bg-white rounded-lg shadow p-6 mb-6">
        <h2 class="text-lg font-semibold mb-3">Protected Page</h2>
        <p class="text-gray-700">
          Welcome, <strong>{@user["name"]}</strong>! This page is protected by middleware.
        </p>
        <p class="text-gray-500 text-sm mt-2">
          You can only see this if you are logged in.
        </p>
      </div>

      <div class="bg-white rounded-lg shadow p-6 mb-6">
        <h2 class="text-lg font-semibold mb-3">Session Counter</h2>
        <p class="text-gray-700">
          You have visited this page <strong>{@visit_count}</strong> time(s) this session.
        </p>
        <p class="text-gray-500 text-sm mt-1">
          Refresh the page to increment. Counter resets on logout.
        </p>
      </div>

      <div class="bg-white rounded-lg shadow p-6">
        <h2 class="text-lg font-semibold mb-3">Session Data</h2>
        <pre class="bg-gray-100 rounded p-3 text-sm overflow-auto">{inspect(@user, pretty: true)}</pre>
      </div>
    </div>
    """
  end
end
