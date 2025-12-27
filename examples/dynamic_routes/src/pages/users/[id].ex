defmodule DynamicRoutes.Pages.Users.Id do
  use Nex.Page

  def mount(%{"id" => id}) do
    %{
      title: "用户详情 - #{id}",
      id: id,
      user: find_user(id),
      params_display: ~s(%{"id" => "#{id}"})
    }
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <nav class="text-sm text-gray-500">
        <a href="/" class="hover:text-gray-700">首页</a>
        <span class="mx-2">/</span>
        <a href="/users" class="hover:text-gray-700">用户</a>
        <span class="mx-2">/</span>
        <span>{@id}</span>
      </nav>

      <div class="bg-white rounded-lg p-6 shadow">
        <div class="flex items-center space-x-4 mb-6">
          <div class="w-16 h-16 bg-blue-500 rounded-full flex items-center justify-center text-white text-2xl font-bold">
            {String.upcase(String.first(@user.name))}
          </div>
          <div>
            <h1 class="text-2xl font-bold">{@user.name}</h1>
            <p class="text-gray-600">{@user.email}</p>
          </div>
        </div>

        <div class="grid md:grid-cols-2 gap-4">
          <div>
            <h3 class="font-semibold text-gray-700 mb-2">基本信息</h3>
            <dl class="space-y-1">
              <div class="flex justify-between">
                <dt class="text-gray-500">ID:</dt>
                <dd>{@user.id}</dd>
              </div>
              <div class="flex justify-between">
                <dt class="text-gray-500">年龄:</dt>
                <dd>{@user.age}岁</dd>
              </div>
              <div class="flex justify-between">
                <dt class="text-gray-500">城市:</dt>
                <dd>{@user.city}</dd>
              </div>
            </dl>
          </div>

          <div>
            <h3 class="font-semibold text-gray-700 mb-2">操作</h3>
            <div class="space-y-2">
              <a href={"/users/#{@id}/profile"}
                 class="block bg-blue-500 text-white px-4 py-2 rounded text-center hover:bg-blue-600">
                查看详细资料
              </a>
              <button
                hx-post={"/users/#{@id}/follow"}
                hx-target="#follow-btn"
                class="w-full bg-green-500 text-white px-4 py-2 rounded hover:bg-green-600">
                关注
              </button>
            </div>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-lg p-6 shadow">
        <h2 class="text-xl font-semibold mb-4">动态路由解析</h2>
        <div class="bg-gray-50 p-4 rounded">
          <h3 class="font-mono text-sm mb-2">文件路径:</h3>
          <code class="text-sm">src/pages/users/[id].ex</code>

          <h3 class="font-mono text-sm mt-4 mb-2">URL 匹配:</h3>
          <code class="text-sm">/users/{@id}</code>

          <h3 class="font-mono text-sm mt-4 mb-2">参数提取:</h3>
          <pre class="text-sm bg-white p-2 rounded mt-2">{@params_display}</pre>
        </div>
      </div>
    </div>
    """
  end

  def follow(%{"id" => id}) do
    # 模拟关注操作
    :timer.sleep(500)  # 模拟延迟

    assigns = %{id: id}
    ~H"""
    <button class="w-full bg-gray-500 text-white px-4 py-2 rounded cursor-not-allowed" disabled>
      已关注
    </button>
    """
  end

  # 模拟用户数据
  defp find_user(id) do
    users = %{
      "1" => %{id: "1", name: "张三", email: "zhangsan@example.com", age: 28, city: "北京"},
      "2" => %{id: "2", name: "李四", email: "lisi@example.com", age: 32, city: "上海"},
      "3" => %{id: "3", name: "王五", email: "wangwu@example.com", age: 25, city: "深圳"}
    }

    Map.get(users, id, %{
      id: id,
      name: "未知用户",
      email: "unknown@example.com",
      age: 0,
      city: "未知"
    })
  end
end
