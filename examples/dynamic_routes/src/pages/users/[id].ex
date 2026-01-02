defmodule DynamicRoutes.Pages.Users.Id do
  use Nex

  def mount(%{"id" => id}) do
    %{
      title: "User Details - #{id}",
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
        <span>{@id}</span>
      </nav>

      <div class="bg-white rounded-lg p-6 shadow">
        <div class="flex items-center space-x-4 mb-6">
          <div class="w-16 h-16 bg-blue-500 rounded-full flex items-center justify-center text-white text-2xl font-bold">
            {String.upcase(String.first(@user.name))}
          </div>
          <div>
            <h1 class="text-2xl font-bold">{@user.name}</h1>
            <p class="text-gray-600">{@user.email}</p>
          </div>
        </div>

        <div class="grid md:grid-cols-2 gap-4">
          <div>
            <h3 class="font-semibold text-gray-700 mb-2">Basic Information</h3>
            <dl class="space-y-1">
              <div class="flex justify-between">
                <dt class="text-gray-500">ID:</dt>
                <dd>{@user.id}</dd>
              </div>
              <div class="flex justify-between">
                <dt class="text-gray-500">Age:</dt>
                <dd>{@user.age} years old</dd>
              </div>
              <div class="flex justify-between">
                <dt class="text-gray-500">City:</dt>
                <dd>{@user.city}</dd>
              </div>
            </dl>
          </div>

          <div>
            <h3 class="font-semibold text-gray-700 mb-2">Actions</h3>
            <div class="space-y-2">
              <a href={"/users/#{@id}/profile"}
                 class="block bg-blue-500 text-white px-4 py-2 rounded text-center hover:bg-blue-600">
                View Profile
              </a>
              <button
                hx-post={"/users/#{@id}/follow"}
                hx-target="#follow-btn"
                class="w-full bg-green-500 text-white px-4 py-2 rounded hover:bg-green-600">
                Follow
              </button>
            </div>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-lg p-6 shadow">
        <h2 class="text-xl font-semibold mb-4">Dynamic Route Parsing</h2>
        <div class="bg-gray-50 p-4 rounded">
          <h3 class="font-mono text-sm mb-2">File Path:</h3>
          <code class="text-sm">src/pages/users/[id].ex</code>

          <h3 class="font-mono text-sm mt-4 mb-2">URL Match:</h3>
          <code class="text-sm">/users/{@id}</code>

          <h3 class="font-mono text-sm mt-4 mb-2">Parameter Extraction:</h3>
          <pre class="text-sm bg-white p-2 rounded mt-2">{@params_display}</pre>
        </div>
      </div>
    </div>
    """
  end

  def follow(%{"id" => id}) do
    # Simulate follow operation
    :timer.sleep(500)  # Simulate delay

    assigns = %{id: id}
    ~H"""
    <button class="w-full bg-gray-500 text-white px-4 py-2 rounded cursor-not-allowed" disabled>
      Already Followed
    </button>
    """
  end

  # Mock user data
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
