defmodule AlpineShowcase.Pages.Index do
  use Nex
  import AlpineShowcase.Components.Users.List
  import AlpineShowcase.Components.Users.FormModal
  import AlpineShowcase.Components.Profile.Settings

  @users_key {__MODULE__, :users}
  @default_users [
    %{id: 1, name: "Alice", email: "alice@example.com"},
    %{id: 2, name: "Bob", email: "bob@example.com"}
  ]

  def mount(_params) do
    %{title: "Alpine Integration Demo", users: load_users()}
  end

  # Define Alpine data structure
  # tab: Current active tab
  # userModalOpen: Controls the user creation modal
  def render(assigns) do
    ~H"""
    <div x-data="{ currentTab: 'users', userModalOpen: false }" data-testid="alpine-page" class="container mx-auto max-w-4xl">

      <div class="text-center mb-8">
        <h1 class="text-4xl font-bold mb-2">Nex + Alpine.js Showcase</h1>
        <p class="text-base-content/70">A comprehensive example of "The STACK"</p>
      </div>

      <!-- Tabs Navigation (Client-side switching) -->
      <div role="tablist" class="tabs tabs-boxed mb-8 bg-base-100 p-2 shadow-sm">
        <a role="tab" class="tab tab-lg"
           data-testid="alpine-tab-users"
           x-bind:class="{ 'tab-active': currentTab === 'users' }"
           x-on:click="currentTab = 'users'">User Management</a>
        <a role="tab" class="tab tab-lg"
           data-testid="alpine-tab-profile"
           x-bind:class="{ 'tab-active': currentTab === 'profile' }"
           x-on:click="currentTab = 'profile'">Profile Settings</a>
      </div>

      <!-- Tab Content 1: Users -->
      <div x-show="currentTab === 'users'" data-testid="alpine-users-panel" x-transition:enter.duration.300ms>
        <div class="flex justify-between items-center mb-6">
          <h2 class="text-2xl font-bold">User Directory</h2>
          <!-- Open modal on click, and auto-focus input ($nextTick ensures DOM update) -->
          <button
            class="btn btn-primary"
            data-testid="alpine-open-user-modal"
            x-on:click="userModalOpen = true; $nextTick(() => $refs.nameInput.focus())"
          >Add User</button>
        </div>

        <!-- User List Component -->
        <.user_list users={@users} />

        <!-- User Form Modal Component (Pass users list for updates) -->
        <.user_form_modal />
      </div>

      <!-- Tab Content 2: Profile -->
      <div x-show="currentTab === 'profile'" data-testid="alpine-profile-panel" style="display: none;" x-transition:enter.duration.300ms>
        <.profile_settings />
      </div>

    </div>
    """
  end

  # Handle Add User: Maps to POST /create_user
  def create_user(req) do
    params = req.body

    new_user = %{
      id: System.unique_integer([:positive]),
      name: params["name"],
      email: params["email"]
    }

    users = load_users() ++ [new_user]
    persist_users(users)

    render_user_row(%{user: new_user})
  end

  # Handle Update Settings: Maps to PUT /update_settings
  def update_settings(_req) do
    Process.sleep(500)

    :empty
  end

  defp load_users do
    :persistent_term.get(@users_key, @default_users)
  end

  defp persist_users(users) do
    :persistent_term.put(@users_key, users)
  end
end
