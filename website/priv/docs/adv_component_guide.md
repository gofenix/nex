# Component-Based Development

Nex supports a powerful component-based development model, helping you build maintainable and reusable UI interfaces.

## 1. UI Components

UI Components are the most basic unit of reuse in Nex. They are typically stored in the `src/components/` directory, but you can define them in any module.

### Defining a Component
A component is just a normal function that receives `assigns` and returns a `~H` template.

```elixir
defmodule MyApp.Components.Buttons do
  use Nex

  def primary_button(assigns) do
    ~H"""
    <button class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 transition">
      {render_slot(@inner_block)}
    </button>
    """
  end
end
```

### Using a Component
In a page, you can use the `<.component_name />` syntax to call it.

```elixir
def render(assigns) do
  ~H"""
  <div class="p-4">
    <MyApp.Components.Buttons.primary_button>
      Submit Application
    </MyApp.Components.Buttons.primary_button>
  </div>
  """
end
```

## 2. Slots

Slots allow you to pass complex HTML content to components.

*   **Default Slot**: Rendered using `{render_slot(@inner_block)}`.
*   **Named Slots**: Passed using the `<:slot_name>` syntax and accessed via `{@slot_name}`.

```elixir
def card(assigns) do
  ~H"""
  <div class="border rounded shadow">
    <div class="p-4 border-b font-bold bg-gray-50">
      {render_slot(@header)}
    </div>
    <div class="p-4">
      {render_slot(@inner_block)}
    </div>
  </div>
  """
end

# Usage
~H"""
<.card>
  <:header>Card Title</:header>
  This is the main content of the card.
</.card>
"""
```

## 3. Layout Contract

`src/layouts.ex` is the top-level container for your application. It must follow a set of "contracts" to ensure framework functionality works correctly.

### Core Variables
*   **`@inner_content`**: Must be rendered, representing the core HTML of the page. Use `{raw(@inner_content)}` to render it.
*   **`@title`**: The page title, returned by the page module's `mount/1` (defaults to "Nex App").

### Layout Example
```elixir
defmodule MyApp.Layouts do
  use Nex

  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="UTF-8" />
        <title>{@title}</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <script src="https://unpkg.com/htmx.org@2"></script>
      </head>
      <body hx-boost="true">
        <nav>...</nav>
        <main>
          {raw(@inner_content)}
        </main>
      </body>
    </html>
    """
  end
end
```

> **Zero boilerplate**: Nex automatically injects `<meta name="csrf-token">` into `</head>` and the HTMX CSRF configuration script before `</body>`. You do not need to add them manually.

## 4. Component Reuse Patterns

1.  **Single-File Components**: For UI fragments used only on the current page, you can define private functions (e.g., `defp my_widget(assigns)`) directly at the bottom of the page module.
2.  **Global Libraries**: Centralize common base components (buttons, inputs, cards) in `src/components/`.
3.  **Zero-Config Import**: Since `use Nex` automatically imports necessary macros for you, you don't need to manually `import Phoenix.Component`.
