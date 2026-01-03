defmodule ErrorShowcase.Pages.TriggerCrash do
  use Nex

  def mount(_params) do
    # Intentionally crash to trigger 500 error
    raise "This is an intentional crash for demonstration purposes"
  end

  def render(assigns) do
    ~H"<div>This will never be rendered</div>"
  end
end
