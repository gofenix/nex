defmodule ErrorPagesExample.Pages.Admin do
  use Nex

  def mount(_params) do
    # Simulate an authorization check - return 403 response
    {:redirect, "/403"}
  end
end
