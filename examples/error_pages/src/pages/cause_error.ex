defmodule ErrorPagesExample.Pages.CauseError do
  use Nex

  def mount(_params) do
    # Intentionally cause an error to demonstrate 500 handling
    raise "This is a test error to demonstrate 500 error pages"
  end
end
