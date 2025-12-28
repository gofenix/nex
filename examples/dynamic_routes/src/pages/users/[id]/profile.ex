defmodule DynamicRoutes.Pages.Users.Id.Profile do
  use Nex.Page

  def mount(%{"id" => id}) do
    %{
      title: "User Profile - #{id}",
      id: id,
      user: find_user(id),
      params_display: ~s(%{"id" => "#{id}"})
    }
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <nav class="text-sm text-gray-500">
        <a href="/" class="hover:text-gray-700">Home</a>
        <span class="mx-2">/</span>
        <a href="/users" class="hover:text-gray-700">Users</a>
        <span class="mx-2">/</span>
        <a href={"/users/#{@id}"} class="hover:text-gray-700">{@id}</a>
        <span class="mx-2">/</span>
        <span>profile</span>
      </nav>

      <div class="bg-white rounded-lg p-6 shadow">
        <h1 class="text-2xl font-bold mb-6">{@user.name}'s Profile</h1>

        <div class="bg-gray-50 p-4 rounded mb-6">
          <h3 class="font-mono text-sm mb-2">Nested Route Parsing</h3>
          <p class="text-sm text-gray-600">Demonstrates support for multi-level dynamic routes</p>
        </div>

        <div class="grid md:grid-cols-3 gap-6">
          <div class="md:col-span-2 space-y-6">
            <div>
              <h3 class="font-semibold text-gray-700 mb-3">Personal Information</h3>
              <div class="space-y-3">
                <div class="flex justify-between py-2 border-b">
                  <span class="text-gray-500">Name</span>
                  <span>{@user.name}</span>
                </div>
                <div class="flex justify-between py-2 border-b">
                  <span class="text-gray-500">Email</span>
                  <span>{@user.email}</span>
                </div>
                <div class="flex justify-between py-2 border-b">
                  <span class="text-gray-500">Age</span>
                  <span>{@user.age} years old</span>
                </div>
                <div class="flex justify-between py-2 border-b">
                  <span class="text-gray-500">City</span>
                  <span>{@user.city}</span>
                </div>
                <div class="flex justify-between py-2 border-b">
                  <span class="text-gray-500">Registration Date</span>
                  <span>2024-01-15</span>
                </div>
              </div>
            </div>

            <div>
              <h3 class="font-semibold text-gray-700 mb-3">Bio</h3>
              <p class="text-gray-600">
                This is {@user.name}'s bio. {@user.name} is a passionate developer,
                focused on Elixir and Phoenix framework. Works and lives in {@user.city}.
              </p>
            </div>
          </div>

          <div>
            <div class="bg-blue-50 p-4 rounded">
              <h3 class="font-semibold text-blue-800 mb-2">Route Information</h3>
              <div class="space-y-2 text-sm">
                <div>
                  <span class="text-blue-600">File:</span>
                  <br>
                  <code class="text-xs">users/[id]/profile.ex</code>
                </div>
                <div>
                  <span class="text-blue-600">URL:</span>
                  <br>
                  <code class="text-xs">/users/{@id}/profile</code>
                </div>
                <div>
                  <span class="text-blue-600">Parameters:</span>
                  <br>
                  <code class="text-xs">{@params_display}</code>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Reuse user lookup function
  defp find_user(id) do
    users = %{
      "1" => %{id: "1", name: "Zhang San", email: "zhangsan@example.com", age: 28, city: "Beijing"},
      "2" => %{id: "2", name: "Li Si", email: "lisi@example.com", age: 32, city: "Shanghai"},
      "3" => %{id: "3", name: "Wang Wu", email: "wangwu@example.com", age: 25, city: "Shenzhen"}
    }

    Map.get(users, id, %{
      id: id,
      name: "Unknown User",
      email: "unknown@example.com",
      age: 0,
      city: "Unknown"
    })
  end
end
