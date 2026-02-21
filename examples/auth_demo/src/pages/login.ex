defmodule AuthDemo.Pages.Login do
  use Nex

  def mount(_params) do
    flash = Flash.pop_all()
    %{flash: flash}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-md mx-auto mt-24 p-8">
      <h1 class="text-2xl font-bold mb-6">Login</h1>

      <%= if @flash[:error] do %>
        <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
          {@flash[:error]}
        </div>
      <% end %>

      <div class="bg-white rounded-lg shadow p-6">
        <form hx-post="/login" hx-target="body" hx-push-url="/">
          <div class="mb-4">
            <label class="block text-sm font-medium text-gray-700 mb-1">Email</label>
            <input type="email" name="email" placeholder="admin@example.com"
              class="w-full border border-gray-300 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500" />
          </div>
          <div class="mb-6">
            <label class="block text-sm font-medium text-gray-700 mb-1">Password</label>
            <input type="password" name="password" placeholder="password"
              class="w-full border border-gray-300 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500" />
          </div>
          <button type="submit"
            class="w-full bg-blue-600 text-white py-2 rounded hover:bg-blue-700 font-medium">
            Login
          </button>
        </form>
        <p class="text-gray-500 text-sm mt-4 text-center">
          Demo credentials: <code class="bg-gray-100 px-1 rounded">admin@example.com</code> / <code class="bg-gray-100 px-1 rounded">password</code>
        </p>
      </div>

      <div class="mt-4 text-center">
        <a href="/" class="text-blue-600 hover:underline text-sm">← Back to home</a>
      </div>
    </div>
    """
  end

  def login(%{"email" => email, "password" => password}) do
    if email == "admin@example.com" and password == "password" do
      Session.put(:user, %{"name" => "Admin User", "email" => email})
      Flash.put(:success, "Welcome back, Admin User!")
      Nex.redirect("/dashboard")
    else
      Flash.put(:error, "Invalid email or password.")
      Nex.redirect("/login")
    end
  end
end
