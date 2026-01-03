defmodule DatastarDemo.Pages.Advanced do
  use Nex

  def mount(_params) do
    %{
      title: "Advanced Features - Datastar Demo"
    }
  end

  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow p-8 max-w-3xl mx-auto">
      <h2 class="text-3xl font-bold text-gray-800 mb-6">Advanced Datastar Features</h2>

      <div class="space-y-8">
        <div class="border-b pb-6">
          <h3 class="text-xl font-semibold text-gray-700 mb-3">特性 6: data-init - 页面加载时执行</h3>
          <p class="text-sm text-gray-600 mb-4">使用 data-init 在元素加载时自动发送请求</p>

          <div
            id="init-content"
            data-init="@get('/advanced/load_data')"
            class="p-4 bg-gray-50 rounded-lg">
            <p class="text-gray-500">加载中...</p>
          </div>

          <div class="mt-4 p-3 bg-blue-50 rounded text-sm text-gray-700">
            <strong>用途：</strong>CQRS 模式 - 页面加载时建立长连接，持续接收后端更新
          </div>
        </div>

        <div class="border-b pb-6">
          <h3 class="text-xl font-semibold text-gray-700 mb-3">特性 7: data-on-intersect - 懒加载</h3>
          <p class="text-sm text-gray-600 mb-4">元素进入视口时触发加载（无限滚动）</p>

          <div class="space-y-4">
            <div :for={i <- 1..3} class="p-4 bg-gray-100 rounded">
              项目 {i}
            </div>

            <div
              id="lazy-trigger"
              data-on-intersect="@get('/advanced/load_more')"
              class="p-4 bg-yellow-50 rounded border-2 border-yellow-300">
              <p class="text-center text-gray-600">👇 滚动到这里加载更多</p>
            </div>

            <div id="lazy-content"></div>
          </div>

          <div class="mt-4 p-3 bg-blue-50 rounded text-sm text-gray-700">
            <strong>用途：</strong>无限滚动、图片懒加载、性能优化
          </div>
        </div>

        <div class="border-b pb-6">
          <h3 class="text-xl font-semibold text-gray-700 mb-3">特性 8: data-effect - 响应式副作用</h3>
          <p class="text-sm text-gray-600 mb-4">当信号变化时自动执行代码</p>

          <div data-signals="{temperature: 20}">
            <div class="flex items-center gap-4 mb-4">
              <label class="text-gray-700">温度：</label>
              <input
                type="range"
                data-bind:temperature
                min="0"
                max="40"
                class="flex-1"
              />
              <span class="text-2xl font-bold" data-text="$temperature + '°C'"></span>
            </div>

            <div
              data-effect="console.log('Temperature changed:', $temperature)"
              data-class:bg-blue-100="$temperature < 15"
              data-class:bg-green-100="$temperature >= 15 && $temperature < 25"
              data-class:bg-red-100="$temperature >= 25"
              class="p-4 rounded-lg transition-colors">
              <p data-show="$temperature < 15" class="text-blue-800">🥶 太冷了</p>
              <p data-show="$temperature >= 15 && $temperature < 25" class="text-green-800">😊 温度适宜</p>
              <p data-show="$temperature >= 25" class="text-red-800">🥵 太热了</p>
            </div>
          </div>

          <div class="mt-4 p-3 bg-blue-50 rounded text-sm text-gray-700">
            <strong>用途：</strong>日志记录、分析追踪、复杂的响应式逻辑
          </div>
        </div>

        <div class="border-b pb-6">
          <h3 class="text-xl font-semibold text-gray-700 mb-3">特性 9: data-ref - 元素引用</h3>
          <p class="text-sm text-gray-600 mb-4">获取 DOM 元素引用，用于复杂操作</p>

          <div data-signals="{message: ''}">
            <textarea
              data-ref="messageInput"
              data-bind:message
              placeholder="输入消息..."
              class="w-full p-3 border rounded-lg mb-2"
              rows="3">
            </textarea>

            <div class="flex gap-2">
              <button
                data-on:click="$refs.messageInput.focus()"
                class="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600">
                聚焦输入框
              </button>
              <button
                data-on:click="$message = ''; $refs.messageInput.focus()"
                class="px-4 py-2 bg-gray-500 text-white rounded hover:bg-gray-600">
                清空并聚焦
              </button>
            </div>

            <p class="mt-2 text-sm text-gray-600">
              字符数：<span data-text="$message.length"></span>
            </p>
          </div>

          <div class="mt-4 p-3 bg-blue-50 rounded text-sm text-gray-700">
            <strong>用途：</strong>直接操作 DOM、集成第三方库、复杂交互
          </div>
        </div>

        <div class="border-b pb-6">
          <h3 class="text-xl font-semibold text-gray-700 mb-3">特性 10: data-indicator - 加载指示器</h3>
          <p class="text-sm text-gray-600 mb-4">请求进行时自动显示加载状态</p>

          <div>
            <button
              data-on:click="@post('/advanced/slow_operation')"
              class="px-6 py-3 bg-purple-500 text-white rounded-lg hover:bg-purple-600">
              执行慢操作（3秒）
            </button>

            <div
              data-indicator
              class="hidden mt-4 p-4 bg-purple-50 border border-purple-200 rounded-lg">
              <div class="flex items-center gap-3">
                <div class="animate-spin w-6 h-6 border-4 border-purple-500 border-t-transparent rounded-full"></div>
                <span class="text-purple-800">处理中，请稍候...</span>
              </div>
            </div>

            <div id="operation-result" class="mt-4"></div>
          </div>

          <div class="mt-4 p-3 bg-blue-50 rounded text-sm text-gray-700">
            <strong>用途：</strong>自动显示/隐藏加载状态，无需手动管理
          </div>
        </div>

        <div>
          <h3 class="text-xl font-semibold text-gray-700 mb-3">特性 11: data-style - 动态样式</h3>
          <p class="text-sm text-gray-600 mb-4">根据信号动态设置内联样式</p>

          <div data-signals="{size: 16, color: '#3b82f6'}">
            <div class="space-y-4">
              <div>
                <label class="block text-gray-700 mb-2">字体大小：<span data-text="$size + 'px'"></span></label>
                <input
                  type="range"
                  data-bind:size
                  min="12"
                  max="48"
                  class="w-full"
                />
              </div>

              <div>
                <label class="block text-gray-700 mb-2">颜色</label>
                <input
                  type="color"
                  data-bind:color
                  class="w-20 h-10 rounded cursor-pointer"
                />
              </div>

              <div
                data-style:font-size="$size + 'px'"
                data-style:color="$color"
                class="p-4 bg-gray-50 rounded-lg font-bold">
                动态样式文本
              </div>
            </div>
          </div>

          <div class="mt-4 p-3 bg-blue-50 rounded text-sm text-gray-700">
            <strong>用途：</strong>主题切换、动画、可视化编辑器
          </div>
        </div>
      </div>

      <div class="mt-8 p-6 bg-gradient-to-r from-blue-50 to-purple-50 rounded-lg">
        <h3 class="text-lg font-bold text-gray-800 mb-3">🎯 Datastar Tao 哲学要点</h3>
        <ul class="space-y-2 text-sm text-gray-700">
          <li>✓ <strong>后端为真理源</strong> - 状态应该在后端管理</li>
          <li>✓ <strong>少用 signals</strong> - 仅用于用户交互和发送数据到后端</li>
          <li>✓ <strong>使用 morphing</strong> - 发送大块 DOM，让 Datastar 智能更新</li>
          <li>✓ <strong>优先 SSE</strong> - 使用 text/event-stream 进行后端推送</li>
          <li>✓ <strong>压缩流</strong> - 使用 Brotli 压缩 SSE 响应</li>
          <li>✓ <strong>保持 DRY</strong> - 使用模板语言复用代码</li>
          <li>✓ <strong>使用锚点导航</strong> - 用 &lt;a&gt; 标签，不要自己管理路由</li>
        </ul>
      </div>
    </div>
    """
  end

  def load_data(_params) do
    Process.sleep(500)
    time = format_time()
    assigns = %{time: time}

    ~H"""
    <div id="init-content" class="p-4 bg-green-50 rounded-lg">
      <p class="text-green-800">✓ 数据加载成功！（通过 data-init）</p>
      <p class="text-sm text-gray-600 mt-2">当前时间：{@time}</p>
    </div>
    """
  end

  def load_more(_params) do
    items = Nex.Store.get(:lazy_items, 3)
    new_items = items + 3
    Nex.Store.put(:lazy_items, new_items)

    assigns = %{items: items, new_items: new_items}

    ~H"""
    <div :for={i <- (@items + 1)..@new_items} class="p-4 bg-gray-100 rounded">
      项目 {i}（懒加载）
    </div>
    """
  end

  def slow_operation(_params) do
    Process.sleep(3000)
    assigns = %{}

    ~H"""
    <div id="operation-result" class="p-4 bg-green-50 border border-green-200 rounded-lg">
      <p class="text-green-800">✓ 操作完成！</p>
    </div>
    """
  end

  defp format_time do
    {{year, month, day}, {hour, minute, second}} = :erlang.localtime()
    "#{year}-#{pad(month)}-#{pad(day)} #{pad(hour)}:#{pad(minute)}:#{pad(second)}"
  end

  defp pad(n) when n < 10, do: "0#{n}"
  defp pad(n), do: "#{n}"
end
