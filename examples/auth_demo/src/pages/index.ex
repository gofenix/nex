defmodule AuthDemo.Pages.Index do
  use Nex

  def mount(_params) do
    user = Session.get(:user)
    theme = Cookie.get(:theme, "light")
    flash = Flash.pop_all()
    %{user: user, theme: theme, flash: flash}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto mt-16 p-8">
      <h1 class="text-3xl font-bold mb-2">Nex Auth Demo</h1>
      <p class="text-gray-500 mb-8">Verifying: Session, Cookie, Flash, Middleware</p>

      <%= if @flash[:error] do %>
        <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
          {@flash[:error]}
        </div>
      <% end %>
      <%= if @flash[:info] do %>
        <div class="bg-blue-100 border border-blue-400 text-blue-700 px-4 py-3 rounded mb-4">
          {@flash[:info]}
        </div>
      <% end %>
      <%= if @flash[:success] do %>
        <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-4">
          {@flash[:success]}
        </div>
      <% end %>

      <div class="bg-white rounded-lg shadow p-6 mb-6">
        <h2 class="text-lg font-semibold mb-3">Session State</h2>
        <%= if @user do %>
          <p class="text-green-600 font-medium">Logged in as: <strong>{@user["name"]}</strong></p>
          <p class="text-gray-500 text-sm mt-1">Email: {@user["email"]}</p>
        <% else %>
          <p class="text-gray-500">Not logged in</p>
        <% end %>
      </div>

      <div class="bg-white rounded-lg shadow p-6 mb-6">
        <h2 class="text-lg font-semibold mb-3">Cookie State</h2>
        <p class="text-gray-700">Current theme cookie: <code class="bg-gray-100 px-2 py-1 rounded">{@theme}</code></p>
        <div class="flex gap-3 mt-3">
          <button hx-post="/set_theme" hx-vals='{"theme": "light"}' hx-target="body" hx-push-url="/"
            class="px-4 py-2 bg-gray-200 rounded hover:bg-gray-300 text-sm">
            Set Light Theme
          </button>
          <button hx-post="/set_theme" hx-vals='{"theme": "dark"}' hx-target="body" hx-push-url="/"
            class="px-4 py-2 bg-gray-800 text-white rounded hover:bg-gray-700 text-sm">
            Set Dark Theme
          </button>
        </div>
      </div>

      <div class="bg-white rounded-lg shadow p-6 mb-6">
        <h2 class="text-lg font-semibold mb-3">Actions</h2>
        <div class="flex gap-3 flex-wrap">
          <%= if @user do %>
            <a href="/dashboard" class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 text-sm">
              Go to Dashboard (protected)
            </a>
            <button hx-post="/logout" hx-target="body" hx-push-url="/"
              class="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700 text-sm">
              Logout
            </button>
          <% else %>
            <a href="/login" class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 text-sm">
              Login
            </a>
            <a href="/dashboard" class="px-4 py-2 bg-gray-600 text-white rounded hover:bg-gray-700 text-sm">
              Try Dashboard (will redirect)
            </a>
          <% end %>
        </div>
      </div>

      <div class="bg-white rounded-lg shadow p-6">
        <h2 class="text-lg font-semibold mb-3">Static File Test</h2>
        <img src="/static/logo.svg" alt="Static file test" class="h-12 mb-2" />
        <p class="text-gray-500 text-sm">If the logo above loads, static file serving works.</p>
      </div>
    </div>
    """
  end

  def set_theme(%{"theme" => theme}) do
    Cookie.put(:theme, theme, max_age: 86_400 * 30, http_only: false)
    Flash.put(:info, "Theme set to #{theme}!")
    Nex.redirect("/")
  end

  def logout(_params) do
    Session.clear()
    Flash.put(:success, "Logged out successfully.")
    Nex.redirect("/")
  end
end
