defmodule AlpineShowcase.Pages.Index do
  use Nex
  import AlpineShowcase.Partials.Users.List
  import AlpineShowcase.Partials.Users.FormModal
  import AlpineShowcase.Partials.Profile.Settings

  def mount(_params) do
    # Initialize server-side data
    # In a real app, this would come from a database
    users = Nex.Store.get(:users, [
      %{id: 1, name: "Alice", email: "alice@example.com"},
      %{id: 2, name: "Bob", email: "bob@example.com"}
    ])
    %{title: "Alpine Integration Demo", users: users}
  end

  # Define Alpine data structure
  # tab: Current active tab
  # userModalOpen: Controls the user creation modal
  def render(assigns) do
    ~H"""
    <div x-data="{ currentTab: 'users', userModalOpen: false }" class="container mx-auto max-w-4xl">

      <div class="text-center mb-8">
        <h1 class="text-4xl font-bold mb-2">Nex + Alpine.js Showcase</h1>
        <p class="text-base-content/70">A comprehensive example of "The STACK"</p>
      </div>

      <!-- Tabs Navigation (Client-side switching) -->
      <div role="tablist" class="tabs tabs-boxed mb-8 bg-base-100 p-2 shadow-sm">
        <a role="tab" class="tab tab-lg"
           x-bind:class="{ 'tab-active': currentTab === 'users' }"
           x-on:click="currentTab = 'users'">User Management</a>
        <a role="tab" class="tab tab-lg"
           x-bind:class="{ 'tab-active': currentTab === 'profile' }"
           x-on:click="currentTab = 'profile'">Profile Settings</a>
      </div>

      <!-- Tab Content 1: Users -->
      <div x-show="currentTab === 'users'" x-transition:enter.duration.300ms>
        <div class="flex justify-between items-center mb-6">
          <h2 class="text-2xl font-bold">User Directory</h2>
          <!-- Open modal on click, and auto-focus input ($nextTick ensures DOM update) -->
          <button
            class="btn btn-primary"
            x-on:click="userModalOpen = true; $nextTick(() => $refs.nameInput.focus())"
          >Add User</button>
        </div>

        <!-- User List Component -->
        <.user_list users={@users} />

        <!-- User Form Modal Component (Pass users list for updates) -->
        <.user_form_modal />
      </div>

      <!-- Tab Content 2: Profile -->
      <div x-show="currentTab === 'profile'" style="display: none;" x-transition:enter.duration.300ms>
        <.profile_settings />
      </div>

    </div>
    """
  end

  # Handle Add User: Maps to POST /create_user
  def create_user(params) do
    new_user = %{
      id: System.unique_integer([:positive]),
      name: params["name"],
      email: params["email"]
    }

    # 1. Update Database/Store
    users = Nex.Store.get(:users, [
      %{id: 1, name: "Alice", email: "alice@example.com"},
      %{id: 2, name: "Bob", email: "bob@example.com"}
    ]) ++ [new_user]
    Nex.Store.put(:users, users)

    # 2. Return HTML fragment to append to list
    # Note: Calls the render function from the Partial module
    render_user_row(%{user: new_user})
  end

  # Handle Update Settings: Maps to PUT /update_settings
  def update_settings(_params) do
    # Simulate save delay
    Process.sleep(500)

    # Return empty content (Frontend doesn't replace DOM, just listens for event)
    :empty
  end
end
