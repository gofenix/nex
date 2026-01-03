defmodule DatastarDemo.Pages.Todos do
  use Nex

  def mount(_params) do
    %{
      title: "Todos - Datastar Demo",
      todos: Nex.Store.get(:todos, [])
    }
  end

  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow p-8 max-w-2xl mx-auto">
      <h2 class="text-3xl font-bold text-gray-800 mb-6">Todo List Demo</h2>

      <div class="mb-6">
        <h3 class="text-lg font-semibold text-gray-700 mb-2">特性 5: 综合示例</h3>
        <p class="text-sm text-gray-600 mb-4">前端验证 + 后端 CRUD + 条件渲染</p>
      </div>

      <div data-signals="{newTodo: '', filter: 'all'}">
        <form data-on:submit.prevent="@post('/todos/create')" class="mb-6 flex gap-2">
          <input
            type="text"
            data-bind:newTodo
            placeholder="新任务..."
            class="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
          <button
            type="submit"
            data-attr:disabled="$newTodo.length < 3"
            class="px-6 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition disabled:bg-gray-300 disabled:cursor-not-allowed">
            添加
          </button>
        </form>

        <div class="mb-4 flex gap-2">
          <button
            data-on:click="$filter = 'all'"
            data-class:bg-blue-500="$filter === 'all'"
            data-class:bg-gray-200="$filter !== 'all'"
            data-class:text-white="$filter === 'all'"
            data-class:text-gray-700="$filter !== 'all'"
            class="px-4 py-2 rounded-lg transition">
            全部
          </button>
          <button
            data-on:click="$filter = 'active'"
            data-class:bg-blue-500="$filter === 'active'"
            data-class:bg-gray-200="$filter !== 'active'"
            data-class:text-white="$filter === 'active'"
            data-class:text-gray-700="$filter !== 'active'"
            class="px-4 py-2 rounded-lg transition">
            进行中
          </button>
          <button
            data-on:click="$filter = 'completed'"
            data-class:bg-blue-500="$filter === 'completed'"
            data-class:bg-gray-200="$filter !== 'completed'"
            data-class:text-white="$filter === 'completed'"
            data-class:text-gray-700="$filter !== 'completed'"
            class="px-4 py-2 rounded-lg transition">
            已完成
          </button>
        </div>

        <ul id="todo-list" class="space-y-2">
          <li :for={todo <- @todos}
              id={"todo-#{todo.id}"}
              data-show="$filter === 'all' || ($filter === 'active' && !#{todo.completed}) || ($filter === 'completed' && #{todo.completed})"
              class="flex items-center gap-3 p-3 bg-gray-50 rounded-lg">
            <input
              type="checkbox"
              checked={todo.completed}
              data-on:change="@post('/todos/toggle?id=#{todo.id}')"
              class="w-5 h-5 text-blue-600 rounded focus:ring-2 focus:ring-blue-500"
            />
            <span class={"flex-1 #{if todo.completed, do: "line-through text-gray-400", else: "text-gray-800"}"}>
              {todo.text}
            </span>
            <button
              data-on:click="@post('/todos/delete?id=#{todo.id}')"
              class="px-3 py-1 text-sm bg-red-500 text-white rounded hover:bg-red-600 transition">
              删除
            </button>
          </li>
        </ul>

        <div :if={length(@todos) == 0} class="text-center text-gray-500 py-10">
          <p>暂无任务，添加一个开始吧！</p>
        </div>

        <div class="mt-6 p-4 bg-blue-50 rounded">
          <p class="text-sm text-gray-700">
            <strong>综合特性展示：</strong><br>
            • 前端验证：至少 3 个字符才能添加<br>
            • 前端过滤：使用信号实现客户端过滤，无需后端<br>
            • 动态样式：<code>data-class</code> 条件应用 CSS 类<br>
            • 条件渲染：<code>data-show</code> 根据过滤器显示/隐藏<br>
            • 后端交互：添加、切换、删除都通过 <code>@post()</code>
          </p>
        </div>
      </div>
    </div>
    """
  end

  def create(req) do
    signals = req.body
    text = signals["newTodo"] || ""

    if String.length(text) >= 3 do
      todo = %{
        id: System.unique_integer([:positive]),
        text: text,
        completed: false
      }

      Nex.Store.update(:todos, [], &[todo | &1])

      assigns = %{todo: todo}
      ~H"""
      <li
        id={"todo-#{@todo.id}"}
        data-show="$filter === 'all' || ($filter === 'active' && !false)"
        class="flex items-center gap-3 p-3 bg-gray-50 rounded-lg">
        <input
          type="checkbox"
          data-on:change="@post('/todos/toggle?id=#{@todo.id}')"
          class="w-5 h-5 text-blue-600 rounded focus:ring-2 focus:ring-blue-500"
        />
        <span class="flex-1 text-gray-800">
          {@todo.text}
        </span>
        <button
          data-on:click="@post('/todos/delete?id=#{@todo.id}')"
          class="px-3 py-1 text-sm bg-red-500 text-white rounded hover:bg-red-600 transition">
          删除
        </button>
      </li>
      """
    else
      Nex.html("")
    end
  end

  def toggle(%{"id" => id}) do
    id = String.to_integer(id)

    Nex.Store.update(:todos, [], fn todos ->
      Enum.map(todos, fn todo ->
        if todo.id == id do
          %{todo | completed: !todo.completed}
        else
          todo
        end
      end)
    end)

    todo = Nex.Store.get(:todos, []) |> Enum.find(&(&1.id == id))

    assigns = %{todo: todo}
    ~H"""
    <li
      id={"todo-#{@todo.id}"}
      data-show="$filter === 'all' || ($filter === 'active' && !#{@todo.completed}) || ($filter === 'completed' && #{@todo.completed})"
      class="flex items-center gap-3 p-3 bg-gray-50 rounded-lg">
      <input
        type="checkbox"
        checked={@todo.completed}
        data-on:change="@post('/todos/toggle?id=#{@todo.id}')"
        class="w-5 h-5 text-blue-600 rounded focus:ring-2 focus:ring-blue-500"
      />
      <span class={"flex-1 #{if @todo.completed, do: "line-through text-gray-400", else: "text-gray-800"}"}>
        {@todo.text}
      </span>
      <button
        data-on:click="@post('/todos/delete?id=#{@todo.id}')"
        class="px-3 py-1 text-sm bg-red-500 text-white rounded hover:bg-red-600 transition">
        删除
      </button>
    </li>
    """
  end

  def delete(%{"id" => id}) do
    id = String.to_integer(id)

    Nex.Store.update(:todos, [], fn todos ->
      Enum.reject(todos, &(&1.id == id))
    end)

    Nex.html("")
  end
end
