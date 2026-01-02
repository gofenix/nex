defmodule Nex do
  @moduledoc """
  Nex - A minimalist Elixir web framework powered by HTMX.

  ## Unified Interface

  All Nex modules use the same simple statement:

      defmodule MyApp.Pages.Index do
        use Nex  # ← One statement for everything

        def render(assigns) do
          ~H\"\"\"
          <h1>Hello, Nex!</h1>
          \"\"\"
        end
      end

  Nex automatically detects the module type based on its path:

  - `*.Api.*` → API module (no imports needed)
  - `*.Pages.*` → Page module (imports HEEx + CSRF)
  - `*.Partials.*` → Partial module (imports HEEx + CSRF)
  - `*.Layouts` → Layout module (imports HEEx + CSRF)

  ## Examples

  ### Page Module

      defmodule MyApp.Pages.Users.Index do
        use Nex

        def render(assigns) do
          ~H\"\"\"
          <div>Users List</div>
          \"\"\"
        end
      end

  ### API Module

      defmodule MyApp.Api.Users.Index do
        use Nex

        def get(req) do
          Nex.json(%{data: users})
        end
      end

  ### Partial Component

      defmodule MyApp.Partials.Users.Card do
        use Nex

        def render(assigns) do
          ~H\"\"\"
          <div class="card">{@user.name}</div>
          \"\"\"
        end
      end

  ### Layout Module

      defmodule MyApp.Layouts do
        use Nex

        def render(assigns) do
          ~H\"\"\"
          <!DOCTYPE html>
          <html>
            <body>{raw(@inner_content)}</body>
          </html>
          \"\"\"
        end
      end
  """

  alias Nex.Response

  @doc """
  Unified macro for all Nex modules.

  Automatically detects module type based on path and imports appropriate functions.
  """
  defmacro __using__(_opts) do
    # Get the calling module name at compile time
    caller_module = __CALLER__.module
    module_name = caller_module |> Module.split() |> Enum.join(".")

    cond do
      # API modules - no imports needed (pure functions)
      String.contains?(module_name, ".Api.") ->
        quote do
          # API modules are pure Elixir modules
          # No imports needed - just define get/1, post/1, etc.
        end

      # Page/Partial/Layout modules - need HEEx support
      String.contains?(module_name, ".Pages.") or
      String.contains?(module_name, ".Partials.") or
      String.ends_with?(module_name, ".Layouts") ->
        quote do
          import Phoenix.Component, only: [sigil_H: 2]
          import Phoenix.HTML, only: [raw: 1]
          import Nex.CSRF, only: [input_tag: 0, hx_headers: 0, meta_tag: 0, get_token: 0]
        end

      # Default: treat as page module
      true ->
        quote do
          import Phoenix.Component, only: [sigil_H: 2]
          import Phoenix.HTML, only: [raw: 1]
          import Nex.CSRF, only: [input_tag: 0, hx_headers: 0, meta_tag: 0, get_token: 0]
        end
    end
  end

  @doc """
  Constructs a JSON response.

  ## Options
    * `:status` - HTTP status code (default: 200)
    * `:headers` - Additional headers (default: %{})
  """
  def json(data, opts \\ []) do
    status = Keyword.get(opts, :status, 200)
    headers = Keyword.get(opts, :headers, %{})

    %Response{
      status: status,
      body: data,
      headers: headers,
      content_type: "application/json"
    }
  end

  @doc """
  Constructs a text response.
  """
  def text(text, opts \\ []) do
    status = Keyword.get(opts, :status, 200)
    %Response{
      status: status,
      body: text,
      content_type: "text/plain"
    }
  end

  @doc """
  Constructs an HTML response.

  Commonly used in HTMX scenarios to return HTML fragments.

  ## Examples

      def get(req) do
        Nex.html(\"\"\"
        <div class="user-card">
          <h2>User Profile</h2>
        </div>
        \"\"\")
      end

  ## Options
    * `:status` - HTTP status code (default: 200)
    * `:headers` - Additional headers (default: %{})
  """
  def html(content, opts \\ []) do
    status = Keyword.get(opts, :status, 200)
    headers = Keyword.get(opts, :headers, %{})

    %Response{
      status: status,
      body: content,
      headers: headers,
      content_type: "text/html"
    }
  end

  @doc """
  Constructs a redirect response.
  """
  def redirect(to, opts \\ []) do
    status = Keyword.get(opts, :status, 302)
    %Response{
      status: status,
      body: "",
      headers: %{"location" => to},
      content_type: "text/html"
    }
  end

  @doc """
  Constructs a response with only a status code.
  """
  def status(code) do
    %Response{status: code, body: ""}
  end
end
