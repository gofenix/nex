defmodule NexBaseDemo.Pages.Index do
  use Nex

  def mount(_params) do
    # SSR: 直接在服务端加载数据
    {:ok, tasks} = NexBase.from("tasks")
    |> NexBase.order(:inserted_at, :desc)
    |> NexBase.limit(20)
    |> NexBase.run()

    %{
      title: "NexBase Demo",
      tasks: tasks
    }
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="card bg-base-100 shadow">
        <div class="card-body">
          <h2 class="card-title">📝 NexBase + Nex Demo</h2>
          <p class="text-base-content/70">SSR 模式 - 服务端直接渲染数据</p>
        </div>
      </div>

      <div class="card bg-base-100 shadow">
        <div class="card-body">
          <h2 class="card-title">创建任务</h2>
          <form hx-post="/create" hx-target="#task-list" hx-swap="afterbegin" class="flex gap-2">
            <input type="text" name="title" placeholder="输入任务标题" class="input input-bordered w-full" required />
            <button type="submit" class="btn btn-primary">添加</button>
          </form>
        </div>
      </div>

      <div class="card bg-base-100 shadow">
        <div class="card-body">
          <h2 class="card-title">任务列表 (<%= length(@tasks) %>)</h2>
          <div id="task-list" class="space-y-2">
            <%= if @tasks == [] do %>
              <div class="text-center py-4 text-base-content/50">暂无任务</div>
            <% else %>
              <%= for task <- @tasks do %>
                <%= task_item(%{task: task}) %>
              <% end %>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Page Actions (SSR)
  def create(%{"title" => title}) do
    NexBase.from("tasks")
    |> NexBase.insert(%{title: title, completed: false})
    |> NexBase.run()

    # 获取新创建的任务
    {:ok, [task]} = NexBase.from("tasks")
    |> NexBase.order(:inserted_at, :desc)
    |> NexBase.limit(1)
    |> NexBase.run()

    task_item(%{task: task})
  end

  def toggle(%{"id" => id}) do
    id = String.to_integer(id)

    {:ok, [task]} = NexBase.from("tasks")
    |> NexBase.eq(:id, id)
    |> NexBase.run()

    NexBase.from("tasks")
    |> NexBase.eq(:id, id)
    |> NexBase.update(%{completed: !task["completed"]})
    |> NexBase.run()

    {:ok, [updated]} = NexBase.from("tasks")
    |> NexBase.eq(:id, id)
    |> NexBase.run()

    task_item(%{task: updated})
  end

  def delete(%{"id" => id}) do
    NexBase.from("tasks")
    |> NexBase.eq(:id, String.to_integer(id))
    |> NexBase.delete()
    |> NexBase.run()

    :empty
  end

  # Private component
  defp task_item(assigns) do
    ~H"""
    <div id={"task-#{@task["id"]}"} class="flex items-center gap-3 p-3 bg-base-200 rounded-lg">
      <input type="checkbox"
             checked={@task["completed"]}
             hx-post={"/toggle?id=#{@task["id"]}"}
             hx-target={"#task-#{@task["id"]}"}
             hx-swap="outerHTML"
             class="checkbox checkbox-sm" />
      <span class={"flex-1 #{if @task["completed"], do: "line-through text-base-content/50"}"}>
        <%= @task["title"] %>
      </span>
      <button hx-post={"/delete?id=#{@task["id"]}"}
              hx-target={"#task-#{@task["id"]}"}
              hx-swap="outerHTML"
              class="btn btn-ghost btn-xs">🗑️</button>
    </div>
    """
  end
end
