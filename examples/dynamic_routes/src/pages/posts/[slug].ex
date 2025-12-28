defmodule DynamicRoutes.Pages.Posts.Slug do
  use Nex.Page

  def mount(%{"slug" => slug}) do
    %{
      title: "Post - #{slug}",
      slug: slug,
      post: find_post(slug),
      params_display: ~s(%{"slug" => "#{slug}"})
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
        <span>{@slug}</span>
      </nav>

      <article class="bg-white rounded-lg p-6 shadow">
        <header class="mb-6">
          <h1 class="text-3xl font-bold mb-2">{@post.title}</h1>
          <div class="flex items-center text-sm text-gray-500 space-x-4">
            <span>Author: {@post.author}</span>
            <span>Published: {@post.date}</span>
            <span>Views: {@post.views}</span>
          </div>
        </header>

        <div class="prose max-w-none">
          <p class="text-lg text-gray-700 mb-4">{@post.excerpt}</p>

          <div class="space-y-4">
            <p>
              This is an article about {@post.topic}. The article's slug is {@slug},
              which is a SEO-friendly URL identifier.
            </p>

            <h2 class="text-2xl font-semibold mt-6 mb-3">What is a Slug?</h2>
            <p>
              A slug is a string used to identify a resource in a URL, typically using lowercase letters,
              numbers, and hyphens. Compared to numeric IDs, slugs are more readable and beneficial for SEO.
            </p>

            <h2 class="text-2xl font-semibold mt-6 mb-3">Advantages of Dynamic Routes</h2>
            <ul class="list-disc pl-6 space-y-2">
              <li>SEO friendly</li>
              <li>User readable</li>
              <li>Easy to share</li>
              <li>Semantically clear</li>
            </ul>
          </div>
        </div>

        <footer class="mt-8 pt-6 border-t">
          <div class="bg-gray-50 p-4 rounded">
            <h3 class="font-mono text-sm mb-2">Route Parsing Details</h3>
            <div class="grid md:grid-cols-2 gap-4 text-sm">
              <div>
                <span class="text-gray-600">File Path:</span>
                <br>
                <code class="text-xs">src/pages/posts/[slug].ex</code>
              </div>
              <div>
                <span class="text-gray-600">Match Pattern:</span>
                <br>
                <code class="text-xs">/posts/{:slug}</code>
              </div>
              <div>
                <span class="text-gray-600">Actual URL:</span>
                <br>
                <code class="text-xs">/posts/{@slug}</code>
              </div>
              <div>
                <span class="text-gray-600">Extracted Parameters:</span>
                <br>
                <code class="text-xs">{@params_display}</code>
              </div>
            </div>
          </div>
        </footer>
      </article>

      <div class="bg-white rounded-lg p-6 shadow">
        <h2 class="text-xl font-semibold mb-4">More Examples</h2>
        <div class="grid md:grid-cols-2 gap-4">
          <a href="/posts/hello-world" class="block p-3 border rounded hover:bg-gray-50">
            <h3 class="font-semibold">Hello World</h3>
            <p class="text-sm text-gray-600">Classic programming introduction article</p>
          </a>
          <a href="/posts/elixir-tips" class="block p-3 border rounded hover:bg-gray-50">
            <h3 class="font-semibold">Elixir Tips</h3>
            <p class="text-sm text-gray-600">Elixir programming tips and tricks</p>
          </a>
          <a href="/posts/web-development-2024" class="block p-3 border rounded hover:bg-gray-50">
            <h3 class="font-semibold">Web Development 2024</h3>
            <p class="text-sm text-gray-600">2024 Web development trends</p>
          </a>
          <a href="/posts/functional-programming" class="block p-3 border rounded hover:bg-gray-50">
            <h3 class="font-semibold">Functional Programming</h3>
            <p class="text-sm text-gray-600">Functional programming concepts</p>
          </a>
        </div>
      </div>
    </div>
    """
  end

  # Mock post data
  defp find_post(slug) do
    posts = %{
      "hello-world" => %{
        title: "Hello World - My Nex Framework Journey",
        author: "Developer",
        date: "2024-12-20",
        views: 1234,
        excerpt: "This is the first article created with Nex framework, showcasing the power of dynamic routes.",
        topic: "Web Development Framework"
      },
      "elixir-tips" => %{
        title: "10 Elixir Programming Tips",
        author: "Elixir Expert",
        date: "2024-12-15",
        views: 892,
        excerpt: "Share 10 practical Elixir programming tips to make your code more elegant.",
        topic: "Elixir Programming"
      },
      "web-development-2024" => %{
        title: "2024 Web Development Trends",
        author: "Technology Observer",
        date: "2024-12-10",
        views: 2156,
        excerpt: "Explore the latest trends in 2024 Web development, including HTMX, Server Components, etc.",
        topic: "Web Development"
      },
      "functional-programming" => %{
        title: "Functional Programming Getting Started Guide",
        author: "Functional Programming Enthusiast",
        date: "2024-12-05",
        views: 1567,
        excerpt: "Learn functional programming from scratch, understand core concepts like immutability and pure functions.",
        topic: "Programming Paradigm"
      }
    }

    Map.get(posts, slug, %{
      title: "Post Not Found",
      author: "System",
      date: "2024-12-01",
      views: 0,
      excerpt: "Sorry, no post found with slug #{slug}.",
      topic: "Unknown"
    })
  end
end
