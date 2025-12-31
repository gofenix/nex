defmodule AlpineShowcase.Partials.Users.List do
  use Nex.Partial

  # Render the entire list container
  def user_list(assigns) do
    ~H"""
    <div class="overflow-x-auto bg-base-100 rounded-box shadow-md">
      <table class="table table-zebra">
        <thead>
          <tr>
            <th>ID</th>
            <th>Name</th>
            <th>Email</th>
          </tr>
        </thead>
        <!-- 
           ID must match hx-target="#user-list" in form_modal
           hx-swap="beforeend" will insert the new row at the end of this tbody
        -->
        <tbody id="user-list">
          <.user_row :for={user <- @users} user={user} />
        </tbody>
      </table>
    </div>
    """
  end

  # Render a single row (Action create_user will also call this to return the new row)
  def render_user_row(assigns) do
    # If assigns lacks :user but has :id, :name etc, adaptation might be needed
    # But typically the controller constructs the user map
    ~H"""
    <.user_row user={@user} />
    """
  end

  # Private component: Row structure
  def user_row(assigns) do
    ~H"""
    <tr class="hover">
      <td>{@user.id}</td>
      <td>{@user.name}</td>
      <td>{@user.email}</td>
    </tr>
    """
  end
end
