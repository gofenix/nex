defmodule DynamicRoutes.Pages.Files.Category.Path do
  use Nex.Page

  def mount(%{"category" => category, "path" => path}) do
    path_string = Enum.join(path, "/")
    full_path = "#{category}/#{path_string}"

    %{
      title: "文件 - #{full_path}",
      category: category,
      path: path,
      path_string: path_string,
      full_path: full_path,
      file_info: get_file_info(category, path_string),
      params_display: ~s(%{"category" => "#{category}", "path" => #{inspect(path)}})
    }
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <nav class="text-sm text-gray-500">
        <a href="/" class="hover:text-gray-700">首页</a>
        <span class="mx-2">/</span>
        <span>文件</span>
        <span class="mx-2">/</span>
        <span class="text-blue-600">{@category}</span>
        <span class="mx-2">/</span>
        <span>{@path_string}</span>
      </nav>

      <div class="bg-white rounded-lg p-6 shadow">
        <h1 class="text-2xl font-bold mb-4">文件路径: {@full_path}</h1>

        <div class="bg-purple-50 border border-purple-200 p-4 rounded mb-6">
          <h3 class="font-semibold text-purple-800 mb-2">📁 混合路由示例</h3>
          <p class="text-sm text-purple-700">
            展示了固定参数 (<code class="bg-purple-100 px-1">[category]</code>)
            和通配符参数 (<code class="bg-purple-100 px-1">[...path]</code>) 的组合使用
          </p>
        </div>

        <div class="grid md:grid-cols-2 gap-6">
          <div>
            <h3 class="font-semibold mb-3">路径解析</h3>
            <div class="bg-gray-50 p-4 rounded text-sm space-y-2">
              <div>
                <span class="text-gray-600">文件路径:</span>
                <br>
                <code class="text-xs">files/[category]/[...path].ex</code>
              </div>
              <div>
                <span class="text-gray-600">实际 URL:</span>
                <br>
                <code class="text-xs">/files/{@full_path}</code>
              </div>
              <div>
                <span class="text-gray-600">提取参数:</span>
                <br>
                <pre class="text-xs bg-white p-2 rounded mt-1">{@params_display}</pre>
              </div>
            </div>
          </div>

          <div>
            <h3 class="font-semibold mb-3">文件信息</h3>
            <div class="bg-gray-50 p-4 rounded">
              <dl class="space-y-2 text-sm">
                <div class="flex justify-between">
                  <dt class="text-gray-600">类别:</dt>
                  <dd class="font-mono">{@category}</dd>
                </div>
                <div class="flex justify-between">
                  <dt class="text-gray-600">子路径:</dt>
                  <dd class="font-mono">{@path_string || "（根目录）"}</dd>
                </div>
                <div class="flex justify-between">
                  <dt class="text-gray-600">文件类型:</dt>
                  <dd>{@file_info.type}</dd>
                </div>
                <div class="flex justify-between">
                  <dt class="text-gray-600">大小:</dt>
                  <dd>{@file_info.size}</dd>
                </div>
                <div class="flex justify-between">
                  <dt class="text-gray-600">修改时间:</dt>
                  <dd>{@file_info.modified}</dd>
                </div>
              </dl>
            </div>
          </div>
        </div>

        <div class="mt-6">
          <h3 class="font-semibold mb-3">使用场景</h3>
          <div class="bg-blue-50 p-4 rounded">
            <p class="text-sm text-gray-700 mb-3">
              这种混合路由模式非常适合文件管理、资源组织等场景：
            </p>
            <ul class="list-disc pl-5 text-sm text-gray-700 space-y-1">
              <li><strong>图片库:</strong> /files/images/2024/12/holiday.jpg</li>
              <li><strong>文档管理:</strong> /files/docs/project/spec.pdf</li>
              <li><strong>媒体资源:</strong> /files/videos/tutorials/lesson1.mp4</li>
              <li><strong>用户上传:</strong> /files/uploads/user123/avatar.png</li>
            </ul>
          </div>
        </div>

        <div class="mt-8">
          <h3 class="font-semibold mb-4">其他文件路径示例</h3>
          <div class="grid md:grid-cols-3 gap-3">
            <a href="/files/images/2024/12/holiday.jpg" class="block p-3 border rounded hover:bg-gray-50 text-sm">
              <code class="text-xs">images/2024/12/holiday.jpg</code>
              <p class="text-gray-600 mt-1">图片文件</p>
            </a>
            <a href="/files/documents/contracts/agreement.pdf" class="block p-3 border rounded hover:bg-gray-50 text-sm">
              <code class="text-xs">documents/contracts/agreement.pdf</code>
              <p class="text-gray-600 mt-1">PDF 文档</p>
            </a>
            <a href="/files/videos/tutorials/intro.mp4" class="block p-3 border rounded hover:bg-gray-50 text-sm">
              <code class="text-xs">videos/tutorials/intro.mp4</code>
              <p class="text-gray-600 mt-1">视频文件</p>
            </a>
            <a href="/files/code/elixir/project.ex" class="block p-3 border rounded hover:bg-gray-50 text-sm">
              <code class="text-xs">code/elixir/project.ex</code>
              <p class="text-gray-600 mt-1">源代码</p>
            </a>
            <a href="/files/archives/backup.zip" class="block p-3 border rounded hover:bg-gray-50 text-sm">
              <code class="text-xs">archives/backup.zip</code>
              <p class="text-gray-600 mt-1">压缩文件</p>
            </a>
            <a href="/files/config/settings.json" class="block p-3 border rounded hover:bg-gray-50 text-sm">
              <code class="text-xs">config/settings.json</code>
              <p class="text-gray-600 mt-1">配置文件</p>
            </a>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # 模拟获取文件信息
  defp get_file_info(category, path_string) do
    extension = path_string
    |> String.split(".")
    |> List.last()
    |> String.downcase()

    type = case extension do
      ext when ext in ["jpg", "jpeg", "png", "gif", "webp"] -> "图片"
      ext when ext in ["pdf", "doc", "docx"] -> "文档"
      ext when ext in ["mp4", "avi", "mov"] -> "视频"
      ext when ext in ["mp3", "wav", "flac"] -> "音频"
      ext when ext in ["zip", "rar", "7z"] -> "压缩包"
      ext when ext in ["ex", "exs", "py", "js"] -> "代码"
      ext when ext in ["json", "yaml", "xml"] -> "配置"
      _ -> "文件"
    end

    size = case extension do
      ext when ext in ["jpg", "jpeg", "png"] -> "2.5 MB"
      ext when ext in ["pdf"] -> "1.2 MB"
      ext when ext in ["mp4"] -> "125.8 MB"
      ext when ext in ["zip"] -> "45.3 MB"
      ext when ext in ["ex", "exs"] -> "12 KB"
      ext when ext in ["json"] -> "4 KB"
      _ -> "未知"
    end

    %{
      type: type,
      size: size,
      modified: "2024-12-20 14:30"
    }
  end
end
