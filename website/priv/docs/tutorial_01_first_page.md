# Create Your First Page

In Nex, creating a page is very intuitive. You just need to create an Elixir module in the `src/pages/` directory and follow the `mount` and `render` conventions.

## 1. Basic Page Structure

A typical Nex page consists of two parts:

1.  **`mount/1`**: Handles business logic, initializes data, and returns a Map as `assigns`.
2.  **`render/1`**: Defines the UI using HEEx templates.

### Example: Hello World

Create `src/pages/hello.ex`:

```elixir
defmodule MyApp.Pages.Hello do
  use Nex

  # 1. Initialize data
  def mount(_params) do
    %{
      name: "World",
      time: Time.utc_now()
    }
  end

  # 2. Render template
  def render(assigns) do
    ~H"""
    <div class="p-10 shadow-lg rounded-xl bg-white">
      <h1 class="text-3xl font-bold">Hello, {@name}!</h1>
      <p class="text-gray-500 mt-2">Current server time: {@time}</p>
    </div>
    """
  end
end
```

## 2. Core Function Analysis

### `mount(params)`
*   **Input**: A Map containing URL path parameters and query parameters.
*   **Output**: Must return a Map. All keys in this Map will be automatically available as variables in the `render` template (e.g., `{@name}`).

### `render(assigns)`
*   **Input**: The `assigns` returned by `mount`.
*   **Syntax**: Uses the `~H` sigil, supporting standard HTML and HEEx syntax (e.g., `{@var}` interpolation, `<%= if ... %>` control flow).

## 3. Layout Constraints

Nex automatically wraps your page content in the layout defined in `src/layouts.ex`.

**Important Rule**:
The Layout template must contain a `<body>` tag. Nex's automation scripts (like CSRF protection, hot reload, state tracking) rely on hooks automatically injected before the `</body>` tag.

## Exercise: Personal Card

Try creating `src/pages/about.ex` to display your name, profession, and a short bio.

1.  Define your info in `mount`.
2.  Use Tailwind CSS in `render` to style it.
3.  Visit `http://localhost:4000/about` to see the result.
