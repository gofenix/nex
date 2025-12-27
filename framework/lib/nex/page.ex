defmodule Nex.Page do
  @moduledoc """
  Page module for rendering full HTML pages and handling HTMX requests.

  ## Usage

      defmodule MyApp.Pages.Index do
        use Nex.Page

        def mount(_params) do
          %{title: "Home", items: []}
        end

        def render(assigns) do
          ~H\"\"\"
          <h1>{@title}</h1>
          \"\"\"
        end

        # HTMX handler: POST /create_item
        def create_item(%{"name" => name}) do
          item = create(name)
          ~H"<li>{item.name}</li>"
        end

        # Return empty for delete
        def delete_item(%{"id" => id}) do
          delete(id)
          :empty
        end
      end
  """

  defmacro __using__(_opts) do
    quote do
      import Phoenix.Component, only: [sigil_H: 2]
      import Phoenix.HTML, only: [raw: 1]
    end
  end
end
