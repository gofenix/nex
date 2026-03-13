defmodule ErrorPagesExample.Pages.NotFound do
  use Nex

  def mount(_params) do
    # This page doesn't exist - trigger 404
    :empty
  end
end
