defmodule DynamicRoutes.Pages.Posts.Year.Month do
  use Nex.Page

  def mount(%{"year" => year, "month" => month}) do
    %{
      title: "#{year}-#{month} - Post Archive",
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
        <a href="/" class="hover:text-gray-700">Home</a>
        <span class="mx-2">/</span>
        <a href="/posts" class="hover:text-gray-700">Posts</a>
        <span class="mx-2">/</span>
        <span>{@year}</span>
        <span class="mx-2">/</span>
        <span>{@month}</span>
      </nav>

      <div class="bg-white rounded-lg p-6 shadow">
        <h1 class="text-2xl font-bold mb-2">{@year}-{@month} Post Archive</h1>
        <p class="text-gray-600 mb-6">Found {length(@posts)} posts</p>

        <div class="bg-blue-50 p-4 rounded mb-6">
          <h3 class="font-mono text-sm mb-2">Multi-Parameter Dynamic Routes</h3>
          <p class="text-sm text-gray-600">
            Demonstrates how to use multiple dynamic parameters in a URL and automatically extract them to params
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
              Published: {post.date} · Author: {post.author}
            </p>
            <p class="text-gray-700">{post.excerpt}</p>
          </div>
        </div>

        <div class="mt-8 bg-gray-50 p-4 rounded">
          <h3 class="font-semibold mb-3">Route Parsing Example</h3>
          <div class="grid md:grid-cols-3 gap-4 text-sm">
            <div>
              <span class="text-gray-600">File:</span>
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
          <h3 class="font-semibold mb-3">Other Months</h3>
          <div class="flex flex-wrap gap-2">
            <a href="/posts/2024/11" class="px-3 py-1 bg-gray-200 rounded hover:bg-gray-300 text-sm">
              2024-11
            </a>
            <a href="/posts/2024/10" class="px-3 py-1 bg-gray-200 rounded hover:bg-gray-300 text-sm">
              2024-10
            </a>
            <a href="/posts/2024/09" class="px-3 py-1 bg-gray-200 rounded hover:bg-gray-300 text-sm">
              2024-09
            </a>
            <a href="/posts/2023/12" class="px-3 py-1 bg-gray-200 rounded hover:bg-gray-300 text-sm">
              2023-12
            </a>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Mock post data
  defp find_posts(year, month) do
    all_posts = [
      %{
        slug: "hello-world",
        title: "Hello World - My Nex Framework Journey",
        author: "Developer",
        date: "2024-12-20",
        excerpt: "This is the first article created with Nex framework..."
      },
      %{
        slug: "elixir-tips",
        title: "10 Elixir Programming Tips",
        author: "Elixir Expert",
        date: "2024-12-15",
        excerpt: "Share 10 practical Elixir programming tips..."
      },
      %{
        slug: "web-development-2024",
        title: "2024 Web Development Trends",
        author: "Technology Observer",
        date: "2024-12-10",
        excerpt: "Explore the latest trends in 2024 Web development..."
      },
      %{
        slug: "functional-programming",
        title: "Functional Programming Getting Started Guide",
        author: "Functional Programming Enthusiast",
        date: "2024-12-05",
        excerpt: "Learn functional programming from scratch..."
      },
      %{
        slug: "htmx-tutorial",
        title: "HTMX Complete Guide",
        author: "Frontend Developer",
        date: "2024-11-25",
        excerpt: "Deep dive into how HTMX works..."
      },
      %{
        slug: "elixir-patterns",
        title: "Elixir Design Patterns",
        author: "Architect",
        date: "2024-11-15",
        excerpt: "Explore common design patterns in Elixir..."
      }
    ]

    # Filter posts for specified year and month
    Enum.filter(all_posts, fn post ->
      String.starts_with?(post.date, "#{year}-#{month}")
    end)
  end
end
