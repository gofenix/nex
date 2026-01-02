# Nex Framework HEEx Template Guide

Nex framework uses Phoenix's HEEx (HTML + EEx) template engine, providing a way to write type-safe HTML templates.

## Table of Contents

- [Basic Syntax](#basic-syntax)
- [Variable Output](#variable-output)
- [Conditional Rendering](#conditional-rendering)
- [Loop Rendering](#loop-rendering)
- [Component Invocation](#component-invocation)
- [Attribute Binding](#attribute-binding)
- [Event Handling](#event-handling)
- [Slots](#slots)
- [Inline Elixir](#inline-elixir)
- [Layout and Page Structure](#layout-and-page-structure)
- [CSRF Protection](#csrf-protection)

---

## Basic Syntax

HEEx templates use the `~H"""..."""` sigil. In Nex, this is primarily used in `render/1` functions and Action functions.

```elixir
def render(assigns) do
  ~H"""
  <div class="container">
    <h1>Hello, World!</h1>
  </div>
  """
end
```

---

## Variable Output

### Assigns Variables (`@`) vs Local Variables

In HEEx templates, there are two types of variables:

#### 1. Assigns Variables (`@name`)
*   **Syntax**: `{@name}` or `@name`
*   **Scope**: Global (within the current rendering context).
*   **Source**: Passed from `mount/1` or action functions via the `assigns` map.
*   **Essence**: `@name` is shorthand for `assigns.name`.

#### 2. Local Variables
*   **Syntax**: `{name}`
*   **Scope**: Local (valid only within the block where it's defined).
*   **Source**: Usually defined in comprehensions (`:for`), `let` bindings, or inline Elixir code blocks.
*   **Note**: Do not add the `@` prefix to local variables.

```elixir
# Initialize variables in mount
def mount(_params) do
  %{
    title: "My Page",   # assigns variable
    items: [            # assigns variable
      %{name: "Apple"},
      %{name: "Banana"}
    ]
  }
end

def render(assigns) do
  ~H"""
  <!-- Using assigns variable -->
  <h1>{@title}</h1>
  
  <ul>
    <!-- item is a local variable defined by :for -->
    <li :for={item <- @items}>
      <!-- Access local variable without @ -->
      {item.name}
    </li>
  </ul>
  """
end
```

**Note**: In Action functions (e.g., handling POST requests), if you need to return a template, you must manually construct the `assigns` map, as Action functions do not automatically inherit previous assigns.

```elixir
def increment(_params) do
  count = Nex.Store.update(:count, 0, &(&1 + 1))
  # Must construct assigns, otherwise @count cannot be accessed in the template
  assigns = %{count: count}
  ~H"<div>{@count}</div>"
end
```

---

## Conditional Rendering

Use `:if` and `:else` attributes for conditional rendering:

```elixir
def render(assigns) do
  ~H"""
  <div>
    <button :if={@count > 0} class="btn-primary">Decrease</button>
    <button :if={@count == 0} class="btn-disabled">Zero</button>
    <!-- :else-if is not supported, use multiple :if -->
  </div>
  """
end
```

Use Elixir expressions in attributes for conditional logic:

```elixir
def render(assigns) do
  ~H"""
  <div class={"p-4 #{if @active, do: "bg-blue-500", else: "bg-gray-200"}"}>
    Content
  </div>
  """
end
```

---

## Loop Rendering

Use the `:for` attribute to iterate over lists:

```elixir
def render(assigns) do
  ~H"""
  <ul>
    <!-- Iterate over list -->
    <li :for={item <- @items} id={"item-#{item.id}"}>
      {item.name}
    </li>
    
    <!-- Iterate with index -->
    <li :for={{item, index} <- Enum.with_index(@items)}>
      #{index + 1}. {item.name}
    </li>
  </ul>
  """
end
```

---

## Component Invocation

### Invoking Partial Components

Components are typically defined in the `src/components/` directory. Components can be invoked directly in HEEx templates using their full module name.

#### Using `import`

Import the component module in the Page module, then use the `<.function_name />` syntax. Note that the dot `.` before the function name is required.

```elixir
defmodule MyApp.Pages.Index do
  use Nex
  # 1. Import component module
  import MyApp.Components.Button

  def render(assigns) do
    ~H"""
    <!-- 2. Invoke using <.function_name /> -->
    <.button label="Click me" />
    """
  end
end
```

**Component Definition Example**:

```elixir
# src/components/button.ex
defmodule MyApp.Components.Button do
  use Nex

  def button(assigns) do
    ~H"""
    <button class={@class}>
      {@label}
    </button>
    """
  end
end
```

---

## Attribute Binding

### Dynamic Attribute Values

Use `{}` to bind dynamic values:

```elixir
<div id={"user-#{@user.id}"} class={@css_class}>
  {@user.name}
</div>
```

### Boolean Attributes

```elixir
<input type="checkbox" checked={@completed} disabled={@readonly} />
```

The attribute exists when the value is `true` and is removed when `false`.

### Global Attributes (Attribute Spread)

You can pass all key-value pairs in a map as attributes to a tag:

```elixir
<div {@rest}>...</div>
```

---

## Event Handling (HTMX)

Nex integrates deeply with HTMX. You can use HTMX attributes directly.

### Click Events

```elixir
<button hx-post="/increment"
        hx-target="#counter"
        hx-swap="outerHTML">
  +1
</button>
```

### Form Submission

```elixir
<form hx-post="/submit"
      hx-target="#result"
      hx-swap="innerHTML">
  <input type="text" name="content" />
  <button type="submit">Submit</button>
</form>
```

### Passing Parameters

In addition to form inputs, you can use `hx-vals` to pass extra parameters:

```elixir
<button hx-post="/delete"
        hx-vals={Jason.encode!(%{id: @todo.id})}
        hx-target={"#todo-#{@todo.id}"}
        hx-swap="outerHTML">
  Delete
</button>
```

---

## Slots

Partial components support slots for wrapping content.

**Defining a Component**:
```elixir
def card(assigns) do
  ~H"""
  <div class="card">
    <div class="card-header">{@title}</div>
    <div class="card-body">
      <!-- Render default slot content -->
      {render_slot(@inner_block)}
    </div>
  </div>
  """
end
```

**Using a Component**:
```elixir
<.card title="My Card">
  <p>This is the card content.</p>
</.card>
```

---

## Layout and Page Structure

### Layout

Layouts are defined in `src/layouts.ex`. Nex automatically injects the Page render result into the Layout's `@inner_content` variable.

```elixir
# src/layouts.ex
def render(assigns) do
  ~H"""
  <!DOCTYPE html>
  <html>
    <head>...</head>
    <body>
      <main>
        <!-- Must include raw(@inner_content) -->
        {raw(@inner_content)}
      </main>
    </body>
  </html>
  """
end
```

**Note**: Do not remove `raw(@inner_content)` from the Layout, as the framework automatically injects necessary scripts (for CSRF handling and hot reloading).

---

## CSRF Protection

### CSRF Token Handling

Nex automatically handles CSRF Token transmission for all POST/PUT/DELETE requests.
When writing a Form, you do not need to manually add hidden fields because Nex's frontend script automatically intercepts HTMX requests and injects the `X-CSRF-Token` header.

> **Note**: Currently, Nex is primarily responsible for Token generation and transmission. Server-side validation relies on stateless token verification (but the default validation logic is relatively permissive in the current version).

1.  **Automatic HTMX Header Injection**: The framework injects a script that listens for `htmx:configRequest` events, adding the `X-CSRF-Token` header to all HTMX requests.
    *   **Implication**: You **do not** need to manually add CSRF token parameters when writing `hx-post` forms or buttons.

2.  **Regular Form Handling**: For non-HTMX regular HTML forms (i.e., traditional `<form method="post">`), you need to manually add a hidden input.

```elixir
<!-- Regular form needs this -->
<form method="post" action="/login">
  {csrf_input_tag()}
  <input type="text" name="username" />
  <button>Login</button>
</form>

<!-- HTMX form does not need manual addition, framework handles it -->
<form hx-post="/api/login">
  <input type="text" name="username" />
  <button>Login</button>
</form>
```

### Manually Getting the Token

If you need to use the token in JavaScript or elsewhere:

```elixir
# Output token string
{csrf_token()}

# Output hidden input tag
{csrf_input_tag()}
```

---

## Action Functions and Return Values

Action functions (handling POST/PUT etc.) only receive `params`. Depending on requirements, they can return different types of values:

### 1. Return HEEx Template (Partial Update)
This is the most common way, used with `hx-swap` to update part of the page. **Note that you must construct `assigns`**.

```elixir
def create_todo(params) do
  # ... business logic ...
  assigns = %{todo: new_todo}
  ~H"<.todo_item todo={@todo} />"
end
```

### 2. Return `:empty` (No Content)
Used for delete operations etc. where no content needs to be returned. Usually used with `hx-target` to remove elements.

```elixir
def delete_todo(%{"id" => id}) do
  # ... delete logic ...
  :empty # Returns 200 OK but empty content
end
```

### 3. Redirect `{:redirect, path}`
Used to jump to a page after an operation completes. Nex notifies the frontend to redirect via the `HX-Redirect` header.

```elixir
def login(params) do
  # ... login logic ...
  {:redirect, "/dashboard"}
end
```

### 4. Refresh Page `{:refresh, _}`
Forces the frontend to refresh the current page.

```elixir
def reset(_params) do
  {:refresh, []}
end
```

---

## Best Practices

### 1. Must Construct Assigns in Action Functions
Action functions do not receive `conn` or old `assigns`. If you use `~H` templates in an Action and reference variables (like `{@count}`), you must explicitly define the `assigns` variable within the function.

### 2. Helper Usage in Partial Components
`use Nex` automatically imports helpers like `csrf_input_tag`. However, in components using `use Nex`, these helpers are not available.
*   **Recommendation**: Use full name invocation in Components, e.g., `Nex.CSRF.input_tag()`.
*   **Or**: Pass needed values via `assigns`.

### 3. Keep Templates Simple

Avoid writing complex Elixir logic in templates.
*   **Recommendation**: Extract logic into private functions.
*   **Reason**: Templates should focus on presentation; complex logic reduces readability.

```elixir
# Not recommended
<div class={if @user.role == "admin" && @user.active, do: "bg-red-500", else: "bg-gray-200"}>

# Recommended
<div class={user_class(@user)}>

defp user_class(user) do
  if user.role == "admin" && user.active do
    "bg-red-500"
  else
    "bg-gray-200"
  end
end
```

### 4. Partial Component Naming
Usually matches the filename, e.g., `src/components/ui/button.ex` corresponds to `MyApp.Components.Ui.Button`. This helps with code organization and lookup.
