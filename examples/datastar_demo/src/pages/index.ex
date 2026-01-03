defmodule DatastarDemo.Pages.Index do
  use Nex

  def mount(_params) do
    %{
      title: "Counter - Datastar Demo",
      count: Nex.Store.get(:count, 0)
    }
  end

  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow p-8 max-w-md mx-auto">
      <h2 class="text-3xl font-bold text-gray-800 mb-6">Counter Demo</h2>

      <div class="mb-6">
        <h3 class="text-lg font-semibold text-gray-700 mb-2">特性 1: 后端驱动更新</h3>
        <p class="text-sm text-gray-600 mb-4">使用 Datastar 的 @post() 发送请求，后端返回 HTML 片段</p>

        <div class="text-center">
          <div id="counter-display" class="text-6xl font-bold text-blue-600 mb-6">
            {@count}
          </div>

          <div class="flex gap-2 justify-center">
            <button
              data-on:click="@post('/decrement')"
              class="px-6 py-3 bg-red-500 text-white rounded-lg hover:bg-red-600 transition">
              -
            </button>

            <button
              data-on:click="@post('/reset')"
              class="px-6 py-3 bg-gray-500 text-white rounded-lg hover:bg-gray-600 transition">
              Reset
            </button>

            <button
              data-on:click="@post('/increment')"
              class="px-6 py-3 bg-green-500 text-white rounded-lg hover:bg-green-600 transition">
              +
            </button>
          </div>
        </div>
      </div>

      <div class="border-t pt-6">
        <h3 class="text-lg font-semibold text-gray-700 mb-2">特性 2: 前端信号（响应性）</h3>
        <p class="text-sm text-gray-600 mb-4">无需后端请求，纯前端响应式更新</p>

        <div data-signals="{localCount: 0}" class="text-center">
          <div class="text-4xl font-bold text-purple-600 mb-4">
            <span data-text="$localCount"></span>
          </div>

          <div class="flex gap-2 justify-center">
            <button
              data-on:click="$localCount--"
              class="px-4 py-2 bg-purple-500 text-white rounded hover:bg-purple-600 transition">
              - (前端)
            </button>

            <button
              data-on:click="$localCount = 0"
              class="px-4 py-2 bg-gray-500 text-white rounded hover:bg-gray-600 transition">
              Reset (前端)
            </button>

            <button
              data-on:click="$localCount++"
              class="px-4 py-2 bg-purple-500 text-white rounded hover:bg-purple-600 transition">
              + (前端)
            </button>
          </div>
        </div>
      </div>

      <div class="mt-6 p-4 bg-blue-50 rounded">
        <p class="text-sm text-gray-700">
          <strong>对比：</strong><br>
          上面的计数器每次点击都会发送请求到后端<br>
          下面的计数器完全在前端运行，无需后端
        </p>
      </div>
    </div>
    """
  end

  def increment(_params) do
    count = Nex.Store.update(:count, 0, &(&1 + 1))
    assigns = %{count: count}
    ~H"""
    <div id="counter-display" class="text-6xl font-bold text-blue-600 mb-6">
      {@count}
    </div>
    """
  end

  def decrement(_params) do
    count = Nex.Store.update(:count, 0, &(&1 - 1))
    assigns = %{count: count}
    ~H"""
    <div id="counter-display" class="text-6xl font-bold text-blue-600 mb-6">
      {@count}
    </div>
    """
  end

  def reset(_params) do
    Nex.Store.put(:count, 0)
    assigns = %{count: 0}
    ~H"""
    <div id="counter-display" class="text-6xl font-bold text-blue-600 mb-6">
      {@count}
    </div>
    """
  end
end
