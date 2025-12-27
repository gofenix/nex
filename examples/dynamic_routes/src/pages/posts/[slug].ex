defmodule DynamicRoutes.Pages.Posts.Slug do
  use Nex.Page

  def mount(%{"slug" => slug}) do
    %{
      title: "文章 - #{slug}",
      slug: slug,
      post: find_post(slug),
      params_display: ~s(%{"slug" => "#{slug}"})
    }
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <nav class="text-sm text-gray-500">
        <a href="/" class="hover:text-gray-700">首页</a>
        <span class="mx-2">/</span>
        <a href="/posts" class="hover:text-gray-700">文章</a>
        <span class="mx-2">/</span>
        <span>{@slug}</span>
      </nav>

      <article class="bg-white rounded-lg p-6 shadow">
        <header class="mb-6">
          <h1 class="text-3xl font-bold mb-2">{@post.title}</h1>
          <div class="flex items-center text-sm text-gray-500 space-x-4">
            <span>作者: {@post.author}</span>
            <span>发布于: {@post.date}</span>
            <span>阅读量: {@post.views}</span>
          </div>
        </header>

        <div class="prose max-w-none">
          <p class="text-lg text-gray-700 mb-4">{@post.excerpt}</p>

          <div class="space-y-4">
            <p>
              这是一篇关于 {@post.topic} 的文章。文章的 slug 是 {@slug}，
              它是一个对 SEO 友好的 URL 标识符。
            </p>

            <h2 class="text-2xl font-semibold mt-6 mb-3">什么是 Slug？</h2>
            <p>
              Slug 是 URL 中用于标识资源的字符串，通常使用小写字母、
              数字和连字符。相比数字 ID，slug 更具可读性，有利于 SEO。
            </p>

            <h2 class="text-2xl font-semibold mt-6 mb-3">动态路由的优势</h2>
            <ul class="list-disc pl-6 space-y-2">
              <li>SEO 友好</li>
              <li>用户可读</li>
              <li>易于分享</li>
              <li>语义明确</li>
            </ul>
          </div>
        </div>

        <footer class="mt-8 pt-6 border-t">
          <div class="bg-gray-50 p-4 rounded">
            <h3 class="font-mono text-sm mb-2">路由解析详情</h3>
            <div class="grid md:grid-cols-2 gap-4 text-sm">
              <div>
                <span class="text-gray-600">文件路径:</span>
                <br>
                <code class="text-xs">src/pages/posts/[slug].ex</code>
              </div>
              <div>
                <span class="text-gray-600">匹配模式:</span>
                <br>
                <code class="text-xs">/posts/{:slug}</code>
              </div>
              <div>
                <span class="text-gray-600">实际 URL:</span>
                <br>
                <code class="text-xs">/posts/{@slug}</code>
              </div>
              <div>
                <span class="text-gray-600">提取参数:</span>
                <br>
                <code class="text-xs">{@params_display}</code>
              </div>
            </div>
          </div>
        </footer>
      </article>

      <div class="bg-white rounded-lg p-6 shadow">
        <h2 class="text-xl font-semibold mb-4">更多示例</h2>
        <div class="grid md:grid-cols-2 gap-4">
          <a href="/posts/hello-world" class="block p-3 border rounded hover:bg-gray-50">
            <h3 class="font-semibold">Hello World</h3>
            <p class="text-sm text-gray-600">经典的编程入门文章</p>
          </a>
          <a href="/posts/elixir-tips" class="block p-3 border rounded hover:bg-gray-50">
            <h3 class="font-semibold">Elixir Tips</h3>
            <p class="text-sm text-gray-600">Elixir 编程技巧分享</p>
          </a>
          <a href="/posts/web-development-2024" class="block p-3 border rounded hover:bg-gray-50">
            <h3 class="font-semibold">Web Development 2024</h3>
            <p class="text-sm text-gray-600">2024年 Web 开发趋势</p>
          </a>
          <a href="/posts/functional-programming" class="block p-3 border rounded hover:bg-gray-50">
            <h3 class="font-semibold">Functional Programming</h3>
            <p class="text-sm text-gray-600">函数式编程思想</p>
          </a>
        </div>
      </div>
    </div>
    """
  end

  # 模拟文章数据
  defp find_post(slug) do
    posts = %{
      "hello-world" => %{
        title: "Hello World - 我的 Nex 框架之旅",
        author: "开发者",
        date: "2024-12-20",
        views: 1234,
        excerpt: "这是使用 Nex 框架创建的第一篇文章，展示了动态路由的强大功能。",
        topic: "Web 开发框架"
      },
      "elixir-tips" => %{
        title: "10 个 Elixir 编程技巧",
        author: "Elixir 专家",
        date: "2024-12-15",
        views: 892,
        excerpt: "分享 10 个实用的 Elixir 编程技巧，让你的代码更加优雅。",
        topic: "Elixir 编程"
      },
      "web-development-2024" => %{
        title: "2024 年 Web 开发趋势",
        author: "技术观察者",
        date: "2024-12-10",
        views: 2156,
        excerpt: "探讨 2024 年 Web 开发的最新趋势，包括 HTMX、Server Components 等。",
        topic: "Web 开发"
      },
      "functional-programming" => %{
        title: "函数式编程入门指南",
        author: "函数式编程爱好者",
        date: "2024-12-05",
        views: 1567,
        excerpt: "从零开始学习函数式编程，理解不可变性、纯函数等核心概念。",
        topic: "编程范式"
      }
    }

    Map.get(posts, slug, %{
      title: "未找到文章",
      author: "系统",
      date: "2024-12-01",
      views: 0,
      excerpt: "抱歉，没有找到 slug 为 #{slug} 的文章。",
      topic: "未知"
    })
  end
end
