defmodule NexAI.Middleware.ExtractReasoning do
  @moduledoc """
  Middleware that extracts reasoning from the model output.
  Maps to `extractReasoningMiddleware`.
  """
  @behaviour NexAI.Middleware

  def wrap(model, opts \\ []) do
    _tag_name = opts[:tag_name] || "reasoning"
    
    # In a real implementation, we would return a wrapped model struct that intercepts generate_text/stream_text
    # and parses the output to extract content within <reasoning> tags.
    # For now, we just return the model as this requires a deeper architecture change to intercept calls properly.
    # This is a placeholder for the architecture support.
    model
  end
end
