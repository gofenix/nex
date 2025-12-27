defmodule DynamicRoutes.Pages.Users.Id.Profile do
  use Nex.Page

  def mount(%{"id" => id}) do
    %{
      title: "用户资料 - #{id}",
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
        <a href={"/users/#{@id}"} class="hover:text-gray-700">{@id}</a>
        <span class="mx-2">/</span>
        <span>profile</span>
      </nav>

      <div class="bg-white rounded-lg p-6 shadow">
        <h1 class="text-2xl font-bold mb-6">{@user.name} 的详细资料</h1>

        <div class="bg-gray-50 p-4 rounded mb-6">
          <h3 class="font-mono text-sm mb-2">嵌套路由解析</h3>
          <p class="text-sm text-gray-600">展示了多层动态路由的支持</p>
        </div>

        <div class="grid md:grid-cols-3 gap-6">
          <div class="md:col-span-2 space-y-6">
            <div>
              <h3 class="font-semibold text-gray-700 mb-3">个人信息</h3>
              <div class="space-y-3">
                <div class="flex justify-between py-2 border-b">
                  <span class="text-gray-500">姓名</span>
                  <span>{@user.name}</span>
                </div>
                <div class="flex justify-between py-2 border-b">
                  <span class="text-gray-500">邮箱</span>
                  <span>{@user.email}</span>
                </div>
                <div class="flex justify-between py-2 border-b">
                  <span class="text-gray-500">年龄</span>
                  <span>{@user.age}岁</span>
                </div>
                <div class="flex justify-between py-2 border-b">
                  <span class="text-gray-500">城市</span>
                  <span>{@user.city}</span>
                </div>
                <div class="flex justify-between py-2 border-b">
                  <span class="text-gray-500">注册时间</span>
                  <span>2024-01-15</span>
                </div>
              </div>
            </div>

            <div>
              <h3 class="font-semibold text-gray-700 mb-3">个人简介</h3>
              <p class="text-gray-600">
                这是 {@user.name} 的个人简介。{@user.name} 是一个热爱编程的开发者，
                专注于 Elixir 和 Phoenix 框架。在 {@user.city} 工作和生活。
              </p>
            </div>
          </div>

          <div>
            <div class="bg-blue-50 p-4 rounded">
              <h3 class="font-semibold text-blue-800 mb-2">路由信息</h3>
              <div class="space-y-2 text-sm">
                <div>
                  <span class="text-blue-600">文件:</span>
                  <br>
                  <code class="text-xs">users/[id]/profile.ex</code>
                </div>
                <div>
                  <span class="text-blue-600">URL:</span>
                  <br>
                  <code class="text-xs">/users/{@id}/profile</code>
                </div>
                <div>
                  <span class="text-blue-600">参数:</span>
                  <br>
                  <code class="text-xs">{@params_display}</code>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # 复用用户查找函数
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
