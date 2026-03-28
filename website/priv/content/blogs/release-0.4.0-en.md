# Announcing Nex 0.4.0: The Minimalist Elixir Framework for the AI Era

Today, we are thrilled to announce the release of **Nex 0.4.0**! 

Before diving into the new features, let’s take a step back: What exactly is Nex, and why did we build it?

## What is Nex?

**Nex** is a minimalist Elixir web framework powered by HTMX, designed specifically for rapid prototyping, indie hackers, and the AI era. 

While Phoenix is the undisputed king of enterprise Elixir applications, it brings a steep learning curve and substantial boilerplate. Nex takes a different approach, heavily inspired by modern meta-frameworks like Next.js, but built on the rock-solid foundation of the Erlang VM (BEAM).

Our core philosophy is **Convention over Configuration and Zero Boilerplate**.

### Core Features of Nex

*   **File-System Routing**: Your file system is your router. Drop a file in `src/pages/`, and you instantly get a route. It supports static routes (`index.ex`), dynamic segments (`[id].ex`), and catch-all paths (`[...path].ex`).
*   **Action Routing (Zero-JS Interactivity)**: Powered by HTMX. You can write a function like `def increment(req)` in your page module, and call it directly from your HTML using `hx-post="/increment"`. No need to define separate API endpoints or write client-side JavaScript.
*   **Native Real-Time (SSE & WebSockets)**: Native Server-Sent Events (`Nex.stream/1`) and WebSockets make it incredibly easy to build AI streaming responses or real-time chat apps with just a few lines of code.
*   **Ephemeral State Management**: Built-in memory stores (`Nex.Store` and `Nex.Session`) backed by ETS. State is isolated by `page_id`, preventing the "dirty state" issues common in traditional session mechanics.
*   **Built for AI (Vibe Coding)**: We designed the framework to be easily understood by LLMs. You can literally prompt an AI with "Build me a Todo app in Nex," and it will generate a fully working, single-file page module.

---

## What is New in Nex 0.4.0?

As Nex grows, we are introducing essential features to handle real-world user interactions safely and efficiently, while maintaining our minimalist DX.

### 🛡️ Declarative Data Validation (`Nex.Validator`)

Handling user input safely is a core requirement. In 0.4.0, we are introducing `Nex.Validator`, a built-in module for clean, declarative parameter validation and type casting.

Instead of manually parsing strings from `req.body`, you can now define concise validation rules:

```elixir
def create_user(req) do
  rules = [
    name: [required: true, type: :string, min: 3],
    age: [required: true, type: :integer, min: 18],
    email: [required: true, type: :string, format: ~r/@/]
  ]

  case Nex.Validator.validate(req.body, rules) do
    {:ok, valid_params} ->
      # valid_params.age is safely cast to an integer!
      DB.insert_user(valid_params)
      Nex.redirect("/dashboard")
      
    {:error, errors} ->
      # errors is a map: %{age: ["must be at least 18"]}
      render(%{errors: errors})
  end
end
```

### 📁 Secure File Uploads (`Nex.Upload`)

Handling `multipart/form-data` is now fully supported out of the box. The new `Nex.Upload` module allows you to access uploaded files directly from `req.body` and provides built-in utilities to validate file sizes and extensions securely.

```elixir
def upload_avatar(req) do
  upload = req.body["avatar"]

  rules = [
    max_size: 5 * 1024 * 1024, # 5MB limit
    allowed_types: ["image/jpeg", "image/png"]
  ]

  with :ok <- Nex.Upload.validate(upload, rules),
       {:ok, _path} <- Nex.Upload.save(upload, "priv/static/uploads", unique_name()) do
    
    Nex.Flash.put(:success, "Avatar updated!")
    {:redirect, "/profile"}
  else
    {:error, reason} -> 
      Nex.Flash.put(:error, reason)
      {:redirect, "/profile"}
  end
end
```

### 🎨 Custom Error Pages

Nex provides a clean stacktrace page in development, but in production, you want error pages (like 404 or 500) to match your site's branding. You can now configure a custom error module:

```elixir
Application.put_env(:nex_core, :error_page_module, MyApp.ErrorPages)
```

Just implement `render_error/4` in your module, and you have complete control over what users see when things go wrong.

### 🔧 Under the Hood Improvements

*   **Rate Limiter Fix**: Added periodic cleanup for expired ETS entries in `Nex.RateLimit` to prevent memory leaks.
*   **Installer Enhancements**: Hardened the `mix nex.new` generator against command injection and edge-case argument parsing.

---

## Getting Started & Upgrading

If you want to try Nex for the first time, getting started takes less than 2 minutes:

```bash
mix archive.install hex nex_new
mix nex.new my_app
cd my_app
mix nex.dev
```

To upgrade an existing application to 0.4.0, simply update your `mix.exs`:

```elixir
defp deps do
  [
    {:nex_core, "~> 0.4.0"}
  ]
end
```

Check out the [official documentation](https://github.com/gofenix/nex) or browse our [example projects](https://github.com/gofenix/nex/tree/main/examples) to see what you can build.

Happy shipping! 🚀
