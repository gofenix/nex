defmodule NexAI.Middleware.DefaultSettings do
  @moduledoc """
  Middleware that applies default settings to model calls.
  Maps to `defaultSettingsMiddleware`.
  """
  @behaviour NexAI.Middleware

  def wrap(model, _opts \\ []) do
    # Similarly, this would return a wrapped model that merges default opts into every call.
    model
  end
end
