defmodule Nex do
  @moduledoc """
  Nex - A minimalist Elixir web framework powered by HTMX.
  
  ## Quick Start
  
      # src/pages/index.ex
      defmodule MyApp.Pages.Index do
        use Nex.Page
        
        def render(assigns) do
          ~H\"\"\"
          <h1>Hello, Nex!</h1>
          \"\"\"
        end
      end
  """
end
