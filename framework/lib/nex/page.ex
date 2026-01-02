defmodule Nex.Page do
  @moduledoc """
  DEPRECATED: Use `use Nex` instead.

  This module is kept for backward compatibility but will be removed in a future version.

  ## Migration

  Change:

      defmodule MyApp.Pages.Index do
        use Nex
      end

  To:

      defmodule MyApp.Pages.Index do
        use Nex
      end

  The framework will automatically detect your module type based on its path.

  ## Why the change?

  Nex now provides a unified interface: all modules (Pages, APIs, Partials, Layouts)
  use the same `use Nex` statement. The framework automatically detects the module
  type based on its path and imports the appropriate functions.

  This provides:
  - Simpler, more consistent API
  - Better alignment with Next.js philosophy
  - Reduced cognitive load for developers
  """

  defmacro __using__(_opts) do
    IO.warn("""
    `use Nex` is deprecated. Please use `use Nex` instead.

    The framework will automatically detect your module type based on its path.

    Migration:
      defmodule MyApp.Pages.Index do
        use Nex  # ← Change from `use Nex`
      end
    """, Macro.Env.stacktrace(__CALLER__))

    quote do
      import Phoenix.Component, only: [sigil_H: 2]
      import Phoenix.HTML, only: [raw: 1]
      import Nex.CSRF, only: [input_tag: 0, hx_headers: 0, meta_tag: 0, get_token: 0]
    end
  end
end
