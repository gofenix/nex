# Nex 0.3.x Design Philosophy: The Evolution of Minimalism

> From 0.2.x to 0.3.x - How a Framework Found Its Identity

## 🙏 A Note Before We Begin

This document records my thoughts during the development of Nex.

Special thanks to the friends from **Reddit (r/elixir)** and **Elixir Forum**. Your feedback, questions, suggestions, and even criticism have helped me gradually understand what Nex should be. Without you, there would be no 0.3.x refactor.

I also want to thank the teams behind **Next.js**, **Phoenix**, and **HTMX**. Your work has been an endless source of inspiration.

---

## 📖 TL;DR

Simply put, 0.2.x was too complex: 4 different `use` statements, confusing API parameters, and unconventional directory naming.

With 0.3.x, I decided to subtract:
* Only one `use Nex`.
* API parameters reduced to just `query` and `body`, like Next.js.
* Directories renamed back to the familiar `components/`.
* Streaming responses became a simple function `Nex.stream/1`.

The result: less code, fewer concepts, and a smoother development experience.

---

## 🎯 The Core Problem: Finding Our Identity

While developing Nex 0.2.x, I was genuinely conflicted. I kept asking myself: What should Nex actually be? I tried many approaches, referenced many frameworks, but always felt something was missing.

### The Dilemma of 0.2.x

Look at this 0.2.x code:

```elixir
defmodule MyApp.Pages.Index do
  use Nex.Page  # Explicitly declare this is a Page
end

defmodule MyApp.Api.Users do
  use Nex.Api  # Explicitly declare this is an Api
end

defmodule MyApp.Partials.Card do
  use Nex.Partial  # Explicitly declare this is a Partial
end
```

This design looked rigorous, but it was exhausting to write. Since files are already in the `pages/` directory, why should I have to tell the framework again, "This is a Page"?

### Learning from Next.js

Later, I revisited Next.js. Its greatest strength is **convention over configuration**. You don't need to write any configuration code—just put files in the right place.

This is what Nex should be: let developers focus on business logic and write less boilerplate.

---

## 💡 Decision 1: One `use Nex` for Everything

### The Awkwardness Before

In 0.2.x, not only did you have to remember 4 different modules, you also had to understand the differences between them. This was entirely artificial cognitive burden.

### The Approach Now

0.3.x uses Elixir's macro system to automatically infer module types based on file paths.

```elixir
# 0.3.x - Much cleaner
defmodule MyApp.Pages.Index do
  use Nex
end

defmodule MyApp.Api.Users do
  use Nex
end
```

While this is a Breaking Change, it makes the code look much cleaner.

---

## 💡 Decision 2: Rename `partials/` to `components/`

This was actually a long-overdue correction.

I initially used `partials` because I was influenced by Rails and thought it had more of a "server-side rendering" flavor. But the reality is, the modern frontend world (React, Vue, Svelte) and Phoenix 1.7+ all use `components`.

Forcing `partials` only confused new users and offered no benefits. So we embraced the change and switched back to the familiar `components`.

---

## 💡 Decision 3: Writing REST APIs Is Finally Easy

### The Pain Point

Writing APIs in 0.2.x was torture. I had 4 places to put parameters: `params`, `path_params`, `query_params`, `body_params`. Developers had to think about where each parameter came from, adding cognitive burden.

Every time you wrote code, you had to wonder:
* "Is this `id` in the path or in the query?"
* "Should I use `params` or `query_params`?"
* "What's the difference between `body_params` and `params`?"

### Learning from Next.js

I looked at how Next.js does it. They offer only two options, yet cover all scenarios:

1. `req.query`: Handles all GET request parameters (whether in the path or after the `?`)
2. `req.body`: Handles all POST/PUT data

This is brilliantly simple. Developers only care about "Do I need to fetch data from the URL (Query)" or "Do I need to fetch data from the body (Body)".

So in 0.3.x, we do the same. The framework automatically unifies path parameters (like `/users/:id`) and query parameters (like `?page=1`) into `req.query`:

```elixir
def get(req) do
  # Both path parameter :id and query parameter ?page are here
  id = req.query["id"]
  page = req.query["page"]
end

def post(req) do
  # All submitted data is here
  user = req.body["user"]
end
```

This "no-brainer" experience is what a good framework should provide.

---

## 💡 Decision 4: Streaming Responses Are First-Class Citizens

In 2025, if a web framework requires effort to support SSE (Server-Sent Events), it's definitely outdated.

In 0.2.x, you needed `use Nex.SSE` and had to follow specific function signatures. But in the age of AI applications, streaming responses should be a standard capability available everywhere.

Now you can return a stream from anywhere:

```elixir
def get(req) do
  Nex.stream(fn send ->
    send.("Hello")
    Process.sleep(1000)
    send.("World")
  end)
end
```

Simple and direct, no magic tricks.

---

## 🎨 Summary: Finding Our Identity

When developing 0.1.x and 0.2.x, I was a bit greedy. I wanted to combine Phoenix's power, Next.js's simplicity, and Rails's classics all together. The result was a "Frankenstein" framework.

By 0.3.x, I finally figured it out: **Nex should not try to be another Phoenix.**

The Elixir community already has Phoenix, a perfect industrial-grade framework. Nex's mission should be to provide a **simple and lightweight** alternative (core code < 500 lines). It should be like Next.js, enabling developers (especially indie developers) to rapidly build usable products.

This is the entire point of Nex 0.3.x: **Embrace simplicity, return to developer intuition.**

---

## 🚀 Future Outlook

### 0.3.0 Is Just the Beginning

This refactor is not just about API changes, but a **shift in design philosophy**:

**From "Elixir's Phoenix" to "Elixir's Next.js"**

### Next Steps

1. **Exploring Datastar Integration**
   - Monitor Datastar's development as a Hypermedia framework
   - Evaluate whether it can provide finer-grained state updates than HTMX
   - Stay open to emerging technologies, but prioritize core DX improvements

2. **Ultimate Developer Experience (DX)**
   - Make the framework "better to use", not "more features"
   - More comprehensive documentation and real-world examples

### Core Values Remain Unchanged

No matter how Nex evolves, these core principles won't change:

- ✅ **Minimal**: Least code, maximum productivity
- ✅ **Modern**: Aligned with modern framework best practices
- ✅ **Practical**: Solving real-world problems

---

## 💭 A Word to Developers

### About Breaking Changes

Nex is currently in an early, fast-moving iteration phase. To pursue the ultimate developer experience, breaking changes may happen at any time.

But I promise: **I will document the thinking and reasoning behind every refactor in detail.**

It's not about change for change's sake, but about exploring the best development experience for Elixir. I hope that by sharing these thoughts, we can communicate, learn together, and collectively refine a truly great framework.

Rather than giving a cold "upgrade guide", I prefer to tell you "why I'm doing this".

### My Promise to Users

1. **Minimal API**: Only need to learn `use Nex` and a few response functions
2. **Familiar Developer Experience**: If you know Next.js, Nex's API design will feel natural
3. **Comprehensive Documentation**: Complete tutorials from beginner to advanced
4. **Active Community**: We will continue to improve and support

---

**Nex 0.3.x - Minimal, Modern, Practical Elixir Web Framework**

Let's build better web applications together! 🚀
