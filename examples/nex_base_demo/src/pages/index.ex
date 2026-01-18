defmodule NexBaseDemo.Pages.Index do
  use Nex

  def mount(_params) do
    %{
      title: "NexBase Demo"
    }
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="card bg-base-100 shadow">
        <div class="card-body">
          <h2 class="card-title">NexBase + Nex Demo</h2>
          <p class="text-base-content/70">演示 Nex Web 框架与 NexBase 数据库的集成</p>
        </div>
      </div>

      <div class="card bg-base-100 shadow">
        <div class="card-body">
          <h2 class="card-title">创建任务</h2>
          <form hx-post="/api/tasks" hx-target="#task-list" class="flex gap-2">
            <input type="text" name="title" placeholder="输入任务标题" class="input input-bordered w-full" required />
            <button type="submit" class="btn btn-primary">添加</button>
          </form>
        </div>
      </div>

      <div class="card bg-base-100 shadow">
        <div class="card-body">
          <h2 class="card-title">任务列表</h2>
          <div id="task-list" class="space-y-2">
            <div class="text-center py-4 text-base-content/50">加载中...</div>
          </div>
        </div>
      </div>

      <div class="card bg-base-100 shadow">
        <div class="card-body">
          <h2 class="card-title">数据库验证</h2>
          <div class="flex gap-2">
            <button hx-get="/api/db/verify" hx-target="#db-status" class="btn btn-outline btn-sm">
              验证连接
            </button>
          </div>
          <div id="db-status" class="mt-2 text-sm"></div>
        </div>
      </div>
    </div>
    """
  end
end

defmodule NexBaseDemo.Api.Tasks do
  use Nex

  def get(_req) do
    list_tasks()
  end

  def post(req) do
    title = req.body["title"]

    if title && title != "" do
      NexBase.from("tasks")
      |> NexBase.insert(%{title: title, completed: false})
      |> NexBase.run()
    end

    list_tasks()
  end

  def patch(req, id) do
    completed = req.body["completed"] == "true"

    NexBase.from("tasks")
    |> NexBase.eq(:id, String.to_integer(id))
    |> NexBase.update(%{completed: completed, updated_at: DateTime.utc_now() |> DateTime.to_iso8601()})
    |> NexBase.run()

    list_tasks()
  end

  def delete(_req, id) do
    NexBase.from("tasks")
    |> NexBase.eq(:id, String.to_integer(id))
    |> NexBase.delete()
    |> NexBase.run()

    Nex.html("")
  end

  defp list_tasks do
    {:ok, tasks} =
      NexBase.from("tasks")
      |> NexBase.order(:inserted_at, :desc)
      |> NexBase.limit(20)
      |> NexBase.select([:id, :title, :completed, :inserted_at])
      |> NexBase.run()

    if Enum.empty?(tasks) do
      Nex.html("<div class='text-center py-4 text-base-content/50'>暂无任务，点击上方按钮添加</div>")
    else
      html = Enum.map(tasks, fn task ->
        task_div_id = "task-#{task.id}"
        completed_class = if(task.completed, do: "opacity-50", else: "")
        strike_class = if(task.completed, do: "line-through", else: "")
        checked_attr = if(task.completed, do: "checked", else: "")

        """
        <div id="#{task_div_id}" class="flex items-center justify-between p-3 bg-base-200 rounded-lg #{completed_class}">
          <div class="flex items-center gap-2">
            <input type="checkbox"
                   hx-patch="/api/tasks/#{task.id}"
                   hx-target="##{task_div_id}"
                   hx-swap="outerHTML"
                   #{checked_attr}
                   class="checkbox checkbox-sm" />
            <span class="#{strike_class}">#{task.title}</span>
          </div>
          <button hx-delete="/api/tasks/#{task.id}"
                  hx-target="##{task_div_id}"
                  hx-swap="outerHTML"
                  class="btn btn-ghost btn-xs text-error">
            删除
          </button>
        </div>
        """
      end) |> Enum.join("")

      Nex.html(html)
    end
  end
end

defmodule NexBaseDemo.Api.DBVerify do
  use Nex

  def get(_req) do
    try do
      result = NexBase.query!("SELECT version()", [])
      [[version]] = result.rows
      Nex.html("<span class='text-success'>✓ 数据库连接成功</span><br/><code class='text-xs'>#{version}</code>")
    rescue
      e ->
        Nex.html("<span class='text-error'>✗ 连接失败: #{inspect(e)}</span>")
    end
  end
end
