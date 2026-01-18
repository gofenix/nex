defmodule NexBaseDemo.Api.Tasks do
  use Nex

  # Initialize NexBase client
  @client NexBase.client(repo: NexBaseDemo.Repo)

  def get(_req) do
    list_tasks()
  end

  def post(req) do
    title = req.body["title"]

    if title && title != "" do
      @client
      |> NexBase.from("tasks")
      |> NexBase.insert(%{title: title, completed: false})
      |> NexBase.run()
    end

    list_tasks()
  end

  def patch(req, id) do
    completed = req.body["completed"] == "true"

    @client
    |> NexBase.from("tasks")
    |> NexBase.eq(:id, String.to_integer(id))
    |> NexBase.update(%{completed: completed})
    |> NexBase.run()

    list_tasks()
  end

  def delete(_req, id) do
    @client
    |> NexBase.from("tasks")
    |> NexBase.eq(:id, String.to_integer(id))
    |> NexBase.delete()
    |> NexBase.run()

    Nex.html("")
  end

  defp list_tasks do
    {:ok, tasks} = @client
    |> NexBase.from("tasks")
    |> NexBase.order(:inserted_at, :desc)
    |> NexBase.limit(20)
    |> NexBase.select([:id, :title, :completed, :inserted_at])
    |> NexBase.run()

    if Enum.empty?(tasks) do
      Nex.html("<div class='text-center py-4 text-base-content/50'>暂无任务</div>")
    else
      html = Enum.map(tasks, fn task ->
        checked = if task["completed"], do: "checked", else: ""
        strike = if task["completed"], do: "line-through", else: ""

        """
        <div id="task-#{task["id"]}" class="flex items-center gap-3 p-3 bg-base-200 rounded-lg">
          <input type="checkbox" #{checked}
                 hx-patch="/api/tasks/#{task["id"]}"
                 hx-vals='{"completed": "#{!task["completed"]}"}'
                 hx-target="#task-#{task["id"]}"
                 class="checkbox checkbox-sm" />
          <span class="flex-1 #{strike}">#{task["title"]}</span>
          <button hx-delete="/api/tasks/#{task["id"]}"
                  hx-target="#task-#{task["id"]}"
                  hx-swap="outerHTML"
                  class="btn btn-ghost btn-xs">🗑️</button>
        </div>
        """
      end) |> Enum.join("")

      Nex.html(html)
    end
  end

  defp ensure_repo_started do
    case NexBaseDemo.Repo.start_link(
      url: System.get_env("DATABASE_URL"),
      pool_size: 10
    ) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end
  end
end
