defmodule NexBaseDemo.Pages.Tasks do
  use Nex

  # Initialize NexBase client
  @client NexBase.client(repo: NexBaseDemo.Repo)

  def mount(_params) do
    # Load all tasks
    {:ok, tasks} = @client
    |> NexBase.from("tasks")
    |> NexBase.order(:inserted_at, :desc)
    |> NexBase.run()

    %{tasks: tasks}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200 p-8">
      <div class="max-w-4xl mx-auto">
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h1 class="card-title text-3xl mb-6">📝 Task Manager</h1>

            <!-- Add Task Form -->
            <form
              hx-post="/tasks/create"
              hx-target="#task-list"
              hx-swap="afterbegin"
              class="flex gap-2 mb-6"
            >
              <input
                type="text"
                name="title"
                placeholder="Add a new task..."
                class="input input-bordered flex-1"
                required
              />
              <button type="submit" class="btn btn-primary">
                Add Task
              </button>
            </form>

            <!-- Task List -->
            <div id="task-list" class="space-y-2">
              <%= for task <- @tasks do %>
                <%= task_item(%{task: task}) %>
              <% end %>
            </div>

            <%= if @tasks == [] do %>
              <div class="text-center py-12 text-base-content/50">
                <p class="text-lg">No tasks yet. Add one above!</p>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Create new task
  def create(%{"title" => title}) do
    @client
    |> NexBase.from("tasks")
    |> NexBase.insert(%{title: title, completed: false})
    |> NexBase.run()

    # Get the newly created task
    {:ok, [task]} = @client
    |> NexBase.from("tasks")
    |> NexBase.eq(:title, title)
    |> NexBase.order(:inserted_at, :desc)
    |> NexBase.limit(1)
    |> NexBase.run()

    task_item(%{task: task})
  end

  # Toggle task completion
  def toggle(%{"id" => id}) do
    id = String.to_integer(id)

    # Get current task
    {:ok, [task]} = @client
    |> NexBase.from("tasks")
    |> NexBase.eq(:id, id)
    |> NexBase.run()

    # Toggle completed status
    @client
    |> NexBase.from("tasks")
    |> NexBase.eq(:id, id)
    |> NexBase.update(%{completed: !task["completed"]})
    |> NexBase.run()

    # Get updated task
    {:ok, [updated_task]} = @client
    |> NexBase.from("tasks")
    |> NexBase.eq(:id, id)
    |> NexBase.run()

    task_item(%{task: updated_task})
  end

  # Delete task
  def delete(%{"id" => id}) do
    id = String.to_integer(id)

    @client
    |> NexBase.from("tasks")
    |> NexBase.eq(:id, id)
    |> NexBase.delete()
    |> NexBase.run()

    :empty
  end

  # Private component for task item
  defp task_item(assigns) do
    ~H"""
    <div
      id={"task-#{@task["id"]}"}
      class="flex items-center gap-3 p-4 bg-base-200 rounded-lg hover:bg-base-300 transition"
    >
      <!-- Checkbox -->
      <input
        type="checkbox"
        checked={@task["completed"]}
        hx-post={"/tasks/toggle?id=#{@task["id"]}"}
        hx-target={"#task-#{@task["id"]}"}
        hx-swap="outerHTML"
        class="checkbox checkbox-primary"
      />

      <!-- Task Title -->
      <span class={"flex-1 #{if @task["completed"], do: "line-through text-base-content/50"}"}>
        <%= @task["title"] %>
      </span>

      <!-- Delete Button -->
      <button
        hx-post={"/tasks/delete?id=#{@task["id"]}"}
        hx-target={"#task-#{@task["id"]}"}
        hx-swap="outerHTML"
        hx-confirm="Are you sure you want to delete this task?"
        class="btn btn-ghost btn-sm btn-circle"
      >
        🗑️
      </button>
    </div>
    """
  end
end
