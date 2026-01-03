defmodule ErrorShowcase.Api.TriggerCrash do
  use Nex

  def get(_req) do
    # Intentionally crash to trigger 500 JSON error
    raise "This is an intentional API crash for demonstration purposes"
  end
end
