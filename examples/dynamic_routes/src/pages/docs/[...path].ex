defmodule DynamicRoutes.Pages.Docs.Path do
  use Nex.Page

  def mount(%{"path" => path}) do
    path_string = Enum.join(path, "/")
    content = get_doc_content(path_string)

    %{
      title: "文档 - #{path_string || "首页"}",
      path: path,
      path_string: path_string,
      content: content,
      params_display: ~s(%{"path" => #{inspect(path)}})
    }
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <nav class="text-sm text-gray-500">
        <a href="/" class="hover:text-gray-700">首页</a>
        <span class="mx-2">/</span>
        <span>文档</span>
        <span class="mx-2">/</span>
        <span>{@path_string || "首页"}</span>
      </nav>

      <div class="bg-white rounded-lg p-6 shadow">
        <h1 class="text-2xl font-bold mb-4">文档: {@path_string || "首页"}</h1>

        <div class="bg-yellow-50 border border-yellow-200 p-4 rounded mb-6">
          <h3 class="font-semibold text-yellow-800 mb-2">⚠️ 通配符路由示例</h3>
          <p class="text-sm text-yellow-700">
            这个页面使用 <code class="bg-yellow-100 px-1">[...path]</code> 通配符路由，
            可以匹配任意层级的路径。
          </p>
        </div>

        <div class="prose max-w-none">
          <div class="bg-gray-50 p-4 rounded mb-6">
            <h3 class="font-mono text-sm mb-2">路由解析</h3>
            <div class="space-y-2 text-sm">
              <div>
                <span class="text-gray-600">文件路径:</span>
                <br>
                <code class="text-xs">docs/[...path].ex</code>
              </div>
              <div>
                <span class="text-gray-600">匹配示例:</span>
                <br>
                <code class="text-xs">/docs/getting-started</code><br>
                <code class="text-xs">/docs/api/users</code><br>
                <code class="text-xs">/docs/tutorials/basics/installation</code>
              </div>
              <div>
                <span class="text-gray-600">提取的路径:</span>
                <br>
                <code class="text-xs">path: ["getting-started"]</code><br>
                <code class="text-xs">path: ["api", "users"]</code><br>
                <code class="text-xs">path: ["tutorials", "basics", "installation"]</code>
              </div>
            </div>
          </div>

          <div class="space-y-4">
            <p>
              当前访问的路径是: <code class="bg-gray-100 px-2 py-1 rounded">/{@path_string}</code>
            </p>

            <p>
              提取的路径参数是:
            </p>

            <pre class="bg-gray-100 p-3 rounded text-sm">{@params_display}</pre>

            <div class="mt-6">
              <h2 class="text-xl font-semibold mb-3">文档内容</h2>
              <div class="bg-blue-50 p-4 rounded">
                <p>{@content}</p>
              </div>
            </div>
          </div>
        </div>

        <div class="mt-8">
          <h2 class="text-xl font-semibold mb-4">其他文档页面</h2>
          <div class="grid md:grid-cols-2 gap-4">
            <a href="/docs/getting-started" class="block p-4 border rounded hover:bg-gray-50">
              <h3 class="font-semibold">快速开始</h3>
              <p class="text-sm text-gray-600">5分钟上手 Nex 框架</p>
            </a>
            <a href="/docs/api/overview" class="block p-4 border rounded hover:bg-gray-50">
              <h3 class="font-semibold">API 文档</h3>
              <p class="text-sm text-gray-600">完整的 API 参考</p>
            </a>
            <a href="/docs/tutorials/basics" class="block p-4 border rounded hover:bg-gray-50">
              <h3 class="font-semibold">基础教程</h3>
              <p class="text-sm text-gray-600">从零开始学习</p>
            </a>
            <a href="/docs/advanced/custom-hooks" class="block p-4 border rounded hover:bg-gray-50">
              <h3 class="font-semibold">进阶指南</h3>
              <p class="text-sm text-gray-600">自定义钩子和扩展</p>
            </a>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # 根据路径返回不同的文档内容
  defp get_doc_content(path_string) do
    case path_string do
      nil -> "欢迎来到 Nex 框架文档！选择一个章节开始学习。"
      "getting-started" -> "这是快速开始指南，包含安装、配置和第一个 Hello World 应用。"
      "api" -> "API 文档总览，包含所有可用的函数和模块。"
      "api" <> rest -> "API 文档: #{rest} - 详细的 API 说明和示例。"
      "tutorials" -> "教程集合，从基础到高级的完整学习路径。"
      "tutorials" <> rest -> "教程: #{rest} - 分步骤的实践指南。"
      "advanced" -> "进阶主题，包括性能优化、扩展开发等。"
      "advanced" <> rest -> "进阶: #{rest} - 深入探讨特定主题。"
      _ -> "文档页面: #{path_string} - 内容正在编写中..."
    end
  end
end
