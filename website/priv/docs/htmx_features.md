# HTMX Complete Feature Guide for Nex

This guide covers all HTMX features and how they integrate with the Nex framework. Nex is designed from the ground up to work seamlessly with HTMX, providing full support for all HTMX capabilities.

## Table of Contents

- [Core AJAX Attributes](#core-ajax-attributes)
- [Triggering Requests](#triggering-requests)
- [Targeting & Swapping](#targeting--swapping)
- [Request Indicators](#request-indicators)
- [Synchronization](#synchronization)
- [Out of Band Swaps](#out-of-band-swaps)
- [Parameters](#parameters)
- [Confirming Requests](#confirming-requests)
- [Attribute Inheritance](#attribute-inheritance)
- [Boosting](#boosting)
- [WebSockets & SSE](#websockets--sse)
- [History Support](#history-support)
- [Validation](#validation)
- [Animations](#animations)
- [Extensions](#extensions)
- [Events & Logging](#events--logging)
- [Security](#security)

---

## Core AJAX Attributes

HTMX provides five core attributes for making AJAX requests. **Nex fully supports all HTTP methods.**

### ✅ hx-get

Issue a GET request to the specified URL.

```html
<button hx-get="/api/users">Load Users</button>
```

**Nex Integration:**
```elixir
defmodule MyApp.Api.Users do
  use Nex

  def get(_params) do
    users = ["Alice", "Bob", "Charlie"]
    {:ok, %{users: users}}
  end
end
```

### ✅ hx-post

Issue a POST request to the specified URL.

```html
<form hx-post="/submit">
  <input name="email" type="email" />
  <button type="submit">Submit</button>
</form>
```

**Nex Integration:**
```elixir
defmodule MyApp.Pages.Index do
  use Nex

  def submit(params) do
    email = params["email"]
    ~H"""
    <p>Thanks, {email}!</p>
    """
  end
end
```

### ✅ hx-put

Issue a PUT request to the specified URL.

```html
<button hx-put="/api/todos/123">Update Todo</button>
```

**Nex Integration (v0.2.4+):**
```elixir
defmodule MyApp.Api.Todos.Id do
  use Nex

  def put(params) do
    id = params["id"]
    # Update todo logic
    {:ok, %{message: "Todo #{id} updated"}}
  end
end
```

### ✅ hx-patch

Issue a PATCH request to the specified URL.

```html
<button hx-patch="/api/users/123">Patch User</button>
```

**Nex Integration (v0.2.4+):**
```elixir
defmodule MyApp.Api.Users.Id do
  use Nex

  def patch(params) do
    id = params["id"]
    # Partial update logic
    {:ok, %{message: "User #{id} patched"}}
  end
end
```

### ✅ hx-delete

Issue a DELETE request to the specified URL.

```html
<button hx-delete="/api/todos/123">Delete Todo</button>
```

**Nex Integration (v0.2.4+):**
```elixir
defmodule MyApp.Api.Todos.Id do
  use Nex

  def delete(params) do
    id = params["id"]
    # Delete logic
    {:ok, %{message: "Todo #{id} deleted"}}
  end
end
```

**✅ Status: All HTTP methods fully supported in Nex v0.2.4+**

---

## Triggering Requests

HTMX allows you to control when requests are triggered using the `hx-trigger` attribute.

### ✅ Default Triggers

Different elements have natural trigger events:
- `input`, `textarea`, `select` → `change` event
- `form` → `submit` event
- Everything else → `click` event

**Nex Integration:**
```elixir
def render(assigns) do
  ~H"""
  <input hx-get="/search" name="q" placeholder="Search..." />
  <form hx-post="/submit">
    <button type="submit">Submit</button>
  </form>
  <button hx-get="/data">Click Me</button>
  """
end
```

### ✅ Custom Triggers

```html
<div hx-post="/mouse_entered" hx-trigger="mouseenter">
  Hover over me!
</div>
```

**Nex Integration:**
```elixir
def mouse_entered(_params) do
  ~H"<p>Mouse entered!</p>"
end
```

### ✅ Trigger Modifiers

HTMX supports several trigger modifiers:

**once** - Only trigger once:
```html
<div hx-get="/data" hx-trigger="click once">Click Once</div>
```

**changed** - Only trigger if value changed:
```html
<input hx-get="/search" hx-trigger="keyup changed" />
```

**delay** - Wait before triggering:
```html
<input hx-get="/search" hx-trigger="keyup changed delay:500ms" />
```

**throttle** - Throttle triggers:
```html
<input hx-get="/search" hx-trigger="keyup throttle:1s" />
```

**from** - Listen on different element:
```html
<input hx-get="/search" hx-trigger="keyup from:body" />
```

**Nex Integration Example (Active Search):**
```elixir
def render(assigns) do
  ~H"""
  <input 
    type="text" 
    name="q"
    hx-get="/search"
    hx-trigger="keyup changed delay:500ms"
    hx-target="#results"
    placeholder="Search..."
  />
  <div id="results"></div>
  """
end

def search(params) do
  query = params["q"]
  results = search_database(query)
  ~H"""
  <ul>
    <li :for={result <- results}>{result}</li>
  </ul>
  """
end
```

### ✅ Trigger Filters

Use JavaScript expressions to conditionally trigger:

```html
<div hx-get="/clicked" hx-trigger="click[ctrlKey]">
  Control+Click Me
</div>
```

**Nex Integration:**
Works out of the box - no special handling needed.

### ✅ Special Events

HTMX provides special trigger events:

**load** - Fires when element loads:
```html
<div hx-get="/data" hx-trigger="load">Loading...</div>
```

**revealed** - Fires when scrolled into viewport:
```html
<div hx-get="/more" hx-trigger="revealed">Load more...</div>
```

**intersect** - Fires on viewport intersection:
```html
<div hx-get="/data" hx-trigger="intersect once">
  Lazy load content
</div>
```

**Nex Integration:**
```elixir
def render(assigns) do
  ~H"""
  <div hx-get="/load_more" hx-trigger="revealed">
    Loading more items...
  </div>
  """
end

def load_more(_params) do
  items = get_next_page()
  ~H"""
  <div :for={item <- items}>{item}</div>
  """
end
```

**✅ Status: All trigger features fully supported**

---

## Targeting & Swapping

### ✅ hx-target

Specify where to load the response using CSS selectors.

```html
<button hx-get="/data" hx-target="#result">Load</button>
<div id="result"></div>
```

**Nex Integration:**
```elixir
def render(assigns) do
  ~H"""
  <button hx-get="/load_data" hx-target="#result">Load</button>
  <div id="result">Initial content</div>
  """
end

def load_data(_params) do
  ~H"<p>New content loaded!</p>"
end
```

### ✅ Extended CSS Selectors

HTMX supports extended selectors:

- `this` - The element itself
- `closest <selector>` - Closest ancestor
- `next <selector>` - Next sibling
- `previous <selector>` - Previous sibling
- `find <selector>` - First child descendant

```html
<tr>
  <td>Item 1</td>
  <td>
    <button hx-delete="/item/1" hx-target="closest tr">Delete</button>
  </td>
</tr>
```

**Nex Integration:**
```elixir
def render(assigns) do
  ~H"""
  <table>
    <tr :for={item <- @items}>
      <td>{item.name}</td>
      <td>
        <button 
          hx-delete={"/delete/#{item.id}"} 
          hx-target="closest tr"
          hx-swap="outerHTML"
        >
          Delete
        </button>
      </td>
    </tr>
  </table>
  """
end

def delete(params) do
  # Return empty to remove the row
  ~H""
end
```

**✅ Status: All targeting features fully supported**

### ✅ hx-swap

Control how content is swapped into the DOM.

**Swap Strategies:**
- `innerHTML` (default) - Replace inner HTML
- `outerHTML` - Replace entire element
- `beforebegin` - Insert before element
- `afterbegin` - Insert at start of element
- `beforeend` - Insert at end of element
- `afterend` - Insert after element
- `delete` - Delete the target element
- `none` - Don't swap, just process response

```html
<button hx-get="/data" hx-swap="outerHTML">Replace Me</button>
```

**Nex Integration:**
```elixir
def render(assigns) do
  ~H"""
  <div id="list">
    <button hx-get="/add_item" hx-target="#list" hx-swap="beforeend">
      Add Item
    </button>
  </div>
  """
end

def add_item(_params) do
  ~H"""
  <div class="item">New Item</div>
  """
end
```

### ✅ Swap Modifiers

HTMX supports swap modifiers:

- `transition:true` - Use View Transitions API
- `swap:<time>` - Delay swap (default 0ms)
- `settle:<time>` - Delay settle (default 20ms)
- `ignoreTitle:true` - Don't update page title
- `scroll:<selector>:top|bottom` - Scroll target
- `show:<selector>:top|bottom` - Show target

```html
<button hx-get="/data" hx-swap="innerHTML swap:100ms settle:200ms">
  Load with Delay
</button>
```

**Nex Integration:**
Works automatically - no special handling needed.

**✅ Status: All swap features fully supported**

---

## Request Indicators

### ✅ Loading States

HTMX automatically adds `htmx-request` class during requests.

```html
<button hx-get="/data">
  <span class="htmx-indicator">Loading...</span>
  Load Data
</button>

<style>
  .htmx-indicator { display: none; }
  .htmx-request .htmx-indicator { display: inline; }
</style>
```

**Nex Integration:**
```elixir
def render(assigns) do
  ~H"""
  <style>
    .htmx-indicator { display: none; }
    .htmx-request .htmx-indicator { display: inline; }
  </style>
  
  <button hx-get="/slow_operation">
    <span class="htmx-indicator">⏳ Loading...</span>
    <span class="htmx-request-hidden">Click Me</span>
  </button>
  """
end

def slow_operation(_params) do
  :timer.sleep(2000)
  ~H"<p>Operation complete!</p>"
end
```

**✅ Status: Fully supported**

---

## Synchronization

### ✅ hx-sync

Synchronize requests to prevent race conditions.

```html
<form hx-post="/submit" hx-sync="this:replace">
  <input name="email" />
  <button type="submit">Submit</button>
</form>
```

**Strategies:**
- `drop` - Drop new requests while one is in flight
- `abort` - Abort current request, make new one
- `replace` - Abort current, replace with new
- `queue` - Queue requests

**Nex Integration:**
```elixir
def render(assigns) do
  ~H"""
  <input 
    hx-get="/search"
    hx-trigger="keyup changed delay:500ms"
    hx-sync="this:replace"
    placeholder="Search..."
  />
  """
end
```

**✅ Status: Fully supported**

---

## Out of Band Swaps

### ✅ hx-swap-oob

Update multiple elements from a single response.

```html
<div id="main">Main content</div>
<div id="sidebar">Sidebar</div>
```

**Nex Integration:**
```elixir
def update_page(_params) do
  ~H"""
  <div id="main">
    Updated main content
  </div>
  <div id="sidebar" hx-swap-oob="true">
    Updated sidebar
  </div>
  """
end
```

**✅ Status: Fully supported**

---

## Parameters

### ✅ hx-params

Control which parameters are included in requests.

```html
<form hx-post="/submit" hx-params="email,name">
  <input name="email" />
  <input name="name" />
  <input name="ignore" />
</form>
```

**Nex Integration:**
```elixir
def submit(params) do
  # Only email and name will be present
  email = params["email"]
  name = params["name"]
  ~H"<p>Hello {name}!</p>"
end
```

### ✅ hx-vals

Add static values to requests.

```html
<button hx-post="/submit" hx-vals='{"action": "delete"}'>
  Delete
</button>
```

**Nex Integration:**
```elixir
def submit(params) do
  action = params["action"] # "delete"
  # Handle action
end
```

**✅ Status: Fully supported**

---

## Confirming Requests

### ✅ hx-confirm

Show confirmation dialog before request.

```html
<button hx-delete="/account" hx-confirm="Are you sure?">
  Delete Account
</button>
```

**Nex Integration:**
```elixir
def render(assigns) do
  ~H"""
  <button 
    hx-delete="/delete_account"
    hx-confirm="Are you sure you want to delete your account?"
  >
    Delete Account
  </button>
  """
end

def delete_account(_params) do
  # Delete logic
  ~H"<p>Account deleted</p>"
end
```

**✅ Status: Fully supported**

---

## Attribute Inheritance

### ✅ Inherited Attributes

Most HTMX attributes are inherited by child elements.

```html
<div hx-confirm="Are you sure?">
  <button hx-delete="/item/1">Delete 1</button>
  <button hx-delete="/item/2">Delete 2</button>
</div>
```

**Nex Integration:**
```elixir
def render(assigns) do
  ~H"""
  <div hx-target="#result" hx-swap="innerHTML">
    <button hx-get="/data1">Load 1</button>
    <button hx-get="/data2">Load 2</button>
  </div>
  <div id="result"></div>
  """
end
```

### ✅ Unset Inheritance

Use `unset` to disable inheritance.

```html
<div hx-confirm="Are you sure?">
  <button hx-delete="/item">Delete</button>
  <button hx-get="/" hx-confirm="unset">Cancel</button>
</div>
```

**✅ Status: Fully supported**

---

## Boosting

### ✅ hx-boost

Convert regular links and forms to AJAX requests.

```html
<div hx-boost="true">
  <a href="/page1">Page 1</a>
  <a href="/page2">Page 2</a>
</div>
```

**Nex Integration:**

Nex v0.2.3+ includes `hx-boost="true"` on the body tag by default in all layouts:

```elixir
def render(assigns) do
  ~H"""
  <!DOCTYPE html>
  <html>
    <head>
      <title>{@title}</title>
      <script src="https://unpkg.com/htmx.org@2.0.4"></script>
    </head>
    <body hx-boost="true">
      {raw(@inner_content)}
    </body>
  </html>
  """
end
```

**Benefits:**
- Smooth page transitions without full reload
- Maintains browser history
- Progressive enhancement
- Works without JavaScript

**✅ Status: Fully supported and enabled by default**

---

## WebSockets & SSE

### ✅ Server-Sent Events (SSE)

HTMX supports SSE via the `sse` extension.

```html
<div hx-ext="sse" sse-connect="/api/stream">
  <div sse-swap="message"></div>
</div>
```

**Nex Integration:**

Nex has first-class SSE support with `Nex.SSE`:

```elixir
defmodule MyApp.Api.Stream do
  use Nex

  @impl true
  def stream(params, send_fn) do
    # Stream loop
    stream_loop(send_fn)
  end

  defp stream_loop(send_fn) do
    data = get_current_data()
    send_fn.(%{event: "message", data: data})
    :timer.sleep(1000)
    stream_loop(send_fn)
  end
end
```

**Client-side:**
```elixir
def render(assigns) do
  ~H"""
  <div hx-ext="sse" sse-connect="/api/stream">
    <div sse-swap="message">Waiting for updates...</div>
  </div>
  """
end
```

**✅ Status: Fully supported with dedicated `Nex.SSE` behavior**

### ✅ WebSockets

HTMX supports WebSockets via the `ws` extension.

```html
<div hx-ext="ws" ws-connect="/chatroom">
  <div id="chat"></div>
  <form ws-send>
    <input name="message" />
  </form>
</div>
```

**Nex Integration:**

⚠️ **Status: Not directly supported** - Nex currently focuses on SSE for real-time features. WebSocket support would require additional implementation. For most real-time use cases, SSE is sufficient and simpler.

**Workaround:** Use Phoenix Channels or implement custom WebSocket handling with Bandit.

---

## History Support

### ✅ hx-push-url

Push URL to browser history.

```html
<a hx-get="/page2" hx-push-url="true">Go to Page 2</a>
```

**Nex Integration:**
```elixir
def render(assigns) do
  ~H"""
  <nav>
    <a hx-get="/about" hx-push-url="true">About</a>
    <a hx-get="/contact" hx-push-url="true">Contact</a>
  </nav>
  """
end
```

### ✅ History Restoration

HTMX sends `HX-History-Restore-Request` header when restoring from history.

**Nex Integration:**

Nex automatically handles history restoration. When a user hits the back button, HTMX will either:
1. Use cached content if available
2. Make a new request with the history header

```elixir
def mount(params) do
  # Nex automatically handles both initial and history requests
  %{
    title: "My Page",
    content: "Page content"
  }
end
```

**✅ Status: Fully supported**

---

## Validation

### ✅ HTML5 Validation

HTMX respects HTML5 validation attributes.

```html
<form hx-post="/submit">
  <input name="email" type="email" required />
  <button type="submit">Submit</button>
</form>
```

**Nex Integration:**
```elixir
def render(assigns) do
  ~H"""
  <form hx-post="/submit">
    <input name="email" type="email" required />
    <input name="age" type="number" min="18" max="100" />
    <button type="submit">Submit</button>
  </form>
  """
end

def submit(params) do
  # Validation already passed on client
  email = params["email"]
  age = params["age"]
  
  # Server-side validation
  case validate(email, age) do
    :ok -> ~H"<p>Success!</p>"
    {:error, msg} -> ~H"<p class='error'>{msg}</p>"
  end
end
```

### ✅ hx-validate

Force validation before request.

```html
<input name="email" hx-get="/check" hx-validate="true" />
```

**✅ Status: Fully supported**

---

## Animations

### ✅ CSS Transitions

HTMX works seamlessly with CSS transitions.

```html
<style>
  .item {
    opacity: 1;
    transition: opacity 200ms ease-out;
  }
  .item.htmx-swapping {
    opacity: 0;
  }
</style>

<div class="item" hx-get="/new-content">Content</div>
```

**Nex Integration:**
```elixir
def render(assigns) do
  ~H"""
  <style>
    .fade-in {
      animation: fadeIn 300ms ease-in;
    }
    @keyframes fadeIn {
      from { opacity: 0; }
      to { opacity: 1; }
    }
  </style>
  
  <div class="fade-in" hx-get="/load_content">
    Click to load
  </div>
  """
end
```

### ✅ View Transitions API

HTMX supports the new View Transitions API.

```html
<button hx-get="/data" hx-swap="innerHTML transition:true">
  Load with Transition
</button>
```

**Nex Integration:**
Works automatically - no special handling needed.

**✅ Status: Fully supported**

---

## Extensions

### ✅ Core Extensions

HTMX provides several official extensions:

**SSE Extension** - Server-Sent Events support
```html
<div hx-ext="sse" sse-connect="/stream">
  <div sse-swap="message"></div>
</div>
```
**✅ Fully supported with `Nex.SSE`**

**WebSocket Extension** - WebSocket support
```html
<div hx-ext="ws" ws-connect="/chat"></div>
```
**⚠️ Not directly supported - use Phoenix Channels**

**JSON Encoding** - Send JSON instead of form data
```html
<form hx-ext="json-enc" hx-post="/api/data"></form>
```
**✅ Fully supported**

**Morphdom** - DOM morphing for better animations
```html
<div hx-ext="morphdom-swap"></div>
```
**✅ Fully supported**

**Class Tools** - Toggle classes on events
```html
<div hx-ext="class-tools"></div>
```
**✅ Fully supported**

**Preload** - Preload content on hover
```html
<a hx-ext="preload" href="/page">Link</a>
```
**✅ Fully supported**

### ✅ Custom Extensions

You can create custom HTMX extensions.

**Nex Integration:**
Custom extensions work with Nex without any special handling.

**✅ Status: All extensions supported except WebSocket**

---

## Events & Logging

### ✅ HTMX Events

HTMX triggers numerous events during its lifecycle:

**Request Events:**
- `htmx:configRequest` - Before request is made
- `htmx:beforeRequest` - Before request is sent
- `htmx:afterRequest` - After request completes
- `htmx:responseError` - On response error

**Swap Events:**
- `htmx:beforeSwap` - Before swap occurs
- `htmx:afterSwap` - After swap occurs
- `htmx:beforeSettle` - Before settle
- `htmx:afterSettle` - After settle

**Nex Integration:**
```elixir
def render(assigns) do
  ~H"""
  <script>
    document.body.addEventListener('htmx:configRequest', (e) => {
      // Add custom headers
      e.detail.headers['X-Custom-Header'] = 'value';
    });
    
    document.body.addEventListener('htmx:afterSwap', (e) => {
      console.log('Content swapped!');
    });
  </script>
  
  <button hx-get="/data">Load Data</button>
  """
end
```

### ✅ hx-on Attributes

Handle events inline with `hx-on*` attributes.

```html
<button 
  hx-get="/data"
  hx-on::after-request="alert('Done!')"
>
  Load
</button>
```

**Nex Integration:**
```elixir
def render(assigns) do
  ~H"""
  <button 
    hx-get="/load_data"
    hx-on::after-request="console.log('Loaded!')"
  >
    Load Data
  </button>
  """
end
```

**✅ Status: Fully supported**

---

## Security

### ✅ CSRF Protection

HTMX automatically includes CSRF tokens in requests.

**Nex Integration:**

Nex has built-in CSRF protection:

```elixir
def render(assigns) do
  ~H"""
  <head>
    <meta name="csrf-token" content={Nex.CSRF.generate_token()} />
  </head>
  
  <form hx-post="/submit">
    {csrf_input_tag()}
    <input name="email" />
    <button type="submit">Submit</button>
  </form>
  """
end
```

For HTMX AJAX requests, add this to your layout:

```elixir
~H"""
<script>
  document.body.addEventListener('htmx:configRequest', (e) => {
    const token = document.querySelector('meta[name="csrf-token"]')?.content;
    if (token) {
      e.detail.headers['X-CSRF-Token'] = token;
    }
  });
</script>
"""
```

**✅ Status: Fully supported with `Nex.CSRF`**

### ✅ Content Security Policy (CSP)

HTMX supports CSP with `hx-on*` attributes instead of inline scripts.

**Nex Integration:**
Use `hx-on*` attributes instead of inline event handlers.

**✅ Status: Fully supported**

### ✅ XSS Prevention

Always escape user content in responses.

**Nex Integration:**

HEEx templates automatically escape content:

```elixir
def render(assigns) do
  ~H"""
  <p>{@user_input}</p>  <!-- Automatically escaped -->
  <p>{raw(@trusted_html)}</p>  <!-- Use raw() only for trusted content -->
  """
end
```

**✅ Status: Automatic XSS protection via HEEx**

---

## Feature Compatibility Matrix

| Feature | HTMX | Nex Support | Notes |
|---------|------|-------------|-------|
| **HTTP Methods** | | | |
| GET | ✅ | ✅ | Full support |
| POST | ✅ | ✅ | Full support |
| PUT | ✅ | ✅ | v0.2.4+ |
| PATCH | ✅ | ✅ | v0.2.4+ |
| DELETE | ✅ | ✅ | v0.2.4+ |
| **Triggers** | | | |
| Default triggers | ✅ | ✅ | Full support |
| Custom events | ✅ | ✅ | Full support |
| Trigger modifiers | ✅ | ✅ | once, changed, delay, throttle, from |
| Trigger filters | ✅ | ✅ | JavaScript expressions |
| Special events | ✅ | ✅ | load, revealed, intersect |
| **Targeting** | | | |
| CSS selectors | ✅ | ✅ | Full support |
| Extended selectors | ✅ | ✅ | this, closest, next, previous, find |
| **Swapping** | | | |
| All swap strategies | ✅ | ✅ | innerHTML, outerHTML, etc. |
| Swap modifiers | ✅ | ✅ | transition, swap, settle, etc. |
| Out of band swaps | ✅ | ✅ | Full support |
| **Features** | | | |
| Request indicators | ✅ | ✅ | Full support |
| Synchronization | ✅ | ✅ | Full support |
| Parameters | ✅ | ✅ | hx-params, hx-vals |
| Confirmation | ✅ | ✅ | hx-confirm |
| Inheritance | ✅ | ✅ | Full support |
| Boosting | ✅ | ✅ | Enabled by default in v0.2.3+ |
| History | ✅ | ✅ | hx-push-url |
| Validation | ✅ | ✅ | HTML5 + custom |
| Animations | ✅ | ✅ | CSS transitions |
| **Real-time** | | | |
| Server-Sent Events | ✅ | ✅ | First-class support with Nex.SSE |
| WebSockets | ✅ | ⚠️ | Use Phoenix Channels instead |
| **Security** | | | |
| CSRF Protection | ✅ | ✅ | Built-in with Nex.CSRF |
| XSS Prevention | ✅ | ✅ | Automatic via HEEx |
| CSP Support | ✅ | ✅ | Use hx-on* attributes |
| **Extensions** | | | |
| SSE Extension | ✅ | ✅ | Full support |
| JSON Encoding | ✅ | ✅ | Full support |
| Morphdom | ✅ | ✅ | Full support |
| Class Tools | ✅ | ✅ | Full support |
| Preload | ✅ | ✅ | Full support |
| WebSocket Extension | ✅ | ⚠️ | Not directly supported |
| Custom Extensions | ✅ | ✅ | Full support |

**Legend:**
- ✅ Fully supported
- ⚠️ Partial support or alternative available
- ❌ Not supported

---

## Summary

**Nex provides comprehensive support for HTMX**, with the framework designed from the ground up to work seamlessly with all HTMX features. The only notable exception is WebSocket support, where we recommend using Phoenix Channels or SSE as alternatives.

### Key Strengths

1. **Full HTTP Method Support** - GET, POST, PUT, PATCH, DELETE (v0.2.4+)
2. **First-Class SSE Support** - Dedicated `Nex.SSE` behavior
3. **Built-in Security** - CSRF protection and XSS prevention
4. **Zero Configuration** - HTMX boost enabled by default
5. **HEEx Integration** - Clean, type-safe templates
6. **RESTful APIs** - Full support with `Nex.Api`

### Getting Started

```bash
# Install Nex
mix archive.install hex nex_new

# Create new project
mix nex.new my_app
cd my_app

# Start development server
mix nex.dev
```

Your new Nex project comes with HTMX pre-configured and ready to use!

---

## Further Reading

- [HTMX Official Documentation](https://htmx.org/docs/)
- [Nex Framework Guide](https://github.com/gofenix/nex)
- [SSE Performance Guide](sse_performance.md)
- [HTMX Integration Guide](htmx_guide.md)
