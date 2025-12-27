defmodule DynamicRoutes.Pages.Index do
  use Nex.Page

  def mount(_params) do
    %{
      title: "动态路由示例"
    }
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-8">
      <div>
        <h1 class="text-3xl font-bold text-gray-800 mb-4">动态路由示例</h1>
        <p class="text-gray-600">展示 Nex 框架的动态路由能力</p>
      </div>

      <div class="grid md:grid-cols-2 gap-6">
        <!-- 用户相关路由 -->
        <div class="bg-white rounded-lg p-6 shadow">
          <h2 class="text-xl font-semibold mb-4">用户路由</h2>
          <div class="space-y-3">
            <div>
              <code class="text-sm bg-gray-100 px-2 py-1 rounded">src/pages/users/[id].ex</code>
              <p class="text-sm text-gray-600 mt-1">匹配: /users/123, /users/456</p>
              <a href="/users/1" class="text-blue-600 hover:underline text-sm">→ 查看用户 1</a>
            </div>
            <div>
              <code class="text-sm bg-gray-100 px-2 py-1 rounded">src/pages/users/[id]/profile.ex</code>
              <p class="text-sm text-gray-600 mt-1">匹配: /users/123/profile</p>
              <a href="/users/1/profile" class="text-blue-600 hover:underline text-sm">→ 查看用户 1 资料</a>
            </div>
          </div>
        </div>

        <!-- 文章相关路由 -->
        <div class="bg-white rounded-lg p-6 shadow">
          <h2 class="text-xl font-semibold mb-4">文章路由</h2>
          <div class="space-y-3">
            <div>
              <code class="text-sm bg-gray-100 px-2 py-1 rounded">src/pages/posts/[slug].ex</code>
              <p class="text-sm text-gray-600 mt-1">匹配: /posts/hello-world, /posts/my-first-post</p>
              <a href="/posts/hello-world" class="text-blue-600 hover:underline text-sm">→ 查看 "hello-world"</a>
            </div>
            <div>
              <code class="text-sm bg-gray-100 px-2 py-1 rounded">src/pages/posts/[year]/[month].ex</code>
              <p class="text-sm text-gray-600 mt-1">匹配: /posts/2024/12</p>
              <a href="/posts/2024/12" class="text-blue-600 hover:underline text-sm">→ 查看 2024年12月</a>
            </div>
          </div>
        </div>

        <!-- 通配符路由 -->
        <div class="bg-white rounded-lg p-6 shadow">
          <h2 class="text-xl font-semibold mb-4">通配符路由</h2>
          <div class="space-y-3">
            <div>
              <code class="text-sm bg-gray-100 px-2 py-1 rounded">src/pages/docs/[...path].ex</code>
              <p class="text-sm text-gray-600 mt-1">匹配: /docs/* (任意层级)</p>
              <a href="/docs/getting-started/install" class="text-blue-600 hover:underline text-sm">→ 查看文档</a>
            </div>
            <div>
              <code class="text-sm bg-gray-100 px-2 py-1 rounded">src/pages/files/[category]/[...path].ex</code>
              <p class="text-sm text-gray-600 mt-1">匹配: /files/images/2024/12/photo.jpg</p>
              <a href="/files/images/2024/12/holiday.jpg" class="text-blue-600 hover:underline text-sm">→ 查看文件路径</a>
            </div>
          </div>
        </div>

        <!-- API 路由 -->
        <div class="bg-white rounded-lg p-6 shadow">
          <h2 class="text-xl font-semibold mb-4">API 路由</h2>
          <div class="space-y-3">
            <div>
              <code class="text-sm bg-gray-100 px-2 py-1 rounded">src/api/users/[id].ex</code>
              <p class="text-sm text-gray-600 mt-1">API: GET /api/users/123</p>
              <button
                hx-get="/api/users/1"
                hx-target="#api-result"
                class="bg-blue-500 text-white px-3 py-1 rounded text-sm hover:bg-blue-600">
                测试 API
              </button>
              <div id="api-result" class="mt-2"></div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
