defmodule DynamicRoutes.Pages.Posts.Year.Month do
  use Nex.Page

  def mount(%{"year" => year, "month" => month}) do
    %{
      title: "#{year}年#{month}月 - 文章归档",
      year: year,
      month: month,
      posts: find_posts(year, month),
      params_display: ~s(%{"year" => "#{year}", "month" => "#{month}"})
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
        <span>{@year}</span>
        <span class="mx-2">/</span>
        <span>{@month}</span>
      </nav>

      <div class="bg-white rounded-lg p-6 shadow">
        <h1 class="text-2xl font-bold mb-2">{@year}年{@month}月 文章归档</h1>
        <p class="text-gray-600 mb-6">共找到 {length(@posts)} 篇文章</p>

        <div class="bg-blue-50 p-4 rounded mb-6">
          <h3 class="font-mono text-sm mb-2">多参数动态路由</h3>
          <p class="text-sm text-gray-600">
            展示了如何在 URL 中使用多个动态参数，并自动提取到 params 中
          </p>
        </div>

        <div class="space-y-4">
          <div :for={post <- @posts} class="border-b pb-4">
            <h3 class="text-lg font-semibold">
              <a href={"/posts/#{post.slug}"} class="text-blue-600 hover:text-blue-800">
                {post.title}
              </a>
            </h3>
            <p class="text-gray-600 text-sm mb-2">
              发布于: {post.date} · 作者: {post.author}
            </p>
            <p class="text-gray-700">{post.excerpt}</p>
          </div>
        </div>

        <div class="mt-8 bg-gray-50 p-4 rounded">
          <h3 class="font-semibold mb-3">路由解析示例</h3>
          <div class="grid md:grid-cols-3 gap-4 text-sm">
            <div>
              <span class="text-gray-600">文件:</span>
              <br>
              <code class="text-xs">posts/[year]/[month].ex</code>
            </div>
            <div>
              <span class="text-gray-600">URL:</span>
              <br>
              <code class="text-xs">/posts/{@year}/{@month}</code>
            </div>
            <div>
              <span class="text-gray-600">Params:</span>
              <br>
              <code class="text-xs">{@params_display}</code>
            </div>
          </div>
        </div>

        <div class="mt-6">
          <h3 class="font-semibold mb-3">其他月份</h3>
          <div class="flex flex-wrap gap-2">
            <a href="/posts/2024/11" class="px-3 py-1 bg-gray-200 rounded hover:bg-gray-300 text-sm">
              2024年11月
            </a>
            <a href="/posts/2024/10" class="px-3 py-1 bg-gray-200 rounded hover:bg-gray-300 text-sm">
              2024年10月
            </a>
            <a href="/posts/2024/09" class="px-3 py-1 bg-gray-200 rounded hover:bg-gray-300 text-sm">
              2024年09月
            </a>
            <a href="/posts/2023/12" class="px-3 py-1 bg-gray-200 rounded hover:bg-gray-300 text-sm">
              2023年12月
            </a>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # 模拟文章数据
  defp find_posts(year, month) do
    all_posts = [
      %{
        slug: "hello-world",
        title: "Hello World - 我的 Nex 框架之旅",
        author: "开发者",
        date: "2024-12-20",
        excerpt: "这是使用 Nex 框架创建的第一篇文章..."
      },
      %{
        slug: "elixir-tips",
        title: "10 个 Elixir 编程技巧",
        author: "Elixir 专家",
        date: "2024-12-15",
        excerpt: "分享 10 个实用的 Elixir 编程技巧..."
      },
      %{
        slug: "web-development-2024",
        title: "2024 年 Web 开发趋势",
        author: "技术观察者",
        date: "2024-12-10",
        excerpt: "探讨 2024 年 Web 开发的最新趋势..."
      },
      %{
        slug: "functional-programming",
        title: "函数式编程入门指南",
        author: "函数式编程爱好者",
        date: "2024-12-05",
        excerpt: "从零开始学习函数式编程..."
      },
      %{
        slug: "htmx-tutorial",
        title: "HTMX 完全指南",
        author: "前端开发者",
        date: "2024-11-25",
        excerpt: "深入了解 HTMX 的工作原理..."
      },
      %{
        slug: "elixir-patterns",
        title: "Elixir 设计模式",
        author: "架构师",
        date: "2024-11-15",
        excerpt: "探索 Elixir 中的常用设计模式..."
      }
    ]

    # 过滤指定年月的文章
    Enum.filter(all_posts, fn post ->
      String.starts_with?(post.date, "#{year}-#{month}")
    end)
  end
end
